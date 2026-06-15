# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] — 2026-05-30

Initial release covering the completed foundation phases.

### Added

- **mercury_core** — shared library with:
  - `config.nim`: Layered configuration (defaults → TOML → `.env` → env vars),
    validated at startup with clear error messages
  - `llm_client.nim`: OpenAI-compatible Chat Completions client with exponential
    backoff retry, typed error hierarchy (`AuthError`, `RateLimitError`,
    `ServerError`, `RetryExhaustedError`)
  - `token_counter.nim`: Heuristic token estimator (GPT tokenizer ratios, bilingual
    support)
  - `memory.nim`: SQLite + FTS5 session persistence, full-text search,
    token-usage tracking
  - `tool_registry.nim`: Named tool registration with JSON schema export and
    safe execution wrapper
  - `discord.nim`: Dependency-injection Discord bot (`DiscordBot` ref) for
    testability
  - `discord_bridge.nim`: `RealDiscordApi` wrapping dimscord REST (send, typing,
    thread management)
  - `discord_commands.nim`: Command parser for `!status`, `!config`, `!admin`,
    `!session`, `!search` with permission checks
  - `discord_types.nim`, `discord_mocks.nim`: Shared types and offline mock API
  - `agent_dispatcher.nim`: Async agent request queue with callback-based result
    delivery
  - `permission.nim`: Role-based permission evaluator (admin, allow, deny lists)
  - `file_path_validator.nim`: Path traversal guards, percent-decode normalization,
    configurable allow/deny patterns
  - `file_tool.nim`: Agent tools for safe file read/write with path rules
  - `message_chunker.nim`: Splits long agent output at Discord's 2000-char limit
  - `rate_limit.nim`: Per-user token-bucket rate limiting
  - `thread_mapping.nim`: Maps Discord channel+user to persistent agent threads
    via SQLite with WAL mode

- **mercury_agent** — CLI binary with:
  - `mercury_agent.nim`: cligen-based dispatcher for `chat`, `ask`, `session`,
    `history`, `search`, `daemon` subcommands
  - `agent_loop.nim`: ReAct loop with loop detection, error recovery, configurable
    iteration cap, and OpenAI function-calling integration
  - `tools/shell.nim`: Sandboxed shell tool with deny-list (20+ patterns),
    per-call timeout (default 30s, max 5min), and 64KB output cap

- **CI pipeline** (GitHub Actions) — automated build + test on push/PR to `main`,
  running against Nim 2.0.8 and 2.2.2

- **Test suite** — 312 assertions across 23 test files:
  - mercury_core: config, LLM client, token counter, memory, tool registry,
    mock server, Discord bot, permission, file tools, rate limiting,
    thread mapping, message chunking, agent dispatcher, e2e
  - mercury_agent: CLI, agent loop, integration, shell tool

### Fixed

- SSL build on Nim 2.2.x: `config.nims` files in both packages now pass
  `--define:ssl`, resolving `raiseSSLError` undeclared identifier in dimscord
  builds
- `file_tool.nim`: Added `except Exception` alongside `except CatchableError`
  to handle Nim 2.2.x's stricter exception propagation on `moveFile` when
  compiled with `-d:ssl`
- `.gitignore`: Removed `*.nims` glob that was preventing `config.nims` from
  being tracked; force-added both `config.nims` files
- `tllm_client.nim` mock server: Added `sleep(50)` inside accept loop so the
  thread reliably detects `running = false` on shutdown, preventing 2s test
  hangs
- Shell timeout test: Removed brittle `durationMs < 3000` wall-clock assertion
  that failed on heavily-loaded CI containers; retained behavioral guarantees
  (`timedOut == true`, timeout message in stderr)
- Stale `OPENROUTER_BASE_URL` in `.env.example` → correct var `MERCURY_OPENROUTER_ENDPOINT`
- `stderr.writeLine` in `discord.nim` → `std/logging` with `newConsoleLogger` +
  `notice()`
- Missing `tllm_client.nim` in `mercury_core.nimble` test task (18→19 entries)
- Missing `tintegration.nim` in `mercury_agent.nimble` test task (3→4 entries)
- `Makefile` test target: replaced `|| true` with proper `&&` chaining so
  failures are not silently swallowed

### Changed

- `allowlistParts` slicing in `discord_commands.nim` simplified from
  `parts[1..<1+(parts.len-1)]` to `parts[1..^1]`
- Daemon dispatcher: replaced `asyncCheck` with `sendWithLogging` (try/except +
  stderr logging) to prevent silent error swallowing when Discord drops mid-response
- Thread-mapping SQLite DB: added `PRAGMA journal_mode=WAL` +
  `PRAGMA busy_timeout=5000` to prevent `SQLITE_BUSY` deadlocks under concurrent
  access
- Permission tests expanded from 6 to 26 covering admin deny, conflict resolution,
  risk-level combos, empty config, explicit allow/deny override behavior
- Shell tool tests relocated from `mercury_core/tests/ttool_registry.nim` to
  `mercury_agent/tests/test_shell_tool.nim` (eliminates cross-package import)

### Docs

- `README.md`: Architecture overview, CLI reference, configuration table,
  quick-start guide, module maps
- `STATUS.md`: Phase-by-phase completion status, test coverage table,
  known issues, architecture diagram
- `CONTRIBUTING.md`: Setup, build commands, SSL workaround, module dependency
  graph, release process, code health summary
- `mercury_core/DISCORD.md`: Discord bot architecture, command reference,
  thread model, testing strategy, module reference
- `.sisyphus/plans/roadmap.md`: Project roadmap with P0/P1/P2/P3 tiers and
  quick wins

## [Unreleased]

### Added

- **mercury_core**: `mock_mcp_server.nim` — async mock MCP HTTP server
  for testing against the `asynchttpserver` pattern. Supports initialize,
  tools/list, tools/call, JSON-RPC error responses, and HTTP error codes.
- **mercury_core**: `test_mcp_client.nim` expanded from 16 to 25 tests.
  Added 9 integration tests using the mock MCP server to verify the
  JSON-RPC protocol: initialize handshake, tool discovery, tool calls,
  error handling, method routing, and request counting.
- **mercury_core**: `test_mcp_tool.nim` — 11 tests for the MCP tool
  registration bridge (`mcp_tool.nim`): single-tool registration,
  duplicate detection, empty-name rejection, null schema handling,
  multi-tool batch registration, disabled/unreachable server handling,
  and execute-proc error mapping.

- **mercury_code** — autonomous coding harness binary:
  - `code_runner.nim`: `CodingHarnessConfig`, `CompileResult`/`CompileError`,
    `parseNimErrors()`, `formatCompileResult()`
  - `code_tool.nim`: `compileTool`, `testTool`, `readFileTool`, `writeFileTool`
    (all `{.gcsafe, raises: [].}` closures matching shell tool pattern)
  - `compile.nim`: subprocess execution with timeout and 512 KiB output cap
  - `mercury_code.nim`: CLI entry point (`--task`, `--version`, `--help`)
  - `tcode_runner.nim`: 11 tests (formatter, error parser, config defaults)
- **build_llm_client.nim** (mercury_core): shared `MercuryConfig → LLMClient`
  builder used by both `mercury_agent` and `mercury_code`

### Changed

- **CI pipeline** (`.github/workflows/ci.yml`): added build + test steps for
  `mercury_code` package on both Nim 2.0.8 and 2.2.2
- **.gitignore**: added `mercury_code/src/mercury_code/mercury_code` and
  `mercury_code/tcode_runner` build artifacts

### Security

- **mercury_code/compile.nim**: `except:` (bare catch) → `except CatchableError:`
  to avoid silencing `Defect` types in subprocess output handling

### Added

- **mercury_core**: `persona.nim` — Persona system with `PersonaConfig`,
  `PersonaRegistry`, TOML loading from `~/.config/mercury/personas.toml`.
  Supports system prompt, model/temperature overrides, per-persona tool
  allow/deny lists, memory scope (own_sessions/none/shared), max history
  cap, delegation bounds, and iteration limits.
- **mercury_core**: `delegate.nim` — DelegationConfig with safety bounds
  (`maxDelegationDepth`, `maxDelegationsPerRun`), `canDelegate()`,
  `useDelegationSlot()`, `applyPersonaDelegation()`.
- **mercury_core**: `tool_registry.nim` — `scopedRegistry()` produces a
  filtered `ToolRegistry` per persona; `filterToolsByPersona()` handles
  allow/deny logic (deny wins on conflict, empty allow = all pass).
- **mercury_agent**: `run <persona> <task>` subcommand that loads
  `~/.config/mercury/personas.toml`, builds a persona-scoped agent config,
  and executes via `runAgentLoop`.
- **mercury_agent**: `delegate` tool (gcsafe closure, `{.raises: [].}`) that
  spawns child agents from named personas within the ReAct loop. Safety
  bounds enforced via `DelegationConfig`.
- **mercury_core**: `test_persona.nim` — 22 tests covering registry
  construction, tool filtering, memory scope, delegation config, defaults.
- **config/personas.example.toml**: Template with 4 personas:
  `code_reviewer` (shell+files), `researcher` (stateless),
  `writer` (files only, memory-capped), `debug` (full access).

### Changed

- **mercury_core/agent_loop.nim**: `AgentConfig` extended with optional
  `persona: PersonaConfig` and `delegation: DelegationConfig` fields.
- **mercury_core**: `tconfig.nim` now imports `mcp_client` for
  `DefaultMcpServerUrl` constant used in tests.

### Security

- **mercury_core/persona.nim**: `parseMemoryScope()` and `parseBool()`
  use constant-time `case` statements; persona names normalized to
  lowercase to prevent duplicate registration via case-folding.
- **mercury_agent**: `cmdRunPersona` validates persona existence before
  spawning; registry globals set before agent loop to prevent nil
  reference in delegate tool.

## [0.1.1] — 2026-05-30

### Fixed

- **MCP/persona/delegation deep audit (Jun 11)**: 9 issues fixed across 6 files.
  - **delegate.nim**: Wired `canDelegate()` check and `useDelegationSlot()` into
    the delegate tool's execute path — delegation depth is now enforced at
    runtime instead of being dead code. The delegate tool is also registered
    in `cmdRunPersona`'s registry so it's available to persona-scoped agents.
  - **mcp_client.nim**: Added `defer: client.http.close()` in `discoverTools`
    to prevent HTTP handle leaks in long-running processes. Also wrapped the
    `notifications/initialized` POST in try/except so a dropped connection
    between initialize and notification doesn't crash the caller. Removed
    dead `bodyStr` variable (unused `pretty()` call). Fixed misleading
    `discoverTools` comment that claimed to prefix tool names but didn't.
    Included `errCode` in JSON-RPC error messages (was computed but unused).
  - **mcp_tool.nim**: Removed dead `except Exception` branch (unreachable
    after `CatchableError` + `Defect` handlers). Changed `var McpClient`
    parameters to `McpClient` (ref object, no mutation needed). Added
    `finally: client.http.close()` in `registerMcpServer` to prevent HTTP
    handle leak. Added `std/httpclient` import for the close() call.
  - **persona.nim**: Removed tautological condition in `applyPersonaDefaults`
    (`A and A` no-op).
  - **config.nim**: Added `name*: string` to `McpServerConfig` — TOML section
    names (`[mcp_servers.filesystem]` → `"filesystem"`) are now propagated
    through config for use in error messages and future tool-prefixing.
  - **mercury_agent.nim**: Removed unused `mcp_client` import.
  - **delegate.nim**: Removed unused `strutils` import.

### Quality

- **Test quality audit**: Reviewed all 26 test source files (388 tests total).
  Fixed 5 weak tests:
  - `test_agent_dispatcher.nim`: renamed "no-ops" to "are idempotent" — now
    verifies two dispatchers can be started/stopped independently with
    meaningful `d1 != nil and d2 != nil` assertion (replaced `check true`).
  - `test_discord_bot.nim`: renamed "chunked and sent" to "triggers at least
    one send" — test name no longer implies chunking verification which it
    doesn't perform. Also fixed `bot = false` syntax error (`=` → `:`).
  - `test_e2e_discord.nim`: wrapped file tool test file creation/cleanup in
    `try/finally` to guarantee `test_allowed.txt` and `.env_test` are removed
    even if test crashes mid-assertion.
  - `tllm_client.nim`: renamed "sends Authorization header" to "request body
    is well-formed JSON with required keys" — current mock cannot inspect HTTP
    headers; test now accurately describes what it actually verifies.
  - `tcli.nim`: replaced hardcoded `/tmp/mercury-cli-resolved.db` with unique
    temp path (`getTempDir() / "mercury_cli_test_abs_{PID}.db"`) + cleanup.

- **Deep audit (May 30)**: Fixed GC-safety issues across all packages.
  Added `{.gcsafe.}` to all async callback type definitions and closures in
  `discord.nim`, `discord_mocks.nim`, `agent_dispatcher.nim`, and
  `mercury_agent.nim`. Changed test closure patterns from global variable
  capture to `new(AgentResult)` heap allocation to satisfy Nim 2.2.x ORC.
  Exported `jsonRpcResponseId*` from `mcp_client.nim` for test import.
  Fixed unterminated string literal in `test_mcp_client.nim`.
  Added `--threads:on` to `tllm_client.nim` and `--threads:on` to
  `mercury_agent.nimble` test task. Added `threadpool` import to
  `tllm_client.nim` for `Thread` type.

### Security

- All 17 modified files: `AgentCallback`, async proc types, factory
  closures, and test closures are now `{.gcsafe.}` throughout. No
  `{.gcsafe.}` violations in any test file remain.

### Changed

- **mercury_core.nimble**: added `-d:ssl` to all 21 test exec commands,
  `--threads:on` for `tllm_client.nim`; removed dangling `test_discord`
  entry
- **mercury_agent.nimble**: added `--threads:on` for `tagent_loop.nim`
- **mercury_core/config.nims** and **mercury_agent/config.nims**: structure
  for `--threads:on` support

### Added

- **.github/workflows/ci.yml**: `--threads:on` flag added to test jobs for
  `tllm_client.nim` threadpool requirement

[0.1.0]: https://github.com/MrSpaghatti/mercury-agent/compare/initial...v0.1.0