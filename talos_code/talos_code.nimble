version       = "0.1.0"
author        = "Talos"
description   = "Talos coding harness — autonomous coding assistant"
license       = "MIT"
srcDir        = "src"
bin           = @["talos_code"]
requires      "nim >= 2.0.0"
requires      "talos_core >= 0.1.0"
switch("path", "src")
switch("path", "../talos_core/src")
switch("path", "../talos_agent/src")

task test, "Run tests":
  exec "nim c --path:src --path:../talos_core/src --path:../talos_core/tests -r tests/tcode_runner.nim"