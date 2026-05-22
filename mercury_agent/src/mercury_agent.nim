## Mercury agent CLI.
##
## Provides the user-facing command-line interface for the Mercury agent.
## Subcommands:
##   - chat                  Interactive REPL
##   - ask <question>        One-shot question
##   - session <id>          Resume an existing session, then chat
##   - history               List recent sessions
##   - search <query>        Full-text search across stored messages
##
## Configuration is loaded by `mercury_core/config.loadConfig()`. Per-run
## flags `--model`, `--provider`, and `--temperature` override the values
## in the loaded config without touching disk.

import std/[os, strutils, strformat, asyncdispatch, options]
import db_connector/db_sqlite

import mercury_core/config
import mercury_core/discord
import mercury_core/discord_bridge
import mercury_core/discord_mocks
import mercury_core/discord_types
import mercury_core/llm_client
import mercury_core/tool_registry
import mercury_core/memory
import mercury_core/thread_mapping
import mercury_core/file_tool
import mercury_core/file_path_validator
import mercury_core/message_chunker
from mercury_core/agent_dispatcher import AgentDispatcher, AgentRequest, newAgentDispatcher

import dimscord

import agent_loop
import tools/shell

# ---------------------------------------------------------------------------
# Globals for graceful Ctrl+C handling
# ---------------------------------------------------------------------------

var ctrlCRequested* = false
  ## Set by the SIGINT hook so the chat loop can exit cleanly between
  ## turns. Exposed for tests.

var daemonShutdownRequested* = false
  ## Set by the SIGINT hook in daemon mode to signal graceful shutdown.

proc onCtrlC() {.noconv.} =
  ctrlCRequested = true
  daemonShutdownRequested = true
  # Best-effort newline so the next prompt isn't glued to "^C".
  try: stdout.write("\n") except CatchableError: discard

# ---------------------------------------------------------------------------
# Config / dependency wiring
# ---------------------------------------------------------------------------

type
  RunOverrides* = object
    ## Per-run flag overrides. Empty/sentinel values mean "leave alone".
    model*: string
    provider*: string
    temperature*: float
    hasTemperature*: bool
    configPath*: string
    envPath*: string

proc emptyOverrides*(): RunOverrides =
  RunOverrides(
    model: "",
    provider: "",
    temperature: 0.0,
    hasTemperature: false,
    configPath: "",
    envPath: ".env",
  )

proc applyOverrides*(cfg: var MercuryConfig; ov: RunOverrides) =
  ## Mutates `cfg` to reflect any non-empty fields of `ov`. The model
  ## override is applied to whichever provider is currently active so a
  ## simple `--model x` works regardless of provider.
  if ov.provider.len > 0:
    cfg.provider = ov.provider
  if ov.model.len > 0:
    case cfg.provider
    of "vllm":       cfg.vllmModel = ov.model
    of "openrouter": cfg.openrouterModel = ov.model
    else:            cfg.openrouterModel = ov.model
  if ov.hasTemperature:
    cfg.temperature = ov.temperature

proc loadConfigWithOverrides*(ov: RunOverrides): MercuryConfig =
  ## Loads config from disk and applies per-run flag overrides. Validation
  ## is re-run after overrides so an invalid provider on the CLI surfaces
  ## as a `ConfigError`.
  result = loadConfig(configPath = ov.configPath, envFilePath = ov.envPath)
  applyOverrides(result, ov)
  validate(result)

proc activeBaseUrl(cfg: MercuryConfig): string =
  case cfg.provider
  of "vllm":       cfg.vllmEndpoint
  of "openrouter": cfg.openrouterEndpoint
  else:            cfg.openrouterEndpoint

proc activeModel(cfg: MercuryConfig): string =
  case cfg.provider
  of "vllm":       cfg.vllmModel
  of "openrouter": cfg.openrouterModel
  else:            cfg.openrouterModel

proc activeApiKey(cfg: MercuryConfig): string =
  case cfg.provider
  of "openrouter": cfg.openrouterApiKey
  else:            ""

proc buildLLMClient*(cfg: MercuryConfig): LLMClient =
  ## Builds an LLMClient from a fully-resolved MercuryConfig.
  newLLMClient(
    baseUrl = activeBaseUrl(cfg),
    apiKey  = activeApiKey(cfg),
    model   = activeModel(cfg),
  )

proc buildRegistry*(): ToolRegistry =
  ## Builds the default tool registry for the agent. Currently registers
  ## only the shell tool.
  result = newToolRegistry()
  result.register(shellTool())

proc resolveDbPath*(cfg: MercuryConfig): string =
  ## Expands `~` in the configured DB path and ensures the parent dir
  ## exists. Returns the absolute path used for SQLite.
  result = cfg.dbPath
  if result.startsWith("~"):
    result = expandTilde(result)
  let parent = parentDir(result)
  if parent.len > 0 and not dirExists(parent):
    try: createDir(parent) except CatchableError: discard

proc openMemory*(cfg: MercuryConfig): Memory =
  ## Opens the memory store at the path configured in `cfg`.
  newMemory(resolveDbPath(cfg))

# ---------------------------------------------------------------------------
# Output formatting
# ---------------------------------------------------------------------------

proc printAssistant(text: string) =
  stdout.writeLine("Mercury> " & text)
  stdout.flushFile()

proc printSystemNote(text: string) =
  stdout.writeLine("[" & text & "]")
  stdout.flushFile()

proc printError(text: string) =
  stderr.writeLine("error: " & text)
  stderr.flushFile()

# ---------------------------------------------------------------------------
# Recent-sessions listing
#
# memory.nim does not expose a `listSessions` proc, so we open our own
# read-only sqlite handle against the same db file. This keeps the
# read-only modules untouched while still letting the CLI render the
# `history` view.
# ---------------------------------------------------------------------------

type
  SessionSummary* = object
    id*: string
    createdAt*: string
    updatedAt*: string
    messageCount*: int

proc listRecentSessions*(dbPath: string; limit: int = 20): seq[SessionSummary] =
  ## Returns up to `limit` most-recently-updated sessions. Returns an
  ## empty seq if the DB does not yet exist (no prior runs).
  result = @[]
  if not fileExists(dbPath):
    return
  let db = open(dbPath, "", "", "")
  defer: db.close()
  for row in db.fastRows(sql"""
    SELECT s.id, s.created_at, s.updated_at,
           (SELECT COUNT(*) FROM messages m WHERE m.session_id = s.id)
    FROM sessions s
    ORDER BY s.updated_at DESC
    LIMIT ?
  """, $limit):
    result.add(SessionSummary(
      id: row[0],
      createdAt: row[1],
      updatedAt: row[2],
      messageCount: parseInt(row[3]),
    ))

proc sessionExists*(dbPath, sessionId: string): bool =
  ## True if a session with the given id exists in the DB at `dbPath`.
  if not fileExists(dbPath):
    return false
  let db = open(dbPath, "", "", "")
  defer: db.close()
  let row = db.getRow(
    sql"SELECT id FROM sessions WHERE id = ?", sessionId)
  return row[0].len > 0

# ---------------------------------------------------------------------------
# Chat REPL
# ---------------------------------------------------------------------------

proc readLine(prompt: string): tuple[line: string, eof: bool] =
  ## Reads a single line of input. Returns `(text, eof=true)` on EOF.
  stdout.write(prompt)
  stdout.flushFile()
  try:
    let line = stdin.readLine()
    return (line, false)
  except EOFError:
    return ("", true)
  except IOError:
    return ("", true)

proc isExitCommand(line: string): bool =
  let s = line.strip().toLowerAscii()
  s in [":q", ":quit", ":exit", "/quit", "/exit", "exit", "quit"]

proc runOneTurn(
    cfg: MercuryConfig;
    llm: LLMClient;
    reg: ToolRegistry;
    mem: var Memory;
    userInput: string;
): AgentResult =
  ## Thin wrapper around `runAgentLoop` so the chat and ask commands
  ## share their per-turn logic.
  runAgentLoop(cfg, llm, reg, mem, userInput)

proc runChatLoop*(
    cfg: MercuryConfig;
    llm: LLMClient;
    reg: ToolRegistry;
    mem: var Memory;
    initialBanner: string = "";
) =
  ## Runs the interactive REPL until EOF or `:quit`. SIGINT between
  ## turns is treated as a clean exit.
  if initialBanner.len > 0:
    printSystemNote(initialBanner)
  printSystemNote("type :quit to exit; Ctrl+C to interrupt")
  while true:
    if ctrlCRequested:
      printSystemNote("interrupted")
      break
    let (line, eof) = readLine("> ")
    if eof:
      printSystemNote("eof")
      break
    if ctrlCRequested:
      printSystemNote("interrupted")
      break
    let trimmed = line.strip()
    if trimmed.len == 0:
      continue
    if isExitCommand(trimmed):
      printSystemNote("bye")
      break
    var res: AgentResult
    try:
      res = runOneTurn(cfg, llm, reg, mem, trimmed)
    except CatchableError as e:
      printError(e.msg)
      continue
    printAssistant(res.text)
    if res.stopReason != asrFinished:
      printSystemNote("stop reason: " & $res.stopReason)

# ---------------------------------------------------------------------------
# Subcommand entry points
# ---------------------------------------------------------------------------

proc cmdChat*(
    model = "";
    provider = "";
    temperature = -1.0;
    config = "";
    envFile = ".env";
): int =
  ## Interactive chat mode. Returns a process exit code.
  setControlCHook(onCtrlC)
  var ov = emptyOverrides()
  ov.model = model
  ov.provider = provider
  if temperature >= 0.0:
    ov.temperature = temperature
    ov.hasTemperature = true
  ov.configPath = config
  ov.envPath = envFile
  var cfg: MercuryConfig
  try:
    cfg = loadConfigWithOverrides(ov)
  except ConfigError as e:
    printError(e.msg); return 2
  let llm = buildLLMClient(cfg)
  let reg = buildRegistry()
  var mem = openMemory(cfg)
  defer: mem.close()
  runChatLoop(
    cfg, llm, reg, mem,
    initialBanner = fmt"chat: provider={cfg.provider} model={activeModel(cfg)}",
  )
  return 0

proc cmdAsk*(
    question: seq[string];
    model = "";
    provider = "";
    temperature = -1.0;
    config = "";
    envFile = ".env";
): int =
  ## Single-shot question mode.
  if question.len == 0:
    printError("ask requires a question")
    return 2
  var ov = emptyOverrides()
  ov.model = model
  ov.provider = provider
  if temperature >= 0.0:
    ov.temperature = temperature
    ov.hasTemperature = true
  ov.configPath = config
  ov.envPath = envFile
  var cfg: MercuryConfig
  try:
    cfg = loadConfigWithOverrides(ov)
  except ConfigError as e:
    printError(e.msg); return 2
  let llm = buildLLMClient(cfg)
  let reg = buildRegistry()
  var mem = openMemory(cfg)
  defer: mem.close()
  let userInput = question.join(" ")
  var res: AgentResult
  try:
    res = runAgentLoop(cfg, llm, reg, mem, userInput)
  except CatchableError as e:
    printError(e.msg); return 1
  stdout.writeLine(res.text)
  if res.stopReason != asrFinished:
    return 3
  return 0

proc replayHistory(history: seq[ChatMessage]) =
  ## Renders a previously-stored session to stdout so the user has
  ## context before resuming.
  for m in history:
    case m.role
    of crSystem:    discard      ## skip the system prompt
    of crUser:      stdout.writeLine("> " & m.content)
    of crAssistant:
      if m.content.len > 0:
        stdout.writeLine("Mercury> " & m.content)
      elif m.toolCalls.len > 0:
        for tc in m.toolCalls:
          stdout.writeLine(fmt"[tool-call] {tc.name}({tc.arguments})")
    of crTool:
      stdout.writeLine(fmt"[tool-result {m.name}] {m.content}")
  stdout.flushFile()

proc cmdSession*(
    id: seq[string];
    model = "";
    provider = "";
    temperature = -1.0;
    config = "";
    envFile = ".env";
): int =
  ## Resume an existing session and continue chatting.
  if id.len == 0:
    printError("session requires an id")
    return 2
  let sessionId = id[0]
  setControlCHook(onCtrlC)
  var ov = emptyOverrides()
  ov.model = model
  ov.provider = provider
  if temperature >= 0.0:
    ov.temperature = temperature
    ov.hasTemperature = true
  ov.configPath = config
  ov.envPath = envFile
  var cfg: MercuryConfig
  try:
    cfg = loadConfigWithOverrides(ov)
  except ConfigError as e:
    printError(e.msg); return 2
  let dbPath = resolveDbPath(cfg)
  if not sessionExists(dbPath, sessionId):
    printError("no such session: " & sessionId); return 4
  let llm = buildLLMClient(cfg)
  let reg = buildRegistry()
  var mem = openMemory(cfg)
  defer: mem.close()
  let history = mem.getHistory(sessionId)
  printSystemNote(
    fmt"resuming session {sessionId} ({history.len} messages)")
  replayHistory(history)
  ## NOTE: runAgentLoop always opens a *new* session under the hood. We
  ## can't transparently extend the previous one without modifying the
  ## existing memory module, so we tell the user and continue with a
  ## fresh session for the new turns.
  printSystemNote(
    "starting a new session for follow-up turns " &
    "(history is read-only here)")
  runChatLoop(
    cfg, llm, reg, mem,
    initialBanner = fmt"session: provider={cfg.provider} model={activeModel(cfg)}",
  )
  return 0

proc cmdHistory*(
    limit = 20;
    config = "";
    envFile = ".env";
): int =
  ## List the most recently updated sessions.
  var ov = emptyOverrides()
  ov.configPath = config
  ov.envPath = envFile
  var cfg: MercuryConfig
  try:
    cfg = loadConfigWithOverrides(ov)
  except ConfigError as e:
    printError(e.msg); return 2
  let dbPath = resolveDbPath(cfg)
  let sessions = listRecentSessions(dbPath, limit)
  if sessions.len == 0:
    printSystemNote("no sessions yet")
    return 0
  echo fmt"{""SESSION ID"":<40}  {""UPDATED"":<25}  MSGS"
  for s in sessions:
    echo fmt"{s.id:<40}  {s.updatedAt:<25}  {s.messageCount}"
  return 0

proc cmdSearch*(
    query: seq[string];
    limit = 20;
    config = "";
    envFile = ".env";
): int =
  ## Search across stored message content.
  if query.len == 0:
    printError("search requires a query")
    return 2
  var ov = emptyOverrides()
  ov.configPath = config
  ov.envPath = envFile
  var cfg: MercuryConfig
  try:
    cfg = loadConfigWithOverrides(ov)
  except ConfigError as e:
    printError(e.msg); return 2
  var mem = openMemory(cfg)
  defer: mem.close()
  let q = query.join(" ")
  let hits = mem.searchHistory(q)
  if hits.len == 0:
    printSystemNote("no matches")
    return 0
  var shown = 0
  for r in hits:
    if shown >= limit: break
    echo fmt"[{r.sessionId}] {r.createdAt}  {r.role}"
    echo "  " & r.snippet
    inc shown
  return 0

# ---------------------------------------------------------------------------
# Wiring
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# Discord API callback wrappers
# ---------------------------------------------------------------------------
# These named procs wrap RealDiscordApi calls so they can be passed as
# callbacks to DiscordBot. Nim's {.async.} pragma doesn't work on inline
# proc literals, so we define them as named procs that capture the API
# adapter via closure.

proc makeSendFn(api: RealDiscordApi): SendMessageFn =
  proc send(channelId, content: string): Future[string] {.async.} =
    return await api.sendMessage(channelId, content)
  return send

proc makeTypingFn(api: RealDiscordApi): TriggerTypingFn =
  proc typing(channelId: string) {.async.} =
    await api.triggerTyping(channelId)
  return typing

proc makeCreateThreadFn(api: RealDiscordApi): CreateThreadFn =
  proc create(channelId, messageId, name: string): Future[string] {.async.} =
    return await api.createThread(channelId, messageId, name)
  return create

proc makeArchiveThreadFn(api: RealDiscordApi): ArchiveThreadFn =
  proc archive(threadId: string) {.async.} =
    await api.archiveThread(threadId)
  return archive

# ---------------------------------------------------------------------------
# Daemon command
# ---------------------------------------------------------------------------

proc cmdDaemon*(
    config = "";
    envFile = ".env";
): int =
  ## Starts the Discord bot daemon.
  ##
  ## Wires the DI-based DiscordBot with a real Dimscord client:
  ## 1. Loads config and reads the Discord token from the env var.
  ## 2. Creates a Dimscord client and RealDiscordApi adapter.
  ## 3. Builds the LLM client, tool registry, and memory store.
  ## 4. Opens the thread-mapping DB and initialises its schema.
  ## 5. Registers file tools conditionally (based on config).
  ## 6. Creates an AgentDispatcher whose callback sends results to Discord.
  ## 7. Wires the message_create event to onMessageCreate.
  ## 8. Starts the Discord gateway session.
  ## 9. Handles SIGINT/SIGTERM for graceful shutdown.
  setControlCHook(onCtrlC)
  var ov = emptyOverrides()
  ov.configPath = config
  ov.envPath = envFile
  var cfg: MercuryConfig
  try:
    cfg = loadConfigWithOverrides(ov)
  except ConfigError as e:
    printError(e.msg); return 2

  # Read Discord bot token from the configured env var
  let tokenEnv = cfg.discord.tokenEnv
  let token = getEnv(tokenEnv)
  if token.len == 0:
    printError("Discord token not found in env var: " & tokenEnv)
    return 2

  # Build LLM client
  let llm = buildLLMClient(cfg)

  # Build tool registry — file tools only, NO shell tool for Discord
  var reg = newToolRegistry()
  let fileRules = FileRules(
    sandboxDir: "",
    allowPatterns: cfg.discord.fileRules.allow,
    askPatterns: @[],
    denyPatterns: cfg.discord.fileRules.deny,
  )
  reg.register(fileReadTool(fileRules))
  # fileWriteTool needs a userId for permission checks; per-message user ID
  # will be wired in the full agent integration (task 4.16). For now we pass
  # an empty string — the tool-level permission check will use the config's
  # default allow/deny lists.
  reg.register(fileWriteTool(fileRules, cfg.discord, ""))

  # Open memory store
  var mem = openMemory(cfg)

  # Open thread-mapping DB
  let threadDbPath = resolveDbPath(cfg)
  let threadDb = open(threadDbPath, "", "", "")
  initThreadMappingSchema(threadDb)

  # Create Dimscord client
  let discord = newDiscordClient(token)

  # Create the real API adapter
  let api = newRealDiscordApi(discord.api)

  # Create a MockShard with the bot's user ID (populated on ready)
  var shard = newMockShard("")

  # Create the agent dispatcher — callback sends results to Discord
  let sendFn = makeSendFn(api)
  let dispatcher = newAgentDispatcher(proc(r: agent_dispatcher.AgentResult) =
    let text = if r.error.isSome: "Error: " & r.error.get()
               else: r.responseText
    let chunks = chunkMessage(text)
    for chunk in chunks:
      asyncCheck sendFn(r.channelId, chunk)
  )

  # Create the DI-based DiscordBot with real API callbacks
  let bot = newDiscordBot(
    sendMessage = makeSendFn(api),
    triggerTyping = makeTypingFn(api),
    createThread = makeCreateThreadFn(api),
    archiveThread = makeArchiveThreadFn(api),
    db = threadDb,
    config = cfg.discord,
    dispatcher = dispatcher,
    shard = shard,
  )

  # Graceful shutdown: SIGINT/SIGTERM closes DBs
  setControlCHook(onCtrlC)

  # Start the Discord bot (blocks until session ends or error)
  try:
    waitFor startDiscordBot(discord, bot)
  except CatchableError as e:
    printError("Daemon crashed: " & e.msg)
    threadDb.close()
    mem.close()
    return 1
  finally:
    if not daemonShutdownRequested:
      threadDb.close()
      mem.close()
  return 0

when isMainModule:
  import cligen

  ## We dispatchMulti so the user invokes subcommands as
  ##   mercury_agent chat
  ##   mercury_agent ask "what is 2+2?"
  ##   mercury_agent session sess_...
  ##   mercury_agent history
  ##   mercury_agent search "needle"
  dispatchMulti(
    [cmdChat,    cmdName = "chat",    help = {
      "model":       "override model name",
      "provider":    "override provider (openrouter|vllm)",
      "temperature": "override sampling temperature (0..2). " &
                     "Negative means leave at config default.",
      "config":      "path to TOML config (overrides default)",
      "envFile":     "path to .env file (default: .env)",
    }],
    [cmdAsk,     cmdName = "ask",     help = {
      "model":       "override model name",
      "provider":    "override provider (openrouter|vllm)",
      "temperature": "override sampling temperature (0..2). " &
                     "Negative means leave at config default.",
      "config":      "path to TOML config (overrides default)",
      "envFile":     "path to .env file (default: .env)",
    }],
    [cmdSession, cmdName = "session", help = {
      "model":       "override model name",
      "provider":    "override provider (openrouter|vllm)",
      "temperature": "override sampling temperature (0..2). " &
                     "Negative means leave at config default.",
      "config":      "path to TOML config (overrides default)",
      "envFile":     "path to .env file (default: .env)",
    }],
    [cmdHistory, cmdName = "history", help = {
      "limit":       "max sessions to show",
      "config":      "path to TOML config (overrides default)",
      "envFile":     "path to .env file (default: .env)",
    }],
    [cmdSearch,  cmdName = "search",  help = {
      "limit":       "max matches to show",
      "config":      "path to TOML config (overrides default)",
      "envFile":     "path to .env file (default: .env)",
    }],
    [cmdDaemon,  cmdName = "daemon",  help = {
      "config":      "path to TOML config (overrides default)",
      "envFile":     "path to .env file (default: .env)",
    }],
  )
