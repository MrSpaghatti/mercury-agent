version       = "0.1.0"
author        = "Mercury"
description   = "Mercury core shared library"
license       = "MIT"
srcDir        = "src"
bin           = @["mercury_core"]
requires "nim >= 2.0.0"
requires "db_connector >= 0.1.0"
requires "dimscord >= 1.0.0"
switch("path", "src")

task test, "Run chunker tests":
  exec "nim c -d:ssl --path:src -r tests/test_message_chunker.nim"
  exec "nim c -d:ssl --path:src -r tests/test_discord_mocks.nim"
  exec "nim c -d:ssl --path:src -r tests/test_discord_commands.nim"
  exec "nim c -d:ssl --path:src -r tests/test_discord_bot.nim"
  exec "nim c -d:ssl --path:src -r tests/test_e2e_discord.nim"
