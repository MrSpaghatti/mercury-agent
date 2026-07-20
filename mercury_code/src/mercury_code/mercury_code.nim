## mercury_code — autonomous coding harness binary.
##
## Built on the ReAct agent loop from `mercury_agent/agent_loop`, extended
## with coding-specific tools (compile, test, read_file, write_file) from
## `mercury_code/code_tool`.
##
## Usage:
##   mercury_code --task "fix the off-by-one error in src/main.nim"
##   mercury_code --task "add tests for the parser module"
##   mercury_code --task "implement the fizzbuzz function in src/fizzbuzz.nim"
##
## Configuration:
##   Uses the same layered config as `mercury_agent` (see mercury_core/config).
##   Additional keys (TOML / env):
##     MERCURY_SANDBOX_ROOT      — absolute path the agent may touch
##     MERCURY_ALLOWED_EXTENSIONS — comma-separated list, e.g. ".nim,.c,.h"
##     MERCURY_BUILD_CMD         — build command, run from sandboxRoot
##     MERCURY_TEST_CMD          — test command, run from sandboxRoot
##     MERCURY_BUILD_TIMEOUT_MS  — build timeout in ms (default 120000)
##     MERCURY_TEST_TIMEOUT_MS   — test timeout in ms (default 300000)
##
## Out of scope (deferred):
##   - Docker container sandboxing (Phase 4+)
##   - Multi-file diffs and PR creation
##   - Branch-per-task isolation

import std/[os, strutils]

import mercury_core/config
import mercury_core/tool_registry
import mercury_core/build_llm_client
import mercury_core/memory
import mercury_core/agent_loop
import mercury_code/code_runner
import mercury_code/code_tool

const Version* = "0.1.0"

proc showHelp =
  echo "mercury_code --task <description>"
  echo "  --task <desc>   coding task to execute"
  echo "  --version       print version"
  echo "  --help          this message"
  echo ""
  echo "Environment variables:"
  echo "  MERCURY_CONFIG_PATH       path to config.toml"
  echo "  MERCURY_DB_PATH          SQLite memory database path"
  echo "  MERCURY_SANDBOX_ROOT     absolute path the agent may touch"
  echo "  MERCURY_ALLOWED_EXTENSIONS comma-separated, e.g. '.nim,.c,.h'"
  echo "  MERCURY_BUILD_CMD       build command run from sandboxRoot"
  echo "  MERCURY_TEST_CMD        test command run from sandboxRoot"
  echo "  MERCURY_BUILD_TIMEOUT_MS build timeout in ms (default 120000)"
  echo "  MERCURY_TEST_TIMEOUT_MS  test timeout in ms (default 300000)"

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

when isMainModule:
  let p = paramCount()
  if p >= 1 and paramStr(1) == "--help":
    showHelp()
    quit 0
  if p >= 1 and paramStr(1) == "--version":
    echo "mercury_code v", Version
    quit 0

  # Get task from positional argument (after any flags).
  let task =
    if p >= 1: paramStr(1)
    else: ""

  let cfg = loadConfig()
  let llm = buildLLMClient(cfg)
  var mem = newMemory(cfg.dbPath)
  let registry = newToolRegistry()

  # Build CodingHarnessConfig from env / config.
  var harnessCfg = defaultCodingHarnessConfig()
  harnessCfg.sandboxRoot = getEnv("MERCURY_SANDBOX_ROOT", "")

  let extEnv = getEnv("MERCURY_ALLOWED_EXTENSIONS", "")
  if extEnv.len > 0:
    harnessCfg.allowedExtensions = extEnv.split(',')
  else:
    harnessCfg.allowedExtensions = @[".nim", ".c", ".h", ".cfg", ".md", ".txt",
                                     ".json", ".toml", ".yml", ".yaml"]

  harnessCfg.buildCmd = getEnv("MERCURY_BUILD_CMD", "")
  harnessCfg.testCmd  = getEnv("MERCURY_TEST_CMD", "")
  let buildT = getEnv("MERCURY_BUILD_TIMEOUT_MS", "")
  harnessCfg.buildTimeoutMs = if buildT.len > 0: parseInt(buildT) else: 120_000
  let testT = getEnv("MERCURY_TEST_TIMEOUT_MS", "")
  harnessCfg.testTimeoutMs = if testT.len > 0: parseInt(testT) else: 300_000

  # Register coding tools.
  registry.register(compileTool(harnessCfg))
  registry.register(testTool(harnessCfg))
  registry.register(readFileTool(harnessCfg))
  registry.register(writeFileTool(harnessCfg))

  # Build agent config.
  let agentCfg = newAgentConfig(cfg)

  if task.len == 0:
    echo "Error: no task provided. Run with --help for usage."
    quit 1

  if harnessCfg.sandboxRoot.len == 0:
    echo "Error: MERCURY_SANDBOX_ROOT must be set to an absolute directory path."
    quit 1

  echo "Starting coding task: ", task
  let result = runAgentLoop(agentCfg, llm, registry, mem, task)
  echo "\nResult (", $result.stopReason, "):\n", result.text
  echo "\nStats: ", result.stats.totalTurns, " turns, ",
        result.stats.toolCallsMade, " tool calls, ",
        result.stats.totalTokens, " tokens"