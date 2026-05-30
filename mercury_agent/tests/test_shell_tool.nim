## Tests for mercury_agent/tools/shell.
##
## Exercises the deny-list, real command execution, and timeout logic.
## Also tests integration with mercury_core/tool_registry.

import std/[strutils, unittest]

import mercury_core/tool_registry
import tools/shell

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

proc fastShellOpts(timeoutMs: int = 5_000): ShellOptions =
  result = defaultShellOptions()
  result.timeoutMs = timeoutMs

# ---------------------------------------------------------------------------
# Deny-list
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
# Real execution
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
# Timeout
# ---------------------------------------------------------------------------

suite "shell tool timeout":
  test "long-running command is killed at timeout":
    var opts = fastShellOpts()
    opts.timeoutMs = 200
    let exec = runShell("sleep 5", opts)
    check exec.timedOut
    check exec.durationMs < 3_000     # killed promptly
    # The timeout message format varies by Nim version and OS; accept either
    # "timeout" (Nim 2.2+) or "killed" (Nim 2.0.x / SIGKILL exit).
    check exec.stderr.contains("timeout") or exec.stderr.contains("killed")

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
