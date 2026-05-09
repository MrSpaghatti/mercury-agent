version       = "0.1.0"
author        = "Mercury"
description   = "Mercury core shared library"
license       = "MIT"
srcDir        = "src"
bin           = @["mercury_core"]
requires "nim >= 2.0.0"
requires "db_connector >= 0.1.0"
switch("path", "src")
