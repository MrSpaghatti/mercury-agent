## Tests for mercury_core/config.nim

import std/[os, unittest]
import mercury_core/config

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

proc writeTempFile(path, content: string) =
  createDir(parentDir(path))
  writeFile(path, content)

template withEnv(key, val: string; body: untyped) =
  ## Temporarily sets an environment variable, then restores the original.
  let oldVal = getEnv(key)
  let hadOldVal = existsEnv(key)
  putEnv(key, val)
  try:
    body
  finally:
    if hadOldVal:
      putEnv(key, oldVal)
    else:
      delEnv(key)

# ---------------------------------------------------------------------------
# Suite: defaultConfig
# ---------------------------------------------------------------------------

suite "defaultConfig":
  test "returns expected defaults":
    let cfg = defaultConfig()
    check cfg.provider == "openrouter"
    check cfg.vllmEndpoint == "http://192.168.4.30:8000/v1"
    check cfg.openrouterEndpoint == "https://openrouter.ai/api/v1"
    check cfg.openrouterModel == "openrouter/auto"
    check cfg.vllmModel == "qwen2.5-7b-instruct"
    check cfg.maxTokens == 4096
    check cfg.temperature == 0.3
    check cfg.maxLoopIterations == 10
    check cfg.dbPath == "~/.local/share/mercury/mercury.db"
    check cfg.openrouterApiKey == ""

# ---------------------------------------------------------------------------
# Suite: parseEnvFile
# ---------------------------------------------------------------------------

suite "parseEnvFile":
  let tmpDir = getTempDir() / "mercury_test_env"

  setup:
    createDir(tmpDir)

  teardown:
    removeDir(tmpDir)

  test "returns empty seq for missing file":
    let pairs = parseEnvFile(tmpDir / "nonexistent.env")
    check pairs.len == 0

  test "parses simple key=value pairs":
    let path = tmpDir / "simple.env"
    writeTempFile(path, "FOO=bar\nBAZ=qux\n")
    let pairs = parseEnvFile(path)
    check pairs.len == 2
    check pairs[0] == ("FOO", "bar")
    check pairs[1] == ("BAZ", "qux")

  test "strips double-quoted values":
    let path = tmpDir / "quoted.env"
    writeTempFile(path, "KEY=\"hello world\"\n")
    let pairs = parseEnvFile(path)
    check pairs.len == 1
    check pairs[0] == ("KEY", "hello world")

  test "strips single-quoted values":
    let path = tmpDir / "squoted.env"
    writeTempFile(path, "KEY='hello world'\n")
    let pairs = parseEnvFile(path)
    check pairs.len == 1
    check pairs[0] == ("KEY", "hello world")

  test "ignores comment lines":
    let path = tmpDir / "comments.env"
    writeTempFile(path, "# this is a comment\nKEY=val\n")
    let pairs = parseEnvFile(path)
    check pairs.len == 1
    check pairs[0] == ("KEY", "val")

  test "ignores blank lines":
    let path = tmpDir / "blanks.env"
    writeTempFile(path, "\n\nKEY=val\n\n")
    let pairs = parseEnvFile(path)
    check pairs.len == 1

  test "handles empty value":
    let path = tmpDir / "empty_val.env"
    writeTempFile(path, "KEY=\n")
    let pairs = parseEnvFile(path)
    check pairs.len == 1
    check pairs[0] == ("KEY", "")

# ---------------------------------------------------------------------------
# Suite: loadConfig — defaults when no files exist
# ---------------------------------------------------------------------------

suite "loadConfig defaults":
  test "uses defaults when config file is missing":
    let cfg = loadConfig(
      configPath = "/nonexistent/path/config.toml",
      envFilePath = "/nonexistent/.env"
    )
    check cfg.provider == "openrouter"
    check cfg.maxTokens == 4096
    check cfg.temperature == 0.3

# ---------------------------------------------------------------------------
# Suite: loadConfig — TOML file overrides
# ---------------------------------------------------------------------------

suite "loadConfig TOML overrides":
  let tmpDir = getTempDir() / "mercury_test_toml"

  setup:
    createDir(tmpDir)

  teardown:
    removeDir(tmpDir)

  test "overrides provider from TOML":
    let cfgFile = tmpDir / "config.toml"
    writeTempFile(cfgFile, "[mercury]\nprovider=vllm\n")
    let cfg = loadConfig(configPath = cfgFile, envFilePath = "/nonexistent/.env")
    check cfg.provider == "vllm"

  test "overrides max_tokens from TOML":
    let cfgFile = tmpDir / "config.toml"
    writeTempFile(cfgFile, "[mercury]\nmax_tokens=2048\n")
    let cfg = loadConfig(configPath = cfgFile, envFilePath = "/nonexistent/.env")
    check cfg.maxTokens == 2048

  test "overrides temperature from TOML":
    let cfgFile = tmpDir / "config.toml"
    writeTempFile(cfgFile, "[mercury]\ntemperature=0.7\n")
    let cfg = loadConfig(configPath = cfgFile, envFilePath = "/nonexistent/.env")
    check cfg.temperature == 0.7

  test "overrides vllm_model from TOML":
    let cfgFile = tmpDir / "config.toml"
    writeTempFile(cfgFile, "[mercury]\nvllm_model=llama3-8b\n")
    let cfg = loadConfig(configPath = cfgFile, envFilePath = "/nonexistent/.env")
    check cfg.vllmModel == "llama3-8b"

  test "overrides db_path from TOML":
    let cfgFile = tmpDir / "config.toml"
    writeTempFile(cfgFile, "[mercury]\ndb_path=/tmp/test.db\n")
    let cfg = loadConfig(configPath = cfgFile, envFilePath = "/nonexistent/.env")
    check cfg.dbPath == "/tmp/test.db"

  test "overrides multiple fields from TOML":
    let cfgFile = tmpDir / "config.toml"
    writeTempFile(cfgFile, "[mercury]\nprovider=vllm\nmax_tokens=1024\nmax_loop_iterations=5\n")
    let cfg = loadConfig(configPath = cfgFile, envFilePath = "/nonexistent/.env")
    check cfg.provider == "vllm"
    check cfg.maxTokens == 1024
    check cfg.maxLoopIterations == 5

  test "raises ConfigError on invalid max_tokens":
    let cfgFile = tmpDir / "bad.toml"
    writeTempFile(cfgFile, "[mercury]\nmax_tokens=notanumber\n")
    expect ConfigError:
      discard loadConfig(configPath = cfgFile, envFilePath = "/nonexistent/.env")

# ---------------------------------------------------------------------------
# Suite: loadConfig — .env file overrides
# ---------------------------------------------------------------------------

suite "loadConfig .env overrides":
  let tmpDir = getTempDir() / "mercury_test_dotenv"

  setup:
    createDir(tmpDir)

  teardown:
    removeDir(tmpDir)

  test "loads OPENROUTER_API_KEY from .env":
    let envFile = tmpDir / ".env"
    writeTempFile(envFile, "OPENROUTER_API_KEY=sk-test-key\n")
    let cfg = loadConfig(
      configPath = "/nonexistent/config.toml",
      envFilePath = envFile
    )
    check cfg.openrouterApiKey == "sk-test-key"

  test "loads MERCURY_PROVIDER from .env":
    let envFile = tmpDir / ".env"
    writeTempFile(envFile, "MERCURY_PROVIDER=vllm\n")
    let cfg = loadConfig(
      configPath = "/nonexistent/config.toml",
      envFilePath = envFile
    )
    check cfg.provider == "vllm"

  test "loads MERCURY_VLLM_ENDPOINT from .env":
    let envFile = tmpDir / ".env"
    writeTempFile(envFile, "MERCURY_VLLM_ENDPOINT=http://10.0.0.1:8000/v1\n")
    let cfg = loadConfig(
      configPath = "/nonexistent/config.toml",
      envFilePath = envFile
    )
    check cfg.vllmEndpoint == "http://10.0.0.1:8000/v1"

# ---------------------------------------------------------------------------
# Suite: loadConfig — environment variable overrides
# ---------------------------------------------------------------------------

suite "loadConfig env var overrides":
  test "MERCURY_PROVIDER overrides config file":
    withEnv("MERCURY_PROVIDER", "vllm"):
      let cfg = loadConfig(
        configPath = "/nonexistent/config.toml",
        envFilePath = "/nonexistent/.env"
      )
      check cfg.provider == "vllm"

  test "MERCURY_VLLM_ENDPOINT overrides default":
    withEnv("MERCURY_VLLM_ENDPOINT", "http://custom:9000/v1"):
      let cfg = loadConfig(
        configPath = "/nonexistent/config.toml",
        envFilePath = "/nonexistent/.env"
      )
      check cfg.vllmEndpoint == "http://custom:9000/v1"

  test "MERCURY_MAX_TOKENS overrides default":
    withEnv("MERCURY_MAX_TOKENS", "512"):
      let cfg = loadConfig(
        configPath = "/nonexistent/config.toml",
        envFilePath = "/nonexistent/.env"
      )
      check cfg.maxTokens == 512

  test "MERCURY_TEMPERATURE overrides default":
    withEnv("MERCURY_TEMPERATURE", "1.0"):
      let cfg = loadConfig(
        configPath = "/nonexistent/config.toml",
        envFilePath = "/nonexistent/.env"
      )
      check cfg.temperature == 1.0

  test "MERCURY_MAX_LOOP_ITERATIONS overrides default":
    withEnv("MERCURY_MAX_LOOP_ITERATIONS", "3"):
      let cfg = loadConfig(
        configPath = "/nonexistent/config.toml",
        envFilePath = "/nonexistent/.env"
      )
      check cfg.maxLoopIterations == 3

  test "OPENROUTER_API_KEY overrides .env":
    withEnv("OPENROUTER_API_KEY", "env-key-override"):
      let cfg = loadConfig(
        configPath = "/nonexistent/config.toml",
        envFilePath = "/nonexistent/.env"
      )
      check cfg.openrouterApiKey == "env-key-override"

  test "env var overrides TOML file value":
    let tmpDir2 = getTempDir() / "mercury_test_priority"
    createDir(tmpDir2)
    defer: removeDir(tmpDir2)
    let cfgFile = tmpDir2 / "config.toml"
    writeTempFile(cfgFile, "[mercury]\nmax_tokens=2048\n")
    withEnv("MERCURY_MAX_TOKENS", "999"):
      let cfg = loadConfig(configPath = cfgFile, envFilePath = "/nonexistent/.env")
      check cfg.maxTokens == 999

  test "raises ConfigError on invalid MERCURY_MAX_TOKENS":
    withEnv("MERCURY_MAX_TOKENS", "bad"):
      expect ConfigError:
        discard loadConfig(
          configPath = "/nonexistent/config.toml",
          envFilePath = "/nonexistent/.env"
        )

  test "raises ConfigError on invalid MERCURY_TEMPERATURE":
    withEnv("MERCURY_TEMPERATURE", "bad"):
      expect ConfigError:
        discard loadConfig(
          configPath = "/nonexistent/config.toml",
          envFilePath = "/nonexistent/.env"
        )

# ---------------------------------------------------------------------------
# Suite: validate
# ---------------------------------------------------------------------------

suite "validate":
  test "valid config passes":
    let cfg = defaultConfig()
    validate(cfg)  # should not raise

  test "invalid provider raises ConfigError":
    var cfg = defaultConfig()
    cfg.provider = "unknown"
    expect ConfigError:
      validate(cfg)

  test "zero max_tokens raises ConfigError":
    var cfg = defaultConfig()
    cfg.maxTokens = 0
    expect ConfigError:
      validate(cfg)

  test "negative max_tokens raises ConfigError":
    var cfg = defaultConfig()
    cfg.maxTokens = -1
    expect ConfigError:
      validate(cfg)

  test "temperature above 2.0 raises ConfigError":
    var cfg = defaultConfig()
    cfg.temperature = 2.1
    expect ConfigError:
      validate(cfg)

  test "negative temperature raises ConfigError":
    var cfg = defaultConfig()
    cfg.temperature = -0.1
    expect ConfigError:
      validate(cfg)

  test "zero max_loop_iterations raises ConfigError":
    var cfg = defaultConfig()
    cfg.maxLoopIterations = 0
    expect ConfigError:
      validate(cfg)

  test "empty vllm_endpoint raises ConfigError":
    var cfg = defaultConfig()
    cfg.vllmEndpoint = ""
    expect ConfigError:
      validate(cfg)

  test "empty openrouter_endpoint raises ConfigError":
    var cfg = defaultConfig()
    cfg.openrouterEndpoint = ""
    expect ConfigError:
      validate(cfg)

  test "empty db_path raises ConfigError":
    var cfg = defaultConfig()
    cfg.dbPath = ""
    expect ConfigError:
      validate(cfg)
