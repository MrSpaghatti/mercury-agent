## Tests for mercury_core/tool_registry and mercury_agent/tools/shell.
##
## We test the registry directly, and the shell tool via the registry's
## execute path so we exercise both modules together.

import std/[json, strutils, unittest]

import mercury_core/tool_registry
import tools/shell

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

proc echoTool(): Tool =
  ## A trivial tool used to exercise registry plumbing.
  let params = %*{
    "type": "object",
    "properties": {
      "msg": {"type": "string"}
    },
    "required": ["msg"],
  }
  newTool(
    name = "echo",
    description = "Echo a message back",
    parameters = params,
    execute = proc (args: JsonNode): ToolResult {.gcsafe, raises: [].} =
      let msgNode = args{"msg"}
      if msgNode.isNil or msgNode.kind != JString:
        return ToolResult(output: "missing msg", isError: true, exitCode: -1)
      ToolResult(output: msgNode.getStr(), isError: false, exitCode: 0)
  )

proc fastShellOpts(timeoutMs: int = 5_000): ShellOptions =
  result = defaultShellOptions()
  result.timeoutMs = timeoutMs

# ---------------------------------------------------------------------------
# Registry basics
# ---------------------------------------------------------------------------

suite "ToolRegistry basics":
  test "newToolRegistry is empty":
    let reg = newToolRegistry()
    check reg.len == 0
    check reg.list().len == 0
    check reg.names().len == 0

  test "register and retrieve":
    let reg = newToolRegistry()
    reg.register(echoTool())
    check reg.len == 1
    check reg.has("echo")
    let t = reg.get("echo")
    check t.name == "echo"
    check t.description.contains("Echo")

  test "duplicate registration raises":
    let reg = newToolRegistry()
    reg.register(echoTool())
    expect ToolDuplicateError:
      reg.register(echoTool())

  test "missing tool raises ToolNotFoundError":
    let reg = newToolRegistry()
    expect ToolNotFoundError:
      discard reg.get("nope")

  test "unregister removes tool":
    let reg = newToolRegistry()
    reg.register(echoTool())
    check reg.unregister("echo")
    check reg.len == 0
    check (not reg.has("echo"))
    check (not reg.unregister("echo"))

  test "list preserves insertion order":
    let reg = newToolRegistry()
    reg.register(newTool("a", "A", emptyParameters(),
      proc (a: JsonNode): ToolResult {.gcsafe, raises: [].} =
        ToolResult(output: "a", isError: false, exitCode: 0)))
    reg.register(newTool("b", "B", emptyParameters(),
      proc (a: JsonNode): ToolResult {.gcsafe, raises: [].} =
        ToolResult(output: "b", isError: false, exitCode: 0)))
    reg.register(newTool("c", "C", emptyParameters(),
      proc (a: JsonNode): ToolResult {.gcsafe, raises: [].} =
        ToolResult(output: "c", isError: false, exitCode: 0)))
    check reg.names() == @["a", "b", "c"]

  test "newTool rejects empty name":
    expect ToolArgumentError:
      discard newTool("", "x", emptyParameters(),
        proc (a: JsonNode): ToolResult {.gcsafe, raises: [].} =
          ToolResult(output: "", isError: false, exitCode: 0))

  test "newTool rejects nil execute":
    expect ToolArgumentError:
      discard newTool("x", "x", emptyParameters(), nil)

# ---------------------------------------------------------------------------
# OpenAI-compatible serialization
# ---------------------------------------------------------------------------

suite "ToolRegistry OpenAI definitions":
  test "single tool has correct shape":
    let t = echoTool()
    let def = toOpenAIDefinition(t)
    check def["type"].getStr() == "function"
    check def["function"]["name"].getStr() == "echo"
    check def["function"]["description"].getStr() == "Echo a message back"
    check def["function"]["parameters"]["type"].getStr() == "object"
    check def["function"]["parameters"]["properties"].hasKey("msg")
    check def["function"]["parameters"]["required"][0].getStr() == "msg"

  test "registry serialization is an array of definitions":
    let reg = newToolRegistry()
    reg.register(echoTool())
    reg.register(shellTool(fastShellOpts()))
    let arr = reg.toOpenAIDefinitions()
    check arr.kind == JArray
    check arr.len == 2
    check arr[0]["function"]["name"].getStr() == "echo"
    check arr[1]["function"]["name"].getStr() == "shell"
    # Each entry is shaped correctly.
    for entry in arr:
      check entry["type"].getStr() == "function"
      check entry["function"]["parameters"]["type"].getStr() == "object"

  test "definitions are independent copies":
    let reg = newToolRegistry()
    reg.register(echoTool())
    let arr1 = reg.toOpenAIDefinitions()
    arr1[0]["function"]["name"] = %"hijacked"
    # Registry state must remain unchanged.
    let arr2 = reg.toOpenAIDefinitions()
    check arr2[0]["function"]["name"].getStr() == "echo"

# ---------------------------------------------------------------------------
# Argument parsing & execution surface
# ---------------------------------------------------------------------------

suite "ToolRegistry argument parsing":
  test "empty string parses to empty object":
    let n = parseArguments("")
    check n.kind == JObject
    check n.len == 0

  test "valid JSON object parses":
    let n = parseArguments("""{"a": 1, "b": "x"}""")
    check n["a"].getInt() == 1
    check n["b"].getStr() == "x"

  test "invalid JSON raises ToolArgumentError":
    expect ToolArgumentError:
      discard parseArguments("not json")

  test "non-object root raises ToolArgumentError":
    expect ToolArgumentError:
      discard parseArguments("[1,2,3]")

suite "ToolRegistry execute":
  test "executes a registered tool with parsed JSON":
    let reg = newToolRegistry()
    reg.register(echoTool())
    let res = reg.execute("echo", """{"msg": "hi"}""")
    check (not res.isError)
    check res.output == "hi"

  test "execute on missing tool raises":
    let reg = newToolRegistry()
    expect ToolNotFoundError:
      discard reg.execute("nope", "{}")

  test "execute returns isError on bad JSON arguments":
    let reg = newToolRegistry()
    reg.register(echoTool())
    let res = reg.execute("echo", "not json")
    check res.isError
    check res.output.contains("invalid arguments")

  test "execute returns isError on non-object args":
    let reg = newToolRegistry()
    reg.register(echoTool())
    let res = reg.execute("echo", "[]")
    check res.isError

# ---------------------------------------------------------------------------
# Shell tool: deny-list
# ---------------------------------------------------------------------------

suite "shell tool deny-list":
  test "isDenied catches rm -rf /":
    check isDenied("rm -rf /", DefaultDenyPatterns)
    check isDenied("RM -RF /", DefaultDenyPatterns)
    check isDenied("rm    -rf   /", DefaultDenyPatterns)

  test "isDenied catches embedded dangerous command":
    check isDenied("echo hi && rm -rf /", DefaultDenyPatterns)

  test "isDenied catches fork bomb":
    check isDenied(":(){ :|:& };:", DefaultDenyPatterns)
    check isDenied(":(){:|:&};:", DefaultDenyPatterns)

  test "isDenied catches mkfs and dd to disk":
    check isDenied("mkfs.ext4 /dev/sda1", DefaultDenyPatterns)
    check isDenied("dd if=/dev/zero of=/dev/sda", DefaultDenyPatterns)

  test "isDenied allows safe commands":
    check (not isDenied("echo hello", DefaultDenyPatterns))
    check (not isDenied("ls -la", DefaultDenyPatterns))
    check (not isDenied("cat /etc/hostname", DefaultDenyPatterns))

  test "shell tool refuses denied command":
    let reg = newToolRegistry()
    reg.register(shellTool(fastShellOpts()))
    let res = reg.execute("shell", """{"cmd": "rm -rf /"}""")
    check res.isError
    check res.output.contains("DENIED")

  test "runShell reports denied=true":
    let exec = runShell("rm -rf /", defaultShellOptions())
    check exec.denied
    check exec.exitCode == -1
    check (not exec.timedOut)

  test "runShell rejects empty command":
    let exec = runShell("   ", defaultShellOptions())
    check exec.denied

# ---------------------------------------------------------------------------
# Shell tool: real execution
# ---------------------------------------------------------------------------

suite "shell tool execution":
  test "runs simple echo and captures stdout":
    let exec = runShell("echo hello-mercury", fastShellOpts())
    check exec.exitCode == 0
    check (not exec.timedOut)
    check (not exec.denied)
    check exec.stdout.contains("hello-mercury")
    check exec.stderr.len == 0

  test "captures stderr separately":
    let exec = runShell(
      """echo to-out; echo to-err 1>&2""", fastShellOpts())
    check exec.exitCode == 0
    check exec.stdout.contains("to-out")
    check exec.stderr.contains("to-err")

  test "non-zero exit code is reported":
    let exec = runShell("exit 7", fastShellOpts())
    check exec.exitCode == 7
    check (not exec.timedOut)
    check (not exec.denied)

  test "shell tool returns exit code via registry":
    let reg = newToolRegistry()
    reg.register(shellTool(fastShellOpts()))
    let res = reg.execute("shell", """{"cmd": "exit 3"}""")
    check res.isError                   # non-zero exit is an error
    check res.exitCode == 3
    check res.output.contains("exit: 3")

  test "shell tool surfaces stdout in formatted output":
    let reg = newToolRegistry()
    reg.register(shellTool(fastShellOpts()))
    let res = reg.execute("shell", """{"cmd": "echo from-shell-tool"}""")
    check (not res.isError)
    check res.exitCode == 0
    check res.output.contains("from-shell-tool")
    check res.output.contains("exit: 0")

  test "missing cmd argument is an error, not a crash":
    let reg = newToolRegistry()
    reg.register(shellTool(fastShellOpts()))
    let res = reg.execute("shell", """{"foo": "bar"}""")
    check res.isError
    check res.output.contains("'cmd'")

# ---------------------------------------------------------------------------
# Shell tool: timeout handling
# ---------------------------------------------------------------------------

suite "shell tool timeout":
  test "long-running command is killed at timeout":
    var opts = fastShellOpts()
    opts.timeoutMs = 200
    let exec = runShell("sleep 5", opts)
    check exec.timedOut
    check exec.durationMs < 3_000     # killed promptly
    check exec.exitCode != 0
    check exec.stderr.contains("timeout")

  test "shell tool reports timeout via registry":
    let reg = newToolRegistry()
    var opts = fastShellOpts()
    opts.timeoutMs = 200
    reg.register(shellTool(opts))
    let res = reg.execute("shell", """{"cmd": "sleep 5"}""")
    check res.isError
    check res.output.contains("timed out")

  test "per-call timeoutMs override is honored":
    let reg = newToolRegistry()
    reg.register(shellTool(fastShellOpts(timeoutMs = 30_000)))
    let res = reg.execute("shell",
      """{"cmd": "sleep 5", "timeoutMs": 200}""")
    check res.isError
    check res.output.contains("timed out")

  test "fast command finishes well before timeout":
    var opts = fastShellOpts()
    opts.timeoutMs = 5_000
    let exec = runShell("echo quick", opts)
    check (not exec.timedOut)
    check exec.exitCode == 0
    check exec.durationMs < 4_000
