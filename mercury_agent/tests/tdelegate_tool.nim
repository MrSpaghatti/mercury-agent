## Tests for the delegate tool execute proc.
##
## Directly tests `makeDelegateExecuteProc()` by setting up `gGlobals` and
## calling the returned closure with various argument combinations. These
## are pure unit tests that exercise the error-guard paths without running
## an agent loop or mock server.

import std/[json, unittest, strutils]

import mercury_core/config
import mercury_core/delegate
import mercury_core/persona
import mercury_core/tool_registry
import mercury_core/llm_client

import mercury_agent

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

proc resetGlobals() =
  ## Resets global state between tests to avoid cross-test contamination.
  gGlobals = nil

proc makeMinimalLLM(): LLMClient =
  ## Returns a minimal LLMClient with a non-empty baseUrl so delegation
  ## guards pass. The URL is fake — tests that exercise full delegation
  ## need a running mock server.
  result = LLMClient(baseUrl: "http://localhost:19999/v1")

proc makeRegistryWithPersona(name: string): PersonaRegistry =
  ## Returns a PersonaRegistry containing one persona with the given name.
  result = newPersonaRegistry()
  let pc = PersonaConfig(
    name: name,
    systemPrompt: "",
    maxIterations: 5,
    toolsAllow: @[],
    toolsDeny: @[],
    memoryScope: msOwnSessions,
    maxDelegationDepth: 2,
    maxDelegationsPerRun: 5,
  )
  registerPersona(result, pc)

proc initGlobals(
    personaName = "test",
    maxDepth = 2,
    maxDelegations = 5,
) =
  ## Sets up gGlobals with reasonable defaults for testing.
  let llm = makeMinimalLLM()
  let reg = makeRegistryWithPersona(personaName)
  let dc = DelegationConfig(
    maxDepth: maxDepth,
    maxDelegations: maxDelegations,
    personaName: personaName,
  )
  let cfg = defaultConfig()
  setGlobalLLMClient(llm)
  setPersonaRegistry(reg)
  setDelegationConfig(dc)
  setMercuryConfig(cfg)

# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

suite "delegate: validation guards":
  test "globals not initialized":
    resetGlobals()
    let exec = makeDelegateExecuteProc()
    let result = exec(%*{"persona": "test", "task": "do something"})
    check result.isError
    check result.exitCode == 1
    check result.output.contains("not initialized")

  test "missing persona argument":
    resetGlobals()
    initGlobals()
    let exec = makeDelegateExecuteProc()
    let result = exec(%*{"task": "do something"})
    check result.isError
    check result.output.contains("persona")
    check result.output.contains("required")

  test "missing task argument":
    resetGlobals()
    initGlobals()
    let exec = makeDelegateExecuteProc()
    let result = exec(%*{"persona": "test"})
    check result.isError
    check result.output.contains("task")
    check result.output.contains("required")

  test "unknown persona name":
    resetGlobals()
    initGlobals("known_persona")
    let exec = makeDelegateExecuteProc()
    let result = exec(%*{"persona": "unknown_persona", "task": "do something"})
    check result.isError
    check result.output.contains("unknown persona")
    check result.output.contains("known_persona")

  test "nil persona registry":
    resetGlobals()
    let llm = makeMinimalLLM()
    let dc = DelegationConfig(maxDepth: 2, maxDelegations: 5)
    setGlobalLLMClient(llm)
    setDelegationConfig(dc)
    # Deliberately not setting personaRegistry — it stays nil
    let exec = makeDelegateExecuteProc()
    let result = exec(%*{"persona": "test", "task": "do something"})
    check result.isError
    check result.output.contains("no persona registry")

suite "delegate: delegation limits":
  test "exhausted depth returns error":
    resetGlobals()
    initGlobals(maxDepth = 0, maxDelegations = 5)
    let exec = makeDelegateExecuteProc()
    let result = exec(%*{"persona": "test", "task": "do something"})
    check result.isError
    check result.output.contains("maximum delegation depth")

  test "exhausted per-run limit returns error":
    resetGlobals()
    initGlobals(maxDepth = 2, maxDelegations = 0)
    let exec = makeDelegateExecuteProc()
    let result = exec(%*{"persona": "test", "task": "do something"})
    check result.isError
    check result.output.contains("maximum delegations per run")

  test "slot consumption decrements counters":
    resetGlobals()
    initGlobals(maxDepth = 1, maxDelegations = 1)
    let exec = makeDelegateExecuteProc()
    # This should error at memory-open (no real DB path), but NOT at
    # delegation check — the counters should be decremented.
    let result = exec(%*{"persona": "test", "task": "do something"})
    # Memory will fail, but the slot was consumed before that.
    check gGlobals.delegationConfig.maxDepth == 0
    check gGlobals.delegationConfig.maxDelegations == 0

suite "delegate: params schema":
  test "makeDelegateParams returns valid schema":
    let params = makeDelegateParams()
    check params{"type"}.getStr() == "object"
    check params{"properties"}{"persona"}{"type"}.getStr() == "string"
    check params{"properties"}{"task"}{"type"}.getStr() == "string"
    check params{"required"}.len == 2
    let requiredNames = @[
      params{"required"}[0].getStr(),
      params{"required"}[1].getStr(),
    ]
    check requiredNames.contains("persona")
    check requiredNames.contains("task")

suite "delegate: tool registration":
  test "makeDelegateTool produces a valid Tool":
    resetGlobals()
    initGlobals()
    let tool = makeDelegateTool()
    check tool.name == "delegate"
    check tool.description.len > 0
    check tool.parameters{"type"}.getStr() == "object"

  test "buildRegistry includes delegate when globals are set":
    resetGlobals()
    initGlobals()
    let cfg = defaultConfig()
    let reg = buildRegistry(cfg)
    # Execute a no-op to verify the registry is valid
    let result = reg.execute("delegate", %*{
      "persona": "nonexistent",
      "task": "test"
    })
    # Should fail at 'unknown persona', not at 'tool not found'
    check result.isError
    check result.output.contains("unknown persona")
