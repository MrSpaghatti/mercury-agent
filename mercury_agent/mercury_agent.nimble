version       = "0.1.0"
author        = "Mercury"
description   = "Mercury agent binary"
license       = "MIT"
srcDir        = "src"
bin           = @["mercury_agent"]
requires "nim >= 2.0.0"
requires "db_connector >= 0.1.0"
requires "dimscord >= 1.0.0"
requires "cligen >= 1.6.0"
switch("path", "src")
switch("path", "../mercury_core/src")
