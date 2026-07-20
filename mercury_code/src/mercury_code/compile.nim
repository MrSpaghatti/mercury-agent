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

import std/[osproc, times, monotimes, os]
when defined(posix):
  import std/posix
else:
  import std/streams

import code_runner

const DefaultCompileTimeoutMs = 120_000

when defined(posix):
  proc setNonBlocking(fd: FileHandle) =
    let flags = fcntl(fd.cint, F_GETFL)
    if flags != -1:
      discard fcntl(fd.cint, F_SETFL, flags or O_NONBLOCK)

  proc drainAvailable(fd: FileHandle; buf: var string; total: var int;
                      cap: int): bool =
    ## Reads all currently-available bytes on `fd`, storing up to `cap` total
    ## bytes into `buf` (counting every byte in `total`) and discarding the
    ## rest so the child never blocks on a full pipe. Returns true at EOF.
    var tmp {.noinit.}: array[8192, char]
    while true:
      let n = read(fd.cint, addr tmp[0], tmp.len)
      if n == 0:
        return true
      if n < 0:
        return false
      total += n
      if cap <= 0 or buf.len < cap:
        let take = if cap <= 0: n else: min(n, cap - buf.len)
        let oldLen = buf.len
        buf.setLen(oldLen + take)
        copyMem(addr buf[oldLen], addr tmp[0], take)

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
      # poEvalCommand: `cmd` is a full shell command line (e.g.
      # "nim c -r src/main.nim"), so it must be evaluated by the shell.
      # Without it, startProcess treats the entire string as one executable
      # name and every multi-word build/test command fails to launch.
      options = {poUsePath, poStdErrToStdOut, poEvalCommand},
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

  # Merged stdout+stderr (poStdErrToStdOut) must be drained while the child
  # runs; reading only after it exits deadlocks once the output exceeds one
  # pipe buffer (~64 KiB) — routine for a verbose compile or test run.
  var outBuf = ""
  var outTotal = 0

  when defined(posix):
    setNonBlocking(p.outputHandle)
    var eof = false
    while true:
      if not eof: eof = drainAvailable(p.outputHandle, outBuf, outTotal, maxOutputBytes)
      if p.peekExitCode() != -1:
        break
      if getMonoTime() >= deadline:
        timedOut = true
        try: p.kill() except CatchableError: discard
        var grace = 500
        while grace > 0 and p.peekExitCode() == -1:
          if not eof: eof = drainAvailable(p.outputHandle, outBuf, outTotal, maxOutputBytes)
          sleep(25)
          grace -= 25
        try: p.terminate() except CatchableError: discard
        break
      sleep(pollIntervalMs)
      if pollIntervalMs < 100:
        pollIntervalMs += 5
    var guard = 0
    while not eof and guard < 100_000:
      eof = drainAvailable(p.outputHandle, outBuf, outTotal, maxOutputBytes)
      inc guard
  else:
    while true:
      let rc = p.peekExitCode()
      if rc != -1:
        break
      if getMonoTime() >= deadline:
        timedOut = true
        try: p.kill() except CatchableError: discard
        var grace = 500
        while grace > 0 and p.peekExitCode() == -1:
          sleep(25)
          grace -= 25
        try: p.terminate() except CatchableError: discard
        break
      sleep(pollIntervalMs)
      if pollIntervalMs < 100:
        pollIntervalMs += 5
    let rawOutput = try: readAll(p.outputStream) except CatchableError: ""
    outTotal = rawOutput.len
    outBuf = if rawOutput.len > maxOutputBytes: rawOutput[0 ..< maxOutputBytes]
             else: rawOutput

  var exitCode = -1
  try:
    exitCode = p.waitForExit()
  except CatchableError:
    discard

  try: p.close() except CatchableError: discard

  let durationMs = int((getMonoTime() - startMono).inMilliseconds)

  # Clamp output to maxOutputBytes.
  let stdout = if outTotal > maxOutputBytes:
                 outBuf & "\n... [output truncated]"
               else:
                 outBuf

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