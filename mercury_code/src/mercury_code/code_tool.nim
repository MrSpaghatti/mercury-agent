## Coding tool registry helpers.
##
## Exposes the coding harness as OpenAI function-calling tools that can
## be registered against a `ToolRegistry`:
##
##   import mercury_core/tool_registry
##   import mercury_code/code_tool
##   let reg = newToolRegistry()
##   reg.register(compileTool(cfg))
##   reg.register(testTool(cfg))
##
## Each tool wraps `runCompile` with the appropriate sandbox root guard,
## parameterises the command, and returns structured output (or a
## parseable error summary for the LLM to fix).

import std/[json, strutils, os]

import mercury_core/tool_registry
import code_runner
import compile

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

proc clampOutput(s: string; cap: int): string =
  if s.len <= cap: s
  else: s[0 ..< cap] & "\n... [output truncated]"

proc sandboxPath*(path: string; root: string): string =
  ## Returns `path` if it is inside `root`, otherwise returns `root`.
  ## Used as a last-ditch guard; callers should still validate before
  ## passing paths to the harness.
  let absPath = if path.startsWith('/'): path else: ""
  let absRoot = if root.startsWith('/'): root else: ""
  if absRoot.len > 0 and absPath.startsWith(absRoot):
    return path
  return root

proc formatCompileResult(res: CompileResult): string =
  if res.success:
    return "Compiled successfully in " & $res.durationMs & "ms.\n" &
           "stdout:\n" & res.stdout
  var lines = @[if res.exitCode == -1: "TIMEOUT or LAUNCH FAILURE"
                else: "Compilation failed (exit " & $res.exitCode & ") in " &
                      $res.durationMs & "ms.\n"]
  if res.errors.len > 0:
    lines.add "Errors:\n"
    for err in res.errors:
      lines.add "  " & err.file & "(" & $err.line & "," & $err.column & "): " &
                err.severity & ": " & err.message
  else:
    lines.add "stdout:\n" & clampOutput(res.stdout, 4096)
  if res.stderr.len > 0:
    lines.add "stderr:\n" & res.stderr
  lines.join("\n")

# ---------------------------------------------------------------------------
# Compile tool
# ---------------------------------------------------------------------------

proc compileTool*(cfg: CodingHarnessConfig): Tool =
  let buildCmd = cfg.buildCmd
  let timeoutMs = cfg.buildTimeoutMs
  let maxOut = cfg.maxOutputBytes
  let execute: ToolExecuteProc = proc (args: JsonNode): ToolResult {.gcsafe, raises: [].} =
    if buildCmd.len == 0:
      return ToolResult(output: "no build command configured", isError: true)
    try:
      let res = runCompile(buildCmd, timeoutMs, maxOut)
      return ToolResult(output: formatCompileResult(res), isError: not res.success)
    except CatchableError as e:
      return ToolResult(output: "compile failed: " & e.msg, isError: true)
  result = newTool(
    name = "compile",
    description = "Compile the project. Returns structured errors with file, " &
                  "line, and message so the model can fix them. Use this " &
                  "after writing or modifying code.",
    parameters = %*{
      "type": "object",
      "properties": {},
      "description": "Run the project's configured build command.",
    },
    execute = execute,
  )

# ---------------------------------------------------------------------------
# Test tool
# ---------------------------------------------------------------------------

proc testTool*(cfg: CodingHarnessConfig): Tool =
  let testCmd = cfg.testCmd
  let timeoutMs = cfg.testTimeoutMs
  let maxOut = cfg.maxOutputBytes
  let execute: ToolExecuteProc = proc (args: JsonNode): ToolResult {.gcsafe, raises: [].} =
    if testCmd.len == 0:
      return ToolResult(output: "no test command configured", isError: true)
    try:
      let res = runCompile(testCmd, timeoutMs, maxOut)
      return ToolResult(output: formatCompileResult(res), isError: not res.success)
    except CatchableError as e:
      return ToolResult(output: "test failed: " & e.msg, isError: true)
  result = newTool(
    name = "test",
    description = "Run the project's test suite. Returns pass/fail counts and " &
                  "any test error details.",
    parameters = %*{
      "type": "object",
      "properties": {},
    },
    execute = execute,
  )

# ---------------------------------------------------------------------------
# Read file tool
# ---------------------------------------------------------------------------

proc readFileTool*(cfg: CodingHarnessConfig): Tool =
  let allowed = cfg.allowedExtensions
  let execute: ToolExecuteProc = proc (args: JsonNode): ToolResult {.gcsafe, raises: [].} =
    let path = args{"path"}.getStr("")
    if path.len == 0:
      return ToolResult(output: "path is required", isError: true)
    let (_, _, ext) = path.splitFile()
    if ext.len > 0 and ext notin allowed:
      return ToolResult(
        output: "file extension '" & ext & "' is not in the allowed list: " &
                allowed.join(", "),
        isError: true,
      )
    try:
      let content = readFile(path)
      return ToolResult(output: content, isError: false)
    except CatchableError as e:
      return ToolResult(
        output: "failed to read file: " & e.msg,
        isError: true,
        exitCode: 1,
      )
  result = newTool(
    name = "read_file",
    description = "Read the contents of a file within the sandbox. " &
                  "Only files with allowed extensions can be read.",
    parameters = %*{
      "type": "object",
      "properties": {
        "path": {
          "type": "string",
          "description": "Absolute path to the file to read.",
        },
      },
      "required": ["path"],
    },
    execute = execute,
  )

# ---------------------------------------------------------------------------
# Write file tool
# ---------------------------------------------------------------------------

proc writeFileTool*(cfg: CodingHarnessConfig): Tool =
  let allowed = cfg.allowedExtensions
  let execute: ToolExecuteProc = proc (args: JsonNode): ToolResult {.gcsafe, raises: [].} =
    let path = args{"path"}.getStr("")
    let content = args{"content"}.getStr("")
    if path.len == 0:
      return ToolResult(output: "path is required", isError: true)
    let (_, _, ext) = path.splitFile()
    if ext.len > 0 and ext notin allowed:
      return ToolResult(
        output: "file extension '" & ext & "' is not in the allowed list: " &
                allowed.join(", "),
        isError: true,
      )
    try:
      writeFile(path, content)
      return ToolResult(
        output: "file written: " & path & " (" & $content.len & " bytes)",
        isError: false,
      )
    except CatchableError as e:
      return ToolResult(
        output: "failed to write file: " & e.msg,
        isError: true,
        exitCode: 1,
      )
  result = newTool(
    name = "write_file",
    description = "Write content to a file within the sandbox. " &
                  "Only files with allowed extensions can be written.",
    parameters = %*{
      "type": "object",
      "properties": {
        "path": {
          "type": "string",
          "description": "Absolute path to the file to write.",
        },
        "content": {
          "type": "string",
          "description": "Full file content to write.",
        },
      },
      "required": ["path", "content"],
    },
    execute = execute,
  )