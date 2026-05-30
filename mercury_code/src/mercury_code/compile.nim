## Sandboxed compilation runner.
##
## Provides `runCompile` which executes an arbitrary shell command
## (typically a compiler invocation) with a hard timeout, captures
## output, parses structured errors, and returns a `CompileResult`.
##
## The key safety property: this proc does NOT make its own security
## decisions. It delegates entirely to the shell tool's deny-list and
## to the sandbox root guard set by the caller. Callers MUST:
##   1. Validate the command is within `sandboxRoot` before calling.
##   2. Use the shell tool's deny-list for command-level safety.

import std/[osproc, streams, times, monotimes, os]

import code_runner

const DefaultCompileTimeoutMs = 120_000

proc runCompile*(
    cmd: string;
    timeoutMs: int = DefaultCompileTimeoutMs;
    maxOutputBytes: int = DefaultMaxOutputBytes;
): CompileResult =
  ## Runs `cmd` as a subprocess with a hard `timeoutMs` deadline.
  ##
  ## Returns a `CompileResult` with `success`, `exitCode`, `stdout`,
  ## `stderr`, `durationMs`, and parsed `errors`.
  ##
  ## If the process times out it is killed (SIGKILL) and `success` is
  ## false. Partial output up to `maxOutputBytes` is returned.
  let startMono = getMonoTime()

  var p: Process
  try:
    p = startProcess(
      cmd,
      workingDir = "",
      env = nil,
      options = {poUsePath, poStdErrToStdOut},
    )
  except CatchableError:
    return CompileResult(
      success: false,
      exitCode: -1,
      stdout: "",
      stderr: "failed to start process: " & getCurrentExceptionMsg(),
      durationMs: 0,
      errors: @[],
    )

  var timedOut = false
  let deadline = startMono + initDuration(milliseconds = timeoutMs)
  var pollIntervalMs = 25

  while true:
    let rc = p.peekExitCode()
    if rc != -1:
      break
    if getMonoTime() >= deadline:
      timedOut = true
      try:
        p.kill()
      except CatchableError:
        discard
      # Brief grace period for process to die.
      var grace = 500
      while grace > 0 and p.peekExitCode() == -1:
        sleep(25)
        grace -= 25
      try:
        p.terminate()
      except CatchableError:
        discard
      break
    sleep(pollIntervalMs)
    if pollIntervalMs < 100:
      pollIntervalMs += 5

  var exitCode = -1
  try:
    exitCode = p.waitForExit()
  except CatchableError:
    discard

  let rawOutput = try: readAll(p.outputStream) except CatchableError: ""
  try: p.close() except CatchableError: discard

  let durationMs = int((getMonoTime() - startMono).inMilliseconds)

  # Clamp output to maxOutputBytes.
  let stdout = if rawOutput.len > maxOutputBytes:
                 rawOutput[0 ..< maxOutputBytes] & "\n... [output truncated]"
               else:
                 rawOutput

  let errors = if exitCode != 0:
                 parseNimCompilerOutput(stdout)
               else:
                 @[]

  result = CompileResult(
    success: not timedOut and exitCode == 0,
    exitCode: if timedOut: -1 else: exitCode,
    stdout: stdout,
    stderr: if timedOut: "command timed out after " & $timeoutMs & "ms" else: "",
    durationMs: durationMs,
    errors: errors,
  )