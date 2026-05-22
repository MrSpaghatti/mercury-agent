## Mercury configuration module.
##
## Loads configuration from:
## 1. Built-in defaults
## 2. TOML config file at ~/.config/mercury/config.toml
## 3. .env file in the current working directory (API keys)
## 4. Environment variables (highest priority)
##
## Supported environment variable overrides:
##   MERCURY_PROVIDER, MERCURY_VLLM_ENDPOINT, MERCURY_OPENROUTER_ENDPOINT,
##   MERCURY_OPENROUTER_MODEL, MERCURY_VLLM_MODEL, MERCURY_MAX_TOKENS,
##   MERCURY_TEMPERATURE, MERCURY_MAX_LOOP_ITERATIONS, MERCURY_DB_PATH,
##   OPENROUTER_API_KEY

import std/[os, parsecfg, strutils, streams]
import discord_types

type
  MercuryConfig* = object
    provider*: string           ## "openrouter" or "vllm"
    vllmEndpoint*: string
    openrouterEndpoint*: string
    openrouterModel*: string
    vllmModel*: string
    maxTokens*: int
    temperature*: float
    maxLoopIterations*: int
    dbPath*: string
    openrouterApiKey*: string   ## loaded from .env or env var
    discord*: DiscordConfig

  ConfigError* = object of CatchableError

const
  DefaultProvider* = "openrouter"
  DefaultVllmEndpoint* = "http://192.168.4.30:8000/v1"
  DefaultOpenrouterEndpoint* = "https://openrouter.ai/api/v1"
  DefaultOpenrouterModel* = "openrouter/auto"
  DefaultVllmModel* = "qwen2.5-7b-instruct"
  DefaultMaxTokens* = 4096
  DefaultTemperature* = 0.3
  DefaultMaxLoopIterations* = 10
  DefaultDbPath* = "~/.local/share/mercury/mercury.db"

proc defaultConfig*(): MercuryConfig =
  ## Returns a MercuryConfig populated with all defaults.
  MercuryConfig(
    provider: DefaultProvider,
    vllmEndpoint: DefaultVllmEndpoint,
    openrouterEndpoint: DefaultOpenrouterEndpoint,
    openrouterModel: DefaultOpenrouterModel,
    vllmModel: DefaultVllmModel,
    maxTokens: DefaultMaxTokens,
    temperature: DefaultTemperature,
    maxLoopIterations: DefaultMaxLoopIterations,
    dbPath: DefaultDbPath,
    openrouterApiKey: "",
    discord: defaultDiscordConfig()
  )

proc parseEnvFile*(path: string): seq[tuple[key, val: string]] =
  ## Parses a .env file and returns key-value pairs.
  ## Lines starting with '#' are comments. Blank lines are skipped.
  ## Values may optionally be quoted with single or double quotes.
  result = @[]
  if not fileExists(path):
    return
  for line in lines(path):
    let trimmed = line.strip()
    if trimmed.len == 0 or trimmed.startsWith("#"):
      continue
    let eqPos = trimmed.find('=')
    if eqPos < 1:
      continue
    let key = trimmed[0 ..< eqPos].strip()
    var val = trimmed[eqPos + 1 .. ^1].strip()
    # Strip optional surrounding quotes
    if val.len >= 2:
      if (val[0] == '"' and val[^1] == '"') or
         (val[0] == '\'' and val[^1] == '\''):
        val = val[1 ..< val.len - 1]
    result.add((key, val))

proc parseCsvList(val: string): seq[string] =
  result = @[]
  for item in val.split(','):
    let stripped = item.strip()
    if stripped.len > 0:
      result.add(stripped)

proc applyTomlSection(cfg: var MercuryConfig; section, key, val: string) =
  ## Applies a single key-value pair from the TOML/INI config to cfg.
  ## Section "" means the global/root section.
  let k = key.toLowerAscii()
  case section.toLowerAscii()
  of "", "mercury":
    case k
    of "provider":           cfg.provider = val
    of "vllm_endpoint":      cfg.vllmEndpoint = val
    of "openrouter_endpoint": cfg.openrouterEndpoint = val
    of "openrouter_model":   cfg.openrouterModel = val
    of "vllm_model":         cfg.vllmModel = val
    of "max_tokens":
      let n = parseInt(val)
      cfg.maxTokens = n
    of "temperature":
      let f = parseFloat(val)
      cfg.temperature = f
    of "max_loop_iterations":
      let n = parseInt(val)
      cfg.maxLoopIterations = n
    of "db_path":            cfg.dbPath = val
    else: discard
  of "discord":
    case k
    of "token_env": cfg.discord.tokenEnv = val
    of "prefix": cfg.discord.prefix = val
    else: discard
  of "discord.admins":
    case k
    of "allow": cfg.discord.admins.allow = parseCsvList(val)
    of "deny": cfg.discord.admins.deny = parseCsvList(val)
    else: discard
  of "discord.users":
    case k
    of "allow": cfg.discord.users.allow = parseCsvList(val)
    of "deny": cfg.discord.users.deny = parseCsvList(val)
    else: discard
  of "discord.file_rules":
    case k
    of "allow": cfg.discord.fileRules.allow = parseCsvList(val)
    of "deny": cfg.discord.fileRules.deny = parseCsvList(val)
    else: discard
  of "discord.tools":
    case k
    of "allow": cfg.discord.tools.allow = parseCsvList(val)
    of "deny": cfg.discord.tools.deny = parseCsvList(val)
    else: discard
  else: discard

proc loadTomlFile(cfg: var MercuryConfig; path: string) =
  ## Loads config values from a TOML/INI file, overriding defaults.
  if not fileExists(path):
    return
  var stream = newFileStream(path, fmRead)
  if stream == nil:
    raise newException(ConfigError, "Cannot open config file: " & path)
  defer: stream.close()
  var parser: CfgParser
  open(parser, stream, path)
  defer: close(parser)
  var currentSection = ""
  while true:
    let event = next(parser)
    case event.kind
    of cfgEof:
      break
    of cfgSectionStart:
      currentSection = event.section
    of cfgKeyValuePair:
      try:
        applyTomlSection(cfg, currentSection, event.key, event.value)
      except ValueError as e:
        raise newException(ConfigError,
          "Invalid value for key '" & event.key & "' in " & path & ": " & e.msg)
    of cfgOption:
      discard
    of cfgError:
      raise newException(ConfigError,
        "Parse error in " & path & ": " & event.msg)

proc applyEnvVars(cfg: var MercuryConfig) =
  ## Applies environment variable overrides to cfg.
  let provider = getEnv("MERCURY_PROVIDER")
  if provider.len > 0:
    cfg.provider = provider

  let vllmEndpoint = getEnv("MERCURY_VLLM_ENDPOINT")
  if vllmEndpoint.len > 0:
    cfg.vllmEndpoint = vllmEndpoint

  let orEndpoint = getEnv("MERCURY_OPENROUTER_ENDPOINT")
  if orEndpoint.len > 0:
    cfg.openrouterEndpoint = orEndpoint

  let orModel = getEnv("MERCURY_OPENROUTER_MODEL")
  if orModel.len > 0:
    cfg.openrouterModel = orModel

  let vllmModel = getEnv("MERCURY_VLLM_MODEL")
  if vllmModel.len > 0:
    cfg.vllmModel = vllmModel

  let maxTokensStr = getEnv("MERCURY_MAX_TOKENS")
  if maxTokensStr.len > 0:
    try:
      cfg.maxTokens = parseInt(maxTokensStr)
    except ValueError:
      raise newException(ConfigError,
        "MERCURY_MAX_TOKENS must be an integer, got: " & maxTokensStr)

  let tempStr = getEnv("MERCURY_TEMPERATURE")
  if tempStr.len > 0:
    try:
      cfg.temperature = parseFloat(tempStr)
    except ValueError:
      raise newException(ConfigError,
        "MERCURY_TEMPERATURE must be a float, got: " & tempStr)

  let maxLoopStr = getEnv("MERCURY_MAX_LOOP_ITERATIONS")
  if maxLoopStr.len > 0:
    try:
      cfg.maxLoopIterations = parseInt(maxLoopStr)
    except ValueError:
      raise newException(ConfigError,
        "MERCURY_MAX_LOOP_ITERATIONS must be an integer, got: " & maxLoopStr)

  let dbPath = getEnv("MERCURY_DB_PATH")
  if dbPath.len > 0:
    cfg.dbPath = dbPath

  let apiKey = getEnv("OPENROUTER_API_KEY")
  if apiKey.len > 0:
    cfg.openrouterApiKey = apiKey

proc validate*(cfg: MercuryConfig) =
  ## Validates the configuration, raising ConfigError on invalid values.
  if cfg.provider != "openrouter" and cfg.provider != "vllm":
    raise newException(ConfigError,
      "provider must be 'openrouter' or 'vllm', got: '" & cfg.provider & "'")
  if cfg.maxTokens <= 0:
    raise newException(ConfigError,
      "max_tokens must be positive, got: " & $cfg.maxTokens)
  if cfg.temperature < 0.0 or cfg.temperature > 2.0:
    raise newException(ConfigError,
      "temperature must be between 0.0 and 2.0, got: " & $cfg.temperature)
  if cfg.maxLoopIterations <= 0:
    raise newException(ConfigError,
      "max_loop_iterations must be positive, got: " & $cfg.maxLoopIterations)
  if cfg.vllmEndpoint.len == 0:
    raise newException(ConfigError, "vllm_endpoint must not be empty")
  if cfg.openrouterEndpoint.len == 0:
    raise newException(ConfigError, "openrouter_endpoint must not be empty")
  if cfg.dbPath.len == 0:
    raise newException(ConfigError, "db_path must not be empty")

proc loadConfig*(
    configPath: string = "",
    envFilePath: string = ".env"
): MercuryConfig =
  ## Loads Mercury configuration with the following priority (highest wins):
  ##   1. Environment variables
  ##   2. .env file (API keys)
  ##   3. TOML config file
  ##   4. Built-in defaults
  ##
  ## configPath: path to the TOML config file.
  ##   Defaults to ~/.config/mercury/config.toml
  ## envFilePath: path to the .env file.
  ##   Defaults to ".env" in the current directory.
  result = defaultConfig()

  # Resolve config file path
  let cfgPath =
    if configPath.len > 0:
      configPath
    else:
      getHomeDir() / ".config" / "mercury" / "config.toml"

  # Layer 2: TOML file
  loadTomlFile(result, cfgPath)

  # Layer 3: .env file (API keys only)
  let envPairs = parseEnvFile(envFilePath)
  for (key, val) in envPairs:
    case key
    of "OPENROUTER_API_KEY":
      result.openrouterApiKey = val
    of "MERCURY_PROVIDER":
      result.provider = val
    of "MERCURY_VLLM_ENDPOINT":
      result.vllmEndpoint = val
    else: discard

  # Layer 4: Environment variables (highest priority)
  applyEnvVars(result)

  validate(result)
