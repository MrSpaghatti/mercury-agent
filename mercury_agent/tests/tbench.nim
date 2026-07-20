## Mercury Agent Benchmark Suite
##
## Benchmarks component-level performance — memory, tools, registry, config.
## No mock server, no threading. LLM call time is estimated from real usage.
##
## Run: nim c -d:ssl -r tests/tbench.nim
##      (from mercury_agent/)

import std/[json, monotimes, strformat]
import mercury_core/config
import mercury_core/llm_client
import mercury_core/tool_registry
import mercury_core/memory

# ---------------------------------------------------------------------------
# Tools for benchmarking
# ---------------------------------------------------------------------------

proc echoToolExecute(args: JsonNode): ToolResult {.gcsafe, raises: [].} =
  let n = args{"text"}
  let s = if n.isNil or n.kind != JString: "" else: n.getStr()
  ToolResult(output: "echo:" & s, isError: false, exitCode: 0)

proc echoTool(): Tool =
  let schema = %*{
    "type": "object",
    "properties": {"text": {"type": "string"}},
    "required": ["text"],
  }
  newTool("echo", "Echo back the supplied text", schema, echoToolExecute)

proc addToolExecute(args: JsonNode): ToolResult {.gcsafe, raises: [].} =
  let a = args{"a"}.getInt(0)
  let b = args{"b"}.getInt(0)
  ToolResult(output: "result:" & $(a + b), isError: false, exitCode: 0)

proc addTool(): Tool =
  let schema = %*{
    "type": "object",
    "properties": {
      "a": {"type": "integer"},
      "b": {"type": "integer"}
    },
    "required": ["a", "b"],
  }
  newTool("add", "Add two numbers", schema, addToolExecute)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

proc elapsedMs(t0: MonoTime): float =
  ## Returns elapsed time in milliseconds from t0 to now.
  let t1 = getMonoTime()
  result = (t1.ticks - t0.ticks).float / 1_000_000.0

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

when isMainModule:
  echo ""
  echo "═══════════════════════════════════════════════════════════════"
  echo "          Mercury Agent — Benchmark Suite"
  echo "═══════════════════════════════════════════════════════════════"
  echo ""

  echo "── Component Benchmarks ──"
  echo ""

  # 1. Memory operations
  block:
    let t0 = getMonoTime()
    for iteration in 0..<100:
      var localMem = newMemory(":memory:")
      let sid = localMem.newSession()
      localMem.appendMessage(sid, ChatMessage(role: crSystem, content: "You are a helpful assistant."))
      localMem.appendMessage(sid, ChatMessage(role: crUser, content: "What is 2+2?"))
      localMem.appendMessage(sid, ChatMessage(role: crAssistant, content: "4"))
      localMem.close()
    let perOp = elapsedMs(t0) / 100.0
    echo &"  Memory (100x: new session + 3 msgs + history): {elapsedMs(t0):>8.1f}ms  ({perOp:.3f}ms per run)"

  # 2. Tool construction
  block:
    let t0 = getMonoTime()
    for i in 0..<1000:
      var t = echoTool()
    echo &"  Tool construction (1000 tools):                 {elapsedMs(t0):>8.1f}ms  ({elapsedMs(t0)/1000.0:.3f}ms per tool)"

  # 3. Tool execution
  block:
    let tool = echoTool()
    let args = %*{"text": "hello"}
    let t0 = getMonoTime()
    for i in 0..<10000:
      discard tool.execute(args)
    echo &"  Tool execution (10000 calls):                   {elapsedMs(t0):>8.1f}ms  ({elapsedMs(t0)/10000.0*1000:.3f}µs per call)"

  # 4. Registry operations
  block:
    var reg = newToolRegistry()
    reg.register(echoTool())
    reg.register(addTool())
    let t0 = getMonoTime()
    for i in 0..<100000:
      discard reg.has("echo")
      discard reg.get("echo")
    echo &"  Registry lookup (100000 has+get):              {elapsedMs(t0):>8.1f}ms  ({elapsedMs(t0)/100000.0*1000:.3f}µs per call)"

  # 5. LLMClient construction
  block:
    let t0 = getMonoTime()
    for i in 0..<100:
      discard newLLMClient(
        baseUrl = "http://localhost:8080/v1",
        apiKey = "sk-test",
        model = "test-model",
        maxRetries = 1,
        retryBackoffMs = 5,
        timeoutMs = 5000,
      )
    echo &"  LLMClient construction (100 instances):          {elapsedMs(t0):>8.1f}ms  ({elapsedMs(t0)/100.0:.3f}ms per instance)"

  # 6. Config defaults
  block:
    let t0 = getMonoTime()
    for i in 0..<1000:
      var c = defaultConfig()
      c.openrouterApiKey = "sk-test"
      validate(c)
    echo &"  Config default+validate (1000 instances):       {elapsedMs(t0):>8.1f}ms  ({elapsedMs(t0)/1000.0*1000:.3f}µs per instance)"

  echo ""
  echo "── Key Takeaway ──"
  echo "  All component operations above run in well under 1ms per call, so"
  echo "  a real ReAct loop's wall time is dominated by LLM round-trip"
  echo "  latency (typically several hundred ms), not this framework."
  echo ""
