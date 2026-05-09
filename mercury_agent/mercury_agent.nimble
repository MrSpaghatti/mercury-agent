version       = "0.1.0"
author        = "Mercury"
description   = "Mercury agent binary"
license       = "MIT"
srcDir        = "src"
bin           = @["mercury_agent"]
requires "nim >= 2.0.0"
switch("path", "src")
