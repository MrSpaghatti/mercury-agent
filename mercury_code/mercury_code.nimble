version       = "0.1.0"
author        = "Mercury"
description   = "Mercury coding harness — autonomous coding assistant"
license       = "MIT"
srcDir        = "src"
bin           = @["mercury_code"]
requires      "nim >= 2.0.0"
requires      "mercury_core >= 0.1.0"
switch("path", "src")
switch("path", "../mercury_core/src")
switch("path", "../mercury_agent/src")

task test, "Run tests":
  exec "nim c --path:src --path:../mercury_core/src --path:../mercury_core/tests -r tests/tcode_runner.nim"