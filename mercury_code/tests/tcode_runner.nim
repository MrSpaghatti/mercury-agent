## Tests for the code runner module.
## Covers CompileResult formatting, error parsing, and CodingHarnessConfig defaults.

import std/[unittest, strutils]

import mercury_code/code_runner

# ---------------------------------------------------------------------------
# CompileResult formatting
# ---------------------------------------------------------------------------

suite "formatCompileResult":

  test "success — no output":
    let res = CompileResult(success: true, exitCode: 0, stdout: "", stderr: "",
                             durationMs: 100, errors: @[])
    let formatted = formatCompileResult(res)
    check: "✓ BUILD SUCCEEDED" in formatted

  test "success — with output":
    let res = CompileResult(success: true, exitCode: 0, stdout: "Compiling...",
                             stderr: "", durationMs: 200, errors: @[])
    let formatted = formatCompileResult(res)
    check: "✓ BUILD SUCCEEDED" in formatted
    check: "Compiling..." in formatted

  test "failure — with errors":
    var errors = newSeq[CompileError]()
    errors.add CompileError(file: "src/foo.nim", line: 10, column: 5,
                            severity: "error", message: "undeclared identifier: bar")
    let res = CompileResult(success: false, exitCode: 1,
                             stdout: "Compiling foo.nim...", stderr: "Error",
                             durationMs: 300, errors: errors)
    let formatted = formatCompileResult(res)
    check: "✗ BUILD FAILED" in formatted
    check: "src/foo.nim(10,5)" in formatted
    check: "undeclared identifier: bar" in formatted

  test "timeout — timed out flag set":
    let res = CompileResult(success: false, exitCode: -1,
                             stdout: "", stderr: "timed out",
                             durationMs: 5000, errors: @[], timedOut: true)
    let formatted = formatCompileResult(res)
    check: "✗ TIMEOUT" in formatted

  test "truncated output":
    let veryLong = "x".repeat(500)
    let res = CompileResult(success: false, exitCode: 1, stdout: veryLong,
                             stderr: veryLong, durationMs: 100,
                             errors: @[], truncated: true)
    let formatted = formatCompileResult(res)
    check: "✗ TRUNCATED" in formatted

# ---------------------------------------------------------------------------
# Error parsing
# ---------------------------------------------------------------------------

suite "parseNimErrors":

  test "basic error":
    let raw = "src/foo.nim(10, 5) Error: undeclared identifier: bar"
    let errors = parseNimErrors(raw, "src/foo.nim")
    check: errors.len == 1
    check: errors[0].file == "src/foo.nim"
    check: errors[0].line == 10
    check: errors[0].column == 5
    check: errors[0].severity == "error"
    check: "undeclared identifier" in errors[0].message

  test "error without column":
    let raw = "src/bar.nim(20) Error: type mismatch"
    let errors = parseNimErrors(raw, "src/bar.nim")
    check: errors.len == 1
    check: errors[0].line == 20
    check: errors[0].column == 0
    check: errors[0].severity == "error"

  test "multiple errors":
    let raw = "src/a.nim(1, 1) Error: first error" & "\n" &
              "src/b.nim(2, 2) Warning: second warning"
    let errors = parseNimErrors(raw, "")
    check: errors.len == 2
    check: errors[0].severity == "error"
    check: errors[1].severity == "warning"

  test "empty input":
    check: parseNimErrors("", "").len == 0
    check: parseNimErrors("no errors here", "").len == 0

  test "skips lines without file(path) pattern":
    let raw = "some unrelated output\nsrc/file.nim(5, 3) Error: real error"
    let errors = parseNimErrors(raw, "src/file.nim")
    check: errors.len == 1
    check: errors[0].line == 5

# ---------------------------------------------------------------------------
# CodingHarnessConfig defaults
# ---------------------------------------------------------------------------

suite "defaultCodingHarnessConfig":

  test "defaults are sensible":
    let cfg = defaultCodingHarnessConfig()
    check: cfg.sandboxRoot == ""
    check: cfg.allowedExtensions.len > 0
    check: ".nim" in cfg.allowedExtensions
    check: cfg.buildCmd == ""
    check: cfg.testCmd == ""
    check: cfg.buildTimeoutMs == 120_000
    check: cfg.testTimeoutMs == 300_000
    check: cfg.maxOutputBytes == 512 * 1024