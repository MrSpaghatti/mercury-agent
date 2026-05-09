Copied Mercury scaffold to /home/spag/mercury and verified Nimble builds for mercury_core and mercury_agent.
Installed desloppify in a local virtual environment at /tmp/opencode/desloppify-venv because system pip was unavailable (PEP 668/external management).
Added make desloppify target to run /tmp/opencode/desloppify-venv/bin/python -m desloppify scan --path . explicitly on demand.
Added .desloppify/ to .gitignore and documented explicit usage in README.md.
Verified make desloppify succeeds and reports a clean scan (0 issues, 100 strict/verified).
6. nimble test discovers tests in <package>/tests/ directory. Use `nimble test <name>` to run a specific test file (e.g., `nimble test tconfig` runs tests/tconfig.nim).
7. nimble test uses `--path:.` (package root) for compilation. To expose src/ modules to tests, add a `tests/config.nims` with `switch("path", "../src")`.
8. std/parsecfg handles INI/TOML-like files with [section] headers and key=value pairs — sufficient for Mercury's config.toml format.
9. Use `template withEnv(key, val: string; body: untyped)` for env var test helpers in Nim 2.x — avoids StmtListLambda deprecation warning from `proc()` body syntax.
10. Config loading priority (highest wins): env vars > .env file > TOML file > defaults.
11. In Nim 2.x, `std/db_sqlite` was moved to the `db_connector` package. Use `import db_connector/db_sqlite` and add `requires "db_connector >= 0.1.0"` to the .nimble file. Install with `nimble install db_connector`.
12. FTS5 is available in SQLite by default. Use `CREATE VIRTUAL TABLE ... USING fts5(content, content='messages', content_rowid='id')` for a content table backed by a real table. Maintain sync with INSERT/DELETE/UPDATE triggers.
13. `nimble test <name>` does NOT filter to a single test file — it runs all tests in the tests/ directory alphabetically. To run a single test, use `nim c --path:src -r tests/tmemory.nim` directly.
14. The tllm_client test hangs at process exit because the mock TCP server thread doesn't join cleanly. This is a pre-existing issue; run individual tests with `nim c -r` to avoid it.
15. `parseBiggestInt` from std/strutils parses int64 values from strings (needed for SQLite AUTOINCREMENT rowids).
16. Tool registry (Wave 2.1): Used OpenAI's Chat Completions tool format — `{"type": "function", "function": {"name", "description", "parameters": <JSON schema>}}`. Schemas follow JSON Schema draft (object with type/properties/required/additionalProperties).
17. Nim 2.x JsonNode access: `args["key"].kind` raises a KeyError that effect-tracking demands you list. Use `args{"key"}` (returns nil if missing) inside `{.raises: [].}` closures to keep them total. Pattern: `let n = args{"k"}; if n.isNil or n.kind != JString: ...; n.getStr()`.
18. `osproc.Process.outputStream`/`errorStream` return `streams.Stream` (not `File`). Import `std/streams` to call `readAll` on them.
19. Shell timeout pattern: poll `process.peekExitCode()` against a `getMonoTime() + initDuration(milliseconds=ms)` deadline; on timeout call `process.kill()`, give a brief grace period (~500ms), then `process.terminate()` and `waitForExit()`. Track `timedOut` flag separately from exit code.
20. Deny-list normalization: lowercase + collapse whitespace before substring matching so `"RM   -RF /"` and `"rm -rf /"` both trigger. Pattern list lives in `DefaultDenyPatterns` const in `tools/shell.nim`.
21. mercury_agent now depends on mercury_core sources via `switch("path", "../mercury_core/src")` in mercury_agent.nimble. Tests in mercury_core/tests use `tests/config.nims` with `switch("path", "../../mercury_agent/src")` to import `tools/shell` for the cross-package ttool_registry tests.
22. ToolExecuteProc signature uses `{.gcsafe, raises: [].}` so closures captured at registration time are safe to call from any agent loop variant. The registry's `execute` proc still wraps any escaped CatchableError into a `ToolResult{isError=true}` defensively.
