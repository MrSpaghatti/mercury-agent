# Testing Fixes Plan

1. **Fix `waitFor` Macro Usage:**
   - Files like `test_discord_mocks.nim` lack the `import std/asyncdispatch` statement causing `waitFor` to be undeclared. Add this import to all test files that use async logic (especially `test_discord_mocks.nim`).

2. **Fix Assertion in `test_discord_bot.nim`:**
   - The test "regular message triggers typing and agent dispatch" fails because it checks `call.channelId == "chan1"` instead of `call.channelId == "thread_1"`. The agent creates a thread and triggers typing *inside* the thread, not the main channel.
   - Wait, actually when checking `call.channelId in ["chan1", "thread_1"]` it succeeds. Need to document to adjust the test correctly.

3. **Fix PCRE Dependency / Regex:**
   - `file_path_validator.nim` imports `nre` / `pcre` which requires `libpcre.so` dynamically at test runtime. We either need to include `libpcre3` in the environment setup (as I did via `apt-get`) or rewrite `file_path_validator` to use `std/pegs` or `nitely/nim-regex` to eliminate the dynamic C dependency. `nim-regex` is already downloaded by nimble so it's a better choice.

4. **Nimble configuration:**
   - `mercury_core.nimble` was failing to run tests because it used `nim c -r` instead of `nim c --path:src -r`. And it lacked the `-d:ssl` flag which is necessary since the tests use Discord and LLM clients. The `test` task should loop through `tests/` and run `nim c -d:ssl --path:src -r $file`.

5. **`raiseSSLError` issue:**
   - Nim 2.2.10 standard library `asyncnet.nim` has a bug where `raiseSSLError` is used but never imported/defined properly when compiled with certain flags, causing compile failures in downstream HTTP clients (like `httpclient.nim`). Wait, the fix for `raiseSSLError` was running with `-d:ssl`! The `httpclient` module conditionally imports `openssl` when `-d:ssl` is specified, which defines `raiseSSLError`. Thus, we must ensure all nimble targets use `-d:ssl` or add it to `config.nims`.
