## Tests for mercury_agent CLI helpers (mercury_agent.nim).
##
## These tests exercise the pieces of the CLI that don't require a live
## LLM endpoint:
##   - Config-override layering
##   - Sqlite-backed session listing / lookup
##   - The history and search subcommand entry points against an empty
##     fresh database
##
## Subcommands that talk to an LLM (`chat`, `ask`, `session`) are not
## covered here — `tagent_loop.nim` already exercises that path via the
## mock server. We instead make sure dispatch and option-parsing wiring
## is correct by invoking the dedicated proc entry points.

import std/[os, osproc, strutils, times, unittest]

import mercury_core/config
import mercury_core/llm_client
import mercury_core/memory
import mercury_agent

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

proc tempDbPath(): string =
  ## Returns a unique writable path for a fresh sqlite db. Files are
  ## removed in `teardownDb`.
  result = getTempDir() / ("mercury_cli_test_" & $getCurrentProcessId() &
                           "_" & $epochTime() & ".db")
  if fileExists(result):
    removeFile(result)

proc teardownDb(path: string) =
  ## Removes any sqlite/WAL artifacts left around by the test.
  for suffix in ["", "-wal", "-shm", "-journal"]:
    let p = path & suffix
    if fileExists(p):
      try: removeFile(p) except CatchableError: discard

proc minimalCfg(dbPath: string): MercuryConfig =
  ## Builds a self-contained MercuryConfig that does not need a config
  ## file or env vars.
  result = defaultConfig()
  result.dbPath = dbPath
  result.openrouterApiKey = "test-key"

proc seedSession(dbPath, content: string): string =
  ## Creates one session with one user message in a fresh memory db
  ## and returns the session id.
  var mem = newMemory(dbPath)
  defer: mem.close()
  let sid = mem.newSession()
  let msg = ChatMessage(role: crUser, content: content)
  mem.appendMessage(sid, msg)
  return sid

# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

suite "cli: applyOverrides":
  test "empty overrides leave config untouched":
    var cfg = defaultConfig()
    let before = cfg
    applyOverrides(cfg, emptyOverrides())
    check cfg.provider == before.provider
    check cfg.openrouterModel == before.openrouterModel
    check cfg.vllmModel == before.vllmModel
    check cfg.temperature == before.temperature

  test "model override applies to the active provider":
    var cfg = defaultConfig()
    cfg.provider = "openrouter"
    var ov = emptyOverrides()
    ov.model = "openrouter/mock"
    applyOverrides(cfg, ov)
    check cfg.openrouterModel == "openrouter/mock"
    # vllmModel is *not* changed when openrouter is active.
    check cfg.vllmModel == DefaultVllmModel

  test "model override targets vllmModel when provider=vllm":
    var cfg = defaultConfig()
    cfg.provider = "vllm"
    var ov = emptyOverrides()
    ov.model = "qwen-mock"
    applyOverrides(cfg, ov)
    check cfg.vllmModel == "qwen-mock"
    check cfg.openrouterModel == DefaultOpenrouterModel

  test "provider override switches active provider":
    var cfg = defaultConfig()
    var ov = emptyOverrides()
    ov.provider = "vllm"
    applyOverrides(cfg, ov)
    check cfg.provider == "vllm"

  test "temperature override only applies when explicitly set":
    var cfg = defaultConfig()
    cfg.temperature = 0.7
    var ov = emptyOverrides()
    applyOverrides(cfg, ov)
    check cfg.temperature == 0.7
    ov.hasTemperature = true
    ov.temperature = 0.1
    applyOverrides(cfg, ov)
    check cfg.temperature == 0.1

suite "cli: loadConfigWithOverrides":
  test "applies env-based overrides on top of defaults":
    putEnv("MERCURY_PROVIDER", "openrouter")
    putEnv("OPENROUTER_API_KEY", "fake-key")
    defer:
      delEnv("MERCURY_PROVIDER")
      delEnv("OPENROUTER_API_KEY")

    var ov = emptyOverrides()
    ov.envPath = "/dev/null"
    ov.model = "openrouter/test-model"
    let cfg = loadConfigWithOverrides(ov)
    check cfg.provider == "openrouter"
    check cfg.openrouterModel == "openrouter/test-model"
    check cfg.openrouterApiKey == "fake-key"

  test "rejects an invalid provider override":
    putEnv("OPENROUTER_API_KEY", "fake-key")
    defer: delEnv("OPENROUTER_API_KEY")
    var ov = emptyOverrides()
    ov.envPath = "/dev/null"
    ov.provider = "definitely-not-real"
    expect ConfigError:
      discard loadConfigWithOverrides(ov)

  test "rejects an out-of-range temperature":
    putEnv("OPENROUTER_API_KEY", "fake-key")
    defer: delEnv("OPENROUTER_API_KEY")
    var ov = emptyOverrides()
    ov.envPath = "/dev/null"
    ov.hasTemperature = true
    ov.temperature = 3.5
    expect ConfigError:
      discard loadConfigWithOverrides(ov)

suite "cli: resolveDbPath":
  test "expands a leading tilde to the home directory":
    var cfg = defaultConfig()
    cfg.dbPath = "~/.local/share/mercury/test.db"
    let resolved = resolveDbPath(cfg)
    check not resolved.startsWith("~")
    check resolved.endsWith("/.local/share/mercury/test.db")

  test "leaves an absolute path alone":
    var cfg = defaultConfig()
    cfg.dbPath = "/tmp/mercury-cli-resolved.db"
    check resolveDbPath(cfg) == "/tmp/mercury-cli-resolved.db"

suite "cli: listRecentSessions":
  test "returns empty seq when the db file does not exist":
    let path = "/tmp/mercury_cli_does_not_exist_" & $epochTime() & ".db"
    check listRecentSessions(path).len == 0

  test "lists most-recently-updated sessions in descending order":
    let path = tempDbPath()
    defer: teardownDb(path)

    # Sessions are ordered by `updated_at` (ISO seconds), so we space
    # them out by >1s to avoid same-second tiebreaker ambiguity.
    let s1 = seedSession(path, "first")
    sleep(1100)
    let s2 = seedSession(path, "second")
    sleep(1100)
    let s3 = seedSession(path, "third")

    let listed = listRecentSessions(path, limit = 10)
    check listed.len == 3
    check listed[0].id == s3
    check listed[1].id == s2
    check listed[2].id == s1
    for s in listed:
      check s.messageCount == 1
      check s.updatedAt.len > 0

  test "respects the limit parameter":
    let path = tempDbPath()
    defer: teardownDb(path)
    discard seedSession(path, "a")
    sleep(5)
    discard seedSession(path, "b")
    sleep(5)
    discard seedSession(path, "c")

    let listed = listRecentSessions(path, limit = 2)
    check listed.len == 2

suite "cli: sessionExists":
  test "returns false for a missing db":
    check not sessionExists(
      "/tmp/mercury_cli_missing_" & $epochTime() & ".db",
      "sess_anything")

  test "returns true only for ids that actually exist":
    let path = tempDbPath()
    defer: teardownDb(path)
    let sid = seedSession(path, "hello")
    check sessionExists(path, sid)
    check not sessionExists(path, "sess_does_not_exist")

suite "cli: cmdHistory and cmdSearch on a fresh db":
  test "history exits 0 with no sessions":
    let path = tempDbPath()
    defer: teardownDb(path)
    putEnv("MERCURY_DB_PATH", path)
    putEnv("OPENROUTER_API_KEY", "dummy")
    defer:
      delEnv("MERCURY_DB_PATH")
      delEnv("OPENROUTER_API_KEY")
    check cmdHistory(envFile = "/dev/null") == 0

  test "history exits 0 and finds seeded sessions":
    let path = tempDbPath()
    defer: teardownDb(path)
    discard seedSession(path, "alpha bravo")
    putEnv("MERCURY_DB_PATH", path)
    putEnv("OPENROUTER_API_KEY", "dummy")
    defer:
      delEnv("MERCURY_DB_PATH")
      delEnv("OPENROUTER_API_KEY")
    check cmdHistory(envFile = "/dev/null") == 0
    # Sanity check via the underlying helper.
    let listed = listRecentSessions(path, 10)
    check listed.len == 1

  test "search rejects an empty query":
    let path = tempDbPath()
    defer: teardownDb(path)
    putEnv("MERCURY_DB_PATH", path)
    putEnv("OPENROUTER_API_KEY", "dummy")
    defer:
      delEnv("MERCURY_DB_PATH")
      delEnv("OPENROUTER_API_KEY")
    let rc = cmdSearch(query = @[], envFile = "/dev/null")
    check rc == 2

  test "search returns 0 with no matches and 0 with a hit":
    let path = tempDbPath()
    defer: teardownDb(path)
    discard seedSession(path, "the quick brown fox")
    putEnv("MERCURY_DB_PATH", path)
    putEnv("OPENROUTER_API_KEY", "dummy")
    defer:
      delEnv("MERCURY_DB_PATH")
      delEnv("OPENROUTER_API_KEY")
    check cmdSearch(query = @["nonexistent"], envFile = "/dev/null") == 0
    check cmdSearch(query = @["quick"], envFile = "/dev/null") == 0

suite "cli: ask and session error handling without a live LLM":
  test "ask requires a question":
    putEnv("OPENROUTER_API_KEY", "dummy")
    defer: delEnv("OPENROUTER_API_KEY")
    check cmdAsk(question = @[], envFile = "/dev/null") == 2

  test "session requires an id":
    putEnv("OPENROUTER_API_KEY", "dummy")
    defer: delEnv("OPENROUTER_API_KEY")
    check cmdSession(id = @[], envFile = "/dev/null") == 2

  test "session reports unknown id without crashing":
    let path = tempDbPath()
    defer: teardownDb(path)
    putEnv("MERCURY_DB_PATH", path)
    putEnv("OPENROUTER_API_KEY", "dummy")
    defer:
      delEnv("MERCURY_DB_PATH")
      delEnv("OPENROUTER_API_KEY")
    let rc = cmdSession(id = @["sess_made_up"], envFile = "/dev/null")
    check rc == 4

suite "cli: binary smoke test":
  test "the built binary prints a usage banner with --help":
    let bin = currentSourcePath().parentDir().parentDir() / "mercury_agent"
    if not fileExists(bin):
      skip()
    else:
      let (output, code) = execCmdEx(bin & " --help")
      check code == 0
      check output.contains("chat")
      check output.contains("ask")
      check output.contains("history")
      check output.contains("search")
