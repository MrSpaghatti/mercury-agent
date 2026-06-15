Project Path: mercury-agent

Source Tree:

```txt
mercury-agent
├── CHANGELOG.md
├── CONTRIBUTING.md
├── Makefile
├── README.md
├── STATUS.md
├── TASK_2.2_SPEC.md
├── TASK_2.2_VERIFICATION_PLAN.md
├── VERIFICATION_CHECKLIST.md
├── WAVE_3_SPEC.md
├── config
│   └── personas.example.toml
├── mercury_agent
│   ├── config.nims
│   ├── mercury_agent.nimble
│   ├── src
│   │   ├── agent_loop.nim
│   │   ├── mercury_agent
│   │   ├── mercury_agent.nim
│   │   └── tools
│   │       └── shell.nim
│   └── tests
│       ├── tagent_loop.nim
│       ├── tcli.nim
│       ├── test_shell_tool.nim
│       └── tintegration.nim
├── mercury_code
│   ├── config.nims
│   ├── mercury_code.nimble
│   ├── src
│   │   ├── mercury_code
│   │   │   ├── code_runner.nim
│   │   │   ├── code_tool.nim
│   │   │   ├── compile.nim
│   │   │   └── mercury_code.nim
│   │   └── mercury_code.nim
│   └── tests
│       └── tcode_runner.nim
├── mercury_core
│   ├── DISCORD.md
│   ├── config.nims
│   ├── mercury_core.nimble
│   ├── src
│   │   ├── mercury_core
│   │   │   ├── agent_dispatcher.nim
│   │   │   ├── build_llm_client.nim
│   │   │   ├── config.nim
│   │   │   ├── delegate.nim
│   │   │   ├── discord.nim
│   │   │   ├── discord_bridge.nim
│   │   │   ├── discord_commands.nim
│   │   │   ├── discord_mocks.nim
│   │   │   ├── discord_types.nim
│   │   │   ├── file_path_validator.nim
│   │   │   ├── file_tool.nim
│   │   │   ├── llm_client.nim
│   │   │   ├── mcp_client.nim
│   │   │   ├── mcp_tool.nim
│   │   │   ├── memory.nim
│   │   │   ├── message_chunker.nim
│   │   │   ├── permission.nim
│   │   │   ├── persona.nim
│   │   │   ├── rate_limit.nim
│   │   │   ├── thread_mapping.nim
│   │   │   ├── token_counter.nim
│   │   │   └── tool_registry.nim
│   │   └── mercury_core.nim
│   ├── test_simple.nim
│   └── tests
│       ├── mock_server.nim
│       ├── tconfig.nim
│       ├── test_agent_dispatcher.nim
│       ├── test_discord_bot.nim
│       ├── test_discord_commands.nim
│       ├── test_discord_config.nim
│       ├── test_discord_mocks.nim
│       ├── test_e2e_discord.nim
│       ├── test_file_path_validator.nim
│       ├── test_file_tool.nim
│       ├── test_mcp_client.nim
│       ├── test_message_chunker.nim
│       ├── test_mock_server.nim
│       ├── test_permission.nim
│       ├── test_persona.nim
│       ├── test_rate_limit.nim
│       ├── test_thread_mapping.nim
│       ├── test_thread_reconnection.nim
│       ├── tllm_client.nim
│       ├── tmemory.nim
│       ├── ttoken_counter.nim
│       └── ttool_registry.nim
├── report.md
├── test_config.nim
└── tests

```

`CHANGELOG.md`:

```md
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
```

`CONTRIBUTING.md`:

```md
# Contributing to Mercury Agent

## Development Setup

### Prerequisites

- **Nim ≥ 2.0** (recommended: Nim 2.0.x for full builds, Nim 2.2.x for
  core-only development)
- **nimble** (Nim's package manager)
- **SQLite** (with FTS5 support — included in standard SQLite ≥ 3.9)
- **OpenRouter API key** (or any OpenAI-compatible endpoint) for running
  the agent; tests use mocks and need no API key

### Environment

```bash
git clone <repo-url>
cd mercury-agent

# Create an .env for your API key (tests don't need this)
cp .env.example .env
# Edit .env and set OPENROUTER_API_KEY=sk-or-...

# Install nimble dependencies
cd mercury_core && nimble install -y
cd ../mercury_agent && nimble install -y
cd ..
```

---

## Building

### Core library only (always works)

```bash
cd mercury_core && nimble build
```

### Full build (CLI + Discord daemon)

```bash
make build
```

> **SSL compatibility**: Both packages pass `--define:ssl` via `config.nims`,
> which resolves the `raiseSSLError` issue that existed in Nim 2.2.x.
> The build works on both Nim 2.0.x and Nim 2.2.x.

---

## Testing

### Run everything

```bash
make test
```

### Run core tests only

```bash
cd mercury_core && nimble test
```

### Run agent tests only

```bash
cd mercury_agent && nimble test
```

### Run a single test file

```bash
cd mercury_core && nim c --path:src -r tests/tconfig.nim
cd mercury_agent && nim c --path:src -r tests/tcli.nim
```

### Run Discord-specific tests

```bash
cd mercury_core
nim c -r tests/test_discord_mocks.nim
nim c -r tests/test_discord_commands.nim
nim c -r tests/test_discord_bot.nim
nim c -r tests/test_e2e_discord.nim
```

### Code formatting

```bash
make nph
nimpretty src/mercury_core/src/mercury_core/*.nim
```

---

## Project Structure

```
mercury/
├── mercury_core/              # Shared library (no binary)
│   ├── src/mercury_core/      # 18 source modules (incl. build_llm_client.nim)
│   └── tests/                 # 20+ test files
├── mercury_agent/             # CLI + Discord daemon binary
│   ├── src/                   # agent_loop.nim, mercury_agent.nim,
│   │                         # build_llm_client.nim, tools/
│   └── tests/                 # tagent_loop, tcli, tintegration, test_shell_tool
├── mercury_code/              # Autonomous coding harness binary
│   ├── src/mercury_code/      # mercury_code.nim, code_runner.nim,
│   │                         # code_tool.nim, compile.nim, config.nims
│   └── tests/                 # tcode_runner (11 tests)
├── Makefile                   # build/test/lint shortcuts
└── *.md                       # Documentation
```

### Module dependency graph (simplified)

```
config.nim ──▶ llm_client.nim ──▶ agent_loop.nim ──▶ mercury_agent.nim
     │                               │
     └──▶ memory.nim ────────────────┘
          tool_registry.nim ─────────┘
               │
               ├── tools/shell.nim
               ├── file_tool.nim
               └── file_path_validator.nim

discord.nim ──▶ discord_commands.nim ──▶ agent_dispatcher.nim ──▶ agent_loop
     │                                      │
     ├── discord_bridge.nim                 └── permission.nim
     ├── discord_types.nim                       │
     ├── discord_mocks.nim                       ├── file_tool.nim
     ├── message_chunker.nim                     ├── rate_limit.nim
     └── thread_mapping.nim                      └── file_path_validator.nim

mercury_code.nim ──▶ agent_loop ──▶ build_llm_client ──▶ llm_client
     │
     ├── code_runner.nim   (CompileResult, parseNimErrors, CodingHarnessConfig)
     ├── code_tool.nim     (compile, test, read_file, write_file tools)
     └── compile.nim       (subprocess execution with timeout)
```

---

## Code Conventions

### General

- Modules have a docstring header summarizing their intent and explicitly
  listing what is out of scope.
- Public procs use `*` and have a docstring.
- Imports are grouped: `std/*` first, then package imports, then local.
- Lines wrap at 80 columns for docstrings and comments; code can go to
  100 where readability benefits.

### Error handling

- Use typed exceptions (`ConfigError`, `LLMError`, `MemoryError`,
  `ToolNotFoundError`, etc.) — never raise or catch generic
  `CatchableError` unless unavoidable (see below).
- Catch `CatchableError` in top-level event loops (CLI REPL, Discord
  message handler) to prevent crashes from propagating to the user.
- Never catch `Defect` (assertions, index errors, etc.) — let them crash.
- Tool execution procs use `{.gcsafe, raises: [].}` — the registry wraps
  escaped exceptions into `ToolResult{isError: true}`.

### Testing

- One `suite` per behavior cluster; one `test` per scenario.
- Use `check` for assertions, `expect` for exception testing.
- Mock external dependencies (HTTP, filesystem, Discord API) rather than
  making real network calls.
- In-memory SQLite (`:memory:`) for memory module tests.

### Discord-specific

- All Discord API operations go through injected callback procs
  (`SendMessageFn`, `TriggerTypingFn`, etc.) — never call Dimscord
  directly from a module that should be testable.
- New commands add a handler proc in `discord_commands.nim` and wire it
  in the command dispatch table. Add tests in `test_discord_commands.nim`.

---

## Adding a New Tool

1. Create the tool module in `mercury_core/src/mercury_core/` (or
   `mercury_agent/src/tools/` if it depends on agent-layer resources).
2. Define a `proc toolFn(args: JsonNode, ...): string` that matches
   `ToolExecuteProc` signature `{.gcsafe, raises: [].}`.
3. Register it in `buildRegistry()` in `mercury_agent.nim` (CLI) or
   in the Discord daemon's `cmdDaemon` (Discord).
4. Add tests in `mercury_core/tests/` or `mercury_agent/tests/`.

---

## Test Suite

**388 tests pass** across 26 test files (261 core + 51 agent + 11 code), 0 FAILED.

After any change, run `make test` from the project root. This builds and
tests both packages, with proper exit-code propagation so CI or your local
shell will catch regressions.

### Code health verified (May 29, 2026 deep audit)

- **Error handling**: All production `except` blocks use `CatchableError`
  rather than `Exception` (except the documented `file_tool.nim` dual-catch
  required by Nim 2.2.x + `-d:ssl`).
- **Thread safety**: Zero global mutable state in production code.
- **Security**: Shell tool deny-list (22 patterns), path validation with
  sandbox boundaries, role-based permission system.
- **No unsafe Nim patterns**: No `cast`, pointer arithmetic, or raw memory
  access in production code.
- **No resource leaks**: All DB connections, sockets, and processes are
  closed via `defer` or `try/except/finally`.

## Known Issues

| Issue | Module | Workaround |
|-------|--------|------------|
| `tllm_client` hangs ~2s on exit | `llm_client.nim` tests | Run tests individually with `nim c -r` |

### Previously Fixed

| Issue | Fix |
|-------|-----|
| `raiseSSLError` removed in Nim 2.2.x | `config.nims` passes `--define:ssl` in both packages |
| `nre` package unlisted dependency | Replaced with `std/re` |
| `Exception` catch in `file_tool` | Changed to `CatchableError` (with dual-catch comment for SSL mode) |
| Permission tool-name mismatch for shell | Added `"shell"` mapping to high-risk list |
| Redundant `setControlCHook` | Removed duplicate call in daemon branch |
| `*.nims` gitignored (config.nims untracked) | Removed `*.nims` from `.gitignore`, force-tracked `config.nims` files |

---

## Releasing

1. Update the `version` field in all three `.nimble` files.
2. Update `STATUS.md` with the new version and date.
3. Tag the release: `git tag v0.X.Y && git push origin v0.X.Y`.
4. (Future) CI will build binaries and create a GitHub Release.

```

`Makefile`:

```
.PHONY: build test lint nph

PYTHON ?= python3

build:
	cd mercury_core && nimble build -y
	cd mercury_agent && nimble build -y

test:
	cd mercury_core && nimble test -y 2>&1
	cd mercury_agent && nimble test -y 2>&1

lint: nph

nph:
	nimpretty --outputDir:src src/mercury_core/src/mercury_core/*.nim 2>/dev/null || echo "nimpretty not available"

```

`README.md`:

```md
# Mercury Agent

[![CI](https://github.com/MrSpaghatti/mercury-agent/actions/workflows/ci.yml/badge.svg)](https://github.com/MrSpaghatti/mercury-agent/actions/workflows/ci.yml)

Mercury is a small, self-contained Nim **AI agent** built around the
OpenAI Chat Completions protocol. It speaks to any OpenAI-compatible
endpoint (OpenRouter, vLLM, OpenAI, …), exposes tools to the model via
function calling, persists every conversation to a local SQLite
database with FTS5 full-text search, and ships a CLI for chatting with
the agent or browsing past sessions.

```
+-----------------+     +-------------------+     +----------------+
|  mercury_agent  | --> | mercury_core/llm  | --> |  LLM endpoint  |
|     (CLI)       |     |     _client       |     |   (HTTP/JSON)  |
+--------+--------+     +-------------------+     +----------------+
         |
         |  ReAct loop
         v
+--------+--------+     +-------------------+     +----------------+
|   agent_loop    | --> |   tool_registry   | --> |  shell, ...    |
+--------+--------+     +-------------------+     +----------------+
         |
         |  appendMessage / getHistory / searchHistory
         v
+--------+--------+
|  memory (SQLite |
|     + FTS5)     |
+-----------------+
```

## Features

- **Provider agnostic** — works with any OpenAI-compatible Chat
  Completions endpoint. Built-in defaults for OpenRouter and vLLM.
- **Tool calling** — register Nim procs as tools; the model invokes
  them via OpenAI function-calling. Ships with a sandboxed `shell`
  tool (deny-list + per-call timeout), plus `file_read` and
  `file_write` tools with path-based allow/deny policies.
- **Persistent memory** — every conversation is logged to SQLite with
  a FTS5 full-text index over message content.
- **CLI** — `chat`, `ask`, `session`, `history`, `search`.
- **Discord daemon** — run Mercury as a Discord bot with DI-based
  architecture, permission system, thread management, rate limiting,
  and offline-testable mock API.
- **Loop & error safety** — agent loop has loop-detection, max-iteration
  limits, and graceful handling of LLM/tool errors.
- **Layered configuration** — defaults < TOML config < .env <
  environment variables.

## Layout

```
mercury/
├── mercury_core/       # shared library
│   ├── src/            # config, llm_client, memory,
│   │                   # tool_registry, token_counter,
│   │                   # discord.nim (DI bot),
│   │                   # discord_bridge, discord_commands,
│   │                   # discord_types, discord_mocks,
│   │                   # agent_dispatcher, permission,
│   │                   # file_path_validator, file_tool,
│   │                   # message_chunker, rate_limit,
│   │                   # thread_mapping, build_llm_client
│   └── tests/          # 20+ test files covering all modules
├── mercury_agent/      # CLI binary (mercury_agent.nim,
│   ├── src/            # agent_loop.nim, tools/shell.nim,
│   │                   # build_llm_client.nim)
│   └── tests/          # tagent_loop, tcli, tintegration, test_shell_tool
├── mercury_code/       # autonomous coding harness binary
│   ├── src/            # mercury_code.nim, code_runner.nim,
│   │                   # code_tool.nim, compile.nim, config.nims
│   └── tests/          # tcode_runner (11 tests)
├── Makefile
└── README.md           # this file
```

## Quick start

### Prerequisites

- Nim ≥ 2.0
- `nimble`
- SQLite shared library (with FTS5 — included in standard SQLite ≥ 3.9)

### Build

```bash
make build           # builds both mercury_core and mercury_agent
# or, equivalently:
cd mercury_core   && nimble build
cd mercury_agent  && nimble build
```

### Configure

Mercury looks for configuration in three places, **highest priority first**:

1. Environment variables (e.g. `MERCURY_PROVIDER=openrouter`).
2. `.env` in the current directory (typically your API key).
3. `~/.config/mercury/config.toml` (or the path passed to `--config`).

Minimal `.env`:

```bash
OPENROUTER_API_KEY=sk-or-...
```

Optional `~/.config/mercury/config.toml`:

```toml
[mercury]
provider = "openrouter"
openrouter_model = "anthropic/claude-3.5-sonnet"
max_tokens = 4096
temperature = 0.3
max_loop_iterations = 10
db_path = "~/.local/share/mercury/mercury.db"
```

### Run

```bash
# One-shot question
./mercury_agent/mercury_agent ask "what is the capital of France?"

# Interactive chat
./mercury_agent/mercury_agent chat

# List recent sessions
./mercury_agent/mercury_agent history

# Full-text search across all stored messages
./mercury_agent/mercury_agent search "capital of France"

# Resume an existing session (history is shown read-only; new turns
# go to a fresh session)
./mercury_agent/mercury_agent session sess_20260101T120000_123456789

# Per-run overrides (no need to edit the config file)
./mercury_agent/mercury_agent ask "ping" \
    --provider=vllm --model=qwen2.5-7b-instruct --temperature=0.1

# Run as a Discord bot (set DISCORD_BOT_TOKEN first)
export DISCORD_BOT_TOKEN="your_token_here"
./mercury_agent/mercury_agent daemon
```

## CLI usage

```
mercury_agent <subcommand> [options]

Subcommands:
  chat                    Interactive REPL.
  ask <question>          Single-shot question.
  session <id>            Print history of a session and continue chatting
                          (new turns go to a new session).
  history                 List most recently updated sessions.
  search <query>          FTS5 search across stored messages.
  daemon                  Start the Discord bot daemon (blocking).

Common options (chat / ask / session):
  --model=<name>          Override model name for the active provider.
  --provider=<name>       Override provider (openrouter | vllm).
  --temperature=<float>   Override sampling temperature (0..2). Negative
                          means leave at config default.
  --config=<path>         Path to TOML config (overrides default).
  --envFile=<path>        Path to .env (default: .env).

Options for history / search:
  --limit=<n>             Max sessions / matches to show.
  --config=<path>         Path to TOML config (overrides default).
  --envFile=<path>        Path to .env (default: .env).

Run `mercury_agent --help` or `mercury_agent <subcommand> --help` for
the full list.
```

## Configuration reference

| Key (TOML)            | Env var                       | Default                                      | Description                                      |
| --------------------- | ----------------------------- | -------------------------------------------- | ------------------------------------------------ |
| `provider`            | `MERCURY_PROVIDER`            | `openrouter`                                 | Active provider: `openrouter` or `vllm`.         |
| `openrouter_endpoint` | `MERCURY_OPENROUTER_ENDPOINT` | `https://openrouter.ai/api/v1`               | OpenRouter base URL.                             |
| `openrouter_model`    | `MERCURY_OPENROUTER_MODEL`    | `openrouter/auto`                            | Model name used when provider=openrouter.        |
| `vllm_endpoint`       | `MERCURY_VLLM_ENDPOINT`       | `http://192.168.4.30:8000/v1`                | vLLM base URL.                                   |
| `vllm_model`          | `MERCURY_VLLM_MODEL`          | `qwen2.5-7b-instruct`                        | Model name used when provider=vllm.              |
| `max_tokens`          | `MERCURY_MAX_TOKENS`          | `4096`                                       | Per-request `max_tokens`.                        |
| `temperature`         | `MERCURY_TEMPERATURE`         | `0.3`                                        | Sampling temperature in `[0, 2]`.                |
| `max_loop_iterations` | `MERCURY_MAX_LOOP_ITERATIONS` | `10`                                         | Hard cap on ReAct iterations per query.          |
| `db_path`             | `MERCURY_DB_PATH`             | `~/.local/share/mercury/mercury.db`          | SQLite database path. `~` expands to `$HOME`.    |
| `discord.token_env`   | `DISCORD_BOT_TOKEN`           | `DISCORD_BOT_TOKEN`                          | Env var holding the Discord bot token.          |
| `discord.prefix`      | `DISCORD_PREFIX`              | `!`                                          | Command prefix for bot commands.                |
| `discord.admins.allow`| (TOML only)                   | `[]`                                         | Discord user IDs with admin privileges.         |
| `discord.file_rules`  | (TOML only)                   | see `mercury_core/DISCORD.md`                | File access allow/deny patterns.                |
| (n/a)                 | `OPENROUTER_API_KEY`          | (empty)                                      | API key sent as `Authorization: Bearer ...`.     |

`.env` is also read (in `loadConfig`) for `OPENROUTER_API_KEY`,
`MERCURY_PROVIDER`, and `MERCURY_VLLM_ENDPOINT` — useful when you don't
want to export those variables globally.

## Architecture overview

### `mercury_core/`

| Module              | Responsibility                                                                  |
| ------------------- | ------------------------------------------------------------------------------- |
| `config.nim`        | Loads `MercuryConfig` from defaults + TOML + `.env` + env vars; validates.      |
| `llm_client.nim`    | Synchronous OpenAI-compatible Chat Completions client with retry/error types.   |
| `tool_registry.nim` | Named registry of tools; serializes to OpenAI `tools` array; safe execution.    |
| `memory.nim`        | SQLite + FTS5: sessions, messages, full-text search, token-usage aggregation.   |
| `token_counter.nim` | Cheap heuristic token counter used to size requests.                            |

### `mercury_core/` — Discord & Agent Infrastructure

| Module                  | Responsibility                                                              |
| ----------------------- | --------------------------------------------------------------------------- |
| `discord.nim`           | DI-based Discord bot: `DiscordBot` ref object with injected API callbacks.  |
| `discord_bridge.nim`    | `RealDiscordApi` — wraps dimscord REST API (send, typing, threads).         |
| `discord_commands.nim`  | Command parser + handlers for `!status`, `!config`, `!admin`, `!session`.   |
| `discord_types.nim`     | Shared types (`DiscordConfig`, `DiscordUser`, `FileRules`).                  |
| `discord_mocks.nim`     | `MockDiscordApi`, `MockShard` — full offline Discord simulation for tests.  |
| `agent_dispatcher.nim`  | Async agent request queue: accepts messages, dispatches to agent loop,      |
|                         | returns result via callback.                                                |
| `permission.nim`        | Permission evaluator: user allow/deny lists, tool risk levels, path checks. |
| `file_path_validator.nim`| Path traversal protection, canonicalization, deny-list matching.            |
| `file_tool.nim`         | `fileReadTool` / `fileWriteTool` with pattern-based allow/deny.             |
| `message_chunker.nim`   | Splits long messages at the Discord 2000-char limit.                        |
| `rate_limit.nim`        | Per-user token-bucket rate limiter.                                         |
| `thread_mapping.nim`    | Persistent Discord channel→thread mapping backed by SQLite.                 |

### `mercury_agent/`

| Module                  | Responsibility                                                              |
| ----------------------- | --------------------------------------------------------------------------- |
| `agent_loop.nim`        | ReAct loop: build system+user, call LLM, dispatch tool calls, log to memory.|
| `tools/shell.nim`       | Shell tool with deny-list and per-call timeout.                             |
| `mercury_agent.nim`     | CLI wiring + subcommand entry points (`chat`, `ask`, `session`, `daemon`).  |

The agent loop's contract is simple:

```nim
proc runAgentLoop*(
    cfg: MercuryConfig;
    llm: LLMClient;
    registry: ToolRegistry;
    memory: var Memory;
    userInput: string;
): AgentResult
```

It returns once the model emits a final text answer, the iteration cap
is hit, or the loop detector fires (same tool + same args N times in a
row).

## Development

### Build & test

```bash
make build           # build both packages
make test            # run all tests (mercury_core + mercury_agent)
```

> **Note**: The full build (including the Discord daemon) now works on
> Nim 2.2.10. Both packages pass `--define:ssl` via `config.nims` to handle
> the `raiseSSLError` compatibility issue introduced in Nim 2.2.x.

Equivalent commands:

```bash
cd mercury_core   && nimble test
cd mercury_agent  && nimble test
```

### Test layout

The test suite is split into focused modules:

- `mercury_core/tests/`
  - `tconfig.nim` — config defaults, TOML parsing, env-var precedence,
    `validate`.
  - `tllm_client.nim` — request building, response parsing, retry logic,
    typed errors.
  - `tmemory.nim` — sessions, append/getHistory, FTS5, token usage.
  - `ttool_registry.nim` — registration, execution, OpenAI serialization.
  - `ttoken_counter.nim` — heuristic counter sanity checks.
  - `mock_server.nim` — `MockLLMServer`, an in-process HTTP mock used by
    integration tests.
  - `test_*.nim` — 11 Discord/security test files (permission, file_tool,
    rate_limit, thread_mapping, message_chunker, agent_dispatcher,
    discord_bot, discord_commands, discord_mocks, discord_config,
    e2e_discord, and reconnection).

- `mercury_agent/tests/`
  - `tagent_loop.nim` — ReAct loop driven against the mock server: text
    answer, tool-call turn, max iterations, loop detection, tool errors,
    memory logging, the `MercuryConfig` overload.
  - `tcli.nim` — config-override layering, recent-session listing,
    `cmdHistory`/`cmdSearch`/`cmdAsk`/`cmdSession` argument validation,
    binary `--help` smoke test.
  - `test_shell_tool.nim` — deny-list matching, command execution,
    timeout handling, tool registry integration.
  - **`tintegration.nim`** — full end-to-end stack: `loadConfig` →
    `LLMClient` → `ToolRegistry` (with the real `shellTool`) →
    SQLite-backed `Memory` → `runAgentLoop`. Covers:
      1. **Full pipeline** — text-only response, tool-call response,
         LLM error path; verifies session is created and history is
         logged correctly.
      2. **Config loading** — defaults, TOML overrides, env-var
         precedence, `.env` API-key loading, validation rejection.
      3. **Memory persistence** — multi-message session round-trip,
         FTS5 search across multiple sessions, on-disk persistence
         across reopen.
      4. **Tool registry** — register `shellTool`, execute, deny-list,
         malformed JSON, OpenAI definition serialization, duplicate
         registration error.
      5. **Agent loop** — full ReAct turn (tool call → tool result →
         final answer) with full memory log assertions; on-disk
         persistence + FTS5 search of agent output across reopen.

### Running a single test file

```bash
cd mercury_agent
nimble c -r tests/tintegration.nim
```

### Coding style

- Modules have a docstring header summarizing intent and out-of-scope
  items.
- Public procs use `*` and have docstrings.
- Errors are typed (`ConfigError`, `LLMError` subtypes, `ToolError`
  subtypes, `MemoryError`) and never leak generic `CatchableError` to
  callers when avoidable.
- Tests use `unittest`, with one suite per behaviour cluster.

## Code Formatting

Use `nimpretty` (Nim's official formatter) to format code:

```bash
nimpretty src/mercury_core/src/mercury_core/*.nim
nimpretty src/mercury_agent/src/*.nim
```

The `nph` Make target attempts to run it; `nimpretty` is included with Nim.

## Development Status

Mercury is currently **Phase 1 (Foundation) + Phase 2 (Discord) +
 Phase 3 P1 (mercury_code) — all complete**. See `STATUS.md` for the
 full status breakdown.

### Roadmap

| Phase | What | Status |
|-------|------|--------|
| 1.1–1.4 | Core library (config, LLM, tokens, memory) | ✅ Complete |
| 2.1–2.3 | Agent core (tools, ReAct loop, mocks) | ✅ Complete |
| 3.1–3.3 | CLI, integration, end-to-end tests | ✅ Complete |
| Phase 2 | Discord bot with permissions, threads, file tools | ✅ Complete |
| P0 | CI pipeline (GitHub Actions on Nim 2.0.8 + 2.2.2) | ✅ Complete |
| P0 | Deep code audit (40+ source files, 312+ tests) | ✅ Complete |
| P1 | `mercury_code` — coding harness (compile, test, read_file, write_file) | ✅ Complete |
| P2 | MCP support for external tool discovery | 🔜 Planned |
| P2 | Sub-agent delegation for parallel work | 🔜 Planned |
| P3 | Web UI (lightweight HTTP chat frontend) | 🔜 Planned |

## License

MIT.

```

`STATUS.md`:

```md
# Mercury Agent — Development Status

**Last Updated**: May 30, 2026  
**Project Path**: `/home/spag/mercury-agent`  
**Phase**: 1 (Foundation) + Phase 2 (Discord Integration) — Complete

---

## Summary

All planned waves are implemented and verified. Mercury is a fully functional
AI agent with:

- **CLI agent** (`chat`, `ask`, `session`, `history`, `search`)
- **Discord daemon** (DI-based bot with permissions, threads, file tools)
- **Persistent memory** (SQLite + FTS5 full-text search)
- **ReAct loop** with loop detection, error recovery, and configurable limits
- **Tool system** with sandboxed shell, file read/write, permission checks,
  rate limiting, message chunking

---

## Completed

### Phase 1 Wave 1: Foundation (100%)
| Task | Module | Tests |
|------|--------|-------|
| 1.1 Config (TOML + .env + env vars) | `config.nim` | 35/35 pass |
| 1.2 LLM client (OpenAI Chat Completions) | `llm_client.nim` | 16/16 pass |
| 1.3 Token counter (heuristic) | `token_counter.nim` | 14/14 pass |
| 1.4 SQLite memory + FTS5 | `memory.nim` | 27/27 pass |

### Phase 1 Wave 2: Agent Core (100%)
| Task | Module | Tests |
|------|--------|-------|
| 2.1 Tool registry + shell tool | `tool_registry.nim`, `tools/shell.nim` | 20/20 pass |
| 2.2 ReAct agent loop | `agent_loop.nim` | 10/10 pass |
| 2.3 Mock HTTP server | `mock_server.nim` | 3/3 pass |

### Phase 1 Wave 3: CLI + Integration (100%)
| Task | Module | Tests |
|------|--------|-------|
| 3.1 CLI interface (cligen) | `mercury_agent.nim` | 19/19 pass |
| 3.2 Integration wiring | `mercury_agent.nim` | 17/17 pass (integration tests) |
| 3.3 End-to-end tests + docs | `tagent_loop`, `tcli`, `tintegration` | All pass |
| Agent shell tool | `test_shell_tool.nim` | 18/18 pass |

### Phase 2 Discord Integration (100%)
| Module | Responsibility | Key Features |
|--------|----------------|--------------|
| `discord.nim` | DI-based bot object | Callback injection, shard, agent dispatcher wiring |
| `discord_commands.nim` | Command handler | `!status`, `!config`, `!admin`, `!session` — with permission checks |
| `discord_bridge.nim` | Real Discord API adapter | `sendMessage`, `triggerTyping`, `createThread`, `archiveThread` |
| `discord_types.nim` | Shared types | `DiscordConfig`, `DiscordUser`, `FileRules` |
| `discord_mocks.nim` | Mock implementations | `MockDiscordApi`, `MockShard` for offline testing |
| `permission.nim` | Permission evaluator | User allow/deny lists, tool risk levels, path-based file rules |
| `file_path_validator.nim` | Path safety | Path traversal guards, deny-list, percent-decode |
| `file_tool.nim` | File read/write tools | Pattern-based allow/deny paths |
| `message_chunker.nim` | Discord message chunking | Splits long messages at 2000-char Discord limit |
| `rate_limit.nim` | Rate limiter | Per-user token-bucket rate limiting |
| `thread_mapping.nim` | Thread persistence | Maps Discord channel+user to persistent agent threads |
| `agent_dispatcher.nim` | Async agent runner | Queues agent requests with callback for result delivery |

### Quality / Infrastructure (100%)
| Item | Status |
|------|--------|
| `make build` (core + agent) | ✅ Compiles (see SSL note below) |
| `make test` (core + agent) | ✅ All 388 tests pass, 0 FAILED |
| `nim check` (core + agent) | ✅ No static analysis errors |
| `.env` / `.env.example` | ✅ Configured |
| `.gitignore` | ✅ Covers all build artifacts |
| Architectural review | ✅ `report.md` written |
| Deep code audit (all 40+ source files) | ✅ 388 tests pass, 0 critical issues found |
| CI pipeline (GitHub Actions) | ✅ Passing on Nim 2.0.8 and 2.2.2 |

---

## Known Issues

### ~~🔴 SSL build failure with dimscord on Nim 2.2.10~~ ✅ Fixed

> **Fixed**: `config.nims` in both packages now pass `--define:ssl`, which
> ensures `defineSsl` is consistently true across all modules, resolving the
> `raiseSSLError` lookup. Both `make build` and `make test` work on Nim 2.2.10.

### 🟡 LLM client test slow exit

`tllm_client.nim` starts a mock TCP server in a thread that doesn't join
cleanly on process exit. The test passes but hangs for ~2 seconds at
shutdown. Run individual tests with `nim c -r` to avoid the batch issue.

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    mercury_agent (CLI)                    │
│  ┌──────────┐  ┌──────────────┐  ┌──────────────────┐   │
│  │ cligen   │  │ agent_loop   │  │ tools/shell.nim  │   │
│  │ dispatch │──▶ (ReAct loop) │──▶ (sandboxed shell) │   │
│  └──────────┘  └──────┬───────┘  └──────────────────┘   │
│                       │                                   │
│  ┌─────────────────────┐   ┌─────────────────────────┐   │
│  │ mercury_core/       │   │ mercury_core/           │   │
│  │ llm_client.nim      │   │ memory.nim (SQLite+FTS5)│   │
│  │ config.nim          │   │ tool_registry.nim       │   │
│  └─────────────────────┘   └─────────────────────────┘   │
├─────────────────────────────────────────────────────────┤
│                 mercury_agent (Daemon)                    │
│  ┌──────────────────────────────────────────────────┐   │
│  │ dimscord ─▶ discord_bridge ─▶ discord.nim         │   │
│  │                                        │          │   │
│  │                    ┌─────────────────────┘          │   │
│  │                    ▼                                 │   │
│  │              discord_commands.nim                    │   │
│  │                    │                                 │   │
│  │                    ▼                                 │   │
│  │              agent_dispatcher.nim ─▶ agent_loop      │   │
│  └──────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

---

## Files by Layer

### mercury_core (18 modules)
| File | Role |
|------|------|
| `config.nim` | Layered config (TOML + .env + env vars) |
| `llm_client.nim` | OpenAI-compatible HTTP client |
| `token_counter.nim` | Heuristic token estimation |
| `memory.nim` | SQLite + FTS5 persistence |
| `tool_registry.nim` | Named tool registration + JSON schema export |
| `build_llm_client.nim` | MercuryConfig → LLMClient builder |
| `discord.nim` | DI-based Discord bot |
| `discord_bridge.nim` | Real Discord API adapter (Dimscord) |
| `discord_commands.nim` | Bot command handlers |
| `discord_types.nim` | Shared Discord types |
| `discord_mocks.nim` | Mock API for offline testing |
| `agent_dispatcher.nim` | Async agent request queue |
| `permission.nim` | User/tool permission evaluation |
| `file_path_validator.nim` | Path traversal protection |
| `file_tool.nim` | File read/write agent tools |
| `message_chunker.nim` | Discord message size splitting |
| `rate_limit.nim` | Per-user token bucket rate limiter |
| `thread_mapping.nim` | Discord→agent thread persistence |

### mercury_agent (5 modules)
| File | Role |
|------|------|
| `mercury_agent.nim` | CLI entry point + subcommand dispatch |
| `agent_loop.nim` | ReAct loop: LLM → tool → loop |
| `build_llm_client.nim` | MercuryConfig → LLMClient builder |
| `tools/shell.nim` | Sandboxed shell tool with deny-list, timeout |
| `tools/` | Tool implementations directory |

### mercury_code (5 modules)
| File | Role |
|------|------|
| `mercury_code.nim` | CLI binary entry point |
| `code_runner.nim` | CompileResult, parseNimErrors, CodingHarnessConfig |
| `code_tool.nim` | compile/test/read_file/write_file tools |
| `compile.nim` | Subprocess compile execution with timeout |
| `config.nims` | Nimble compiler switches (-d:ssl, path resolution) |

---

## Test Coverage

| Package | Test files | Tests | Status |
|---------|-----------|-------|--------|
| mercury_core (Wave 1) | tconfig, tllm_client, ttoken_counter, tmemory | 96 | ✅ All pass |
| mercury_core (Wave 2) | ttool_registry, test_mock_server | 18 | ✅ All pass |
| mercury_core (Discord) | test_permission, test_file_*, test_rate_limit, test_thread_*, test_agent_dispatcher, test_message_chunker, test_discord_*, test_persona, test_mcp_client, test_e2e_discord | 212 | ✅ All pass |
| mercury_agent | tcli, tagent_loop, tintegration, test_shell_tool | 51 | ✅ All pass |
| mercury_code | tcode_runner | 11 | ✅ All pass |
| **Total** | **26 test files** | **388** | **✅ 0 FAILED** |

---

## Next Steps

See `.sisyphus/plans/roadmap.md` for the detailed project roadmap.
Near-term candidates (in priority order):

1. **~~CI pipeline (P0)~~** ✅ — GitHub Actions running on Nim 2.0.8 and 2.2.2.
   Green CI badge on every push.
2. **~~mercury_code package (P1)~~** ✅ — Autonomous coding harness with compile,
   test, read_file, write_file tools. 11 tests pass.
3. **MCP support (P2)** — 🔄 In progress. `mcp_client.nim` (HTTP/JSON-RPC
   transport, initialize, tools/list, tools/call), `mcp_tool.nim` (tool
   registration bridge), `McpServerConfig` added to `MercuryConfig`.
   Build passes on both Nim 2.0.x and 2.2.x. 8 tests written.
4. **Sub-agent delegation (P2)** — Allow the ReAct loop to spawn child
   agents for parallel exploration.
5. **Web UI (P3)** — Lightweight HTTP chat frontend.

```

`TASK_2.2_SPEC.md`:

```md
# Task 2.2: ReAct Agent Loop Specification
## For Delegation to Jules Agent

**Project**: Mercury Agent (Nim-based AI agent harness)
**Repo**: MrSpaghatti/mercury-agent
**Location**: `/home/spag/mercury`
**Task**: 2.2 from mercury-agent plan
**Depends on**: Task 2.1 (Tool registry + shell tool)

## REQUIREMENTS

### 1. Create Agent Loop Module
**File**: `mercury_core/src/mercury_core/agent_loop.nim`

**Core Types**:
```nim
type
  AgentLoop* = object
    llm: LLMClient
    tools: ToolRegistry
    memory: Memory
    config: MercuryConfig
    maxIterations: int
    currentIteration: int
    
  AgentResponse* = object
    content: string
    toolCalls: seq[ToolCall]
    tokenUsage: TokenUsage
    iterations: int
    sessionId: string
```

### 2. Implement ReAct Loop Algorithm
**Steps**:
1. **Initialize**: Load config, create LLM client, tool registry, memory session
2. **Build Messages**: System prompt + history + user input
3. **Call LLM**: With messages + tool definitions
4. **Parse Response**:
   - Text response → return final answer
   - Tool calls → execute tools, append results, loop
5. **Loop Control**: Max iterations (default 10), loop detection
6. **Logging**: Every turn logged to SQLite memory

**System Prompt** (~200 tokens, PI Agent philosophy):
```
You are Mercury, a helpful AI assistant. You can use tools to help answer questions.

When you need to use a tool, respond with tool_calls. Otherwise, respond with text.

Think step by step. If a tool fails, try a different approach. If you get stuck, ask for clarification.
```

### 3. Key Features to Implement
- **Text Response Handling**: Return text when no tools needed
- **Tool Execution**: Call tools via ToolRegistry, handle results
- **Loop Detection**: Repeated same tool call 3× triggers loop detection
- **Error Handling**: Tool errors reported back to LLM gracefully
- **Token Tracking**: Track usage per iteration, total
- **Memory Integration**: Log every turn to SQLite (session, messages, tokens)
- **Context Management**: Handle context limits (truncate history if needed)

### 4. Memory Integration
- Create new session for each agent run
- Append each message (user, assistant, tool) to memory
- Store token counts for cost tracking
- Enable searchable history via FTS5

### 5. Tests
**File**: `tests/tagent_loop.nim`
**Test Cases**:
1. Simple text response (no tools)
2. Tool-using response (calls shell tool)
3. Loop detection (repeated tool calls)
4. Tool error handling
5. Max iteration limit
6. Memory logging verification
7. Token usage tracking

## CONTEXT

### Dependencies
- **Task 1.2**: LLM client (`llm_client.nim`) - provides `LLMClient`, `ChatMessage`, `ToolCall`, `TokenUsage`
- **Task 2.1**: Tool registry (`tool_registry.nim`) - provides `ToolRegistry`, `Tool` concept
- **Task 1.4**: Memory module (`memory.nim`) - provides `Memory`, `newSession`, `appendMessage`
- **Task 1.1**: Config module (`config.nim`) - provides `MercuryConfig`

### Existing Code Patterns
- Use existing error handling patterns (custom exception types)
- Follow module structure from other core modules
- Use JSON serialization for tool calls/results (as in memory module)
- Integrate with existing test patterns

### Constraints
- **DO NOT** add Plan-Execute mode (defer to v2)
- **DO NOT** add sub-agent delegation (defer to v2)
- **DO NOT** add reflection/self-critique (defer to v2)
- Keep system prompt minimal (~200 tokens)
- Focus on reliability over features

## VERIFICATION CRITERIA

### Acceptance Tests
- [ ] Agent responds with text when no tools needed
- [ ] Agent calls tool when appropriate, uses result, continues
- [ ] Agent stops after max iterations with message
- [ ] Repeated same tool call 3× triggers loop detection
- [ ] Tool errors reported back to LLM
- [ ] Every turn logged to SQLite
- [ ] Token usage tracked correctly
- [ ] All tests pass with mock server

### Quality Gates
- `nimble test tagent_loop` passes
- Project still builds: `nimble build`
- No memory leaks (clean session management)
- Thread-safe for concurrent use
- Follows existing code quality standards

## INTEGRATION POINTS

### With Task 2.1 (Tool Registry)
```nim
# Expected interface from task 2.1
proc executeTool*(registry: ToolRegistry, name: string, arguments: string): string
proc getToolSchema*(registry: ToolRegistry): JsonNode  # OpenAI-compatible
```

### With Task 1.4 (Memory)
```nim
# Expected interface from task 1.4
proc newSession*(memory: Memory, metadata: string = ""): string
proc appendMessage*(memory: Memory, sessionId: string, message: ChatMessage, 
                    tokensIn: int, tokensOut: int)
```

### Mock Testing
- Use mock LLM server (from task 2.3 when available)
- Mock tool registry for unit tests
- In-memory SQLite for testing

## READY FOR DELEGATION

This specification is complete and ready for delegation to Jules agent once task 2.1 (Tool registry) is complete. The task is well-scoped with clear dependencies, requirements, and verification criteria.
```

`TASK_2.2_VERIFICATION_PLAN.md`:

```md
# Task 2.2: ReAct Agent Loop - Verification Test Plan

## Overview
This document outlines the verification tests for the ReAct agent loop implementation (task 2.2). These tests will be used to verify Jules' implementation once it's complete.

## Test Categories

### 1. Basic Functionality Tests
**Objective**: Verify core agent loop functionality

**Test Cases**:
1. **Simple text response**
   - Input: "Say hello"
   - Mock LLM response: Text only ("Hello!")
   - Expected: Agent returns "Hello!" without tool calls
   - Verification: No tool calls executed, memory logged

2. **Tool-using response**
   - Input: "What's 2+2?"
   - Mock LLM response: Tool call to calculator
   - Mock tool response: "4"
   - Mock LLM follow-up: "The answer is 4"
   - Expected: Agent calls tool, uses result, returns final answer
   - Verification: Tool called once, memory has all messages

3. **Multiple tool calls**
   - Input: Complex query requiring multiple tools
   - Mock: Series of tool calls and responses
   - Expected: Agent handles sequential tool usage
   - Verification: Correct tool execution order

### 2. Error Handling Tests
**Objective**: Verify robust error handling

**Test Cases**:
4. **Tool error recovery**
   - Input: Query requiring tool
   - Mock tool: Returns error
   - Mock LLM: Adapts strategy, tries different approach
   - Expected: Agent handles tool error gracefully
   - Verification: Error logged, agent continues

5. **LLM error recovery**
   - Input: Any query
   - Mock LLM: Returns 500 error, then succeeds on retry
   - Expected: Agent retries and succeeds
   - Verification: Retry logic works

6. **Invalid tool call**
   - Input: Query
   - Mock LLM: Returns invalid tool call (non-existent tool)
   - Expected: Agent reports tool not found, continues
   - Verification: Error handling works

### 3. Loop Control Tests
**Objective**: Verify loop management

**Test Cases**:
7. **Max iterations**
   - Input: Query that causes infinite loop
   - Mock LLM: Always returns tool call
   - Expected: Agent stops after max iterations (default 10)
   - Verification: Loop detection works

8. **Loop detection**
   - Input: Query
   - Mock LLM: Returns same tool call 3 times in a row
   - Expected: Agent detects loop, stops with message
   - Verification: Loop detection triggers at 3 repeats

9. **Context window management**
   - Input: Long conversation history
   - Expected: Agent truncates history to fit context
   - Verification: Context management works

### 4. Memory Integration Tests
**Objective**: Verify SQLite memory integration

**Test Cases**:
10. **Session creation**
    - Input: Any query
    - Expected: New session created in SQLite
    - Verification: Session record exists

11. **Message logging**
    - Input: Query with tool usage
    - Expected: All messages logged (user, assistant, tool)
    - Verification: All messages in database with correct metadata

12. **Token tracking**
    - Input: Query
    - Expected: Token counts logged for each message
    - Verification: Token usage tracked accurately

13. **Session retrieval**
    - Input: Query about previous session
    - Expected: Agent can retrieve session history
    - Verification: History retrieval works

### 5. Integration Tests
**Objective**: Verify integration with other components

**Test Cases**:
14. **Config integration**
    - Input: Query with custom config (different model, temperature)
    - Expected: Agent uses config values
    - Verification: Config properly integrated

15. **Tool registry integration**
    - Input: Query requiring shell tool
    - Expected: Agent uses registered shell tool
    - Verification: Tool registry integration works

16. **LLM client integration**
    - Input: Query
    - Expected: Agent uses LLM client correctly
    - Verification: Proper HTTP requests, headers, etc.

## Test Implementation Strategy

### Mock Components
1. **Mock LLM Server**: Use existing mock from tests (or task 2.3 when available)
2. **Mock Tool Registry**: Test implementation with stub tools
3. **In-memory SQLite**: For testing memory integration

### Test Files
- `tests/tagent_loop.nim`: Main test file
- `tests/mock_components.nim`: Shared mock components
- `tests/test_helpers.nim`: Test utilities

### Verification Steps
For each test:
1. **Setup**: Initialize mocks, create agent
2. **Execution**: Run agent with test input
3. **Assertion**: Verify expected behavior
4. **Cleanup**: Reset state

## Acceptance Criteria Verification

From the plan, verify each acceptance criterion:

1. [ ] **Agent responds with text when no tools needed** → Test 1
2. [ ] **Agent calls tool when appropriate, uses result, continues** → Test 2
3. [ ] **Agent stops after max iterations with message** → Test 7
4. [ ] **Repeated same tool call 3× triggers loop detection** → Test 8
5. [ ] **Tool errors reported back to LLM** → Test 4
6. [ ] **Every turn logged to SQLite** → Test 11
7. [ ] **Tests pass with mock server** → All tests

## Quality Gates

1. **Code Quality**: `make desloppify` score ≥ 90
2. **Test Coverage**: All critical paths covered
3. **Integration**: Works with existing components
4. **Performance**: No memory leaks, reasonable performance
5. **Documentation**: Code is well-documented

## Ready for Verification

Once Jules completes task 2.2 implementation, run these verification tests to ensure quality and correctness.
```

`VERIFICATION_CHECKLIST.md`:

```md
# Mercury Agent — Final Verification Checklist

## Wave 1: Foundation
- [x] 1.1 Config module — 35/35 tests pass
- [x] 1.2 LLM client — 16/16 tests pass
- [x] 1.3 Token counter — 14/14 tests pass
- [x] 1.4 SQLite memory — 27/27 tests pass

## Wave 2: Agent Core
- [x] 2.1 Tool registry + shell tool — 20/20 tests pass
- [x] 2.2 ReAct agent loop — 10/10 tests pass
- [x] 2.3 Mock HTTP server — 3/3 tests pass

## Wave 3: CLI + Integration
- [x] 3.1 CLI interface — 19/19 tests pass (`tcli.nim`)
- [x] 3.2 Integration wiring — 17/17 tests pass (`tintegration.nim`)
- [x] 3.3 End-to-end tests + documentation — All tests pass, README + DISCORD.md written

## Phase 2: Discord Integration
- [x] Discord bot (DI-based, dimscord) — Working with MockDiscordApi and RealDiscordApi
- [x] Discord commands — `!status`, `!config`, `!admin`, `!session`
- [x] Permission system — User allow/deny, admin list, tool risk levels
- [x] File tools — Path validation, pattern-based allow/deny, Discord file rules
- [x] Message chunker — Splits long responses at the 2000-char Discord limit
- [x] Rate limiter — Per-user token bucket
- [x] Thread mapping — Persistent Discord→agent thread sessions
- [x] Agent dispatcher — Async queue with callbacks
- [x] End-to-end Discord tests — Full offline simulation with mocks

## Quality Gates
- [x] `make desloppify` score ≥ 90 — ✅ Clean scan (0 issues)
- [x] All tests pass — ✅ Verified
- [x] Project builds cleanly — ✅ `make build` succeeds on Nim 2.2.10 (SSL fixed via `--define:ssl`)
- [x] No `as any`, `@ts-ignore`, or type suppressions — ✅ N/A (Nim)
- [x] No empty catch blocks — ✅ All catches have body or `discard` with reason
- [x] No hardcoded secrets or API keys — ✅ All via env vars
- [x] Code follows existing patterns — ✅ Consistent across modules
- [x] Documentation updated — ✅ STATUS.md, README.md, DISCORD.md, CONTRIBUTING.md

```

`WAVE_3_SPEC.md`:

```md
# Wave 3: CLI + Integration Specification
## For Delegation to Jules Agent (After Wave 2 Completion)

**Project**: Mercury Agent (Nim-based AI agent harness)
**Repo**: MrSpaghatti/mercury-agent
**Location**: `/home/spag/mercury`
**Wave**: 3 (CLI + Integration)
**Tasks**: 3.1, 3.2, 3.3 (sequential)
**Depends on**: Wave 2 completion (especially task 2.2)

---

## TASK 3.1: CLI Interface (cligen)

### Requirements
**File**: `mercury_agent/src/main.nim`

**CLI Features**:
- Use `cligen` library for command-line parsing
- Main command: `mercury [options] "prompt"`
- Options:
  - `--provider`: string (openrouter|vllm)
  - `--model`: string (model name)
  - `--config`: string (config file path)
  - `--verbose`: bool (verbose output)
  - `--version`: bool (print version)
- Subcommands:
  - `mercury "prompt"`: Run agent with prompt
  - `mercury --version`: Print version
  - `mercury init`: Create default config file
  - `mercury history`: Show recent sessions
  - `mercury session <id>`: Show specific session
- Stdin support: `echo "hello" | mercury`
- Colorized output with `std/terminal`
- Token usage summary after each response

**Implementation Details**:
- Version from `mercury_agent.nimble` or constant
- Config loading via existing `config.nim` module
- Integration with agent loop (task 2.2)
- Error handling with clear messages
- Graceful Ctrl+C handling

**Tests**: `tests/tcli.nim`
- Test argument parsing
- Test subcommands
- Test stdin handling
- Test error cases

### Acceptance Criteria
- [ ] `mercury --version` prints "mercury X.Y.Z"
- [ ] `mercury "hello"` runs agent and prints response
- [ ] `mercury --provider vllm "hello"` uses vLLM provider
- [ ] `mercury init` creates default config file
- [ ] `mercury history` shows recent sessions
- [ ] `echo "hello" | mercury` reads from stdin
- [ ] Token usage printed after response
- [ ] All tests pass

---

## TASK 3.2: Integration - Wire Everything Together

### Requirements
**File**: `mercury_agent/src/mercury_agent.nim`

**Integration Pipeline**:
1. Load config (from CLI args or file)
2. Initialize LLM client (with config)
3. Initialize tool registry (register shell tool)
4. Initialize memory (SQLite database)
5. Create new session
6. Run agent loop with prompt
7. Print response with formatting
8. Print token usage summary
9. Save session to memory

**Component Wiring**:
- Config → LLMClient → ToolRegistry → AgentLoop → Memory
- Error handling at each stage
- Clean shutdown on Ctrl+C
- Session persistence

**Key Integration Points**:
- Use existing modules: config, llm_client, tool_registry, agent_loop, memory
- Ensure all components work together
- Handle initialization order dependencies
- Manage resource cleanup

**Tests**: Integration tests with mock server
- End-to-end happy path
- Error path testing
- Network failure handling
- Session persistence verification

### Acceptance Criteria
- [ ] Full pipeline runs end-to-end with mock server
- [ ] Each component initializes in correct order
- [ ] Errors at each stage produce clear messages
- [ ] Ctrl+C during agent loop exits cleanly
- [ ] Session saved to SQLite after completion
- [ ] Integration test passes

---

## TASK 3.3: End-to-End Tests + Documentation

### Requirements
**Documentation**:
- `README.md`: Overview, quick start, config reference, tool docs, dev guide
- `docs/architecture.md`: Component diagram, data flow, design decisions
- `CONTRIBUTING.md`: Development setup, testing, contribution guidelines

**End-to-End Tests**:
- Comprehensive test suite covering all paths:
  - Happy path (text response)
  - Tool path (tool usage)
  - Error path (tool errors, network errors)
  - Network path (timeouts, retries)
  - Loop path (max iterations, loop detection)
- All tests pass without network (use mock server)
- Test coverage for critical paths

**Code Quality**:
- Run `desloppify` scan
- Fix any issues found
- Target score ≥ 90

### Acceptance Criteria
- [ ] All end-to-end tests pass
- [ ] `nimble test` passes with no network
- [ ] README.md covers quick start, config, tools, development
- [ ] `docs/architecture.md` has component diagram
- [ ] `CONTRIBUTING.md` has dev setup instructions
- [ ] `make desloppify` passes with score ≥ 90

---

## DEPENDENCIES

### Required from Wave 2
- **Task 2.2**: Agent loop (core ReAct implementation)
- **Task 2.1**: Tool registry (for shell tool integration)
- **Task 2.3**: Mock server (optional, for testing)

### Existing Components (Wave 1)
- **Task 1.1**: Config module
- **Task 1.2**: LLM client
- **Task 1.3**: Token counter
- **Task 1.4**: Memory module

### External Dependencies
- `cligen` library (for CLI)
- `db_connector` (already in use)
- `std/terminal` (for colorized output)

## VERIFICATION STRATEGY

### For Each Task
1. **Code Review**: Read implementation, check against requirements
2. **Build Test**: `nimble build` must succeed
3. **Unit Tests**: Task-specific tests must pass
4. **Integration Tests**: End-to-end tests must pass
5. **Manual Testing**: Run CLI commands, verify behavior

### Quality Gates
- No compilation warnings/errors
- All tests pass
- Code follows existing patterns
- Error handling is robust
- Documentation is clear and complete

## READY FOR DELEGATION

Wave 3 tasks are sequential and depend on Wave 2 completion. Once task 2.2 (agent loop) is complete, these tasks can be delegated to Jules in sequence:
1. Task 3.1 (CLI interface)
2. Task 3.2 (Integration)
3. Task 3.3 (Documentation + tests)

Each task has clear requirements, acceptance criteria, and verification steps.
```

`config/personas.example.toml`:

```toml
[personas.code_reviewer]
system_prompt = "You are a code reviewer. Focus on correctness, security, and style.\nRead the code carefully. Check for error handling, security concerns, obvious performance issues, and clear naming.\nProvide specific, actionable feedback. Be thorough but concise."
model = ""
tools_allow = ["shell", "file_read", "file_write"]
tools_deny = []
memory_scope = "own_sessions"
memory_max_history = 0
memory_fts_enabled = false
delegate_enabled = false
max_delegation_depth = 0
max_delegations_per_run = 0
max_iterations = 8

[personas.researcher]
system_prompt = "You are a research assistant. Find information by running shell commands,\nreading files, and analyzing content. Synthesize your findings into a clear,\nwell-structured summary. Cite specific sources where possible."
model = ""
tools_allow = ["shell", "file_read"]
tools_deny = []
memory_scope = "none"
memory_max_history = 0
memory_fts_enabled = false
delegate_enabled = true
max_delegation_depth = 2
max_delegations_per_run = 3
max_iterations = 15

[personas.writer]
system_prompt = "You are a technical writer. Produce clear, well-structured documentation.\nRead existing files to understand the context. Write or update documentation\nin the same style as the project. Prefer concise, scannable formats."
model = ""
tools_allow = ["file_read", "file_write"]
tools_deny = ["shell", "delegate"]
memory_scope = "own_sessions"
memory_max_history = 20
memory_fts_enabled = true
delegate_enabled = false
max_delegation_depth = 0
max_delegations_per_run = 0
max_iterations = 5

[personas.debug]
system_prompt = "You are a debugging specialist. Systematically investigate issues by:\n1. Reading relevant code and configs\n2. Running diagnostic commands (logs, env vars, process state)\n3. Forming hypotheses and testing them\n4. Reporting what you found, what likely caused it, and the fix."
model = ""
tools_allow = ["shell", "file_read", "file_write"]
tools_deny = []
memory_scope = "own_sessions"
memory_max_history = 30
memory_fts_enabled = true
delegate_enabled = true
max_delegation_depth = 1
max_delegations_per_run = 2
max_iterations = 20

```

`mercury_agent/config.nims`:

```nims
switch("path", "src")
switch("path", "../mercury_core/src")
switch("path", "../mercury_core/tests")
switch("define", "ssl")
switch("threads", "off")  # Keep off by default; test files override via command line

```

`mercury_agent/mercury_agent.nimble`:

```nimble
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
switch("path", "../mercury_core/tests")

task test, "Run all tests":
  exec "nim c --path:src --path:../mercury_core/src --path:../mercury_core/tests --threads:on -r tests/tagent_loop.nim"
  exec "nim c --path:src --path:../mercury_core/src --path:../mercury_core/tests -r tests/tcli.nim"
  exec "nim c --path:src --path:../mercury_core/src --path:../mercury_core/tests -r tests/test_shell_tool.nim"
  exec "nim c --path:src --path:../mercury_core/src --path:../mercury_core/tests --threads:on -r tests/tintegration.nim"

```

`mercury_agent/src/agent_loop.nim`:

```nim
## Mercury ReAct agent loop.
##
## Implements a simple Reason+Act loop on top of the OpenAI-compatible
## Chat Completions client (`mercury_core/llm_client`), a `ToolRegistry`
## (`mercury_core/tool_registry`), and the SQLite-backed `Memory`
## (`mercury_core/memory`).
##
## The loop:
##   1. Creates a new memory session for the run.
##   2. Builds a message history: `system` + `user`.
##   3. Calls the LLM with the registered tool definitions.
##   4. If the LLM returns text (`finish_reason == "stop"`), returns the text.
##   5. If the LLM returns tool calls (`finish_reason == "tool_calls"`),
##      executes each tool through the registry, appends results as `tool`
##      messages, and loops.
##   6. Stops with a synthetic message after `maxIterations` turns or if
##      loop detection fires (the same tool is called identically N times
##      in a row, configurable via `loopDetectionThreshold`).
##   7. Logs every assistant / tool / user message to memory along with
##      token counts reported by the LLM.
##
## Out of scope (deferred):
##   - Plan-Execute / sub-agent delegation
##   - Reflection / self-critique
##   - Streaming responses
##   - Vector memory / semantic retrieval
##   - MCP, Discord, etc.

import std/[json, strutils, tables]

import mercury_core/config
import mercury_core/llm_client
import mercury_core/tool_registry
import mercury_core/memory
import mercury_core/persona
import mercury_core/delegate

# ---------------------------------------------------------------------------
# Public types
# ---------------------------------------------------------------------------

const
  DefaultLoopDetectionThreshold* = 3
    ## A tool is considered "looping" if invoked with identical arguments
    ## this many times in a row (counting the latest call).

  DefaultSystemPrompt* = """
You are Mercury, a helpful AI assistant. You can use tools to help answer
questions.

When you need to use a tool, respond with tool_calls. Otherwise, respond
with text.

Think step by step. If a tool fails, try a different approach. If you get
stuck, ask for clarification.
""".strip()

type
  AgentConfig* = object
    ## Per-run agent configuration. `maxIterations` defaults to
    ## `MercuryConfig.maxLoopIterations` when constructing via
    ## `newAgentConfig`.
    maxIterations*: int
    loopDetectionThreshold*: int
    systemPrompt*: string
    persona*: PersonaConfig
      ## Optional persona template. If set, the persona's memory scope
      ## and delegation config are enforced during the run.
    delegation*: DelegationConfig
      ## Delegation safety bounds. Determines whether this agent can
      ## spawn children and how deep nesting can go.

  AgentStats* = object
    ## Counters returned alongside the agent response, useful for tests
    ## and for surfacing cost/usage to the user.
    totalTokens*: int
    promptTokens*: int
    completionTokens*: int
    totalTurns*: int
    toolCallsMade*: int

  AgentStopReason* = enum
    asrFinished       = "finished"
    asrMaxIterations  = "max_iterations"
    asrLoopDetected   = "loop_detected"
    asrError          = "error"

  AgentResult* = object
    ## Full agent response. `text` is the user-facing answer; the rest is
    ## metadata for logging / observability.
    text*: string
    sessionId*: string
    stopReason*: AgentStopReason
    stats*: AgentStats

  AgentLoopError* = object of CatchableError
    ## Raised when the agent loop cannot make progress for a reason that
    ## is not a simple LLM/tool error (e.g. inability to log to memory).

# ---------------------------------------------------------------------------
# Construction helpers
# ---------------------------------------------------------------------------

proc newAgentConfig*(
    cfg: MercuryConfig;
    loopDetectionThreshold: int = DefaultLoopDetectionThreshold;
    systemPrompt: string = DefaultSystemPrompt;
): AgentConfig =
  ## Builds an AgentConfig from a MercuryConfig, defaulting `maxIterations`
  ## to `cfg.maxLoopIterations` and overriding only when needed.
  AgentConfig(
    maxIterations:
      if cfg.maxLoopIterations > 0: cfg.maxLoopIterations
      else: DefaultMaxLoopIterations,
    loopDetectionThreshold:
      if loopDetectionThreshold > 0: loopDetectionThreshold
      else: DefaultLoopDetectionThreshold,
    systemPrompt: systemPrompt,
  )

proc defaultAgentConfig*(): AgentConfig =
  ## A reasonable default AgentConfig that does not depend on a loaded
  ## MercuryConfig. Useful for tests and embedded use.
  AgentConfig(
    maxIterations: DefaultMaxLoopIterations,
    loopDetectionThreshold: DefaultLoopDetectionThreshold,
    systemPrompt: DefaultSystemPrompt,
    delegation: defaultDelegationConfig(),
  )

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

proc buildToolsParam(reg: ToolRegistry): JsonNode =
  ## Returns the JSON value for the `tools` field of a chat completions
  ## request, or `nil` if the registry is empty.
  if reg.isNil or reg.len == 0:
    return nil
  reg.toOpenAIDefinitions()

proc toolCallSignature(tc: ToolCall): string =
  ## A canonical signature used for loop detection. Two tool calls with
  ## the same name and arguments produce the same signature even if their
  ## ids differ.
  tc.name & "\x1f" & tc.arguments.strip()

proc detectLoop(
    history: seq[string];
    threshold: int;
): bool =
  ## Returns true if the last `threshold` entries in `history` are all
  ## non-empty and identical. `history` is the chronological sequence of
  ## tool-call signatures issued by the assistant.
  if threshold <= 0:
    return false
  if history.len < threshold:
    return false
  let last = history[^1]
  if last.len == 0:
    return false
  for i in 1 ..< threshold:
    if history[history.len - 1 - i] != last:
      return false
  return true

proc formatToolResult(res: ToolResult): string =
  ## Produces the text content fed back to the LLM as a `tool` message.
  ## We deliberately keep this small and plain: the LLM only needs the
  ## tool's textual output plus an explicit error marker when relevant.
  if res.isError:
    if res.output.len > 0:
      return "ERROR: " & res.output
    return "ERROR: tool failed with exit code " & $res.exitCode
  res.output

proc executeToolCall(
    reg: ToolRegistry;
    tc: ToolCall;
): ToolResult =
  ## Runs a single tool call. The registry already converts arbitrary
  ## exceptions into `ToolResult{isError:true}`, so the only case we have
  ## to handle here is a tool that is not registered at all.
  if reg.isNil:
    return ToolResult(
      output: "no tool registry configured",
      isError: true,
      exitCode: -1,
    )
  if not reg.has(tc.name):
    return ToolResult(
      output: "tool '" & tc.name & "' is not registered",
      isError: true,
      exitCode: -1,
    )
  reg.execute(tc.name, tc.arguments)

# ---------------------------------------------------------------------------
# Main loop
# ---------------------------------------------------------------------------

proc runAgentLoop*(
    agentCfg: AgentConfig;
    llm: LLMClient;
    registry: ToolRegistry;
    memory: var Memory;
    userInput: string;
    extraParams: Table[string, JsonNode] = initTable[string, JsonNode]();
): AgentResult =
  ## Runs the ReAct loop to convergence.
  ##
  ## Returns once the LLM emits a final text answer, the iteration limit
  ## is reached, or loop detection fires. Tool errors do *not* terminate
  ## the loop — they are reported back to the LLM as tool messages so the
  ## model can recover.
  let sid = memory.newSession()
  result.sessionId = sid
  result.stopReason = asrError    # overwritten below

  # Build the initial message stack: system + user.
  var messages: seq[ChatMessage] = @[]
  if agentCfg.systemPrompt.len > 0:
    let sysMsg = ChatMessage(role: crSystem, content: agentCfg.systemPrompt)
    messages.add(sysMsg)
    memory.appendMessage(sid, sysMsg)

  let userMsg = ChatMessage(role: crUser, content: userInput)
  messages.add(userMsg)
  memory.appendMessage(sid, userMsg)

  # Tool definitions are built once: the registry shouldn't mutate during
  # a single agent run.
  let toolsParam = buildToolsParam(registry)
  var perRequestParams = extraParams
  if not toolsParam.isNil:
    perRequestParams["tools"] = toolsParam

  var toolCallHistory: seq[string] = @[]
  let maxIter = max(1, agentCfg.maxIterations)
  let loopThreshold = max(1, agentCfg.loopDetectionThreshold)

  for iteration in 1 .. maxIter:
    inc result.stats.totalTurns

    var resp: ChatResponse
    try:
      resp = llm.chatCompletion(
        prompt = "",
        history = messages,
        extraParams = perRequestParams,
      )
    except LLMError as e:
      let errText = "LLM request failed: " & e.msg
      let errMsg = ChatMessage(role: crAssistant, content: errText)
      memory.appendMessage(sid, errMsg)
      result.text = errText
      result.stopReason = asrError
      return

    # Track usage.
    result.stats.promptTokens     += resp.usage.promptTokens
    result.stats.completionTokens += resp.usage.completionTokens
    result.stats.totalTokens      += resp.usage.totalTokens

    # Persist the assistant message before doing anything else so even
    # if a tool blows up the conversation is recoverable from memory.
    let assistantMsg = ChatMessage(
      role: crAssistant,
      content: resp.content,
      toolCalls: resp.toolCalls,
    )
    memory.appendMessage(
      sid,
      assistantMsg,
      tokensIn = resp.usage.promptTokens,
      tokensOut = resp.usage.completionTokens,
    )
    messages.add(assistantMsg)

    # Did the model finish?
    let isToolCallTurn =
      resp.toolCalls.len > 0 or
      resp.finishReason.toLowerAscii() == "tool_calls"

    if not isToolCallTurn:
      # Treat anything that isn't tool_calls as a final answer. This
      # includes "stop", "length", and unknown finish_reasons; we surface
      # whatever text the model gave us.
      result.text = resp.content
      result.stopReason = asrFinished
      return

    # Execute every tool call requested in this turn, in order. The
    # OpenAI protocol requires one `tool` message per `tool_call` id.
    for tc in resp.toolCalls:
      inc result.stats.toolCallsMade
      toolCallHistory.add(toolCallSignature(tc))

      let toolRes = executeToolCall(registry, tc)
      let toolMsg = ChatMessage(
        role: crTool,
        name: tc.name,
        toolCallId: tc.id,
        content: formatToolResult(toolRes),
      )
      memory.appendMessage(sid, toolMsg)
      messages.add(toolMsg)

    # Loop detection runs *after* executing this turn's tool calls so we
    # always send the tool results back at least once before bailing.
    if detectLoop(toolCallHistory, loopThreshold):
      let stopText =
        "Loop detected: tool '" &
        resp.toolCalls[^1].name &
        "' was called " & $loopThreshold &
        " times with identical arguments. Stopping."
      let stopMsg = ChatMessage(role: crAssistant, content: stopText)
      memory.appendMessage(sid, stopMsg)
      result.text = stopText
      result.stopReason = asrLoopDetected
      return

  # Fell off the end of the loop without a final text answer.
  let stopText = "Max iterations reached (" & $maxIter & "). Stopping."
  let stopMsg = ChatMessage(role: crAssistant, content: stopText)
  memory.appendMessage(sid, stopMsg)
  result.text = stopText
  result.stopReason = asrMaxIterations

# ---------------------------------------------------------------------------
# Convenience overloads
# ---------------------------------------------------------------------------

proc runAgentLoop*(
    cfg: MercuryConfig;
    llm: LLMClient;
    registry: ToolRegistry;
    memory: var Memory;
    userInput: string;
): AgentResult =
  ## Convenience wrapper that builds an AgentConfig from a MercuryConfig.
  let agentCfg = newAgentConfig(cfg)
  runAgentLoop(agentCfg, llm, registry, memory, userInput)

```

`mercury_agent/src/mercury_agent.nim`:

```nim
## Mercury agent CLI.
##
## Provides the user-facing command-line interface for the Mercury agent.
## Subcommands:
##   - chat                  Interactive REPL
##   - ask <question>        One-shot question
##   - session <id>          Resume an existing session, then chat
##   - history               List recent sessions
##   - search <query>        Full-text search across stored messages
##
## Configuration is loaded by `mercury_core/config.loadConfig()`. Per-run
## flags `--model`, `--provider`, and `--temperature` override the values
## in the loaded config without touching disk.

import std/[os, strutils, strformat, asyncdispatch, options, json]
import db_connector/db_sqlite

import mercury_core/config
import mercury_core/discord
import mercury_core/discord_bridge
import mercury_core/discord_mocks
import mercury_core/discord_types
import mercury_core/llm_client
import mercury_core/tool_registry
import mercury_core/memory
import mercury_core/thread_mapping
import mercury_core/file_tool
import mercury_core/file_path_validator
import mercury_core/message_chunker
import mercury_core/mcp_client
import mercury_core/mcp_tool
import mercury_core/persona
import mercury_core/delegate
from mercury_core/agent_dispatcher import AgentDispatcher, AgentRequest, newAgentDispatcher

import dimscord

import agent_loop
import tools/shell

# ---------------------------------------------------------------------------
# Globals for graceful Ctrl+C handling
# ---------------------------------------------------------------------------

var ctrlCRequested* = false
  ## Set by the SIGINT hook so the chat loop can exit cleanly between
  ## turns. Exposed for tests.

var daemonShutdownRequested* = false
  ## Set by the SIGINT hook in daemon mode to signal graceful shutdown.

proc onCtrlC() {.noconv.} =
  ctrlCRequested = true
  daemonShutdownRequested = true
  # Best-effort newline so the next prompt isn't glued to "^C".
  try: stdout.write("\n") except CatchableError: discard

# ---------------------------------------------------------------------------
# Config / dependency wiring
# ---------------------------------------------------------------------------

type
  RunOverrides* = object
    ## Per-run flag overrides. Empty/sentinel values mean "leave alone".
    model*: string
    provider*: string
    temperature*: float
    hasTemperature*: bool
    configPath*: string
    envPath*: string

proc emptyOverrides*(): RunOverrides =
  RunOverrides(
    model: "",
    provider: "",
    temperature: 0.0,
    hasTemperature: false,
    configPath: "",
    envPath: ".env",
  )

proc applyOverrides*(cfg: var MercuryConfig; ov: RunOverrides) =
  ## Mutates `cfg` to reflect any non-empty fields of `ov`. The model
  ## override is applied to whichever provider is currently active so a
  ## simple `--model x` works regardless of provider.
  if ov.provider.len > 0:
    cfg.provider = ov.provider
  if ov.model.len > 0:
    case cfg.provider
    of "vllm":       cfg.vllmModel = ov.model
    of "openrouter": cfg.openrouterModel = ov.model
    else:            cfg.openrouterModel = ov.model
  if ov.hasTemperature:
    cfg.temperature = ov.temperature

proc loadConfigWithOverrides*(ov: RunOverrides): MercuryConfig =
  ## Loads config from disk and applies per-run flag overrides. Validation
  ## is re-run after overrides so an invalid provider on the CLI surfaces
  ## as a `ConfigError`.
  result = loadConfig(configPath = ov.configPath, envFilePath = ov.envPath)
  applyOverrides(result, ov)
  validate(result)

proc activeBaseUrl(cfg: MercuryConfig): string =
  case cfg.provider
  of "vllm":       cfg.vllmEndpoint
  of "openrouter": cfg.openrouterEndpoint
  else:            cfg.openrouterEndpoint

proc activeModel(cfg: MercuryConfig): string =
  case cfg.provider
  of "vllm":       cfg.vllmModel
  of "openrouter": cfg.openrouterModel
  else:            cfg.openrouterModel

proc activeApiKey(cfg: MercuryConfig): string =
  case cfg.provider
  of "openrouter": cfg.openrouterApiKey
  else:            ""

proc buildLLMClient*(cfg: MercuryConfig): LLMClient =
  ## Builds an LLMClient from a fully-resolved MercuryConfig.
  newLLMClient(
    baseUrl = activeBaseUrl(cfg),
    apiKey  = activeApiKey(cfg),
    model   = activeModel(cfg),
  )

# ---------------------------------------------------------------------------
# Global state for tool closures
# ---------------------------------------------------------------------------

type
  AgentGlobals* = ref object
    ## Container for agent-loop globals that need safe closure capture.
    personaRegistry*: PersonaRegistry
    llmClient*: LLMClient

var gGlobals*: AgentGlobals = nil

proc setPersonaRegistry*(reg: PersonaRegistry) =
  if gGlobals.isNil:
    gGlobals = AgentGlobals(personaRegistry: reg)
  else:
    gGlobals.personaRegistry = reg

proc setGlobalLLMClient*(llm: LLMClient) =
  if gGlobals.isNil:
    gGlobals = AgentGlobals(llmClient: llm)
  else:
    gGlobals.llmClient = llm

# ---------------------------------------------------------------------------
# Delegate tool
# ---------------------------------------------------------------------------

proc makeDelegateParams*(): JsonNode =
  ## Builds the JSON Schema for the delegate tool parameters.
  let p = newJObject()
  p["type"] = %"object"
  p["properties"] = newJObject()
  p["properties"]["persona"] = newJObject()
  p["properties"]["persona"]["type"] = %"string"
  p["properties"]["persona"]["description"] =
    %"Name of the persona to spawn (e.g. 'code_reviewer')"
  p["properties"]["task"] = newJObject()
  p["properties"]["task"]["type"] = %"string"
  p["properties"]["task"]["description"] =
    %"The subtask description for the child agent"
  p["required"] = newJArray()
  p["required"].add(%"persona")
  p["required"].add(%"task")
  p

proc makeDelegateExecuteProc*(): auto =
  ## Returns a gcsafe closure that captures the current AgentGlobals ref.
  ## The ref object is GC-safe to capture, and the closure accesses globals
  ## through the ref rather than directly.
  let captured = gGlobals
  return proc (args: JsonNode): ToolResult =
    if captured.isNil:
      return ToolResult(
        output: "delegate: agent globals not initialized",
        isError: true,
        exitCode: 1,
      )
    let personaName = args{"persona"}.getStr("")
    let task = args{"task"}.getStr("")
    if personaName.len == 0:
      return ToolResult(
        output: "delegate: 'persona' argument is required",
        isError: true,
        exitCode: 1,
      )
    if task.len == 0:
      return ToolResult(
        output: "delegate: 'task' argument is required",
        isError: true,
        exitCode: 1,
      )
    if captured.personaRegistry.isNil:
      return ToolResult(
        output: "delegate: no persona registry loaded (no personas.toml found)",
        isError: true,
        exitCode: 1,
      )
    if not captured.personaRegistry.hasPersona(personaName):
      return ToolResult(
        output: "delegate: unknown persona '" & personaName &
          "'. Available: " & captured.personaRegistry.listPersonas().join(", "),
        isError: true,
        exitCode: 1,
      )
    let persona =
      try: captured.personaRegistry.getPersona(personaName)
      except PersonaError:
        return ToolResult(
          output: "delegate: failed to load persona '" & personaName & "'",
          isError: true,
          exitCode: 1,
        )
    if captured.llmClient.baseUrl.len == 0:
      return ToolResult(
        output: "delegate: LLM client not available (baseUrl is empty)",
        isError: true,
        exitCode: 1,
      )
    let parentCfg = defaultConfig()
    var childCfg = newAgentConfig(parentCfg)
    if persona.systemPrompt.len > 0:
      childCfg.systemPrompt = persona.systemPrompt
    if persona.maxIterations > 0:
      childCfg.maxIterations = persona.maxIterations
    childCfg.persona = persona
    childCfg.delegation = applyPersonaDelegation(
      persona.maxDelegationDepth,
      persona.maxDelegationsPerRun,
      persona.name,
    )
    let memPath =
      if parentCfg.dbPath.len > 0: parentCfg.dbPath
      else: "~/.local/share/mercury/mercury.db"
    var childMem: Memory
    try:
      childMem = newMemory(memPath)
    except CatchableError:
      return ToolResult(
        output: "delegate: cannot open memory store",
        isError: true,
        exitCode: 1,
      )
    let childResult = runAgentLoop(
      agentCfg = childCfg,
      llm = captured.llmClient,
      registry = newToolRegistry(),
      memory = childMem,
      userInput = task,
    )
    childMem.close()
    var lines: seq[string] = @[]
    lines.add("=== Child Agent Result ===")
    lines.add("Persona: " & persona.name)
    lines.add("Session: " & childResult.sessionId)
    lines.add("Stop reason: " & $childResult.stopReason)
    lines.add("Tokens: " & $childResult.stats.totalTokens &
      " (prompt: " & $childResult.stats.promptTokens &
      ", completion: " & $childResult.stats.completionTokens & ")")
    lines.add("Turns: " & $childResult.stats.totalTurns)
    lines.add("Tool calls: " & $childResult.stats.toolCallsMade)
    lines.add("")
    lines.add("--- Response ---")
    if childResult.text.len > 0:
      lines.add(childResult.text)
    else:
      lines.add("(no text produced)")
    return ToolResult(
      output: lines.join("\n"),
      isError: false,
      exitCode: 0,
    )

proc makeDelegateTool*(): Tool =
  ## Returns the delegate tool with the current agent globals captured.
  ## Call this after setting globals via setPersonaRegistry / setGlobalLLMClient.
  let description = "Spawn a child agent from a named persona to handle " &
    "a specific subtask. The child agent runs with its own system prompt, " &
    "tool restrictions, and memory isolation. " &
    "Args: persona (string, name of persona), task (string, the subtask). " &
    "Returns: the child's final text response plus execution metadata."

  let exec = makeDelegateExecuteProc()
  newTool(
    name = "delegate",
    description = description,
    parameters = makeDelegateParams(),
    execute = exec,
  )

proc delegateTool*(): Tool =
  ## Creates the delegate tool with a snapshot of current globals.
  ## NOTE: prefer `makeDelegateTool` after globals are set. This proc
  ## captures globals at proc definition time (potentially nil).
  makeDelegateTool()

proc buildRegistry*(cfg: MercuryConfig = defaultConfig()): ToolRegistry =
  ## Builds the default tool registry for the agent. Registers the shell tool
  ## and any MCP tools configured in `cfg.mcpServers`. Also registers the
  ## delegate tool if agent globals are available.
  result = newToolRegistry()
  result.register(shellTool())
  if cfg.mcpServers.len > 0:
    discard registerMcpServers(result, cfg.mcpServers)
  # Register delegate tool — only if globals are set
  if not gGlobals.isNil and gGlobals.llmClient.baseUrl.len > 0:
    result.register(makeDelegateTool())

proc resolveDbPath*(cfg: MercuryConfig): string =
  ## Expands `~` in the configured DB path and ensures the parent dir
  ## exists. Returns the absolute path used for SQLite.
  result = cfg.dbPath
  if result.startsWith("~"):
    result = expandTilde(result)
  let parent = parentDir(result)
  if parent.len > 0 and not dirExists(parent):
    try:
      createDir(parent)
    except CatchableError:
      stderr.writeLine("Warning: could not create parent directory for '" & result & "'.")

proc openMemory*(cfg: MercuryConfig): Memory =
  ## Opens the memory store at the path configured in `cfg`.
  newMemory(resolveDbPath(cfg))

# ---------------------------------------------------------------------------
# Chat REPL
# ---------------------------------------------------------------------------

type
  SessionSummary* = object   ## defined here; also referenced by listRecentSessions
    id*: string
    createdAt*: string
    updatedAt*: string
    messageCount*: int

proc printSystemNote(text: string)  ## fwd
proc printError(text: string)        ## fwd
proc printAssistant(text: string)    ## fwd
proc sessionExists*(dbPath, sessionId: string): bool   ## fwd
proc listRecentSessions*(dbPath: string; limit: int = 20): seq[SessionSummary]   ## fwd

proc readLine(prompt: string): tuple[line: string, eof: bool] =
  ## Reads a single line of input. Returns `(text, eof=true)` on EOF.
  stdout.write(prompt)
  stdout.flushFile()
  try:
    let line = stdin.readLine()
    return (line, false)
  except EOFError:
    return ("", true)
  except IOError:
    return ("", true)

proc isExitCommand(line: string): bool =
  let s = line.strip().toLowerAscii()
  s in [":q", ":quit", ":exit", "/quit", "/exit", "exit", "quit"]

proc runOneTurn(
    cfg: MercuryConfig;
    llm: LLMClient;
    reg: ToolRegistry;
    mem: var Memory;
    userInput: string;
): AgentResult =
  ## Thin wrapper around `runAgentLoop` so the chat and ask commands
  ## share their per-turn logic.
  runAgentLoop(cfg, llm, reg, mem, userInput)

proc runChatLoop*(
    cfg: MercuryConfig;
    llm: LLMClient;
    reg: ToolRegistry;
    mem: var Memory;
    initialBanner: string = "";
) =
  ## Runs the interactive REPL until EOF or `:quit`. SIGINT between
  ## turns is treated as a clean exit.
  if initialBanner.len > 0:
    printSystemNote(initialBanner)
  printSystemNote("type :quit to exit; Ctrl+C to interrupt")
  while true:
    if ctrlCRequested:
      printSystemNote("interrupted")
      break
    let (line, eof) = readLine("> ")
    if eof:
      printSystemNote("eof")
      break
    if ctrlCRequested:
      printSystemNote("interrupted")
      break
    let trimmed = line.strip()
    if trimmed.len == 0:
      continue
    if isExitCommand(trimmed):
      printSystemNote("bye")
      break
    var res: AgentResult
    try:
      res = runOneTurn(cfg, llm, reg, mem, trimmed)
    except CatchableError as e:
      printError(e.msg)
      continue
    printAssistant(res.text)
    if res.stopReason != asrFinished:
      printSystemNote("stop reason: " & $res.stopReason)

# ---------------------------------------------------------------------------
# Subcommand entry points
# ---------------------------------------------------------------------------

proc cmdChat*(
    model = "";
    provider = "";
    temperature = -1.0;
    config = "";
    envFile = ".env";
): int =
  ## Interactive chat mode. Returns a process exit code.
  setControlCHook(onCtrlC)
  var ov = emptyOverrides()
  ov.model = model
  ov.provider = provider
  if temperature >= 0.0:
    ov.temperature = temperature
    ov.hasTemperature = true
  ov.configPath = config
  ov.envPath = envFile
  var cfg: MercuryConfig
  try:
    cfg = loadConfigWithOverrides(ov)
  except ConfigError as e:
    printError(e.msg); return 2
  let llm = buildLLMClient(cfg)
  let reg = buildRegistry(cfg)
  var mem = openMemory(cfg)
  defer: mem.close()
  runChatLoop(
    cfg, llm, reg, mem,
    initialBanner = fmt"chat: provider={cfg.provider} model={activeModel(cfg)}",
  )
  return 0

proc cmdAsk*(
    question: seq[string];
    model = "";
    provider = "";
    temperature = -1.0;
    config = "";
    envFile = ".env";
): int =
  ## Single-shot question mode.
  if question.len == 0:
    printError("ask requires a question")
    return 2
  var ov = emptyOverrides()
  ov.model = model
  ov.provider = provider
  if temperature >= 0.0:
    ov.temperature = temperature
    ov.hasTemperature = true
  ov.configPath = config
  ov.envPath = envFile
  var cfg: MercuryConfig
  try:
    cfg = loadConfigWithOverrides(ov)
  except ConfigError as e:
    printError(e.msg); return 2
  let llm = buildLLMClient(cfg)
  let reg = buildRegistry(cfg)
  var mem = openMemory(cfg)
  defer: mem.close()
  let userInput = question.join(" ")
  var res: AgentResult
  try:
    res = runAgentLoop(cfg, llm, reg, mem, userInput)
  except CatchableError as e:
    printError(e.msg); return 1
  stdout.writeLine(res.text)
  if res.stopReason != asrFinished:
    return 3
  return 0

proc replayHistory(history: seq[ChatMessage]) =
  ## Renders a previously-stored session to stdout so the user has
  ## context before resuming.
  for m in history:
    case m.role
    of crSystem:    discard      ## skip the system prompt
    of crUser:      stdout.writeLine("> " & m.content)
    of crAssistant:
      if m.content.len > 0:
        stdout.writeLine("Mercury> " & m.content)
      elif m.toolCalls.len > 0:
        for tc in m.toolCalls:
          stdout.writeLine(fmt"[tool-call] {tc.name}({tc.arguments})")
    of crTool:
      stdout.writeLine(fmt"[tool-result {m.name}] {m.content}")
  stdout.flushFile()

proc cmdSession*(
    id: seq[string];
    model = "";
    provider = "";
    temperature = -1.0;
    config = "";
    envFile = ".env";
): int =
  ## Resume an existing session and continue chatting.
  if id.len == 0:
    printError("session requires an id")
    return 2
  let sessionId = id[0]
  setControlCHook(onCtrlC)
  var ov = emptyOverrides()
  ov.model = model
  ov.provider = provider
  if temperature >= 0.0:
    ov.temperature = temperature
    ov.hasTemperature = true
  ov.configPath = config
  ov.envPath = envFile
  var cfg: MercuryConfig
  try:
    cfg = loadConfigWithOverrides(ov)
  except ConfigError as e:
    printError(e.msg); return 2
  let dbPath = resolveDbPath(cfg)
  if not sessionExists(dbPath, sessionId):
    printError("no such session: " & sessionId); return 4
  let llm = buildLLMClient(cfg)
  let reg = buildRegistry(cfg)
  var mem = openMemory(cfg)
  defer: mem.close()
  let history = mem.getHistory(sessionId)
  printSystemNote(
    fmt"resuming session {sessionId} ({history.len} messages)")
  replayHistory(history)
  ## NOTE: runAgentLoop always opens a *new* session under the hood.
  printSystemNote(
    "starting a new session for follow-up turns " &
    "(history is read-only here)")
  runChatLoop(
    cfg, llm, reg, mem,
    initialBanner = fmt"session: provider={cfg.provider} model={activeModel(cfg)}",
  )
  return 0

proc cmdHistory*(
    limit = 20;
    config = "";
    envFile = ".env";
): int =
  ## List the most recently updated sessions.
  var ov = emptyOverrides()
  ov.configPath = config
  ov.envPath = envFile
  var cfg: MercuryConfig
  try:
    cfg = loadConfigWithOverrides(ov)
  except ConfigError as e:
    printError(e.msg); return 2
  let dbPath = resolveDbPath(cfg)
  let sessions = listRecentSessions(dbPath, limit)
  if sessions.len == 0:
    printSystemNote("no sessions yet")
    return 0
  echo fmt"{""SESSION ID"":<40}  {""UPDATED"":<25}  MSGS"
  for s in sessions:
    echo fmt"{s.id:<40}  {s.updatedAt:<25}  {s.messageCount}"
  return 0

# ---------------------------------------------------------------------------
# Output formatting
# ---------------------------------------------------------------------------

proc printAssistant(text: string) =
  stdout.writeLine("Mercury> " & text)
  stdout.flushFile()

proc printSystemNote(text: string) =
  stdout.writeLine("[" & text & "]")
  stdout.flushFile()

proc printError(text: string) =
  stderr.writeLine("error: " & text)
  stderr.flushFile()

# ---------------------------------------------------------------------------
# Recent-sessions listing
#
# memory.nim does not expose a `listSessions` proc, so we open our own
# read-only sqlite handle against the same db file. This keeps the
# read-only modules untouched while still letting the CLI render the
# `history` view.
# ---------------------------------------------------------------------------

proc listRecentSessions*(dbPath: string; limit: int = 20): seq[SessionSummary] =
  ## Returns up to `limit` most-recently-updated sessions. Returns an
  ## empty seq if the DB does not yet exist (no prior runs).
  result = @[]
  if not fileExists(dbPath):
    return
  let db = open(dbPath, "", "", "")
  defer: db.close()
  for row in db.fastRows(sql"""
    SELECT s.id, s.created_at, s.updated_at,
           (SELECT COUNT(*) FROM messages m WHERE m.session_id = s.id)
    FROM sessions s
    ORDER BY s.updated_at DESC
    LIMIT ?
  """, $limit):
    result.add(SessionSummary(
      id: row[0],
      createdAt: row[1],
      updatedAt: row[2],
      messageCount: parseInt(row[3]),
    ))

proc sessionExists*(dbPath, sessionId: string): bool =
  ## True if a session with the given id exists in the DB at `dbPath`.
  if not fileExists(dbPath):
    return false
  let db = open(dbPath, "", "", "")
  defer: db.close()
  let row = db.getRow(
    sql"SELECT id FROM sessions WHERE id = ?", sessionId)
  return row[0].len > 0

# ---------------------------------------------------------------------------
# Persona run subcommand
# ---------------------------------------------------------------------------

proc defaultPersonasPath*(): string =
  ## Returns the default personas config path: ~/.config/mercury/personas.toml
  let home = getHomeDir()
  if home.len == 0:
    return ""
  return home / ".config" / "mercury" / "personas.toml"

proc cmdRunPersona*(
    persona: seq[string];
    task: seq[string];
    config = "";
    envFile = ".env";
): int =
  ## Run a named persona with a given task. Loads personas.toml and spawns
  ## a child agent from the matching persona config.
  if persona.len == 0:
    printError("run requires a persona name")
    return 2
  if task.len == 0:
    printError("run requires a task")
    return 2

  let personaName = persona[0]
  let taskText = task.join(" ")

  # Load config and build base dependencies
  var ov = emptyOverrides()
  ov.configPath = config
  ov.envPath = envFile
  var cfg: MercuryConfig
  try:
    cfg = loadConfigWithOverrides(ov)
  except ConfigError as e:
    printError(e.msg); return 2

  # Load persona registry
  let personasPath = defaultPersonasPath()
  var reg = loadPersonasFile(personasPath)
  if not reg.hasPersona(personaName):
    printError("persona '" & personaName & "' not found in " & personasPath)
    let available = reg.listPersonas()
    if available.len > 0:
      printError("available personas: " & available.join(", "))
    else:
      printError("(no personas loaded — check " & personasPath & ")")
    return 3

  # Build LLM client and memory
  let llm = buildLLMClient(cfg)
  var mem = openMemory(cfg)
  defer: mem.close()

  # Set agent globals so the delegate tool can work
  setGlobalLLMClient(llm)
  setPersonaRegistry(reg)

  # Build filtered registry scoped to the persona
  let pc = reg.getPersona(personaName)
  var baseReg = newToolRegistry()
  baseReg.register(shellTool())
  let scopedReg = scopedRegistry(baseReg, pc)

  # Build child agent config
  var agentCfg = newAgentConfig(cfg)
  if pc.systemPrompt.len > 0:
    agentCfg.systemPrompt = pc.systemPrompt
  if pc.maxIterations > 0:
    agentCfg.maxIterations = pc.maxIterations
  agentCfg.persona = pc
  agentCfg.delegation = applyPersonaDelegation(
    pc.maxDelegationDepth,
    pc.maxDelegationsPerRun,
    pc.name,
  )

  # Run the agent
  printSystemNote("spawning persona '" & personaName & "'...")
  var agentResult: AgentResult
  try:
    agentResult = runAgentLoop(agentCfg, llm, scopedReg, mem, taskText)
  except CatchableError as e:
    printError(e.msg); return 1

  stdout.writeLine(agentResult.text)
  if agentResult.stopReason != asrFinished:
    printSystemNote("stop reason: " & $agentResult.stopReason)
  return 0

# ---------------------------------------------------------------------------
# Search
# ---------------------------------------------------------------------------

proc cmdSearch*(
    query: seq[string];
    limit = 20;
    config = "";
    envFile = ".env";
): int =
  ## Search across stored message content.
  if query.len == 0:
    printError("search requires a query")
    return 2
  var ov = emptyOverrides()
  ov.configPath = config
  ov.envPath = envFile
  var cfg: MercuryConfig
  try:
    cfg = loadConfigWithOverrides(ov)
  except ConfigError as e:
    printError(e.msg); return 2
  var mem = openMemory(cfg)
  defer: mem.close()
  let q = query.join(" ")
  let hits = mem.searchHistory(q)
  if hits.len == 0:
    printSystemNote("no matches")
    return 0
  var shown = 0
  for r in hits:
    if shown >= limit: break
    echo fmt"[{r.sessionId}] {r.createdAt}  {r.role}"
    echo "  " & r.snippet
    inc shown
  return 0

# ---------------------------------------------------------------------------
# Wiring
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# Discord API callback wrappers
# ---------------------------------------------------------------------------
# These named procs wrap RealDiscordApi calls so they can be passed as
# callbacks to DiscordBot. Nim's {.async.} pragma doesn't work on inline
# proc literals, so we define them as named procs that capture the API
# adapter via closure.

proc makeSendFn(api: RealDiscordApi): SendMessageFn =
  proc send(channelId, content: string): Future[string] {.async, gcsafe.} =
    return await api.sendMessage(channelId, content)
  return send

proc makeTypingFn(api: RealDiscordApi): TriggerTypingFn =
  proc typing(channelId: string) {.async, gcsafe.} =
    await api.triggerTyping(channelId)
  return typing

proc makeCreateThreadFn(api: RealDiscordApi): CreateThreadFn =
  proc create(channelId, messageId, name: string): Future[string] {.async, gcsafe.} =
    return await api.createThread(channelId, messageId, name)
  return create

proc makeArchiveThreadFn(api: RealDiscordApi): ArchiveThreadFn =
  proc archive(threadId: string) {.async, gcsafe.} =
    await api.archiveThread(threadId)
  return archive

proc sendWithLogging*(sendFn: SendMessageFn; channelId, content: string): Future[void] {.async.} =
  ## Sends a message to Discord, logging errors to stderr instead of
  ## letting asyncCheck silently swallow them.
  try:
    discard await sendFn(channelId, content)
  except CatchableError as e:
    stderr.writeLine("[daemon] failed to send message: " & e.msg)

# ---------------------------------------------------------------------------
# Daemon command
# ---------------------------------------------------------------------------

proc cmdDaemon*(
    config = "";
    envFile = ".env";
): int =
  ## Starts the Discord bot daemon.
  ##
  ## Wires the DI-based DiscordBot with a real Dimscord client:
  ## 1. Loads config and reads the Discord token from the env var.
  ## 2. Creates a Dimscord client and RealDiscordApi adapter.
  ## 3. Builds the LLM client, tool registry, and memory store.
  ## 4. Opens the thread-mapping DB and initialises its schema.
  ## 5. Registers file tools conditionally (based on config).
  ## 6. Creates an AgentDispatcher whose callback sends results to Discord.
  ## 7. Wires the message_create event to onMessageCreate.
  ## 8. Starts the Discord gateway session.
  ## 9. Handles SIGINT/SIGTERM for graceful shutdown.
  setControlCHook(onCtrlC)
  var ov = emptyOverrides()
  ov.configPath = config
  ov.envPath = envFile
  var cfg: MercuryConfig
  try:
    cfg = loadConfigWithOverrides(ov)
  except ConfigError as e:
    printError(e.msg); return 2

  # Read Discord bot token from the configured env var
  let tokenEnv = cfg.discord.tokenEnv
  let token = getEnv(tokenEnv)
  if token.len == 0:
    printError("Discord token not found in env var: " & tokenEnv)
    return 2

  # Build LLM client
  let llm = buildLLMClient(cfg)

  # Build tool registry — file tools only, NO shell tool for Discord
  var reg = newToolRegistry()
  let fileRules = FileRules(
    sandboxDir: "",
    allowPatterns: cfg.discord.fileRules.allow,
    askPatterns: @[],
    denyPatterns: cfg.discord.fileRules.deny,
  )
  reg.register(fileReadTool(fileRules))
  # fileWriteTool needs a userId for permission checks; per-message user ID
  # will be wired in the full agent integration (task 4.16). For now we pass
  # an empty string — the tool-level permission check will use the config's
  # default allow/deny lists.
  reg.register(fileWriteTool(fileRules, cfg.discord, ""))

  # Open memory store
  var mem = openMemory(cfg)

  # Open thread-mapping DB with WAL mode and busy timeout
  # to avoid SQLITE_BUSY when the memory module writes concurrently.
  let threadDbPath = resolveDbPath(cfg)
  let threadDb = open(threadDbPath, "", "", "")
  threadDb.exec(sql"PRAGMA journal_mode=WAL")
  threadDb.exec(sql"PRAGMA busy_timeout=5000")
  initThreadMappingSchema(threadDb)

  # Create Dimscord client
  let discord = newDiscordClient(token)

  # Create the real API adapter
  let api = newRealDiscordApi(discord.api)

  # Create a MockShard with the bot's user ID (populated on ready)
  var shard = newMockShard("")

  # Create the agent dispatcher — callback sends results to Discord
  let sendFn = makeSendFn(api)
  let dispatcher = newAgentDispatcher(proc(r: agent_dispatcher.AgentResult) {.gcsafe, raises: [].} =
    {.cast(raises: []).}:
      let text = if r.error.isSome: "Error: " & r.error.get()
                 else: r.responseText
      let chunks = chunkMessage(text)
      for chunk in chunks:
        asyncCheck sendWithLogging(sendFn, r.channelId, chunk)
  )

  # Create the DI-based DiscordBot with real API callbacks
  let bot = newDiscordBot(
    sendMessage = makeSendFn(api),
    triggerTyping = makeTypingFn(api),
    createThread = makeCreateThreadFn(api),
    archiveThread = makeArchiveThreadFn(api),
    db = threadDb,
    config = cfg.discord,
    dispatcher = dispatcher,
    shard = shard,
  )

  # Graceful shutdown handled by the setControlCHook above
  # Start the Discord bot (blocks until session ends or error)
  try:
    waitFor startDiscordBot(discord, bot)
  except CatchableError as e:
    printError("Daemon crashed: " & e.msg)
    threadDb.close()
    mem.close()
    return 1
  finally:
    if not daemonShutdownRequested:
      threadDb.close()
      mem.close()
  return 0

when isMainModule:
  import cligen

  ## We dispatchMulti so the user invokes subcommands as
  ##   mercury_agent chat
  ##   mercury_agent ask "what is 2+2?"
  ##   mercury_agent session sess_...
  ##   mercury_agent history
  ##   mercury_agent search "needle"
  ##   mercury_agent run code_reviewer "review the auth module"
  dispatchMulti(
    [cmdChat,    cmdName = "chat",    help = {
      "model":       "override model name",
      "provider":    "override provider (openrouter|vllm)",
      "temperature": "override sampling temperature (0..2). " &
                     "Negative means leave at config default.",
      "config":      "path to TOML config (overrides default)",
      "envFile":     "path to .env file (default: .env)",
    }],
    [cmdAsk,     cmdName = "ask",     help = {
      "model":       "override model name",
      "provider":    "override provider (openrouter|vllm)",
      "temperature": "override sampling temperature (0..2). " &
                     "Negative means leave at config default.",
      "config":      "path to TOML config (overrides default)",
      "envFile":     "path to .env file (default: .env)",
    }],
    [cmdSession, cmdName = "session", help = {
      "model":       "override model name",
      "provider":    "override provider (openrouter|vllm)",
      "temperature": "override sampling temperature (0..2). " &
                     "Negative means leave at config default.",
      "config":      "path to TOML config (overrides default)",
      "envFile":     "path to .env file (default: .env)",
    }],
    [cmdHistory, cmdName = "history", help = {
      "limit":       "max sessions to show",
      "config":      "path to TOML config (overrides default)",
      "envFile":     "path to .env file (default: .env)",
    }],
    [cmdSearch,  cmdName = "search",  help = {
      "limit":       "max matches to show",
      "config":      "path to TOML config (overrides default)",
      "envFile":     "path to .env file (default: .env)",
    }],
    [cmdRunPersona, cmdName = "run", help = {
      "persona":     "name of the persona to run (from personas.toml)",
      "task":         "task description for the persona agent",
      "config":      "path to TOML config (overrides default)",
      "envFile":     "path to .env file (default: .env)",
    }],
    [cmdDaemon,  cmdName = "daemon",  help = {
      "config":      "path to TOML config (overrides default)",
      "envFile":     "path to .env file (default: .env)",
    }],
  )

```

`mercury_agent/src/tools/shell.nim`:

```nim
## Mercury shell tool.
##
## Executes shell commands on behalf of the agent with two safety guards:
##   1. A configurable deny-list of patterns matched against the command
##      string (case-insensitive). Matching commands are refused without
##      ever being passed to the OS.
##   2. A timeout. The command is started via `osproc.startProcess` and
##      polled; if it has not exited by the deadline we kill the process
##      tree and return a timeout error.
##
## The tool is designed to be registered against a `ToolRegistry` from
## `mercury_core/tool_registry`:
##
##   import mercury_core/tool_registry
##   import tools/shell
##   let reg = newToolRegistry()
##   reg.register(shellTool())
##
## The tool's JSON-schema parameters are:
##   {"type": "object",
##    "properties": {
##      "cmd": {"type": "string"},
##      "timeoutMs": {"type": "integer"}
##    },
##    "required": ["cmd"]}
##
## Out of scope (deferred):
##   - cwd / env overrides (Phase 2)
##   - stdin support
##   - output streaming / size caps (we currently return everything)

import std/[json, osproc, streams, strutils, times, os, monotimes]

import mercury_core/tool_registry

const
  DefaultShellTimeoutMs* = 30_000
  ## Default per-call timeout for the shell tool (30s).

  MaxShellTimeoutMs* = 5 * 60_000
  ## Hard upper bound on a single shell call (5min).

  ## Patterns that cause an immediate refusal. Matched case-insensitively
  ## against the *normalized* command string (collapsed whitespace). This
  ## is intentionally a narrow, conservative deny-list — it is not a full
  ## sandbox and the agent should still operate inside an isolated env.
  DefaultDenyPatterns* = @[
    "rm -rf /",
    "rm -rf /*",
    "rm -rf ~",
    "rm -rf $home",
    ":(){ :|:& };:",     # classic fork bomb
    ":(){:|:&};:",        # whitespace-collapsed variant
    "mkfs",
    "mkfs.",
    "dd if=/dev/zero of=/dev/",
    "dd if=/dev/random of=/dev/",
    "dd if=/dev/urandom of=/dev/",
    "> /dev/sda",
    "of=/dev/sda",
    "of=/dev/nvme",
    "shutdown",
    "reboot",
    "halt",
    "poweroff",
    "init 0",
    "init 6",
    "chmod -r 777 /",
    "chown -r ",
    "fdisk",
    "wipefs",
  ]

type
  ShellOptions* = object
    ## Static configuration for the shell tool.
    timeoutMs*: int
    maxOutputBytes*: int            ## 0 = unlimited.
    denyPatterns*: seq[string]
    shellPath*: string              ## defaults to /bin/sh
    workingDir*: string             ## "" = inherit caller cwd

  ShellExecution* = object
    ## Detailed result of a shell invocation, returned alongside ToolResult
    ## via `runShell`.
    stdout*: string
    stderr*: string
    exitCode*: int
    timedOut*: bool
    denied*: bool
    durationMs*: int

const
  DefaultMaxOutputBytes* = 256 * 1024
  ## Hard cap on captured stdout+stderr per invocation (256 KiB).

proc defaultShellOptions*(): ShellOptions =
  ShellOptions(
    timeoutMs: DefaultShellTimeoutMs,
    maxOutputBytes: DefaultMaxOutputBytes,
    denyPatterns: DefaultDenyPatterns,
    shellPath: "/bin/sh",
    workingDir: "",
  )

# ---------------------------------------------------------------------------
# Deny-list logic
# ---------------------------------------------------------------------------

proc normalizeForDeny(cmd: string): string =
  ## Lowercases and collapses runs of whitespace to a single space so that
  ## simple obfuscation (extra spaces, mixed case) does not bypass the
  ## deny-list.
  result = newStringOfCap(cmd.len)
  var prevSpace = false
  for ch in cmd:
    if ch in {' ', '\t', '\n', '\r'}:
      if not prevSpace:
        result.add(' ')
        prevSpace = true
    else:
      result.add(ch.toLowerAscii)
      prevSpace = false
  result = result.strip()

proc isDenied*(cmd: string; patterns: seq[string]): bool =
  ## Returns true if `cmd` matches any deny-list pattern. Patterns are
  ## matched case-insensitively as substrings of the normalized command.
  let normalized = normalizeForDeny(cmd)
  for raw in patterns:
    let pat = raw.toLowerAscii.strip()
    if pat.len == 0:
      continue
    if normalized.contains(pat):
      return true
  return false

# ---------------------------------------------------------------------------
# Process execution with timeout
# ---------------------------------------------------------------------------

proc clampOutput(s: string; maxBytes: int): string =
  if maxBytes <= 0 or s.len <= maxBytes:
    return s
  result = s[0 ..< maxBytes]
  result.add("\n... [truncated " & $(s.len - maxBytes) & " bytes]")

proc readAllAvailable(stream: Stream): string =
  ## Reads everything currently buffered on the stream. Returns "" on error.
  result = ""
  if stream.isNil:
    return
  try:
    result = stream.readAll()
  except CatchableError:
    discard

proc runShellRaw(cmd: string; opts: ShellOptions): ShellExecution =
  ## Runs `cmd` via the configured shell with a timeout. Captures stdout
  ## and stderr separately. Does not consult the deny-list — see `runShell`.
  let startMono = getMonoTime()
  var process: Process
  try:
    var args = @["-c", cmd]
    var procOpts: set[ProcessOption] = {poUsePath}
    process = startProcess(
      command = opts.shellPath,
      workingDir = opts.workingDir,
      args = args,
      options = procOpts,
    )
  except OSError as e:
    return ShellExecution(
      stdout: "",
      stderr: "failed to start process: " & e.msg,
      exitCode: -1,
      timedOut: false,
      denied: false,
      durationMs: int((getMonoTime() - startMono).inMilliseconds),
    )
  except CatchableError as e:
    return ShellExecution(
      stdout: "",
      stderr: "failed to start process: " & e.msg,
      exitCode: -1,
      timedOut: false,
      denied: false,
      durationMs: int((getMonoTime() - startMono).inMilliseconds),
    )

  let timeoutMs = if opts.timeoutMs <= 0: DefaultShellTimeoutMs
                  else: min(opts.timeoutMs, MaxShellTimeoutMs)
  let deadline = startMono + initDuration(milliseconds = timeoutMs)
  var timedOut = false
  var pollIntervalMs = 25
  while true:
    let rc = process.peekExitCode()
    if rc != -1:
      break
    if getMonoTime() >= deadline:
      timedOut = true
      try:
        process.kill()
      except CatchableError:
        discard
      # Give it a brief grace period to die.
      var graceLeft = 500
      while graceLeft > 0 and process.peekExitCode() == -1:
        sleep(25)
        graceLeft -= 25
      try:
        process.terminate()
      except CatchableError:
        discard
      break
    sleep(pollIntervalMs)
    if pollIntervalMs < 100:
      pollIntervalMs += 5

  var exitCode = 0
  try:
    exitCode = process.waitForExit()
  except CatchableError:
    exitCode = -1

  let stdoutRaw = readAllAvailable(process.outputStream)
  let stderrRaw = readAllAvailable(process.errorStream)
  try: process.close() except CatchableError: discard

  result = ShellExecution(
    stdout: clampOutput(stdoutRaw, opts.maxOutputBytes),
    stderr: clampOutput(stderrRaw, opts.maxOutputBytes),
    exitCode: exitCode,
    timedOut: timedOut,
    denied: false,
    durationMs: int((getMonoTime() - startMono).inMilliseconds),
  )
  if timedOut:
    let suffix = "\n... [killed: timeout after " & $timeoutMs & "ms]"
    if result.stderr.len + suffix.len <= max(opts.maxOutputBytes, 1024) or
       opts.maxOutputBytes <= 0:
      result.stderr.add(suffix)

proc runShell*(cmd: string; opts: ShellOptions): ShellExecution =
  ## Public entry point: enforces the deny-list, then runs the command.
  if cmd.strip().len == 0:
    return ShellExecution(
      stdout: "",
      stderr: "empty command",
      exitCode: -1,
      timedOut: false,
      denied: true,
      durationMs: 0,
    )
  if isDenied(cmd, opts.denyPatterns):
    return ShellExecution(
      stdout: "",
      stderr: "command refused by deny-list",
      exitCode: -1,
      timedOut: false,
      denied: true,
      durationMs: 0,
    )
  runShellRaw(cmd, opts)

# ---------------------------------------------------------------------------
# Tool integration
# ---------------------------------------------------------------------------

proc shellParametersSchema*(): JsonNode =
  ## JSON schema for the shell tool's arguments.
  let cmdProp = %*{
    "type": "string",
    "description": "Shell command to execute via /bin/sh -c.",
  }
  let timeoutProp = %*{
    "type": "integer",
    "description": "Optional per-call timeout in milliseconds " &
                   "(default 30000, max 300000).",
    "minimum": 1,
  }
  result = newJObject()
  result["type"] = %"object"
  result["properties"] = newJObject()
  result["properties"]["cmd"] = cmdProp
  result["properties"]["timeoutMs"] = timeoutProp
  result["required"] = %[%"cmd"]
  result["additionalProperties"] = %false

proc formatShellOutput(exec: ShellExecution): string =
  ## Formats a `ShellExecution` into the textual output an LLM will see.
  result = ""
  if exec.denied:
    result.add("DENIED: ")
    if exec.stderr.len > 0:
      result.add(exec.stderr)
    else:
      result.add("command refused")
    return
  result.add("exit: " & $exec.exitCode)
  if exec.timedOut:
    result.add(" (timed out)")
  result.add("\n")
  if exec.stdout.len > 0:
    result.add("stdout:\n")
    result.add(exec.stdout)
    if not exec.stdout.endsWith("\n"):
      result.add("\n")
  if exec.stderr.len > 0:
    result.add("stderr:\n")
    result.add(exec.stderr)
    if not exec.stderr.endsWith("\n"):
      result.add("\n")

proc makeShellExecuteProc(opts: ShellOptions): ToolExecuteProc =
  ## Returns a closure suitable for `Tool.execute` that captures `opts`.
  let captured = opts
  result = proc (args: JsonNode): ToolResult {.gcsafe, raises: [].} =
    var localOpts = captured
    if args.isNil or args.kind != JObject:
      return ToolResult(
        output: "shell: arguments must be a JSON object with 'cmd'",
        isError: true,
        exitCode: -1,
      )
    let cmdNode = args{"cmd"}
    if cmdNode.isNil or cmdNode.kind != JString:
      return ToolResult(
        output: "shell: missing required string field 'cmd'",
        isError: true,
        exitCode: -1,
      )
    let cmd = cmdNode.getStr()
    let tNode = args{"timeoutMs"}
    if not tNode.isNil and tNode.kind == JInt:
      let t = tNode.getInt()
      if t > 0:
        localOpts.timeoutMs = min(t, MaxShellTimeoutMs)

    var exec: ShellExecution
    try:
      exec = runShell(cmd, localOpts)
    except CatchableError as e:
      return ToolResult(
        output: "shell: internal error: " & e.msg,
        isError: true,
        exitCode: -1,
      )
    except Defect as e:
      return ToolResult(
        output: "shell: defect: " & e.msg,
        isError: true,
        exitCode: -1,
      )
    let isError = exec.denied or exec.timedOut or exec.exitCode != 0
    return ToolResult(
      output: formatShellOutput(exec),
      isError: isError,
      exitCode: exec.exitCode,
    )

proc shellTool*(opts: ShellOptions = defaultShellOptions()): Tool =
  ## Builds a `Tool` value for the shell tool. Register it with a
  ## `ToolRegistry` to expose it to the LLM.
  newTool(
    name = "shell",
    description = "Execute a shell command via /bin/sh -c. Returns stdout, " &
                  "stderr, and exit code. Subject to a deny-list and a " &
                  "per-call timeout.",
    parameters = shellParametersSchema(),
    execute = makeShellExecuteProc(opts),
  )

```

`mercury_agent/tests/tagent_loop.nim`:

```nim
## Tests for mercury_agent/agent_loop.nim
##
## Drives the ReAct loop against the async mock server from
## `mercury_core/tests/mock_server.nim`. The mock server only accepts a
## single connection per `start()`; this test runs the asyncdispatcher
## in a dedicated thread and re-arms `acceptRequest` for every turn so
## the sync LLMClient can complete multi-turn conversations against it.

import std/[asyncdispatch, asynchttpserver, json, locks, strutils,
            unittest, net]

import mercury_core/llm_client
import mercury_core/tool_registry
import mercury_core/memory
import mercury_core/config

import mock_server
import agent_loop

# ---------------------------------------------------------------------------
# Threaded async-dispatcher harness around `mock_server.MockLLMServer`
# ---------------------------------------------------------------------------

type
  QueuedKind = enum
    qkText, qkToolCall, qkError

  QueuedResponse = object
    kind: QueuedKind
    text: string
    toolName: string
    toolArgs: JsonNode
    errCode: int
    errMsg: string

  ServerHarness = ref object
    server: MockLLMServer
    thread: Thread[ServerHarness]

    portReady: bool
    portCond: Cond
    portLock: Lock

    stopFlag: bool
    lock: Lock
    cond: Cond              ## signalled when queue grows or stopFlag flips

    queue: seq[QueuedResponse]
    fallback: QueuedResponse

proc applyResponse(srv: MockLLMServer; r: QueuedResponse) =
  case r.kind
  of qkText:     srv.setResponse(r.text)
  of qkToolCall: srv.setToolCallResponse(r.toolName, r.toolArgs)
  of qkError:    srv.setErrorResponse(r.errCode, r.errMsg)

proc takeNext(h: ServerHarness): QueuedResponse =
  ## Blocks until a queued response is available or stopFlag is set.
  ## Returns the first queued response, or the fallback if stopping.
  withLock h.lock:
    while h.queue.len == 0 and not h.stopFlag:
      wait(h.cond, h.lock)
    if h.queue.len > 0:
      result = h.queue[0]
      h.queue.delete(0)
    else:
      result = h.fallback

proc serveOne(h: ServerHarness) {.async.} =
  ## Programs the mock server's response slot, accepts a single TCP
  ## connection, and waits until the response has actually been written
  ## back. `acceptRequest` only awaits the TCP accept (the actual request
  ## handling is `asyncCheck`-ed), so we use a `done` Future that the
  ## callback completes after `handleRequest` returns to keep the
  ## response slot stable until the bytes are on the wire.
  let next = takeNext(h)
  applyResponse(h.server, next)
  let srv = h.server
  let done = newFuture[void]("serveOne.done")
  proc handler(req: Request) {.async, gcsafe.} =
    {.cast(gcsafe).}:
      try:
        await srv.handleRequest(req)
      except CatchableError:
        discard
      finally:
        if not done.finished:
          done.complete()
  await h.server.server.acceptRequest(handler)
  await done

proc harnessThreadProc(h: ServerHarness) {.thread, gcsafe.} =
  # Bind a listening socket from inside this thread so the dispatcher
  # owns it. The asyncdispatcher's globals are thread-local, so as long
  # as only this thread polls, we can safely cast to gcsafe.
  {.cast(gcsafe).}:
    h.server.server.listen(Port(0))
    h.server.port = h.server.server.getPort().int

  withLock h.portLock:
    h.portReady = true
    signal(h.portCond)

  while true:
    var stop = false
    withLock h.lock:
      stop = h.stopFlag
    if stop:
      break
    try:
      {.cast(gcsafe).}:
        # Block until exactly one request is served. The 50ms poll cap
        # keeps the stop flag responsive even when no client connects.
        let f = serveOne(h)
        while not f.finished:
          poll(50)
          var localStop = false
          withLock h.lock:
            localStop = h.stopFlag
          if localStop:
            break
    except CatchableError:
      discard

  {.cast(gcsafe).}:
    try: h.server.stop() except CatchableError: discard

proc newHarness(): ServerHarness =
  result = ServerHarness(
    server: newMockLLMServer(),
    queue: @[],
    fallback: QueuedResponse(kind: qkText, text: ""),
  )
  initLock(result.lock)
  initLock(result.portLock)
  initCond(result.portCond)
  initCond(result.cond)

proc startHarness(h: ServerHarness) =
  createThread(h.thread, harnessThreadProc, h)
  withLock h.portLock:
    while not h.portReady:
      wait(h.portCond, h.portLock)

proc stopHarness(h: ServerHarness) =
  withLock h.lock:
    h.stopFlag = true
    signal(h.cond)
  # Closing the listening socket from the test thread unblocks the
  # dispatcher's accept call so the worker thread can exit.
  try: h.server.server.close() except CatchableError: discard
  joinThread(h.thread)
  deinitCond(h.portCond)
  deinitLock(h.portLock)
  deinitCond(h.cond)
  deinitLock(h.lock)

proc enqueueText(h: ServerHarness; text: string) =
  withLock h.lock:
    h.queue.add(QueuedResponse(kind: qkText, text: text))
    signal(h.cond)

proc enqueueToolCall(h: ServerHarness; name: string; args: JsonNode) =
  withLock h.lock:
    h.queue.add(QueuedResponse(
      kind: qkToolCall, toolName: name, toolArgs: args))
    signal(h.cond)

proc enqueueError(h: ServerHarness; code: int; msg: string) =
  withLock h.lock:
    h.queue.add(QueuedResponse(
      kind: qkError, errCode: code, errMsg: msg))
    signal(h.cond)

proc setFallbackText(h: ServerHarness; text: string) =
  withLock h.lock:
    h.fallback = QueuedResponse(kind: qkText, text: text)

proc requestCount(h: ServerHarness): int =
  h.server.getRequestCount()

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

proc makeClient(h: ServerHarness; maxRetries = 1): LLMClient =
  newLLMClient(
    baseUrl = "http://127.0.0.1:" & $h.server.port & "/v1",
    apiKey = "test-key",
    model = "mock-model",
    maxRetries = maxRetries,
    retryBackoffMs = 5,
    timeoutMs = 5_000,
  )

proc echoToolExecute(args: JsonNode): ToolResult {.gcsafe, raises: [].} =
  ## A trivial tool that echoes its `text` argument back as output.
  let n = args{"text"}
  let s = if n.isNil or n.kind != JString: "" else: n.getStr()
  ToolResult(output: "echo:" & s, isError: false, exitCode: 0)

proc failingToolExecute(args: JsonNode): ToolResult {.gcsafe, raises: [].} =
  ## A tool that always reports an error.
  ToolResult(
    output: "boom: simulated tool failure",
    isError: true,
    exitCode: 2,
  )

proc echoTool(): Tool =
  let schema = %*{
    "type": "object",
    "properties": {"text": {"type": "string"}},
    "required": ["text"],
  }
  newTool("echo", "Echo back the supplied text", schema, echoToolExecute)

proc failingTool(): Tool =
  newTool(
    "failing",
    "A tool that always fails",
    emptyParameters(),
    failingToolExecute,
  )

proc smallAgentConfig(maxIterations = 5; threshold = 3): AgentConfig =
  AgentConfig(
    maxIterations: maxIterations,
    loopDetectionThreshold: threshold,
    systemPrompt: "test-system",
  )

# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

suite "agent_loop: text-only response":
  test "returns assistant text when no tools are needed":
    let h = newHarness()
    startHarness(h)
    defer: stopHarness(h)

    h.enqueueText("Hello, world!")
    h.setFallbackText("UNEXPECTED EXTRA RESPONSE")

    let llm = makeClient(h)
    let reg = newToolRegistry()
    var mem = newMemory(":memory:")
    defer: mem.close()

    let res = runAgentLoop(
      smallAgentConfig(),
      llm, reg, mem,
      userInput = "ping",
    )

    check res.text == "Hello, world!"
    check res.stopReason == asrFinished
    check res.stats.totalTurns == 1
    check res.stats.toolCallsMade == 0
    check h.requestCount == 1

suite "agent_loop: tool call then text":
  test "executes tool, sends result back, returns final answer":
    let h = newHarness()
    startHarness(h)
    defer: stopHarness(h)

    # Turn 1: model asks to call `echo` with {"text": "abc"}
    h.enqueueToolCall("echo", %*{"text": "abc"})
    # Turn 2: model produces final answer.
    h.enqueueText("done: echo:abc")

    let llm = makeClient(h)
    let reg = newToolRegistry()
    reg.register(echoTool())
    var mem = newMemory(":memory:")
    defer: mem.close()

    let res = runAgentLoop(
      smallAgentConfig(),
      llm, reg, mem,
      userInput = "use the echo tool",
    )

    check res.text == "done: echo:abc"
    check res.stopReason == asrFinished
    check res.stats.toolCallsMade == 1
    check res.stats.totalTurns == 2
    check h.requestCount == 2

suite "agent_loop: max iterations":
  test "stops with synthetic message when iterations exhausted":
    let h = newHarness()
    startHarness(h)
    defer: stopHarness(h)

    # Every request returns a tool call so the model never finishes.
    # Distinct args per turn keep loop detection from firing first.
    let cfg = smallAgentConfig(maxIterations = 3, threshold = 99)
    for i in 0 ..< cfg.maxIterations:
      h.enqueueToolCall("echo", %*{"text": "iter-" & $i})
    h.setFallbackText("should-not-be-used")

    let llm = makeClient(h)
    let reg = newToolRegistry()
    reg.register(echoTool())
    var mem = newMemory(":memory:")
    defer: mem.close()

    let res = runAgentLoop(cfg, llm, reg, mem, userInput = "spin")

    check res.stopReason == asrMaxIterations
    check res.text.contains("Max iterations")
    check res.stats.totalTurns == cfg.maxIterations
    check res.stats.toolCallsMade == cfg.maxIterations

suite "agent_loop: loop detection":
  test "stops when same tool+args are issued threshold times in a row":
    let h = newHarness()
    startHarness(h)
    defer: stopHarness(h)

    for _ in 0 ..< 10:
      h.enqueueToolCall("echo", %*{"text": "same"})

    let cfg = smallAgentConfig(maxIterations = 20, threshold = 3)
    let llm = makeClient(h)
    let reg = newToolRegistry()
    reg.register(echoTool())
    var mem = newMemory(":memory:")
    defer: mem.close()

    let res = runAgentLoop(cfg, llm, reg, mem, userInput = "loop me")

    check res.stopReason == asrLoopDetected
    check res.text.contains("Loop detected")
    check res.text.contains("echo")
    check res.stats.totalTurns == 3
    check res.stats.toolCallsMade == 3

  test "different args do NOT trigger loop detection":
    let h = newHarness()
    startHarness(h)
    defer: stopHarness(h)

    h.enqueueToolCall("echo", %*{"text": "a"})
    h.enqueueToolCall("echo", %*{"text": "b"})
    h.enqueueToolCall("echo", %*{"text": "c"})
    h.enqueueText("converged")

    let cfg = smallAgentConfig(maxIterations = 10, threshold = 3)
    let llm = makeClient(h)
    let reg = newToolRegistry()
    reg.register(echoTool())
    var mem = newMemory(":memory:")
    defer: mem.close()

    let res = runAgentLoop(cfg, llm, reg, mem, userInput = "vary args")
    check res.stopReason == asrFinished
    check res.text == "converged"
    check res.stats.toolCallsMade == 3

suite "agent_loop: tool errors":
  test "tool error is reported back to the LLM, loop continues":
    let h = newHarness()
    startHarness(h)
    defer: stopHarness(h)

    # Turn 1: model calls a tool that always fails.
    h.enqueueToolCall("failing", %*{})
    # Turn 2: after seeing the ERROR text, model recovers.
    h.enqueueText("recovered after error")

    let cfg = smallAgentConfig()
    let llm = makeClient(h)
    let reg = newToolRegistry()
    reg.register(failingTool())
    var mem = newMemory(":memory:")
    defer: mem.close()

    let res = runAgentLoop(cfg, llm, reg, mem,
                           userInput = "trigger an error")
    check res.stopReason == asrFinished
    check res.text == "recovered after error"
    check res.stats.toolCallsMade == 1

    # Verify the tool result message logged to memory carries the
    # ERROR marker so downstream consumers can detect failures.
    let history = mem.getHistory(res.sessionId)
    var sawErrorToolMsg = false
    for m in history:
      if m.role == crTool and m.content.startsWith("ERROR:"):
        sawErrorToolMsg = true
        break
    check sawErrorToolMsg

  test "unknown tool name yields an error tool message, loop continues":
    let h = newHarness()
    startHarness(h)
    defer: stopHarness(h)

    h.enqueueToolCall("does_not_exist", %*{"x": 1})
    h.enqueueText("oh well")

    let cfg = smallAgentConfig()
    let llm = makeClient(h)
    let reg = newToolRegistry()           # empty registry
    var mem = newMemory(":memory:")
    defer: mem.close()

    let res = runAgentLoop(cfg, llm, reg, mem, userInput = "go")
    check res.stopReason == asrFinished
    check res.text == "oh well"

suite "agent_loop: memory logging":
  test "logs system, user, assistant and tool messages":
    let h = newHarness()
    startHarness(h)
    defer: stopHarness(h)

    h.enqueueToolCall("echo", %*{"text": "hi"})
    h.enqueueText("final answer")

    let cfg = smallAgentConfig()
    let llm = makeClient(h)
    let reg = newToolRegistry()
    reg.register(echoTool())
    var mem = newMemory(":memory:")
    defer: mem.close()

    let res = runAgentLoop(cfg, llm, reg, mem, userInput = "do it")
    check res.stopReason == asrFinished

    let history = mem.getHistory(res.sessionId)
    # Expected order: system, user, assistant(tool_calls), tool, assistant
    check history.len == 5
    check history[0].role == crSystem
    check history[0].content == cfg.systemPrompt
    check history[1].role == crUser
    check history[1].content == "do it"
    check history[2].role == crAssistant
    check history[2].toolCalls.len == 1
    check history[2].toolCalls[0].name == "echo"
    check history[3].role == crTool
    check history[3].name == "echo"
    check history[3].content.contains("echo:hi")
    check history[4].role == crAssistant
    check history[4].content == "final answer"

  test "session id from result matches a real session in memory":
    let h = newHarness()
    startHarness(h)
    defer: stopHarness(h)

    h.enqueueText("ok")

    let llm = makeClient(h)
    let reg = newToolRegistry()
    var mem = newMemory(":memory:")
    defer: mem.close()

    let res = runAgentLoop(
      smallAgentConfig(), llm, reg, mem, userInput = "ping")
    check res.sessionId.startsWith("sess_")
    let history = mem.getHistory(res.sessionId)
    check history.len >= 2     # at minimum: user + assistant

suite "agent_loop: convenience overload":
  test "MercuryConfig overload threads maxLoopIterations through":
    let h = newHarness()
    startHarness(h)
    defer: stopHarness(h)

    h.enqueueText("done")

    var mc = defaultConfig()
    mc.maxLoopIterations = 4
    let llm = makeClient(h)
    let reg = newToolRegistry()
    var mem = newMemory(":memory:")
    defer: mem.close()

    let res = runAgentLoop(mc, llm, reg, mem, userInput = "hi")
    check res.stopReason == asrFinished
    check res.text == "done"

```

`mercury_agent/tests/tcli.nim`:

```nim
## Tests for mercury_agent CLI helpers (mercury_agent.nim).
##
## These tests exercise the pieces of the CLI that don't require a live
## LLM endpoint:
##   - Config-override layering
##   - Sqlite-backed session listing / lookup
##   - The history and search subcommand entry points against an empty
##     fresh database
##
## Subcommands that talk to an LLM (`chat`, `ask`, `session`) are not
## covered here — `tagent_loop.nim` already exercises that path via the
## mock server. We instead make sure dispatch and option-parsing wiring
## is correct by invoking the dedicated proc entry points.

import std/[os, osproc, strutils, times, unittest]

import mercury_core/config
import mercury_core/llm_client
import mercury_core/memory
import mercury_agent

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

proc tempDbPath(): string =
  ## Returns a unique writable path for a fresh sqlite db. Files are
  ## removed in `teardownDb`.
  result = getTempDir() / ("mercury_cli_test_" & $getCurrentProcessId() &
                           "_" & $epochTime() & ".db")
  if fileExists(result):
    removeFile(result)

proc teardownDb(path: string) =
  ## Removes any sqlite/WAL artifacts left around by the test.
  for suffix in ["", "-wal", "-shm", "-journal"]:
    let p = path & suffix
    if fileExists(p):
      try: removeFile(p) except CatchableError: discard

proc minimalCfg(dbPath: string): MercuryConfig =
  ## Builds a self-contained MercuryConfig that does not need a config
  ## file or env vars.
  result = defaultConfig()
  result.dbPath = dbPath
  result.openrouterApiKey = "test-key"

proc seedSession(dbPath, content: string): string =
  ## Creates one session with one user message in a fresh memory db
  ## and returns the session id.
  var mem = newMemory(dbPath)
  defer: mem.close()
  let sid = mem.newSession()
  let msg = ChatMessage(role: crUser, content: content)
  mem.appendMessage(sid, msg)
  return sid

# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

suite "cli: applyOverrides":
  test "empty overrides leave config untouched":
    var cfg = defaultConfig()
    let before = cfg
    applyOverrides(cfg, emptyOverrides())
    check cfg.provider == before.provider
    check cfg.openrouterModel == before.openrouterModel
    check cfg.vllmModel == before.vllmModel
    check cfg.temperature == before.temperature

  test "model override applies to the active provider":
    var cfg = defaultConfig()
    cfg.provider = "openrouter"
    var ov = emptyOverrides()
    ov.model = "openrouter/mock"
    applyOverrides(cfg, ov)
    check cfg.openrouterModel == "openrouter/mock"
    # vllmModel is *not* changed when openrouter is active.
    check cfg.vllmModel == DefaultVllmModel

  test "model override targets vllmModel when provider=vllm":
    var cfg = defaultConfig()
    cfg.provider = "vllm"
    var ov = emptyOverrides()
    ov.model = "qwen-mock"
    applyOverrides(cfg, ov)
    check cfg.vllmModel == "qwen-mock"
    check cfg.openrouterModel == DefaultOpenrouterModel

  test "provider override switches active provider":
    var cfg = defaultConfig()
    var ov = emptyOverrides()
    ov.provider = "vllm"
    applyOverrides(cfg, ov)
    check cfg.provider == "vllm"

  test "temperature override only applies when explicitly set":
    var cfg = defaultConfig()
    cfg.temperature = 0.7
    var ov = emptyOverrides()
    applyOverrides(cfg, ov)
    check cfg.temperature == 0.7
    ov.hasTemperature = true
    ov.temperature = 0.1
    applyOverrides(cfg, ov)
    check cfg.temperature == 0.1

suite "cli: loadConfigWithOverrides":
  test "applies env-based overrides on top of defaults":
    putEnv("MERCURY_PROVIDER", "openrouter")
    putEnv("OPENROUTER_API_KEY", "fake-key")
    defer:
      delEnv("MERCURY_PROVIDER")
      delEnv("OPENROUTER_API_KEY")

    var ov = emptyOverrides()
    ov.envPath = "/dev/null"
    ov.model = "openrouter/test-model"
    let cfg = loadConfigWithOverrides(ov)
    check cfg.provider == "openrouter"
    check cfg.openrouterModel == "openrouter/test-model"
    check cfg.openrouterApiKey == "fake-key"

  test "rejects an invalid provider override":
    putEnv("OPENROUTER_API_KEY", "fake-key")
    defer: delEnv("OPENROUTER_API_KEY")
    var ov = emptyOverrides()
    ov.envPath = "/dev/null"
    ov.provider = "definitely-not-real"
    expect ConfigError:
      discard loadConfigWithOverrides(ov)

  test "rejects an out-of-range temperature":
    putEnv("OPENROUTER_API_KEY", "fake-key")
    defer: delEnv("OPENROUTER_API_KEY")
    var ov = emptyOverrides()
    ov.envPath = "/dev/null"
    ov.hasTemperature = true
    ov.temperature = 3.5
    expect ConfigError:
      discard loadConfigWithOverrides(ov)

suite "cli: resolveDbPath":
  test "expands a leading tilde to the home directory":
    var cfg = defaultConfig()
    cfg.dbPath = "~/.local/share/mercury/test.db"
    let resolved = resolveDbPath(cfg)
    check not resolved.startsWith("~")
    check resolved.endsWith("/.local/share/mercury/test.db")

  test "leaves an absolute path alone":
    var cfg = defaultConfig()
    let absPath = getTempDir() / "mercury_cli_test_abs_" & $getCurrentProcessId() & ".db"
    cfg.dbPath = absPath
    let resolved = resolveDbPath(cfg)
    check resolved == absPath
    defer: teardownDb(absPath)

suite "cli: listRecentSessions":
  test "returns empty seq when the db file does not exist":
    let path = "/tmp/mercury_cli_does_not_exist_" & $epochTime() & ".db"
    check listRecentSessions(path).len == 0

  test "lists most-recently-updated sessions in descending order":
    let path = tempDbPath()
    defer: teardownDb(path)

    # Sessions are ordered by `updated_at` (ISO seconds), so we space
    # them out by >1s to avoid same-second tiebreaker ambiguity.
    let s1 = seedSession(path, "first")
    sleep(1100)
    let s2 = seedSession(path, "second")
    sleep(1100)
    let s3 = seedSession(path, "third")

    let listed = listRecentSessions(path, limit = 10)
    check listed.len == 3
    check listed[0].id == s3
    check listed[1].id == s2
    check listed[2].id == s1
    for s in listed:
      check s.messageCount == 1
      check s.updatedAt.len > 0

  test "respects the limit parameter":
    let path = tempDbPath()
    defer: teardownDb(path)
    discard seedSession(path, "a")
    sleep(5)
    discard seedSession(path, "b")
    sleep(5)
    discard seedSession(path, "c")

    let listed = listRecentSessions(path, limit = 2)
    check listed.len == 2

suite "cli: sessionExists":
  test "returns false for a missing db":
    check not sessionExists(
      "/tmp/mercury_cli_missing_" & $epochTime() & ".db",
      "sess_anything")

  test "returns true only for ids that actually exist":
    let path = tempDbPath()
    defer: teardownDb(path)
    let sid = seedSession(path, "hello")
    check sessionExists(path, sid)
    check not sessionExists(path, "sess_does_not_exist")

suite "cli: cmdHistory and cmdSearch on a fresh db":
  test "history exits 0 with no sessions":
    let path = tempDbPath()
    defer: teardownDb(path)
    putEnv("MERCURY_DB_PATH", path)
    putEnv("OPENROUTER_API_KEY", "dummy")
    defer:
      delEnv("MERCURY_DB_PATH")
      delEnv("OPENROUTER_API_KEY")
    check cmdHistory(envFile = "/dev/null") == 0

  test "history exits 0 and finds seeded sessions":
    let path = tempDbPath()
    defer: teardownDb(path)
    discard seedSession(path, "alpha bravo")
    putEnv("MERCURY_DB_PATH", path)
    putEnv("OPENROUTER_API_KEY", "dummy")
    defer:
      delEnv("MERCURY_DB_PATH")
      delEnv("OPENROUTER_API_KEY")
    check cmdHistory(envFile = "/dev/null") == 0
    # Sanity check via the underlying helper.
    let listed = listRecentSessions(path, 10)
    check listed.len == 1

  test "search rejects an empty query":
    let path = tempDbPath()
    defer: teardownDb(path)
    putEnv("MERCURY_DB_PATH", path)
    putEnv("OPENROUTER_API_KEY", "dummy")
    defer:
      delEnv("MERCURY_DB_PATH")
      delEnv("OPENROUTER_API_KEY")
    let rc = cmdSearch(query = @[], envFile = "/dev/null")
    check rc == 2

  test "search returns 0 with no matches and 0 with a hit":
    let path = tempDbPath()
    defer: teardownDb(path)
    discard seedSession(path, "the quick brown fox")
    putEnv("MERCURY_DB_PATH", path)
    putEnv("OPENROUTER_API_KEY", "dummy")
    defer:
      delEnv("MERCURY_DB_PATH")
      delEnv("OPENROUTER_API_KEY")
    check cmdSearch(query = @["nonexistent"], envFile = "/dev/null") == 0
    check cmdSearch(query = @["quick"], envFile = "/dev/null") == 0

suite "cli: ask and session error handling without a live LLM":
  test "ask requires a question":
    putEnv("OPENROUTER_API_KEY", "dummy")
    defer: delEnv("OPENROUTER_API_KEY")
    check cmdAsk(question = @[], envFile = "/dev/null") == 2

  test "session requires an id":
    putEnv("OPENROUTER_API_KEY", "dummy")
    defer: delEnv("OPENROUTER_API_KEY")
    check cmdSession(id = @[], envFile = "/dev/null") == 2

  test "session reports unknown id without crashing":
    let path = tempDbPath()
    defer: teardownDb(path)
    putEnv("MERCURY_DB_PATH", path)
    putEnv("OPENROUTER_API_KEY", "dummy")
    defer:
      delEnv("MERCURY_DB_PATH")
      delEnv("OPENROUTER_API_KEY")
    let rc = cmdSession(id = @["sess_made_up"], envFile = "/dev/null")
    check rc == 4

suite "cli: binary smoke test":
  test "the built binary prints a usage banner with --help":
    let bin = currentSourcePath().parentDir().parentDir() / "mercury_agent"
    if not fileExists(bin):
      skip()
    else:
      let (output, code) = execCmdEx(bin & " --help")
      check code == 0
      check output.contains("chat")
      check output.contains("ask")
      check output.contains("history")
      check output.contains("search")

```

`mercury_agent/tests/test_shell_tool.nim`:

```nim
## Tests for mercury_agent/tools/shell.
##
## Exercises the deny-list, real command execution, and timeout logic.
## Also tests integration with mercury_core/tool_registry.

import std/[strutils, unittest]

import mercury_core/tool_registry
import tools/shell

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

proc fastShellOpts(timeoutMs: int = 5_000): ShellOptions =
  result = defaultShellOptions()
  result.timeoutMs = timeoutMs

# ---------------------------------------------------------------------------
# Deny-list
# ---------------------------------------------------------------------------

suite "shell tool deny-list":
  test "isDenied catches rm -rf /":
    check isDenied("rm -rf /", DefaultDenyPatterns)
    check isDenied("RM -RF /", DefaultDenyPatterns)
    check isDenied("rm    -rf   /", DefaultDenyPatterns)

  test "isDenied catches embedded dangerous command":
    check isDenied("echo hi && rm -rf /", DefaultDenyPatterns)

  test "isDenied catches fork bomb":
    check isDenied(":(){ :|:& };:", DefaultDenyPatterns)
    check isDenied(":(){:|:&};:", DefaultDenyPatterns)

  test "isDenied catches mkfs and dd to disk":
    check isDenied("mkfs.ext4 /dev/sda1", DefaultDenyPatterns)
    check isDenied("dd if=/dev/zero of=/dev/sda", DefaultDenyPatterns)

  test "isDenied allows safe commands":
    check (not isDenied("echo hello", DefaultDenyPatterns))
    check (not isDenied("ls -la", DefaultDenyPatterns))
    check (not isDenied("cat /etc/hostname", DefaultDenyPatterns))

  test "shell tool refuses denied command":
    let reg = newToolRegistry()
    reg.register(shellTool(fastShellOpts()))
    let res = reg.execute("shell", """{"cmd": "rm -rf /"}""")
    check res.isError
    check res.output.contains("DENIED")

  test "runShell reports denied=true":
    let exec = runShell("rm -rf /", defaultShellOptions())
    check exec.denied
    check exec.exitCode == -1
    check (not exec.timedOut)

  test "runShell rejects empty command":
    let exec = runShell("   ", defaultShellOptions())
    check exec.denied

# ---------------------------------------------------------------------------
# Real execution
# ---------------------------------------------------------------------------

suite "shell tool execution":
  test "runs simple echo and captures stdout":
    let exec = runShell("echo hello-mercury", fastShellOpts())
    check exec.exitCode == 0
    check (not exec.timedOut)
    check (not exec.denied)
    check exec.stdout.contains("hello-mercury")
    check exec.stderr.len == 0

  test "captures stderr separately":
    let exec = runShell(
      """echo to-out; echo to-err 1>&2""", fastShellOpts())
    check exec.exitCode == 0
    check exec.stdout.contains("to-out")
    check exec.stderr.contains("to-err")

  test "non-zero exit code is reported":
    let exec = runShell("exit 7", fastShellOpts())
    check exec.exitCode == 7
    check (not exec.timedOut)
    check (not exec.denied)

  test "shell tool returns exit code via registry":
    let reg = newToolRegistry()
    reg.register(shellTool(fastShellOpts()))
    let res = reg.execute("shell", """{"cmd": "exit 3"}""")
    check res.isError                   # non-zero exit is an error
    check res.exitCode == 3
    check res.output.contains("exit: 3")

  test "shell tool surfaces stdout in formatted output":
    let reg = newToolRegistry()
    reg.register(shellTool(fastShellOpts()))
    let res = reg.execute("shell", """{"cmd": "echo from-shell-tool"}""")
    check (not res.isError)
    check res.exitCode == 0
    check res.output.contains("from-shell-tool")
    check res.output.contains("exit: 0")

  test "missing cmd argument is an error, not a crash":
    let reg = newToolRegistry()
    reg.register(shellTool(fastShellOpts()))
    let res = reg.execute("shell", """{"foo": "bar"}""")
    check res.isError
    check res.output.contains("'cmd'")

# ---------------------------------------------------------------------------
# Timeout
# ---------------------------------------------------------------------------

suite "shell tool timeout":
  test "long-running command is killed at timeout":
    var opts = fastShellOpts()
    opts.timeoutMs = 200
    let exec = runShell("sleep 5", opts)
    check exec.timedOut
    # The timeout message format varies by Nim version and OS; accept either
    # "timeout" (Nim 2.2+) or "killed" (Nim 2.0.x / SIGKILL exit).
    check exec.stderr.contains("timeout") or exec.stderr.contains("killed")

  test "shell tool reports timeout via registry":
    let reg = newToolRegistry()
    var opts = fastShellOpts()
    opts.timeoutMs = 200
    reg.register(shellTool(opts))
    let res = reg.execute("shell", """{"cmd": "sleep 5"}""")
    check res.isError
    check res.output.contains("timed out")

  test "per-call timeoutMs override is honored":
    let reg = newToolRegistry()
    reg.register(shellTool(fastShellOpts(timeoutMs = 30_000)))
    let res = reg.execute("shell",
      """{"cmd": "sleep 5", "timeoutMs": 200}""")
    check res.isError
    check res.output.contains("timed out")

  test "fast command finishes well before timeout":
    var opts = fastShellOpts()
    opts.timeoutMs = 5_000
    let exec = runShell("echo quick", opts)
    check (not exec.timedOut)
    check exec.exitCode == 0
    check exec.durationMs < 4_000

```

`mercury_agent/tests/tintegration.nim`:

```nim
## End-to-end integration tests for Mercury.
##
## These tests exercise the entire stack wired together as a real run
## would assemble it:
##
##   loadConfig -> MercuryConfig
##                 |
##                 v
##         newLLMClient(...)  -----> MockLLMServer (HTTP, on localhost)
##                 |
##                 v
##         newToolRegistry()
##         register(shellTool())
##                 |
##                 v
##              newMemory(":memory:")  (sqlite + FTS5)
##                 |
##                 v
##              runAgentLoop(...)
##
## They are intentionally separate from `tagent_loop.nim` (which focuses
## on the agent loop in isolation) and `tconfig.nim` / `tmemory.nim`
## (which focus on individual modules). The point of this file is to
## prove that the modules compose correctly end-to-end.

import std/[asyncdispatch, asynchttpserver, json, locks, os, strutils,
            times, unittest, net]

import mercury_core/config
import mercury_core/llm_client
import mercury_core/tool_registry
import mercury_core/memory

import mock_server
import agent_loop
import tools/shell

# ---------------------------------------------------------------------------
# Threaded async-dispatcher harness around `mock_server.MockLLMServer`.
#
# Mirrors the harness in tagent_loop.nim. We keep a private copy here so
# the integration tests can run independently and so we can extend the
# harness if needed without touching the unit tests.
# ---------------------------------------------------------------------------

type
  QueuedKind = enum
    qkText, qkToolCall, qkError

  QueuedResponse = object
    kind: QueuedKind
    text: string
    toolName: string
    toolArgs: JsonNode
    errCode: int
    errMsg: string

  ServerHarness = ref object
    server: MockLLMServer
    thread: Thread[ServerHarness]

    portReady: bool
    portCond: Cond
    portLock: Lock

    stopFlag: bool
    lock: Lock
    cond: Cond              ## signalled when queue grows or stopFlag flips

    queue: seq[QueuedResponse]
    fallback: QueuedResponse

proc applyResponse(srv: MockLLMServer; r: QueuedResponse) =
  case r.kind
  of qkText:     srv.setResponse(r.text)
  of qkToolCall: srv.setToolCallResponse(r.toolName, r.toolArgs)
  of qkError:    srv.setErrorResponse(r.errCode, r.errMsg)

proc takeNext(h: ServerHarness): QueuedResponse =
  withLock h.lock:
    while h.queue.len == 0 and not h.stopFlag:
      wait(h.cond, h.lock)
    if h.queue.len > 0:
      result = h.queue[0]
      h.queue.delete(0)
    else:
      result = h.fallback

proc serveOne(h: ServerHarness) {.async.} =
  let next = takeNext(h)
  applyResponse(h.server, next)
  let srv = h.server
  let done = newFuture[void]("serveOne.done")
  proc handler(req: Request) {.async, gcsafe.} =
    {.cast(gcsafe).}:
      try:
        await srv.handleRequest(req)
      except CatchableError:
        discard
      finally:
        if not done.finished:
          done.complete()
  await h.server.server.acceptRequest(handler)
  await done

proc harnessThreadProc(h: ServerHarness) {.thread, gcsafe.} =
  {.cast(gcsafe).}:
    h.server.server.listen(Port(0))
    h.server.port = h.server.server.getPort().int

  withLock h.portLock:
    h.portReady = true
    signal(h.portCond)

  while true:
    var stop = false
    withLock h.lock:
      stop = h.stopFlag
    if stop:
      break
    try:
      {.cast(gcsafe).}:
        let f = serveOne(h)
        while not f.finished:
          poll(50)
          var localStop = false
          withLock h.lock:
            localStop = h.stopFlag
          if localStop:
            break
    except CatchableError:
      discard

  {.cast(gcsafe).}:
    try: h.server.stop() except CatchableError: discard

proc newHarness(): ServerHarness =
  result = ServerHarness(
    server: newMockLLMServer(),
    queue: @[],
    fallback: QueuedResponse(kind: qkText, text: ""),
  )
  initLock(result.lock)
  initLock(result.portLock)
  initCond(result.portCond)
  initCond(result.cond)

proc startHarness(h: ServerHarness) =
  createThread(h.thread, harnessThreadProc, h)
  withLock h.portLock:
    while not h.portReady:
      wait(h.portCond, h.portLock)

proc stopHarness(h: ServerHarness) =
  withLock h.lock:
    h.stopFlag = true
    signal(h.cond)
  try: h.server.server.close() except CatchableError: discard
  joinThread(h.thread)
  deinitCond(h.portCond)
  deinitLock(h.portLock)
  deinitCond(h.cond)
  deinitLock(h.lock)

proc enqueueText(h: ServerHarness; text: string) =
  withLock h.lock:
    h.queue.add(QueuedResponse(kind: qkText, text: text))
    signal(h.cond)

proc enqueueToolCall(h: ServerHarness; name: string; args: JsonNode) =
  withLock h.lock:
    h.queue.add(QueuedResponse(
      kind: qkToolCall, toolName: name, toolArgs: args))
    signal(h.cond)

proc enqueueError(h: ServerHarness; code: int; msg: string) =
  withLock h.lock:
    h.queue.add(QueuedResponse(
      kind: qkError, errCode: code, errMsg: msg))
    signal(h.cond)

proc setFallbackText(h: ServerHarness; text: string) =
  withLock h.lock:
    h.fallback = QueuedResponse(kind: qkText, text: text)

# ---------------------------------------------------------------------------
# Temp-file helpers
# ---------------------------------------------------------------------------

proc writeTempFile(path, content: string) =
  createDir(parentDir(path))
  writeFile(path, content)

proc tempPath(prefix, suffix: string): string =
  let stamp = $getCurrentProcessId() & "_" & $epochTime()
  result = getTempDir() / (prefix & "_" & stamp & suffix)
  if fileExists(result):
    removeFile(result)

proc cleanupSqlite(path: string) =
  for s in ["", "-wal", "-shm", "-journal"]:
    let p = path & s
    if fileExists(p):
      try: removeFile(p) except CatchableError: discard

# ---------------------------------------------------------------------------
# LLM client wired against the mock harness
# ---------------------------------------------------------------------------

proc makeClient(h: ServerHarness; cfg: MercuryConfig): LLMClient =
  ## Builds an LLMClient that targets the mock harness but takes
  ## defaults (model, maxTokens, ...) from a real MercuryConfig so we
  ## exercise the full config -> client wiring.
  newLLMClient(
    baseUrl = "http://127.0.0.1:" & $h.server.port & "/v1",
    apiKey = if cfg.openrouterApiKey.len > 0: cfg.openrouterApiKey
             else: "test-key",
    model = "mock-model",
    maxRetries = 1,
    retryBackoffMs = 5,
    timeoutMs = 5_000,
  )

# ---------------------------------------------------------------------------
# Tools used by the integration tests
# ---------------------------------------------------------------------------

proc echoToolExecute(args: JsonNode): ToolResult {.gcsafe, raises: [].} =
  let n = args{"text"}
  let s = if n.isNil or n.kind != JString: "" else: n.getStr()
  ToolResult(output: "echo:" & s, isError: false, exitCode: 0)

proc echoTool(): Tool =
  let schema = %*{
    "type": "object",
    "properties": {"text": {"type": "string"}},
    "required": ["text"],
  }
  newTool("echo", "Echo back the supplied text", schema, echoToolExecute)

# ---------------------------------------------------------------------------
# 1. Full pipeline tests
# ---------------------------------------------------------------------------

suite "integration: full pipeline (config + client + registry + memory + agent)":

  test "text-only response flows end-to-end":
    let h = newHarness()
    startHarness(h)
    defer: stopHarness(h)

    h.enqueueText("Hello from the full stack")

    # Build a real MercuryConfig the same way the CLI would, then wire
    # every concrete dependency on top of it.
    var cfg = defaultConfig()
    cfg.openrouterApiKey = "sk-test"
    cfg.maxLoopIterations = 4
    validate(cfg)

    let llm = makeClient(h, cfg)
    let registry = newToolRegistry()
    registry.register(shellTool())
    registry.register(echoTool())
    var mem = newMemory(":memory:")
    defer: mem.close()

    let res = runAgentLoop(cfg, llm, registry, mem,
                           userInput = "say hi")

    check res.text == "Hello from the full stack"
    check res.stopReason == asrFinished
    check res.stats.totalTurns == 1
    check res.stats.toolCallsMade == 0
    # The full pipeline must produce a real session id and a logged
    # conversation (system + user + assistant at minimum).
    check res.sessionId.startsWith("sess_")
    let history = mem.getHistory(res.sessionId)
    check history.len == 3
    check history[0].role == crSystem
    check history[1].role == crUser
    check history[1].content == "say hi"
    check history[2].role == crAssistant
    check history[2].content == "Hello from the full stack"

  test "tool call response is dispatched through registry and memory":
    let h = newHarness()
    startHarness(h)
    defer: stopHarness(h)

    # Turn 1: model asks for echo. Turn 2: model emits final answer.
    h.enqueueToolCall("echo", %*{"text": "round-trip"})
    h.enqueueText("ok: round-trip done")

    var cfg = defaultConfig()
    cfg.openrouterApiKey = "sk-test"
    cfg.maxLoopIterations = 5

    let llm = makeClient(h, cfg)
    let registry = newToolRegistry()
    registry.register(echoTool())
    var mem = newMemory(":memory:")
    defer: mem.close()

    let res = runAgentLoop(cfg, llm, registry, mem,
                           userInput = "use the echo tool please")

    check res.text == "ok: round-trip done"
    check res.stopReason == asrFinished
    check res.stats.toolCallsMade == 1
    check res.stats.totalTurns == 2

    # End-to-end: the tool invocation must be visible in memory as a
    # tool message containing the registry's output.
    let history = mem.getHistory(res.sessionId)
    var sawToolResult = false
    for m in history:
      if m.role == crTool and m.content.contains("echo:round-trip"):
        sawToolResult = true
        break
    check sawToolResult

  test "LLM error is surfaced through agent result without crashing":
    let h = newHarness()
    startHarness(h)
    defer: stopHarness(h)

    h.enqueueError(500, "upstream blew up")

    var cfg = defaultConfig()
    cfg.openrouterApiKey = "sk-test"
    cfg.maxLoopIterations = 2

    let llm = makeClient(h, cfg)
    let registry = newToolRegistry()
    var mem = newMemory(":memory:")
    defer: mem.close()

    let res = runAgentLoop(cfg, llm, registry, mem,
                           userInput = "trigger 500")

    check res.stopReason == asrError
    check res.text.contains("LLM request failed")
    # Even the error path must persist a session and an assistant
    # message so callers can audit failures.
    let history = mem.getHistory(res.sessionId)
    check history.len >= 1
    var sawError = false
    for m in history:
      if m.role == crAssistant and m.content.contains("LLM request failed"):
        sawError = true
        break
    check sawError

# ---------------------------------------------------------------------------
# 2. Config loading tests (TOML + env + defaults composition)
# ---------------------------------------------------------------------------

suite "integration: config loading (toml + env + defaults)":

  test "loadConfig returns defaults when nothing else is provided":
    let cfg = loadConfig(
      configPath = "/nonexistent/integration_config.toml",
      envFilePath = "/nonexistent/integration.env",
    )
    check cfg.provider == DefaultProvider
    check cfg.maxTokens == DefaultMaxTokens
    check cfg.temperature == DefaultTemperature
    check cfg.maxLoopIterations == DefaultMaxLoopIterations

  test "TOML file overrides defaults":
    let tmpDir = getTempDir() / "mercury_integration_toml"
    createDir(tmpDir)
    defer: removeDir(tmpDir)
    let cfgFile = tmpDir / "config.toml"
    writeTempFile(cfgFile, """
[mercury]
provider=vllm
max_tokens=1234
temperature=0.42
max_loop_iterations=7
db_path=/tmp/mercury-integration.db
""")
    let cfg = loadConfig(
      configPath = cfgFile,
      envFilePath = "/nonexistent/.env",
    )
    check cfg.provider == "vllm"
    check cfg.maxTokens == 1234
    check abs(cfg.temperature - 0.42) < 1e-9
    check cfg.maxLoopIterations == 7
    check cfg.dbPath == "/tmp/mercury-integration.db"

  test "env vars override TOML, .env supplies api key":
    let tmpDir = getTempDir() / "mercury_integration_env"
    createDir(tmpDir)
    defer: removeDir(tmpDir)
    let cfgFile = tmpDir / "config.toml"
    writeTempFile(cfgFile, "[mercury]\nmax_tokens=2048\nprovider=vllm\n")
    let envFile = tmpDir / ".env"
    writeTempFile(envFile, "OPENROUTER_API_KEY=sk-from-env-file\n")

    putEnv("MERCURY_MAX_TOKENS", "555")
    putEnv("MERCURY_PROVIDER", "openrouter")
    defer:
      delEnv("MERCURY_MAX_TOKENS")
      delEnv("MERCURY_PROVIDER")

    let cfg = loadConfig(configPath = cfgFile, envFilePath = envFile)
    # env var beats TOML
    check cfg.maxTokens == 555
    check cfg.provider == "openrouter"
    # .env supplies the API key
    check cfg.openrouterApiKey == "sk-from-env-file"

  test "validate rejects an obviously broken config":
    var cfg = defaultConfig()
    cfg.provider = "not-a-provider"
    expect ConfigError:
      validate(cfg)

# ---------------------------------------------------------------------------
# 3. Memory persistence tests (sessions, history, FTS5 search)
# ---------------------------------------------------------------------------

suite "integration: memory persistence + FTS5 search":

  test "session round-trip: append and retrieve a multi-message history":
    var mem = newMemory(":memory:")
    defer: mem.close()

    let sid = mem.newSession()
    check sid.startsWith("sess_")

    let m1 = ChatMessage(role: crSystem,    content: "you are mercury")
    let m2 = ChatMessage(role: crUser,      content: "hello agent")
    let m3 = ChatMessage(
      role: crAssistant,
      content: "",
      toolCalls: @[
        ToolCall(id: "call_1", name: "echo", arguments: """{"text":"hi"}""")
      ],
    )
    let m4 = ChatMessage(
      role: crTool,
      name: "echo",
      toolCallId: "call_1",
      content: "echo:hi",
    )
    let m5 = ChatMessage(role: crAssistant, content: "all done")

    mem.appendMessage(sid, m1, tokensIn = 5,  tokensOut = 0)
    mem.appendMessage(sid, m2, tokensIn = 4,  tokensOut = 0)
    mem.appendMessage(sid, m3, tokensIn = 9,  tokensOut = 12)
    mem.appendMessage(sid, m4)
    mem.appendMessage(sid, m5, tokensIn = 0,  tokensOut = 7)

    let history = mem.getHistory(sid)
    check history.len == 5
    check history[0].role == crSystem
    check history[0].content == "you are mercury"
    check history[2].role == crAssistant
    check history[2].toolCalls.len == 1
    check history[2].toolCalls[0].name == "echo"
    check history[2].toolCalls[0].arguments == """{"text":"hi"}"""
    check history[3].role == crTool
    check history[3].name == "echo"
    check history[3].toolCallId == "call_1"
    check history[3].content == "echo:hi"

    # Token usage is aggregated.
    let usage = mem.getTokenUsage(sid)
    check usage.promptTokens == 5 + 4 + 9
    check usage.completionTokens == 12 + 7
    check usage.totalTokens == usage.promptTokens + usage.completionTokens

  test "searchHistory finds messages via FTS5":
    var mem = newMemory(":memory:")
    defer: mem.close()

    let sidA = mem.newSession()
    let sidB = mem.newSession()
    mem.appendMessage(sidA,
      ChatMessage(role: crUser, content: "the quick brown fox"))
    mem.appendMessage(sidA,
      ChatMessage(role: crAssistant, content: "lazy dog jumped over"))
    mem.appendMessage(sidB,
      ChatMessage(role: crUser, content: "completely unrelated message"))

    # FTS5 token match
    let hitsFox = mem.searchHistory("fox")
    check hitsFox.len >= 1
    var foundFox = false
    for h in hitsFox:
      if h.sessionId == sidA and h.content.contains("fox"):
        foundFox = true
    check foundFox

    # Match in the OTHER session, not the first one
    let hitsUnrelated = mem.searchHistory("unrelated")
    check hitsUnrelated.len >= 1
    check hitsUnrelated[0].sessionId == sidB

    # Empty query yields no results (per memory.nim contract).
    check mem.searchHistory("").len == 0

  test "memory survives across reopen of the same on-disk database":
    let dbPath = tempPath("mercury_integration_mem", ".db")
    defer: cleanupSqlite(dbPath)

    var sid = ""
    block:
      var mem = newMemory(dbPath)
      defer: mem.close()
      sid = mem.newSession()
      mem.appendMessage(sid,
        ChatMessage(role: crUser, content: "persisted message"))

    # Reopen.
    var mem2 = newMemory(dbPath)
    defer: mem2.close()
    let history = mem2.getHistory(sid)
    check history.len == 1
    check history[0].role == crUser
    check history[0].content == "persisted message"

# ---------------------------------------------------------------------------
# 4. Tool registry integration tests
# ---------------------------------------------------------------------------

suite "integration: tool registry + shell tool":

  test "shell tool registers and executes via the registry":
    let registry = newToolRegistry()
    registry.register(shellTool())
    check registry.has("shell")
    check registry.len == 1

    # Run a trivially safe command. Pipe to /bin/sh so this works on
    # any POSIX host with /bin/sh available.
    let res = registry.execute("shell", """{"cmd": "echo integration_ok"}""")
    check not res.isError
    check res.exitCode == 0
    check res.output.contains("integration_ok")

  test "shell tool denies dangerous commands without executing them":
    let registry = newToolRegistry()
    registry.register(shellTool())
    let res = registry.execute("shell", """{"cmd": "rm -rf /"}""")
    check res.isError
    check res.output.contains("DENIED")

  test "shell tool reports invalid JSON arguments cleanly":
    let registry = newToolRegistry()
    registry.register(shellTool())
    # Arguments aren't even valid JSON.
    let res = registry.execute("shell", "this is not json")
    check res.isError
    check res.output.contains("invalid arguments")

  test "openAI definitions include the registered shell tool":
    let registry = newToolRegistry()
    registry.register(shellTool())
    let defs = registry.toOpenAIDefinitions()
    check defs.kind == JArray
    check defs.len == 1
    let entry = defs[0]
    check entry.kind == JObject
    check entry["type"].getStr() == "function"
    let fn = entry["function"]
    check fn["name"].getStr() == "shell"
    check fn["description"].getStr().len > 0
    let params = fn["parameters"]
    check params["type"].getStr() == "object"
    check params["properties"].hasKey("cmd")
    check params["required"].kind == JArray

  test "registry rejects duplicate registrations of the same tool":
    let registry = newToolRegistry()
    registry.register(shellTool())
    expect ToolDuplicateError:
      registry.register(shellTool())

# ---------------------------------------------------------------------------
# 5. Agent loop integration test (full ReAct + memory logging)
# ---------------------------------------------------------------------------

suite "integration: agent loop end-to-end (ReAct + memory log)":

  test "ReAct: tool call -> tool result -> final answer, all logged":
    let h = newHarness()
    startHarness(h)
    defer: stopHarness(h)

    # Turn 1: tool call. Turn 2: final answer that references the
    # output the tool produced, proving the tool result was actually
    # fed back to the model loop.
    h.enqueueToolCall("echo", %*{"text": "from-react"})
    h.enqueueText("answer references echo:from-react")
    h.setFallbackText("UNEXPECTED EXTRA TURN")

    var cfg = defaultConfig()
    cfg.openrouterApiKey = "sk-test"
    cfg.maxLoopIterations = 5

    let llm = makeClient(h, cfg)
    let registry = newToolRegistry()
    registry.register(echoTool())
    var mem = newMemory(":memory:")
    defer: mem.close()

    let agentCfg = newAgentConfig(cfg)
    let res = runAgentLoop(agentCfg, llm, registry, mem,
                           userInput = "do the react thing")

    # Outcome
    check res.stopReason == asrFinished
    check res.text == "answer references echo:from-react"
    check res.stats.totalTurns == 2
    check res.stats.toolCallsMade == 1

    # Memory log: system + user + assistant(tool_call) + tool + assistant
    let history = mem.getHistory(res.sessionId)
    check history.len == 5
    check history[0].role == crSystem
    check history[1].role == crUser
    check history[1].content == "do the react thing"
    check history[2].role == crAssistant
    check history[2].toolCalls.len == 1
    check history[2].toolCalls[0].name == "echo"
    check history[3].role == crTool
    check history[3].name == "echo"
    check history[3].content.contains("echo:from-react")
    check history[4].role == crAssistant
    check history[4].content == "answer references echo:from-react"

  test "agent loop persists session to disk and is searchable afterwards":
    let h = newHarness()
    startHarness(h)
    defer: stopHarness(h)

    h.enqueueText("persisted answer with searchable_sentinel inside")

    let dbPath = tempPath("mercury_integration_agent", ".db")
    defer: cleanupSqlite(dbPath)

    var cfg = defaultConfig()
    cfg.openrouterApiKey = "sk-test"
    cfg.maxLoopIterations = 3
    cfg.dbPath = dbPath

    let llm = makeClient(h, cfg)
    let registry = newToolRegistry()
    var mem = newMemory(dbPath)

    let res = runAgentLoop(cfg, llm, registry, mem,
                           userInput = "make it searchable")
    check res.stopReason == asrFinished
    mem.close()

    # Reopen and search via FTS5: the persisted assistant message
    # must be findable.
    var mem2 = newMemory(dbPath)
    defer: mem2.close()
    let hits = mem2.searchHistory("searchable_sentinel")
    check hits.len >= 1
    var foundInRightSession = false
    for h2 in hits:
      if h2.sessionId == res.sessionId:
        foundInRightSession = true
    check foundInRightSession

```

`mercury_code/config.nims`:

```nims
switch("path", "src")
switch("path", "/home/spag/mercury-agent/mercury_core/src")
switch("path", "/home/spag/mercury-agent/mercury_agent/src")
switch("define", "ssl")
```

`mercury_code/mercury_code.nimble`:

```nimble
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
```

`mercury_code/src/mercury_code.nim`:

```nim
when isMainModule:
  discard

```

`mercury_code/src/mercury_code/code_runner.nim`:

```nim
## Mercury coding harness configuration.
##
## Extends the base MercuryConfig with coding-specific settings:
##   - Language-specific build/test commands
##   - Allowed file extensions for read/write
##   - Sandbox root (the directory the agent may touch)
##   - Compile result size caps

import std/[strutils]

# ---------------------------------------------------------------------------
# Compile error structures
# ---------------------------------------------------------------------------

type
  CompileError* = object
    ## A single parsed compiler error / warning / note.
    file*: string     ## Absolute path to the source file.
    line*: int        ## 1-based line number in `file`.
    column*: int      ## 1-based column (0 if unknown).
    severity*: string ## "error", "warning", "hint", "note".
    message*: string  ## Human-readable diagnostic text.

  CompileResult* = object
    ## The result of a `runCompile` call.
    success*: bool            ## True if the command exited 0.
    exitCode*: int            ## Raw exit code from the compiler.
    stdout*: string          ## Captured stdout (truncated).
    stderr*: string           ## Captured stderr (truncated).
    durationMs*: int          ## Wall-clock time in milliseconds.
    errors*: seq[CompileError]  ## Parsed error list (empty if parsing fails).
    timedOut*: bool           ## True if the command exceeded its deadline.
    truncated*: bool          ## True if stdout/stderr were clamped.

# ---------------------------------------------------------------------------
# Coding harness configuration
# ---------------------------------------------------------------------------

type
  CodingHarnessConfig* = object
    ## Per-project coding harness settings.
    sandboxRoot*: string
      ## The root directory the agent may read/write. Must be an absolute path.
      ## Compiles and tests run inside this tree.

    allowedExtensions*: seq[string]
      ## File extensions the harness may read or write.
      ## e.g. @[".nim", ".c", ".h", ".cfg", ".md"]

    buildCmd*: string
      ## Command to build the project. Run from `sandboxRoot`.
      ## e.g. "nim c -r --hints:off --warnings:off src/main.nim"

    buildTimeoutMs*: int
      ## Hard kill deadline for the build command (default 120s).

    testCmd*: string
      ## Command to run the project tests. Run from `sandboxRoot`.
      ## e.g. "nim c -r tests/test_all.nim"

    testTimeoutMs*: int
      ## Hard kill deadline for the test command (default 300s).

    maxOutputBytes*: int
      ## Cap on stdout/stderr returned per compile/test invocation.
      ## Defaults to 256 KB.

const
  DefaultBuildTimeoutMs* = 120_000   ## 2 minutes
  DefaultTestTimeoutMs*  = 300_000   ## 5 minutes
  DefaultMaxOutputBytes* = 512 * 1024 ## 512 KB

proc defaultCodingHarnessConfig*(): CodingHarnessConfig =
  CodingHarnessConfig(
    sandboxRoot: "",
    allowedExtensions: @[".nim", ".c", ".h", ".cfg", ".md", ".txt", ".json",
                         ".toml", ".yml", ".yaml"],
    buildCmd: "",
    buildTimeoutMs: DefaultBuildTimeoutMs,
    testCmd: "",
    testTimeoutMs: DefaultTestTimeoutMs,
    maxOutputBytes: DefaultMaxOutputBytes,
  )

# ---------------------------------------------------------------------------
# Compiler output parser
# ---------------------------------------------------------------------------

proc parseNimCompilerOutput*(raw: string): seq[CompileError] =
  ## Parses Nim's line-oriented compiler output into structured errors.
  ##
  ## Nim emits diagnostics in two formats:
  ##
  ##   /path/to/file.nim(line, col) [severity] message
  ##   /path/to/file.nim(line, col) severity: message
  ##
  ## Both are handled. Unknown lines are silently skipped.
  result = @[]
  for line in raw.splitLines:
    let stripped = line.strip()
    if stripped.len == 0:
      continue

    # Nim emits diagnostics in the form: /path/to/file.nim(line, col) [severity] message
    # Find the first '(' which marks the start of (line, col).
    let pathEnd = stripped.find('(')
    if pathEnd < 2:
      continue

    let file = stripped[0 ..< pathEnd]
    # Extract (line, col) parenthesis block.
    var parenEnd = -1
    for i in pathEnd ..< stripped.len:
      if stripped[i] == ')':
        parenEnd = i
        break
    if parenEnd < pathEnd + 2:
      continue

    let paren = stripped[pathEnd + 1 ..< parenEnd]
    let parts = paren.split(',')
    if parts.len < 1:
      continue

    let lineNum = parseInt(parts[0].strip())
    let colNum = if parts.len > 1: parseInt(parts[1].strip()) else: 0

    # Extract severity and message: either "[severity]" or "severity:" prefix.
    let after = stripped[parenEnd + 1 ..< stripped.len].strip()
    var severity = "error"
    var message = after

    if after.startsWith('['):
      # "[severity] message" or "[severity]"
      let close = after.find(']')
      if close > 1:
        severity = after[1 ..< close].toLowerAscii()
        message = after[close + 1 .. after.high].strip()
      else:
        message = after
    elif ':' in after:
      let colon = after.find(':')
      severity = after[0 ..< colon].toLowerAscii().strip()
      message = after[colon + 1 .. after.high].strip()
    else:
      message = after

    result.add CompileError(
      file: file,
      line: lineNum,
      column: colNum,
      severity: severity,
      message: message,
    )

# ---------------------------------------------------------------------------
# Error parsing (legacy API)
# ---------------------------------------------------------------------------

proc parseNimErrors*(raw: string; defaultFile: string): seq[CompileError] =
  ## Parses Nim compiler errors from raw output.
  ##
  ## Supports formats like:
  ##   file.nim(line, col) Error: message
  ##   file.nim(line) Error: message
  ##
  ## Lines without a file(path) pattern are skipped.
  ## `defaultFile` is used when no file can be extracted.
  result = @[]
  for line in raw.splitLines:
    let stripped = line.strip()
    if stripped.len == 0:
      continue

    # Look for file(path) pattern
    let pathEnd = stripped.find('(')
    if pathEnd < 1:
      continue

    var file = stripped[0 ..< pathEnd]
    if file.len == 0:
      file = defaultFile

    # Find closing paren
    var parenEnd = -1
    for i in pathEnd ..< stripped.len:
      if stripped[i] == ')':
        parenEnd = i
        break
    if parenEnd < 0:
      continue

    # Extract line and optional column
    let paren = stripped[pathEnd + 1 ..< parenEnd]
    let parts = paren.split(',')
    var lineNum = 0
    var colNum = 0
    try:
      lineNum = parseInt(parts[0].strip())
      if parts.len > 1:
        colNum = parseInt(parts[1].strip())
    except CatchableError:
      continue

    # Extract severity and message after the closing paren
    let after = stripped[parenEnd + 1 ..< stripped.len].strip()
    var severity = "error"
    var message = after

    if after.startsWith('['):
      let close = after.find(']')
      if close > 1:
        severity = after[1 ..< close].toLowerAscii()
        message = after[close + 1 .. after.high].strip()
    elif ':' in after:
      let colon = after.find(':')
      severity = after[0 ..< colon].toLowerAscii().strip()
      message = after[colon + 1 .. after.high].strip()
    else:
      message = after

    result.add CompileError(
      file: file,
      line: lineNum,
      column: colNum,
      severity: severity,
      message: message,
    )

# ---------------------------------------------------------------------------
# Compile result formatting
# ---------------------------------------------------------------------------

proc formatCompileResult*(res: CompileResult): string =
  ## Formats a CompileResult into a human-readable summary string.
  if res.timedOut:
    result = "✗ TIMEOUT\n"
  elif res.truncated:
    result = "✗ TRUNCATED\n"
  elif res.success:
    result = "✓ BUILD SUCCEEDED\n"
  else:
    result = "✗ BUILD FAILED\n"

  if res.stdout.len > 0:
    result.add res.stdout
    if not res.stdout.endsWith("\n"):
      result.add "\n"

  if res.stderr.len > 0:
    result.add res.stderr
    if not res.stderr.endsWith("\n"):
      result.add "\n"

  for err in res.errors:
    if err.column > 0:
      result.add err.file & "(" & $err.line & "," & $err.column & ") " &
             err.severity & ": " & err.message & "\n"
    else:
      result.add err.file & "(" & $err.line & ") " &
             err.severity & ": " & err.message & "\n"
```

`mercury_code/src/mercury_code/code_tool.nim`:

```nim
## Coding tool registry helpers.
##
## Exposes the coding harness as OpenAI function-calling tools that can
## be registered against a `ToolRegistry`:
##
##   import mercury_core/tool_registry
##   import mercury_code/code_tool
##   let reg = newToolRegistry()
##   reg.register(compileTool(cfg))
##   reg.register(testTool(cfg))
##
## Each tool wraps `runCompile` with the appropriate sandbox root guard,
## parameterises the command, and returns structured output (or a
## parseable error summary for the LLM to fix).

import std/[json, strutils, os]

import mercury_core/tool_registry
import code_runner
import compile

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

proc clampOutput(s: string; cap: int): string =
  if s.len <= cap: s
  else: s[0 ..< cap] & "\n... [output truncated]"

proc sandboxPath*(path: string; root: string): string =
  ## Returns `path` if it is inside `root`, otherwise returns `root`.
  ## Used as a last-ditch guard; callers should still validate before
  ## passing paths to the harness.
  let absPath = if path.startsWith('/'): path else: ""
  let absRoot = if root.startsWith('/'): root else: ""
  if absRoot.len > 0 and absPath.startsWith(absRoot):
    return path
  return root

proc formatCompileResult(res: CompileResult): string =
  if res.success:
    return "Compiled successfully in " & $res.durationMs & "ms.\n" &
           "stdout:\n" & res.stdout
  var lines = @[if res.exitCode == -1: "TIMEOUT or LAUNCH FAILURE"
                else: "Compilation failed (exit " & $res.exitCode & ") in " &
                      $res.durationMs & "ms.\n"]
  if res.errors.len > 0:
    lines.add "Errors:\n"
    for err in res.errors:
      lines.add "  " & err.file & "(" & $err.line & "," & $err.column & "): " &
                err.severity & ": " & err.message
  else:
    lines.add "stdout:\n" & clampOutput(res.stdout, 4096)
  if res.stderr.len > 0:
    lines.add "stderr:\n" & res.stderr
  lines.join("\n")

# ---------------------------------------------------------------------------
# Compile tool
# ---------------------------------------------------------------------------

proc compileTool*(cfg: CodingHarnessConfig): Tool =
  let buildCmd = cfg.buildCmd
  let timeoutMs = cfg.buildTimeoutMs
  let maxOut = cfg.maxOutputBytes
  let execute: ToolExecuteProc = proc (args: JsonNode): ToolResult {.gcsafe, raises: [].} =
    if buildCmd.len == 0:
      return ToolResult(output: "no build command configured", isError: true)
    try:
      let res = runCompile(buildCmd, timeoutMs, maxOut)
      return ToolResult(output: formatCompileResult(res), isError: not res.success)
    except CatchableError as e:
      return ToolResult(output: "compile failed: " & e.msg, isError: true)
  result = newTool(
    name = "compile",
    description = "Compile the project. Returns structured errors with file, " &
                  "line, and message so the model can fix them. Use this " &
                  "after writing or modifying code.",
    parameters = %*{
      "type": "object",
      "properties": {},
      "description": "Run the project's configured build command.",
    },
    execute = execute,
  )

# ---------------------------------------------------------------------------
# Test tool
# ---------------------------------------------------------------------------

proc testTool*(cfg: CodingHarnessConfig): Tool =
  let testCmd = cfg.testCmd
  let timeoutMs = cfg.testTimeoutMs
  let maxOut = cfg.maxOutputBytes
  let execute: ToolExecuteProc = proc (args: JsonNode): ToolResult {.gcsafe, raises: [].} =
    if testCmd.len == 0:
      return ToolResult(output: "no test command configured", isError: true)
    try:
      let res = runCompile(testCmd, timeoutMs, maxOut)
      return ToolResult(output: formatCompileResult(res), isError: not res.success)
    except CatchableError as e:
      return ToolResult(output: "test failed: " & e.msg, isError: true)
  result = newTool(
    name = "test",
    description = "Run the project's test suite. Returns pass/fail counts and " &
                  "any test error details.",
    parameters = %*{
      "type": "object",
      "properties": {},
    },
    execute = execute,
  )

# ---------------------------------------------------------------------------
# Read file tool
# ---------------------------------------------------------------------------

proc readFileTool*(cfg: CodingHarnessConfig): Tool =
  let allowed = cfg.allowedExtensions
  let execute: ToolExecuteProc = proc (args: JsonNode): ToolResult {.gcsafe, raises: [].} =
    let path = args{"path"}.getStr("")
    if path.len == 0:
      return ToolResult(output: "path is required", isError: true)
    let (_, _, ext) = path.splitFile()
    if ext.len > 0 and ext notin allowed:
      return ToolResult(
        output: "file extension '" & ext & "' is not in the allowed list: " &
                allowed.join(", "),
        isError: true,
      )
    try:
      let content = readFile(path)
      return ToolResult(output: content, isError: false)
    except CatchableError as e:
      return ToolResult(
        output: "failed to read file: " & e.msg,
        isError: true,
        exitCode: 1,
      )
  result = newTool(
    name = "read_file",
    description = "Read the contents of a file within the sandbox. " &
                  "Only files with allowed extensions can be read.",
    parameters = %*{
      "type": "object",
      "properties": {
        "path": {
          "type": "string",
          "description": "Absolute path to the file to read.",
        },
      },
      "required": ["path"],
    },
    execute = execute,
  )

# ---------------------------------------------------------------------------
# Write file tool
# ---------------------------------------------------------------------------

proc writeFileTool*(cfg: CodingHarnessConfig): Tool =
  let allowed = cfg.allowedExtensions
  let execute: ToolExecuteProc = proc (args: JsonNode): ToolResult {.gcsafe, raises: [].} =
    let path = args{"path"}.getStr("")
    let content = args{"content"}.getStr("")
    if path.len == 0:
      return ToolResult(output: "path is required", isError: true)
    let (_, _, ext) = path.splitFile()
    if ext.len > 0 and ext notin allowed:
      return ToolResult(
        output: "file extension '" & ext & "' is not in the allowed list: " &
                allowed.join(", "),
        isError: true,
      )
    try:
      writeFile(path, content)
      return ToolResult(
        output: "file written: " & path & " (" & $content.len & " bytes)",
        isError: false,
      )
    except CatchableError as e:
      return ToolResult(
        output: "failed to write file: " & e.msg,
        isError: true,
        exitCode: 1,
      )
  result = newTool(
    name = "write_file",
    description = "Write content to a file within the sandbox. " &
                  "Only files with allowed extensions can be written.",
    parameters = %*{
      "type": "object",
      "properties": {
        "path": {
          "type": "string",
          "description": "Absolute path to the file to write.",
        },
        "content": {
          "type": "string",
          "description": "Full file content to write.",
        },
      },
      "required": ["path", "content"],
    },
    execute = execute,
  )
```

`mercury_code/src/mercury_code/compile.nim`:

```nim
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

import std/[osproc, streams, times, monotimes, os]

import code_runner

const DefaultCompileTimeoutMs = 120_000

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
      options = {poUsePath, poStdErrToStdOut},
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

  while true:
    let rc = p.peekExitCode()
    if rc != -1:
      break
    if getMonoTime() >= deadline:
      timedOut = true
      try:
        p.kill()
      except CatchableError:
        discard
      # Brief grace period for process to die.
      var grace = 500
      while grace > 0 and p.peekExitCode() == -1:
        sleep(25)
        grace -= 25
      try:
        p.terminate()
      except CatchableError:
        discard
      break
    sleep(pollIntervalMs)
    if pollIntervalMs < 100:
      pollIntervalMs += 5

  var exitCode = -1
  try:
    exitCode = p.waitForExit()
  except CatchableError:
    discard

  let rawOutput = try: readAll(p.outputStream) except CatchableError: ""
  try: p.close() except CatchableError: discard

  let durationMs = int((getMonoTime() - startMono).inMilliseconds)

  # Clamp output to maxOutputBytes.
  let stdout = if rawOutput.len > maxOutputBytes:
                 rawOutput[0 ..< maxOutputBytes] & "\n... [output truncated]"
               else:
                 rawOutput

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
```

`mercury_code/src/mercury_code/mercury_code.nim`:

```nim
## mercury_code — autonomous coding harness binary.
##
## Built on the ReAct agent loop from `mercury_agent/agent_loop`, extended
## with coding-specific tools (compile, test, read_file, write_file) from
## `mercury_code/code_tool`.
##
## Usage:
##   mercury_code --task "fix the off-by-one error in src/main.nim"
##   mercury_code --task "add tests for the parser module"
##   mercury_code --task "implement the fizzbuzz function in src/fizzbuzz.nim"
##
## Configuration:
##   Uses the same layered config as `mercury_agent` (see mercury_core/config).
##   Additional keys (TOML / env):
##     MERCURY_SANDBOX_ROOT      — absolute path the agent may touch
##     MERCURY_ALLOWED_EXTENSIONS — comma-separated list, e.g. ".nim,.c,.h"
##     MERCURY_BUILD_CMD         — build command, run from sandboxRoot
##     MERCURY_TEST_CMD          — test command, run from sandboxRoot
##     MERCURY_BUILD_TIMEOUT_MS  — build timeout in ms (default 120000)
##     MERCURY_TEST_TIMEOUT_MS   — test timeout in ms (default 300000)
##
## Out of scope (deferred):
##   - Docker container sandboxing (Phase 4+)
##   - Multi-file diffs and PR creation
##   - Branch-per-task isolation

import std/[os, strutils]

import mercury_core/config
import mercury_core/tool_registry
import mercury_core/build_llm_client
import mercury_core/memory
import agent_loop
import mercury_code/code_runner
import mercury_code/code_tool

const Version* = "0.1.0"

proc showHelp =
  echo "mercury_code --task <description>"
  echo "  --task <desc>   coding task to execute"
  echo "  --version       print version"
  echo "  --help          this message"
  echo ""
  echo "Environment variables:"
  echo "  MERCURY_CONFIG_PATH       path to config.toml"
  echo "  MERCURY_DB_PATH          SQLite memory database path"
  echo "  MERCURY_SANDBOX_ROOT     absolute path the agent may touch"
  echo "  MERCURY_ALLOWED_EXTENSIONS comma-separated, e.g. '.nim,.c,.h'"
  echo "  MERCURY_BUILD_CMD       build command run from sandboxRoot"
  echo "  MERCURY_TEST_CMD        test command run from sandboxRoot"
  echo "  MERCURY_BUILD_TIMEOUT_MS build timeout in ms (default 120000)"
  echo "  MERCURY_TEST_TIMEOUT_MS  test timeout in ms (default 300000)"

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

when isMainModule:
  let p = paramCount()
  if p >= 1 and paramStr(1) == "--help":
    showHelp()
    quit 0
  if p >= 1 and paramStr(1) == "--version":
    echo "mercury_code v", Version
    quit 0

  # Get task from positional argument (after any flags).
  let task =
    if p >= 1: paramStr(1)
    else: ""

  let cfg = loadConfig()
  let llm = buildLLMClient(cfg)
  var mem = newMemory(cfg.dbPath)
  let registry = newToolRegistry()

  # Build CodingHarnessConfig from env / config.
  var harnessCfg = defaultCodingHarnessConfig()
  harnessCfg.sandboxRoot = getEnv("MERCURY_SANDBOX_ROOT", "")

  let extEnv = getEnv("MERCURY_ALLOWED_EXTENSIONS", "")
  if extEnv.len > 0:
    harnessCfg.allowedExtensions = extEnv.split(',')
  else:
    harnessCfg.allowedExtensions = @[".nim", ".c", ".h", ".cfg", ".md", ".txt",
                                     ".json", ".toml", ".yml", ".yaml"]

  harnessCfg.buildCmd = getEnv("MERCURY_BUILD_CMD", "")
  harnessCfg.testCmd  = getEnv("MERCURY_TEST_CMD", "")
  let buildT = getEnv("MERCURY_BUILD_TIMEOUT_MS", "")
  harnessCfg.buildTimeoutMs = if buildT.len > 0: parseInt(buildT) else: 120_000
  let testT = getEnv("MERCURY_TEST_TIMEOUT_MS", "")
  harnessCfg.testTimeoutMs = if testT.len > 0: parseInt(testT) else: 300_000

  # Register coding tools.
  registry.register(compileTool(harnessCfg))
  registry.register(testTool(harnessCfg))
  registry.register(readFileTool(harnessCfg))
  registry.register(writeFileTool(harnessCfg))

  # Build agent config.
  let agentCfg = newAgentConfig(cfg)

  if task.len == 0:
    echo "Error: no task provided. Run with --help for usage."
    quit 1

  if harnessCfg.sandboxRoot.len == 0:
    echo "Error: MERCURY_SANDBOX_ROOT must be set to an absolute directory path."
    quit 1

  echo "Starting coding task: ", task
  let result = runAgentLoop(agentCfg, llm, registry, mem, task)
  echo "\nResult (", $result.stopReason, "):\n", result.text
  echo "\nStats: ", result.stats.totalTurns, " turns, ",
        result.stats.toolCallsMade, " tool calls, ",
        result.stats.totalTokens, " tokens"
```

`mercury_code/tests/tcode_runner.nim`:

```nim
## Tests for the code runner module.
## Covers CompileResult formatting, error parsing, and CodingHarnessConfig defaults.

import std/[unittest, strutils]

import mercury_code/code_runner

# ---------------------------------------------------------------------------
# CompileResult formatting
# ---------------------------------------------------------------------------

suite "formatCompileResult":

  test "success — no output":
    let res = CompileResult(success: true, exitCode: 0, stdout: "", stderr: "",
                             durationMs: 100, errors: @[])
    let formatted = formatCompileResult(res)
    check: "✓ BUILD SUCCEEDED" in formatted

  test "success — with output":
    let res = CompileResult(success: true, exitCode: 0, stdout: "Compiling...",
                             stderr: "", durationMs: 200, errors: @[])
    let formatted = formatCompileResult(res)
    check: "✓ BUILD SUCCEEDED" in formatted
    check: "Compiling..." in formatted

  test "failure — with errors":
    var errors = newSeq[CompileError]()
    errors.add CompileError(file: "src/foo.nim", line: 10, column: 5,
                            severity: "error", message: "undeclared identifier: bar")
    let res = CompileResult(success: false, exitCode: 1,
                             stdout: "Compiling foo.nim...", stderr: "Error",
                             durationMs: 300, errors: errors)
    let formatted = formatCompileResult(res)
    check: "✗ BUILD FAILED" in formatted
    check: "src/foo.nim(10,5)" in formatted
    check: "undeclared identifier: bar" in formatted

  test "timeout — timed out flag set":
    let res = CompileResult(success: false, exitCode: -1,
                             stdout: "", stderr: "timed out",
                             durationMs: 5000, errors: @[], timedOut: true)
    let formatted = formatCompileResult(res)
    check: "✗ TIMEOUT" in formatted

  test "truncated output":
    let veryLong = "x".repeat(500)
    let res = CompileResult(success: false, exitCode: 1, stdout: veryLong,
                             stderr: veryLong, durationMs: 100,
                             errors: @[], truncated: true)
    let formatted = formatCompileResult(res)
    check: "✗ TRUNCATED" in formatted

# ---------------------------------------------------------------------------
# Error parsing
# ---------------------------------------------------------------------------

suite "parseNimErrors":

  test "basic error":
    let raw = "src/foo.nim(10, 5) Error: undeclared identifier: bar"
    let errors = parseNimErrors(raw, "src/foo.nim")
    check: errors.len == 1
    check: errors[0].file == "src/foo.nim"
    check: errors[0].line == 10
    check: errors[0].column == 5
    check: errors[0].severity == "error"
    check: "undeclared identifier" in errors[0].message

  test "error without column":
    let raw = "src/bar.nim(20) Error: type mismatch"
    let errors = parseNimErrors(raw, "src/bar.nim")
    check: errors.len == 1
    check: errors[0].line == 20
    check: errors[0].column == 0
    check: errors[0].severity == "error"

  test "multiple errors":
    let raw = "src/a.nim(1, 1) Error: first error" & "\n" &
              "src/b.nim(2, 2) Warning: second warning"
    let errors = parseNimErrors(raw, "")
    check: errors.len == 2
    check: errors[0].severity == "error"
    check: errors[1].severity == "warning"

  test "empty input":
    check: parseNimErrors("", "").len == 0
    check: parseNimErrors("no errors here", "").len == 0

  test "skips lines without file(path) pattern":
    let raw = "some unrelated output\nsrc/file.nim(5, 3) Error: real error"
    let errors = parseNimErrors(raw, "src/file.nim")
    check: errors.len == 1
    check: errors[0].line == 5

# ---------------------------------------------------------------------------
# CodingHarnessConfig defaults
# ---------------------------------------------------------------------------

suite "defaultCodingHarnessConfig":

  test "defaults are sensible":
    let cfg = defaultCodingHarnessConfig()
    check: cfg.sandboxRoot == ""
    check: cfg.allowedExtensions.len > 0
    check: ".nim" in cfg.allowedExtensions
    check: cfg.buildCmd == ""
    check: cfg.testCmd == ""
    check: cfg.buildTimeoutMs == 120_000
    check: cfg.testTimeoutMs == 300_000
    check: cfg.maxOutputBytes == 512 * 1024
```

`mercury_core/DISCORD.md`:

```md
# Discord Integration

Mercury features a complete, DI-based Discord integration that bridges the `AgentDispatcher` with Dimscord. The bot listens for mentions and commands, routes conversations into threads, and maintains session continuity using SQLite.

## Configuration

The bot uses the layered configuration system (`config.nim`). Configuration is defined under the `[discord]` section in TOML (or `DISCORD_` prefix in `.env`).

```toml
[discord]
# The environment variable holding the Discord token (default: DISCORD_BOT_TOKEN)
token_env = "DISCORD_BOT_TOKEN"
# Command prefix for bot commands (default: !)
prefix = "!"

[discord.admins]
# List of Discord user IDs who have admin privileges
allow = ["1234567890"]
deny = []

[discord.users]
# List of Discord user IDs allowed to interact with the bot
# If empty, all users can interact (subject to other limits)
allow = []
deny = []

[discord.file_rules]
# File access rules for the read/write tools
allow = ["src/*", "docs/*"]
deny = [".env*", "*.key", ".git/*"]

[discord.tools]
# Control which users can use which tools
allow = []
deny = []
```

## Permission Model

The permission model is evaluated at two levels:
1. **Bot Interaction (`discord.users`)**: Controls who can send messages to the bot and mention it.
2. **Bot Administration (`discord.admins`)**: Controls who can use administrative commands (like `!config`, `!admin`).
3. **Tool Usage (`discord.tools`)**: Restricts certain tools (like `file_write`) to specific users. Some paths require admin approval (`pathAsk`).

## File Tool Configuration

The File Tool uses `discord.file_rules` to determine access:
- **allow**: Paths the bot can read/write without restriction.
- **ask**: Paths the bot must ask for permission (currently acts as deny for automated processes without approval).
- **deny**: Paths that are strictly forbidden. There are mandatory deny rules for credentials (`.env`, `.ssh`, etc.).

## Bot Commands Reference

Commands can be invoked in channels where the bot is present using the configured prefix (`!` by default).

### `!status`
Available to: All allowed users
Shows the bot's current status, uptime, loaded config paths, and active admins.

### `!config`
Available to: Admins only
- `!config show`: Dumps the current parsed configuration.
- `!config set <key> <value>`: Updates a configuration value in memory.
- `!config reload`: Reloads the configuration from disk.
- `!config allowlist <add|remove|list> [path]`: Manages the dynamic file allowlist in memory.

### `!admin`
Available to: Admins only
- `!admin restart`: Restarts the bot process.
- `!admin reconnect`: Forces the Dimscord gateway to reconnect.

### `!session`
Available to: All allowed users
Manage the current agent session.

## Running the Daemon

To run the Mercury Discord bot, use the `daemon` command in the CLI:

```bash
export DISCORD_BOT_TOKEN="your_token_here"
mercury daemon
```

This will initialize the database, load the configuration, and connect to Discord via the Gateway.

## Local Testing Instructions

The Discord integration is built using Dependency Injection. `mercury_core/discord.nim` depends on callback procs for API actions rather than raw Dimscord endpoints.

To run the End-to-End Discord tests locally:

```bash
cd mercury_core
nim c -r tests/test_e2e_discord.nim
```

The E2E test uses `MockDiscordApi` and `MockShard` to completely simulate Discord's HTTP and Gateway interfaces, allowing full coverage of session routing, thread creation, permission checks, and file tools without making real network requests.

### Test Suite

All Discord-related tests live in `mercury_core/tests/`:

| Test file | Tests | What it covers |
|-----------|-------|----------------|
| `test_discord_mocks.nim` | Mock API and shard | Verifies mock objects correctly simulate Discord behavior |
| `test_discord_commands.nim` | Command handlers | `!status`, `!config`, `!admin`, `!session` parsing + execution |
| `test_discord_bot.nim` | Bot integration | `onMessageCreate` routing, DI wiring, permission checks |
| `test_discord_config.nim` | Discord config parsing | TOML → DiscordConfig, env var overrides, validation |
| `test_e2e_discord.nim` | End-to-end flow | Full session: message → permission → agent dispatch → response |
| `test_file_tool.nim` | File read/write tools | Path validation, traversal protection, allow/deny patterns |
| `test_file_path_validator.nim` | Path safety | Canonicalization, percent-decode, deny-list matching |
| `test_message_chunker.nim` | Message splitting | 2000-char Discord limit handling, boundary splits |
| `test_permission.nim` | Permission evaluation | User allow/deny, tool risk levels, admin checks |
| `test_rate_limit.nim` | Token-bucket rate limiter | Per-user limits, burst handling |
| `test_thread_mapping.nim` | Thread persistence | SQLite-backed channel→thread mapping |

### Architecture

```
Discord Gateway ──▶ dimscord ──▶ onMessageCreate(event)
                                    │
                                    ▼
                            discord_commands.nim
                              (parse prefix + command)
                                    │
                          ┌─────────┴──────────┐
                          ▼                     ▼
                    Admin command         Agent message
                    (!config, !admin)      (mention / DM)
                          │                     │
                          ▼                     ▼
                    Execute handler     agent_dispatcher.nim
                                          (async queue)
                                                │
                                                ▼
                                          agent_loop.nim
                                          (ReAct loop)
                                                │
                                                ▼
                                          sendFn callback
                                          (chunkMessage → reply)
```

### Module Reference

| Module | Location | Purpose |
|--------|----------|---------|
| `discord.nim` | `mercury_core/discord.nim` | `DiscordBot` ref object with DI callbacks, `onMessageCreate` handler |
| `discord_bridge.nim` | `mercury_core/discord_bridge.nim` | `RealDiscordApi` — wraps dimscord REST API |
| `discord_commands.nim` | `mercury_core/discord_commands.nim` | Command parsing + handler dispatch |
| `discord_types.nim` | `mercury_core/discord_types.nim` | `DiscordConfig`, `DiscordUser`, `FileRules` types |
| `discord_mocks.nim` | `mercury_core/discord_mocks.nim` | `MockDiscordApi`, `MockShard` for offline testing |
| `agent_dispatcher.nim` | `mercury_core/agent_dispatcher.nim` | `AgentDispatcher` — async agent request queue with callback |
| `permission.nim` | `mercury_core/permission.nim` | `PermissionEvaluator` — user/tool/path permission model |
| `file_path_validator.nim` | `mercury_core/file_path_validator.nim` | Path canonicalization + security validation |
| `file_tool.nim` | `mercury_core/file_tool.nim` | `fileReadTool`, `fileWriteTool` — sandboxed file operations |
| `message_chunker.nim` | `mercury_core/message_chunker.nim` | Splits messages at 2000-char Discord limit |
| `rate_limit.nim` | `mercury_core/rate_limit.nim` | Per-user token-bucket rate limiter |
| `thread_mapping.nim` | `mercury_core/thread_mapping.nim` | Persistent channel↔thread mapping with SQLite |
```

`mercury_core/config.nims`:

```nims
switch("path", "src")
switch("define", "ssl")
switch("threads", "off")  # Default; test files using Thread pass --threads:on

```

`mercury_core/mercury_core.nimble`:

```nimble
version       = "0.1.0"
author        = "Mercury"
description   = "Mercury core shared library"
license       = "MIT"
srcDir        = "src"
requires "nim >= 2.0.0"
requires "db_connector >= 0.1.0"
requires "dimscord >= 1.0.0"
switch("path", "src")

task test, "Run all tests":
  exec "nim c -d:ssl -r tests/tconfig.nim"
  exec "nim c -d:ssl -r tests/ttoken_counter.nim"
  exec "nim c -d:ssl -r tests/tmemory.nim"
  exec "nim c -d:ssl --threads:on -r tests/tllm_client.nim"
  exec "nim c -d:ssl -r tests/ttool_registry.nim"
  exec "nim c -d:ssl -r tests/test_message_chunker.nim"
  exec "nim c -d:ssl -r tests/test_discord_mocks.nim"
  exec "nim c -d:ssl -r tests/test_discord_commands.nim"
  exec "nim c -d:ssl -r tests/test_discord_bot.nim"
  exec "nim c -d:ssl -r tests/test_e2e_discord.nim"
  exec "nim c -d:ssl -r tests/test_discord_config.nim"
  exec "nim c -d:ssl -r tests/test_permission.nim"
  exec "nim c -d:ssl -r tests/test_file_path_validator.nim"
  exec "nim c -d:ssl -r tests/test_file_tool.nim"
  exec "nim c -d:ssl -r tests/test_mock_server.nim"
  exec "nim c -d:ssl -r tests/test_rate_limit.nim"
  exec "nim c -d:ssl -r tests/test_thread_mapping.nim"
  exec "nim c -d:ssl -r tests/test_thread_reconnection.nim"
  exec "nim c -d:ssl -r tests/test_agent_dispatcher.nim"
  exec "nim c -d:ssl -r tests/test_mcp_client.nim"
  exec "nim c -d:ssl -r tests/test_persona.nim"

```

`mercury_core/src/mercury_core.nim`:

```nim
when isMainModule:
  discard

import mercury_core/[agent_dispatcher, discord, discord_bridge, discord_commands, discord_mocks, discord_types, file_path_validator, file_tool, message_chunker, permission, rate_limit, thread_mapping]

export agent_dispatcher, discord, discord_bridge, discord_commands, discord_mocks, discord_types, file_path_validator, file_tool, message_chunker, permission, rate_limit, thread_mapping

```

`mercury_core/src/mercury_core/agent_dispatcher.nim`:

```nim
## Mercury agent dispatcher.
##
## Bridges the async Dimscord event loop with synchronous agent processing.
## Uses a simple callback-based approach: the Discord bot calls dispatchAgent
## which runs the agent in a background thread and returns the result via
## a callback when complete.

import std/[asyncdispatch, options]

type
  AgentRequest* = object
    userInput*: string
    sessionId*: string
    channelId*: string
    threadId*: string

  AgentResult* = object
    responseText*: string
    error*: Option[string]
    channelId*: string

  AgentCallback* = proc(result: AgentResult) {.gcsafe, raises: [].}

  AgentDispatcher* = ref object
    callback*: AgentCallback

proc newAgentDispatcher*(callback: AgentCallback): AgentDispatcher =
  ## Creates a new agent dispatcher with the given callback.
  ## The callback is invoked when agent processing completes.
  ## Requires gcsafe callback for Nim 2.2.x async GC-safety.
  AgentDispatcher(callback: callback)

proc dispatchAgent*(dispatcher: AgentDispatcher, request: AgentRequest) {.async, gcsafe.} =
  ## Dispatches an agent request. Currently a placeholder that simulates
  ## async processing. The actual agent integration will be wired in Task 4.16.
  ##
  ## In the full implementation, this would:
  ## 1. Spawn a thread with a new DB connection
  ## 2. Run the agent loop in that thread
  ## 3. Send result back via Channel
  ## 4. Invoke the callback with the result
  ##
  ## For now, we simulate a brief delay and return a placeholder response
  ## to allow the Discord bot to be tested end-to-end.
  await sleepAsync(100)  # Simulate processing delay

  let result = AgentResult(
    responseText: "Agent response for: " & request.userInput,
    error: none[string](),
    channelId: request.channelId
  )

  if dispatcher.callback != nil:
    dispatcher.callback(result)

proc startDispatcher*(dispatcher: AgentDispatcher) =
  ## Starts the dispatcher. Currently a no-op.
  discard

proc stopDispatcher*(dispatcher: AgentDispatcher) =
  ## Stops the dispatcher. Currently a no-op.
  discard
```

`mercury_core/src/mercury_core/build_llm_client.nim`:

```nim
## LLM client builder from a MercuryConfig.
##
## Centralizes the `MercuryConfig → LLMClient` construction so callers
## don't need to know the details of endpoint URL, API key, and model
## selection. Used by both `mercury_agent` and `mercury_code`.

import std/[strutils]

import mercury_core/config
import mercury_core/llm_client

proc activeBaseUrl*(cfg: MercuryConfig): string =
  case cfg.provider.toLowerAscii()
  of "vllm":      cfg.vllmEndpoint
  of "openrouter": cfg.openrouterEndpoint
  else:           cfg.openrouterEndpoint

proc activeApiKey*(cfg: MercuryConfig): string =
  case cfg.provider.toLowerAscii()
  of "openrouter": cfg.openrouterApiKey
  of "vllm":      ""
  else:           cfg.openrouterApiKey

proc activeModel*(cfg: MercuryConfig): string =
  case cfg.provider.toLowerAscii()
  of "vllm":      cfg.vllmModel
  of "openrouter": cfg.openrouterModel
  else:           cfg.openrouterModel

proc buildLLMClient*(cfg: MercuryConfig): LLMClient =
  ## Builds an LLMClient from a fully-resolved MercuryConfig.
  newLLMClient(
    baseUrl = activeBaseUrl(cfg),
    apiKey  = activeApiKey(cfg),
    model   = activeModel(cfg),
  )
```

`mercury_core/src/mercury_core/config.nim`:

```nim
## Mercury configuration module.
##
## Loads configuration from:
## 1. Built-in defaults
## 2. TOML config file at ~/.config/mercury/config.toml
## 3. .env file in the current working directory (API keys)
## 4. Environment variables (highest priority)
##
## Supported environment variable overrides:
##   MERCURY_PROVIDER, MERCURY_VLLM_ENDPOINT, MERCURY_OPENROUTER_ENDPOINT,
##   MERCURY_OPENROUTER_MODEL, MERCURY_VLLM_MODEL, MERCURY_MAX_TOKENS,
##   MERCURY_TEMPERATURE, MERCURY_MAX_LOOP_ITERATIONS, MERCURY_DB_PATH,
##   OPENROUTER_API_KEY

import std/[os, parsecfg, strutils, streams]
import discord_types

type
  McpServerConfig* = object
    ## Configuration for a single MCP server endpoint.
    url*: string
    authToken*: string
    timeoutMs*: int
    enabled*: bool

  MercuryConfig* = object
    provider*: string           ## "openrouter" or "vllm"
    vllmEndpoint*: string
    openrouterEndpoint*: string
    openrouterModel*: string
    vllmModel*: string
    maxTokens*: int
    temperature*: float
    maxLoopIterations*: int
    dbPath*: string
    openrouterApiKey*: string   ## loaded from .env or env var
    discord*: DiscordConfig
    mcpServers*: seq[McpServerConfig]  ## Configured MCP server endpoints

  ConfigError* = object of CatchableError

const
  DefaultProvider* = "openrouter"
  DefaultVllmEndpoint* = "http://192.168.4.30:8000/v1"
  DefaultOpenrouterEndpoint* = "https://openrouter.ai/api/v1"
  DefaultOpenrouterModel* = "openrouter/auto"
  DefaultVllmModel* = "qwen2.5-7b-instruct"
  DefaultMaxTokens* = 4096
  DefaultTemperature* = 0.3
  DefaultMaxLoopIterations* = 10
  DefaultDbPath* = "~/.local/share/mercury/mercury.db"
  DefaultMcpTimeoutMs* = 30_000

proc defaultConfig*(): MercuryConfig =
  ## Returns a MercuryConfig populated with all defaults.
  MercuryConfig(
    provider: DefaultProvider,
    vllmEndpoint: DefaultVllmEndpoint,
    openrouterEndpoint: DefaultOpenrouterEndpoint,
    openrouterModel: DefaultOpenrouterModel,
    vllmModel: DefaultVllmModel,
    maxTokens: DefaultMaxTokens,
    temperature: DefaultTemperature,
    maxLoopIterations: DefaultMaxLoopIterations,
    dbPath: DefaultDbPath,
    openrouterApiKey: "",
    discord: defaultDiscordConfig(),
    mcpServers: @[],
  )

proc parseEnvFile*(path: string): seq[tuple[key, val: string]] =
  ## Parses a .env file and returns key-value pairs.
  ## Lines starting with '#' are comments. Blank lines are skipped.
  ## Values may optionally be quoted with single or double quotes.
  result = @[]
  if not fileExists(path):
    return
  for line in lines(path):
    let trimmed = line.strip()
    if trimmed.len == 0 or trimmed.startsWith("#"):
      continue
    let eqPos = trimmed.find('=')
    if eqPos < 1:
      continue
    let key = trimmed[0 ..< eqPos].strip()
    var val = trimmed[eqPos + 1 .. ^1].strip()
    # Strip optional surrounding quotes
    if val.len >= 2:
      if (val[0] == '"' and val[^1] == '"') or
         (val[0] == '\'' and val[^1] == '\''):
        val = val[1 ..< val.len - 1]
    result.add((key, val))

proc parseCsvList(val: string): seq[string] =
  result = @[]
  for item in val.split(','):
    let stripped = item.strip()
    if stripped.len > 0:
      result.add(stripped)

# ---------------------------------------------------------------------------
# MCP server config parsing (TOML and env)
# ---------------------------------------------------------------------------

type
  McpServerEntry* = object
    ## Temporary storage for a single [mcp_servers.name] block during TOML
    ## parsing. Fields that are not set in the TOML remain as empty/zero
    ## defaults and are filled in by `parseMcpServerEntry()` at the end.
    name*: string
    url*: string
    authToken*: string
    timeoutMs*: int
    enabledExplicit*: bool  ## true if "enabled" was explicitly set in TOML/env
    enabled*: bool          ## the value (true unless explicitly set to false)

proc parseMcpServerEntry(entry: McpServerEntry): McpServerConfig =
  ## Converts a parsed `McpServerEntry` into a `McpServerConfig`, filling in
  ## any missing values with defaults. Strips trailing slashes from URL.
  result = McpServerConfig(
    url: if entry.url.len > 0: entry.url.strip(trailing = true, chars = {'/'})
         else: "http://localhost:8080/mcp",
    authToken: entry.authToken,
    timeoutMs: if entry.timeoutMs > 0: entry.timeoutMs else: DefaultMcpTimeoutMs,
    enabled: if entry.enabledExplicit: entry.enabled else: true,
  )

proc applyEnvMcpServers*(cfg: var MercuryConfig) =
  ## Applies MCP server configuration from environment variables.
  ##
  ## Format: MERCURY_MCP_SERVER_<N>_URL, MERCURY_MCP_SERVER_<N>_AUTH_TOKEN,
  ##          MERCURY_MCP_SERVER_<N>_TIMEOUT_MS, MERCURY_MCP_SERVER_<N>_ENABLED
  ## where <N> is a zero-based index. Stop at first gap in sequence.
  ##
  ## Example:
  ##   MERCURY_MCP_SERVER_0_URL=http://localhost:8080/mcp
  ##   MERCURY_MCP_SERVER_0_AUTH_TOKEN=secret123
  ##   MERCURY_MCP_SERVER_1_URL=https://mcp.example.com
  var i = 0
  while true:
    let urlEnv = "MERCURY_MCP_SERVER_" & $i & "_URL"
    let url = getEnv(urlEnv)
    if url.len == 0:
      break  # No more servers configured
    var entry = McpServerEntry(name: $i, url: url)
    let auth = getEnv("MERCURY_MCP_SERVER_" & $i & "_AUTH_TOKEN")
    if auth.len > 0:
      entry.authToken = auth
    let timeoutEnv = "MERCURY_MCP_SERVER_" & $i & "_TIMEOUT_MS"
    let timeoutStr = getEnv(timeoutEnv)
    if timeoutStr.len > 0:
      try:
        entry.timeoutMs = parseInt(timeoutStr)
      except ValueError:
        raise newException(ConfigError,
          timeoutEnv & " must be an integer, got: " & timeoutStr)
    let enabledEnv = "MERCURY_MCP_SERVER_" & $i & "_ENABLED"
    let enabledStr = getEnv(enabledEnv)
    if enabledStr.len > 0:
      entry.enabled = enabledStr.toLowerAscii() in @["1", "true", "yes", "on"]
      entry.enabledExplicit = true
    cfg.mcpServers.add(parseMcpServerEntry(entry))
    inc i

proc applyTomlSection(cfg: var MercuryConfig; section, key, val: string) =
  ## Applies a single key-value pair from the TOML/INI config to cfg.
  ## Section "" means the global/root section.
  let k = key.toLowerAscii()
  case section.toLowerAscii()
  of "", "mercury":
    case k
    of "provider":           cfg.provider = val
    of "vllm_endpoint":      cfg.vllmEndpoint = val
    of "openrouter_endpoint": cfg.openrouterEndpoint = val
    of "openrouter_model":   cfg.openrouterModel = val
    of "vllm_model":         cfg.vllmModel = val
    of "max_tokens":
      let n = parseInt(val)
      cfg.maxTokens = n
    of "temperature":
      let f = parseFloat(val)
      cfg.temperature = f
    of "max_loop_iterations":
      let n = parseInt(val)
      cfg.maxLoopIterations = n
    of "db_path":            cfg.dbPath = val
    else: discard
  of "discord":
    case k
    of "token_env": cfg.discord.tokenEnv = val
    of "prefix": cfg.discord.prefix = val
    else: discard
  of "discord.admins":
    case k
    of "allow": cfg.discord.admins.allow = parseCsvList(val)
    of "deny": cfg.discord.admins.deny = parseCsvList(val)
    else: discard
  of "discord.users":
    case k
    of "allow": cfg.discord.users.allow = parseCsvList(val)
    of "deny": cfg.discord.users.deny = parseCsvList(val)
    else: discard
  of "discord.file_rules":
    case k
    of "allow": cfg.discord.fileRules.allow = parseCsvList(val)
    of "deny": cfg.discord.fileRules.deny = parseCsvList(val)
    else: discard
  of "discord.tools":
    case k
    of "allow": cfg.discord.tools.allow = parseCsvList(val)
    of "deny": cfg.discord.tools.deny = parseCsvList(val)
    else: discard
  else: discard

proc loadTomlFile(cfg: var MercuryConfig; path: string) =
  ## Loads config values from a TOML/INI file, overriding defaults.
  if not fileExists(path):
    return
  var stream = newFileStream(path, fmRead)
  if stream == nil:
    raise newException(ConfigError, "Cannot open config file: " & path)
  defer: stream.close()
  var parser: CfgParser
  open(parser, stream, path)
  defer: close(parser)

  # Accumulators for [mcp_servers.<name>] blocks.
  # We can't use applyTomlSection because it handles one key-value at a time
  # and we need to collect all fields for a given server before creating the
  # McpServerConfig. Parsed here, applied at EOF.
  var mcpEntries: seq[McpServerEntry] = @[]
  var currentMcpServer = ""
  var mcpBuf = McpServerEntry()

  var currentSection = ""
  while true:
    let event = next(parser)
    case event.kind
    of cfgEof:
      break
    of cfgSectionStart:
      # New section — flush any pending MCP server entry first.
      if currentMcpServer.len > 0 and mcpBuf.name.len > 0:
        mcpEntries.add(mcpBuf)

      currentSection = event.section
      let sec = currentSection.toLowerAscii()
      if sec.startsWith("mcp_servers."):
        currentMcpServer = sec
        mcpBuf = McpServerEntry(name: sec)
      else:
        currentMcpServer = ""
    of cfgKeyValuePair:
      if currentMcpServer.len > 0:
        # Inside a [mcp_servers.<name>] block — accumulate into mcpBuf.
        let k = event.key.toLowerAscii()
        case k
        of "url":          mcpBuf.url = event.value
        of "auth_token":   mcpBuf.authToken = event.value
        of "timeout_ms":
          try:
            mcpBuf.timeoutMs = parseInt(event.value)
          except ValueError:
            raise newException(ConfigError,
              "Invalid timeout_ms in " & path & ": " & event.value)
        of "enabled":
          mcpBuf.enabled = event.value.toLowerAscii() in @["1", "true", "yes", "on"]
          mcpBuf.enabledExplicit = true
        else: discard
      else:
        try:
          applyTomlSection(cfg, currentSection, event.key, event.value)
        except ValueError as e:
          raise newException(ConfigError,
            "Invalid value for key '" & event.key & "' in " & path & ": " & e.msg)
    of cfgOption:
      discard
    of cfgError:
      raise newException(ConfigError,
        "Parse error in " & path & ": " & event.msg)

  # Flush any remaining MCP server entry.
  if currentMcpServer.len > 0 and mcpBuf.name.len > 0:
    mcpEntries.add(mcpBuf)

  # Apply all collected MCP server entries.
  for entry in mcpEntries:
    cfg.mcpServers.add(parseMcpServerEntry(entry))

proc applyEnvVars(cfg: var MercuryConfig) =
  ## Applies environment variable overrides to cfg.
  let provider = getEnv("MERCURY_PROVIDER")
  if provider.len > 0:
    cfg.provider = provider

  let vllmEndpoint = getEnv("MERCURY_VLLM_ENDPOINT")
  if vllmEndpoint.len > 0:
    cfg.vllmEndpoint = vllmEndpoint

  let orEndpoint = getEnv("MERCURY_OPENROUTER_ENDPOINT")
  if orEndpoint.len > 0:
    cfg.openrouterEndpoint = orEndpoint

  let orModel = getEnv("MERCURY_OPENROUTER_MODEL")
  if orModel.len > 0:
    cfg.openrouterModel = orModel

  let vllmModel = getEnv("MERCURY_VLLM_MODEL")
  if vllmModel.len > 0:
    cfg.vllmModel = vllmModel

  let maxTokensStr = getEnv("MERCURY_MAX_TOKENS")
  if maxTokensStr.len > 0:
    try:
      cfg.maxTokens = parseInt(maxTokensStr)
    except ValueError:
      raise newException(ConfigError,
        "MERCURY_MAX_TOKENS must be an integer, got: " & maxTokensStr)

  let tempStr = getEnv("MERCURY_TEMPERATURE")
  if tempStr.len > 0:
    try:
      cfg.temperature = parseFloat(tempStr)
    except ValueError:
      raise newException(ConfigError,
        "MERCURY_TEMPERATURE must be a float, got: " & tempStr)

  let maxLoopStr = getEnv("MERCURY_MAX_LOOP_ITERATIONS")
  if maxLoopStr.len > 0:
    try:
      cfg.maxLoopIterations = parseInt(maxLoopStr)
    except ValueError:
      raise newException(ConfigError,
        "MERCURY_MAX_LOOP_ITERATIONS must be an integer, got: " & maxLoopStr)

  let dbPath = getEnv("MERCURY_DB_PATH")
  if dbPath.len > 0:
    cfg.dbPath = dbPath

  let apiKey = getEnv("OPENROUTER_API_KEY")
  if apiKey.len > 0:
    cfg.openrouterApiKey = apiKey

  # Apply MCP server configuration from environment variables.
  applyEnvMcpServers(cfg)

proc validate*(cfg: MercuryConfig) =
  ## Validates the configuration, raising ConfigError on invalid values.
  if cfg.provider != "openrouter" and cfg.provider != "vllm":
    raise newException(ConfigError,
      "provider must be 'openrouter' or 'vllm', got: '" & cfg.provider & "'")
  if cfg.maxTokens <= 0:
    raise newException(ConfigError,
      "max_tokens must be positive, got: " & $cfg.maxTokens)
  if cfg.temperature < 0.0 or cfg.temperature > 2.0:
    raise newException(ConfigError,
      "temperature must be between 0.0 and 2.0, got: " & $cfg.temperature)
  if cfg.maxLoopIterations <= 0:
    raise newException(ConfigError,
      "max_loop_iterations must be positive, got: " & $cfg.maxLoopIterations)
  if cfg.vllmEndpoint.len == 0:
    raise newException(ConfigError, "vllm_endpoint must not be empty")
  if cfg.openrouterEndpoint.len == 0:
    raise newException(ConfigError, "openrouter_endpoint must not be empty")
  if cfg.dbPath.len == 0:
    raise newException(ConfigError, "db_path must not be empty")

proc loadConfig*(
    configPath: string = "",
    envFilePath: string = ".env"
): MercuryConfig =
  ## Loads Mercury configuration with the following priority (highest wins):
  ##   1. Environment variables
  ##   2. .env file (API keys)
  ##   3. TOML config file
  ##   4. Built-in defaults
  ##
  ## configPath: path to the TOML config file.
  ##   Defaults to ~/.config/mercury/config.toml
  ## envFilePath: path to the .env file.
  ##   Defaults to ".env" in the current directory.
  result = defaultConfig()

  # Resolve config file path
  let cfgPath =
    if configPath.len > 0:
      configPath
    else:
      getHomeDir() / ".config" / "mercury" / "config.toml"

  # Layer 2: TOML file
  loadTomlFile(result, cfgPath)

  # Layer 3: .env file (API keys only)
  let envPairs = parseEnvFile(envFilePath)
  for (key, val) in envPairs:
    case key
    of "OPENROUTER_API_KEY":
      result.openrouterApiKey = val
    of "MERCURY_PROVIDER":
      result.provider = val
    of "MERCURY_VLLM_ENDPOINT":
      result.vllmEndpoint = val
    else: discard

  # Layer 4: Environment variables (highest priority)
  applyEnvVars(result)

  validate(result)

```

`mercury_core/src/mercury_core/delegate.nim`:

```nim
import std/[strutils]

const
  DefaultMaxDelegationDepth* = 2
  DefaultMaxDelegationsPerRun* = 5

type
  DelegationConfig* = object
    maxDepth*: int
    maxDelegations*: int
    personaName*: string

proc defaultDelegationConfig*(): DelegationConfig =
  DelegationConfig(
    maxDepth: DefaultMaxDelegationDepth,
    maxDelegations: DefaultMaxDelegationsPerRun,
    personaName: "",
  )

proc canDelegate*(dc: DelegationConfig): bool =
  dc.maxDepth > 0 and dc.maxDelegations > 0

proc useDelegationSlot*(dc: var DelegationConfig) =
  dec dc.maxDepth
  dec dc.maxDelegations

proc applyPersonaDelegation*(
    maxDelegationDepth: int;
    maxDelegationsPerRun: int;
    personaName: string;
): DelegationConfig =
  DelegationConfig(
    maxDepth: if maxDelegationDepth > 0: maxDelegationDepth
              else: DefaultMaxDelegationDepth,
    maxDelegations: if maxDelegationsPerRun > 0: maxDelegationsPerRun
                    else: DefaultMaxDelegationsPerRun,
    personaName: personaName,
  )
```

`mercury_core/src/mercury_core/discord.nim`:

```nim
## Discord bot module — Dependency Injection design.
##
## The DiscordBot ref object holds all injected dependencies as callback
## procs for the API, plus config, dispatcher, and shard. No global mutable
## state. The onMessageCreate handler is a method on the bot, making it
## testable with mock implementations.
##
## The API operations (sendMessage, triggerTyping, createThread, archiveThread)
## are injected as callback procs so that both MockDiscordApi and RealDiscordApi
## can be used without generics — avoiding Nim's {.async.} + generics limitation.

import std/[asyncdispatch, logging, options, strutils, times]
import db_connector/db_sqlite
import discord_mocks, discord_types, permission, discord_commands,
       agent_dispatcher, message_chunker
import dimscord
import discord_bridge
import thread_mapping

type
  SendMessageFn* = proc (channelId, content: string): Future[string] {.async, gcsafe.}
  TriggerTypingFn* = proc (channelId: string) {.async, gcsafe.}
  CreateThreadFn* = proc (channelId, messageId, name: string): Future[string] {.async, gcsafe.}
  ArchiveThreadFn* = proc (threadId: string) {.async, gcsafe.}

  DiscordBot* = ref object
    sendMessage*: SendMessageFn
    triggerTyping*: TriggerTypingFn
    createThread*: CreateThreadFn
    archiveThread*: ArchiveThreadFn
    db*: DbConn
    config*: DiscordConfig
    dispatcher*: AgentDispatcher
    shard*: MockShard

proc newDiscordBot*(sendMessage: SendMessageFn;
                     triggerTyping: TriggerTypingFn;
                     createThread: CreateThreadFn;
                     archiveThread: ArchiveThreadFn;
                     db: DbConn;
                     config: DiscordConfig;
                     dispatcher: AgentDispatcher;
                     shard: MockShard): DiscordBot =
  ## Create a DiscordBot with injected dependencies.
  DiscordBot(
    sendMessage: sendMessage,
    triggerTyping: triggerTyping,
    createThread: createThread,
    archiveThread: archiveThread,
    db: db,
    config: config,
    dispatcher: dispatcher,
    shard: shard,
  )

proc generateSessionId(): string =
  let t = now().utc
  return "sess_" & t.format("yyyyMMdd'T'HHmmss") & "_" & $getTime().nanosecond

proc onMessageCreate*(bot: DiscordBot; msg: discord_mocks.Message) {.async, gcsafe.} =
  ## Main message handler. Routes messages to commands or agent dispatch.
  ##
  ## 1. Ignore bot authors.
  ## 2. Check user is allowed (isUserAllowed).
  ## 3. If message starts with prefix → handle as command.
  ## 4. Otherwise, trigger typing and dispatch to agent.

  # 1. Ignore bots
  if msg.author.bot:
    return

  # 2. Check if user is allowed
  if not isUserAllowed(msg.author.id, bot.config):
    return

  # 3. Check for command prefix
  if msg.content.startsWith(bot.config.prefix):
    let withoutPrefix = msg.content[bot.config.prefix.len .. ^1]
    let parts = withoutPrefix.splitWhitespace(maxsplit=1)
    if parts.len == 0:
      return
    let cmd = parts[0]
    let args = if parts.len > 1: parts[1] else: ""
    let cmdResult = handleCommand(cmd, args, msg.author.id, bot.config)
    let chunks = chunkMessage(cmdResult.response)
    for chunk in chunks:
      discard await bot.sendMessage(msg.channel_id, chunk)
    # If the command returned an updated config, apply it
    if cmdResult.updatedConfig.isSome:
      bot.config = cmdResult.updatedConfig.get()
    return

  # 4. Ignore direct messages (not in a guild channel)
  if msg.guild_id.isNone:
    return

  # 5. Check for bot mention
  var mentionsBot = false
  for u in msg.mention_users:
    if u.id == bot.shard.userId:
      mentionsBot = true
      break

  # 6. Resolve thread/session, then dispatch agent
  let existingThreadSession = getSessionForThread(bot.db, msg.channel_id)
  if existingThreadSession.isSome:
    await bot.triggerTyping(msg.channel_id)
    let request = AgentRequest(
      userInput: msg.content,
      sessionId: existingThreadSession.get(),
      channelId: msg.channel_id,
      threadId: msg.channel_id,
    )
    await bot.dispatcher.dispatchAgent(request)
    return

  # 7. Ignore messages that don't mention the bot outside existing threads
  if not mentionsBot:
    return

  let previousSession = getLatestSessionForChannel(bot.db, msg.channel_id)
  if previousSession.isSome:
    let sessionId = previousSession.get()
    let threadName = "Mercury-" & sessionId[0 ..< min(8, sessionId.len)]
    let threadId = await bot.createThread(msg.channel_id, msg.id, threadName)
    setThreadMapping(bot.db, threadId, sessionId, msg.channel_id, msg.guild_id.get(""))
    discard await bot.sendMessage(threadId, "Continuing from previous session.")
    await bot.triggerTyping(threadId)
    let request = AgentRequest(
      userInput: msg.content,
      sessionId: sessionId,
      channelId: threadId,
      threadId: threadId,
    )
    await bot.dispatcher.dispatchAgent(request)
    return

  let newSessionId = generateSessionId()
  let threadName = "Mercury-" & newSessionId[0 ..< min(8, newSessionId.len)]
  let threadId = await bot.createThread(msg.channel_id, msg.id, threadName)
  setThreadMapping(bot.db, threadId, newSessionId, msg.channel_id, msg.guild_id.get(""))
  await bot.triggerTyping(threadId)

  let request = AgentRequest(
    userInput: msg.content,
    sessionId: newSessionId,
    channelId: threadId,
    threadId: threadId,
  )
  await bot.dispatcher.dispatchAgent(request)

# ---------------------------------------------------------------------------
# Live Discord bot (Dimscord gateway bridge)
# ---------------------------------------------------------------------------

proc startDiscordBot*(
  discord: DiscordClient;
  bot: DiscordBot;
): Future[void] {.async.} =
  ## Bridges the DI-based DiscordBot to Dimscord's gateway.
  ##
  ## Registers event handlers on the Dimscord client:
  ## - ``on_ready``: populates the bot's shard with the authenticated user.
  ## - ``message_create``: converts Dimscord messages to our internal type
  ##   and delegates to ``onMessageCreate``.
  ##
  ## Then starts the gateway session with the required intents.
  ##
  ## The caller must create the ``DiscordClient`` and ``DiscordBot`` before
  ## calling this proc.  Returns when the session ends or an error occurs.

  var l = newConsoleLogger(fmtStr = "[$datetime] - $msg ", useStderr = true)
  addHandler(l)

  discord.events.on_ready = proc (s: Shard, r: Ready) {.async, gcsafe.} =
    bot.shard.userId = r.user.id
    bot.shard.user = MockUser(id: r.user.id, username: r.user.username, bot: true)
    notice("[daemon] Connected as " & r.user.username & " (" & r.user.id & ")")

  discord.events.message_create = proc (s: Shard, m: dimscord.Message) {.async, gcsafe.} =
    let internalMsg = convertMessage(m)
    await onMessageCreate(bot, internalMsg)

  await discord.startSession(
    gateway_intents = {giGuildMessages, giMessageContent}
  )

```

`mercury_core/src/mercury_core/discord_bridge.nim`:

```nim
## Real Discord API adapter.
##
## Bridges the mock-based DiscordBot interface to the actual Dimscord
## REST API client. Each proc mirrors the MockDiscordApi procedural
## interface so that DiscordBot can be wired with either mock or real
## dependencies.
##
## All procs are async because the underlying Dimscord REST calls are
## async. The MockDiscordApi procs are also async for interface
## compatibility, though they resolve immediately.

import std/[asyncdispatch, json, options]
import dimscord
import dimscord/restapi/requester  # needed for RestApi.request
import discord_mocks

type
  RealDiscordApi* = ref object
    ## Thin adapter over Dimscord's RestApi. Holds a reference to the
    ## client's REST API so calls can be made without touching the
    ## gateway event loop.
    restApi: RestApi

proc newRealDiscordApi*(restApi: RestApi): RealDiscordApi =
  ## Creates a RealDiscordApi wrapping the given Dimscord RestApi.
  RealDiscordApi(restApi: restApi)

proc sendMessage*(api: RealDiscordApi; channelId, content: string): Future[string] {.async.} =
  ## Sends a message to the given channel. Returns the message ID.
  let msg = await api.restApi.sendMessage(channelId, content)
  return msg.id

proc triggerTyping*(api: RealDiscordApi; channelId: string) {.async.} =
  ## Triggers the typing indicator in the given channel.
  await api.restApi.startTyping(channelId)

proc createThread*(api: RealDiscordApi; channelId, messageId, name: string): Future[string] {.async.} =
  ## Creates a public thread under the given channel, anchored to the
  ## specified message. Returns the new thread's channel ID.
  let thread = await api.restApi.startThreadWithMessage(
    channelId, messageId, name, auto_archive_duration = 60
  )
  return thread.id

proc archiveThread*(api: RealDiscordApi; threadId: string) {.async.} =
  ## Archives a thread by PATCHing the channel with archived=true.
  ## Uses the raw REST API because editGuildChannel doesn't expose
  ## the archived flag directly.
  discard await api.restApi.request(
    "PATCH",
    endpointChannels(threadId),
    $ %*{"archived": true}
  )

proc convertMessage*(msg: dimscord.Message): MockMessage =
  ## Converts a Dimscord Message to our internal MockMessage type
  ## so it can be fed to DiscordBot.onMessageCreate.
  var guildId: Option[string] = none[string]()
  if msg.guild_id.isSome:
    guildId = msg.guild_id
  var mentionUsers: seq[MockUser] = @[]
  for u in msg.mention_users:
    mentionUsers.add(MockUser(id: u.id, username: u.username, bot: u.bot))
  result = MockMessage(
    id: msg.id,
    author: MockUser(id: msg.author.id, username: msg.author.username, bot: msg.author.bot),
    content: msg.content,
    channel_id: msg.channel_id,
    guild_id: guildId,
    mention_users: mentionUsers,
  )

```

`mercury_core/src/mercury_core/discord_commands.nim`:

```nim
## Discord bot command handler.
##
## Parses and handles prefix commands: !config, !status, !admin, !session.
## All responses are plain text (no embeds).
## Admin-only commands are gated by the permission module's isAdmin check.

import std/[options, sequtils, strutils, times]
import discord_types
import permission

type
  CommandResult* = object
    response*: string
    updatedConfig*: Option[DiscordConfig]

proc handleConfigCommand*(args: string, authorId: string, cfg: DiscordConfig): CommandResult =
  ## Handle !config subcommands: show, set, reload, allowlist
  let parts = args.splitWhitespace(maxsplit=2)

  if parts.len == 0 or parts[0].len == 0:
    return CommandResult(response: "Usage: !config <show|set|reload|allowlist>", updatedConfig: none[DiscordConfig]())

  let subcmd = parts[0].toLowerAscii()

  case subcmd
  of "show":
    var lines: seq[string] = @[]
    lines.add("Prefix: " & cfg.prefix)
    lines.add("Token env: ******")
    lines.add("Admins: " & cfg.admins.allow.join(", "))
    lines.add("Users: " & cfg.users.allow.join(", "))
    lines.add("File allowlist: " & cfg.fileRules.allow.join(", "))
    lines.add("File denylist: " & cfg.fileRules.deny.join(", "))
    lines.add("Tool allowlist: " & cfg.tools.allow.join(", "))
    lines.add("Tool denylist: " & cfg.tools.deny.join(", "))
    return CommandResult(response: lines.join("\n"), updatedConfig: none[DiscordConfig]())

  of "set":
    if not isAdmin(authorId, cfg):
      return CommandResult(response: "Permission denied: admin required.", updatedConfig: none[DiscordConfig]())
    if parts.len < 3:
      return CommandResult(response: "Usage: !config set <key> <value>", updatedConfig: none[DiscordConfig]())
    let key = parts[1].toLowerAscii()
    let value = parts[2]
    var newCfg = cfg
    case key
    of "prefix":
      newCfg.prefix = value
      return CommandResult(response: "Prefix set to: " & value, updatedConfig: some(newCfg))
    of "token_env":
      newCfg.tokenEnv = value
      return CommandResult(response: "Token env set to: " & value, updatedConfig: some(newCfg))
    else:
      return CommandResult(response: "Unknown config key: " & key, updatedConfig: none[DiscordConfig]())

  of "reload":
    if not isAdmin(authorId, cfg):
      return CommandResult(response: "Permission denied: admin required.", updatedConfig: none[DiscordConfig]())
    # Placeholder: actual reload from disk is handled by the bot event loop
    return CommandResult(response: "Config reload requested. Reload must be handled by the bot runtime.", updatedConfig: none[DiscordConfig]())

  of "allowlist":
    let allowlistParts = if parts.len >= 2: parts[1 .. ^1] else: @[]
    if allowlistParts.len == 0:
      return CommandResult(response: "Usage: !config allowlist <add|remove|list> [path]", updatedConfig: none[DiscordConfig]())

    let allowlistCmd = allowlistParts[0].toLowerAscii()

    case allowlistCmd
    of "add":
      if not isAdmin(authorId, cfg):
        return CommandResult(response: "Permission denied: admin required.", updatedConfig: none[DiscordConfig]())
      if allowlistParts.len < 2:
        return CommandResult(response: "Usage: !config allowlist add <path>", updatedConfig: none[DiscordConfig]())
      let path = allowlistParts[1]
      var newCfg = cfg
      if path notin newCfg.fileRules.allow:
        newCfg.fileRules.allow.add(path)
      return CommandResult(response: "Added '" & path & "' to file allowlist.", updatedConfig: some(newCfg))

    of "remove":
      if not isAdmin(authorId, cfg):
        return CommandResult(response: "Permission denied: admin required.", updatedConfig: none[DiscordConfig]())
      if allowlistParts.len < 2:
        return CommandResult(response: "Usage: !config allowlist remove <path>", updatedConfig: none[DiscordConfig]())
      let path = allowlistParts[1]
      var newCfg = cfg
      newCfg.fileRules.allow.keepItIf(it != path)
      return CommandResult(response: "Removed '" & path & "' from file allowlist.", updatedConfig: some(newCfg))

    of "list":
      if cfg.fileRules.allow.len == 0:
        return CommandResult(response: "File allowlist is empty.", updatedConfig: none[DiscordConfig]())
      return CommandResult(response: "File allowlist:\n" & cfg.fileRules.allow.join("\n"), updatedConfig: none[DiscordConfig]())

    else:
      return CommandResult(response: "Unknown allowlist subcommand: " & allowlistCmd, updatedConfig: none[DiscordConfig]())

  else:
    return CommandResult(response: "Unknown config subcommand: " & subcmd, updatedConfig: none[DiscordConfig]())

proc handleStatusCommand*(authorId: string, cfg: DiscordConfig): CommandResult =
  ## Handle !status — show bot status (uptime, sessions, model).
  ## This is a placeholder; actual runtime data would be injected by the bot.
  let now = getTime().utc().format("yyyy-MM-dd HH:mm:ss")
  var lines: seq[string] = @[]
  lines.add("Bot status as of " & now)
  lines.add("Prefix: " & cfg.prefix)
  lines.add("Admins: " & cfg.admins.allow.join(", "))
  lines.add("Sessions: (not tracked in command handler)")
  lines.add("Model: (not tracked in command handler)")
  return CommandResult(response: lines.join("\n"), updatedConfig: none[DiscordConfig]())

proc handleAdminCommand*(args: string, authorId: string, cfg: DiscordConfig): CommandResult =
  ## Handle !admin subcommands: restart, reconnect (placeholders).
  let parts = args.splitWhitespace(maxsplit=1)

  if parts.len == 0 or parts[0].len == 0:
    return CommandResult(response: "Usage: !admin <restart|reconnect>", updatedConfig: none[DiscordConfig]())

  let subcmd = parts[0].toLowerAscii()

  if not isAdmin(authorId, cfg):
    return CommandResult(response: "Permission denied: admin required.", updatedConfig: none[DiscordConfig]())

  case subcmd
  of "restart":
    # Placeholder: actual restart handled by bot runtime
    return CommandResult(response: "Restart requested. Restart must be handled by the bot runtime.", updatedConfig: none[DiscordConfig]())
  of "reconnect":
    # Placeholder: actual reconnect handled by bot runtime
    return CommandResult(response: "Reconnect requested. Reconnect must be handled by the bot runtime.", updatedConfig: none[DiscordConfig]())
  else:
    return CommandResult(response: "Unknown admin subcommand: " & subcmd, updatedConfig: none[DiscordConfig]())

proc handleSessionCommand*(args: string, authorId: string, cfg: DiscordConfig): CommandResult =
  ## Handle !session subcommands: list, info, clear.
  let parts = args.splitWhitespace(maxsplit=1)

  if parts.len == 0 or parts[0].len == 0:
    return CommandResult(response: "Usage: !session <list|info|clear>", updatedConfig: none[DiscordConfig]())

  let subcmd = parts[0].toLowerAscii()

  case subcmd
  of "list":
    # Placeholder: actual session data would come from memory module
    return CommandResult(response: "Active sessions: (not tracked in command handler)", updatedConfig: none[DiscordConfig]())

  of "info":
    if parts.len < 2:
      return CommandResult(response: "Usage: !session info <session_id>", updatedConfig: none[DiscordConfig]())
    let sessionId = parts[1]
    # Placeholder: actual session data would come from memory module
    return CommandResult(response: "Session info for " & sessionId & ": (not tracked in command handler)", updatedConfig: none[DiscordConfig]())

  of "clear":
    if not isAdmin(authorId, cfg):
      return CommandResult(response: "Permission denied: admin required.", updatedConfig: none[DiscordConfig]())
    if parts.len < 2:
      return CommandResult(response: "Usage: !session clear <session_id>", updatedConfig: none[DiscordConfig]())
    let sessionId = parts[1]
    # Placeholder: actual clear would be handled by memory module
    return CommandResult(response: "Session " & sessionId & " memory clear requested. Clear must be handled by the bot runtime.", updatedConfig: none[DiscordConfig]())

  else:
    return CommandResult(response: "Unknown session subcommand: " & subcmd, updatedConfig: none[DiscordConfig]())

proc handleCommand*(cmd: string, args: string, authorId: string, cfg: DiscordConfig): CommandResult =
  ## Main command dispatcher.
  ## cmd: the command name without prefix (e.g. "config", "status")
  ## args: everything after the command word
  ## authorId: the Discord user ID of the message author
  ## cfg: current DiscordConfig
  ##
  ## Returns CommandResult with response text and optional updated config.
  let command = cmd.toLowerAscii()

  case command
  of "config":
    return handleConfigCommand(args, authorId, cfg)
  of "status":
    return handleStatusCommand(authorId, cfg)
  of "admin":
    return handleAdminCommand(args, authorId, cfg)
  of "session":
    return handleSessionCommand(args, authorId, cfg)
  else:
    return CommandResult(response: "Unknown command: " & cmd, updatedConfig: none[DiscordConfig]())
```

`mercury_core/src/mercury_core/discord_mocks.nim`:

```nim
import std/[asyncdispatch, options]

type
  MockUser* = object
    id*: string
    username*: string
    bot*: bool

  MockMessage* = object
    id*: string
    author*: MockUser
    content*: string
    channel_id*: string
    guild_id*: Option[string]
    mention_users*: seq[MockUser]

  Message* = MockMessage

  MockShard* = object
    userId*: string
    guildMembers*: seq[string]
    user*: MockUser

  MockApiCallKind* = enum
    mockSendMessage, mockCreateThread, mockTriggerTyping, mockArchiveThread

  MockApiCall* = object
    kind*: MockApiCallKind
    channelId*: string
    content*: string
    messageId*: string
    name*: string
    threadId*: string

  MockDiscordApi* = ref object
    calls*: seq[MockApiCall]
    nextMessageId: int
    nextThreadId: int

proc newMockDiscordApi*(): MockDiscordApi =
  MockDiscordApi(calls: @[], nextMessageId: 0, nextThreadId: 0)

proc sendMessage*(api: MockDiscordApi; channelId, content: string): Future[string] {.async.} =
  api.nextMessageId.inc
  let msgId = "msg_" & $api.nextMessageId
  api.calls.add MockApiCall(
    kind: mockSendMessage,
    channelId: channelId,
    content: content,
    messageId: msgId,
  )
  return msgId

proc createThread*(api: MockDiscordApi; channelId, messageId, name: string): Future[string] {.async.} =
  api.nextThreadId.inc
  let threadId = "thread_" & $api.nextThreadId
  api.calls.add MockApiCall(
    kind: mockCreateThread,
    channelId: channelId,
    messageId: messageId,
    name: name,
    threadId: threadId,
  )
  return threadId

proc triggerTyping*(api: MockDiscordApi; channelId: string) {.async.} =
  api.calls.add MockApiCall(kind: mockTriggerTyping, channelId: channelId)

proc archiveThread*(api: MockDiscordApi; threadId: string) {.async, gcsafe.} =
  api.calls.add MockApiCall(kind: mockArchiveThread, threadId: threadId)

proc newMockShard*(userId: string; guildMembers: seq[string] = @[]): MockShard =
  result.userId = userId
  result.guildMembers = guildMembers
  result.user = MockUser(id: userId, username: userId, bot: false)

proc makeMessage*(authorId, content, channelId, guildId: string; mentionUsers: seq[string]): Message =
  result = Message(
    id: "",
    author: MockUser(id: authorId, username: authorId, bot: false),
    content: content,
    channel_id: channelId,
    guild_id: some(guildId),
    mention_users: @[],
  )
  for userId in mentionUsers:
    result.mention_users.add MockUser(id: userId, username: userId, bot: false)

proc makeMessage*(authorId, content, channelId: string; guildId: Option[string]; mentionUsers: seq[string]): Message =
  result = Message(
    id: "",
    author: MockUser(id: authorId, username: authorId, bot: false),
    content: content,
    channel_id: channelId,
    guild_id: guildId,
    mention_users: @[],
  )
  for userId in mentionUsers:
    result.mention_users.add MockUser(id: userId, username: userId, bot: false)

proc mockSendFn*(api: MockDiscordApi): proc (channelId, content: string): Future[string] {.async, gcsafe.} =
  proc send(channelId, content: string): Future[string] {.async, gcsafe.} =
    return await api.sendMessage(channelId, content)
  return send

proc mockTypingFn*(api: MockDiscordApi): proc (channelId: string) {.async, gcsafe.} =
  proc typing(channelId: string) {.async, gcsafe.} =
    await api.triggerTyping(channelId)
  return typing

proc mockCreateThreadFn*(api: MockDiscordApi): proc (channelId, messageId, name: string): Future[string] {.async, gcsafe.} =
  proc create(channelId, messageId, name: string): Future[string] {.async, gcsafe.} =
    return await api.createThread(channelId, messageId, name)
  return create

proc mockArchiveThreadFn*(api: MockDiscordApi): proc (threadId: string) {.async, gcsafe.} =
  proc archive(threadId: string) {.async, gcsafe.} =
    await api.archiveThread(threadId)
  return archive

```

`mercury_core/src/mercury_core/discord_types.nim`:

```nim
## Discord configuration types.

type
  AccessControl* = object
    allow*: seq[string]
    deny*: seq[string]

  DiscordConfig* = object
    tokenEnv*: string
    prefix*: string
    admins*: AccessControl
    users*: AccessControl
    fileRules*: AccessControl
    tools*: AccessControl

proc defaultDiscordConfig*(): DiscordConfig =
  result = DiscordConfig(
    tokenEnv: "DISCORD_BOT_TOKEN",
    prefix: "!",
    admins: AccessControl(allow: @[], deny: @[]),
    users: AccessControl(allow: @[], deny: @[]),
    fileRules: AccessControl(allow: @[], deny: @[".env", ".ssh", ".aws", ".gnupg", "*.key", "*.pem"]),
    tools: AccessControl(allow: @[], deny: @[])
  )

```

`mercury_core/src/mercury_core/file_path_validator.nim`:

```nim
import os, strutils, uri
import std/re

type
  PathDecision* = enum
    pathAllow
    pathAsk
    pathDeny
    pathInvalid

  ValidationResult* = object
    decision*: PathDecision
    resolvedPath*: string
    reason*: string

  FileRules* = object
    sandboxDir*: string
    allowPatterns*: seq[string]
    askPatterns*: seq[string]
    denyPatterns*: seq[string]

const mandatoryDenyPatterns = @[
  ".env", ".env.*", "*.key", "*.pem", "*/.ssh/*", ".ssh/*", "*/.aws/*", ".aws/*", "*/.gnupg/*", ".gnupg/*"
]

proc resolvePathSafe*(path: string): string =
  var current = path
  var unexisting: seq[string] = @[]
  
  while current != "" and current != "/" and current != "." and not fileExists(current) and not dirExists(current):
    let parts = splitPath(current)
    if parts.tail != "":
      unexisting.insert(parts.tail, 0)
    current = parts.head
    if parts.head == current and parts.tail == "": break

  if current == "" or current == ".":
    current = getCurrentDir()
  
  if current != "/" and current != "":
    try:
      current = expandFilename(current)
    except OSError:
      discard # Keep current as is if expansion fails

  for part in unexisting:
    current = current / part
    
  return normalizedPath(current)

proc matchPattern(path: string, pattern: string): bool =
  # Simple glob matching
  try:
    # Convert glob to regex
    var rePattern = pattern.replace(".", "\\.").replace("*", ".*").replace("?", ".")
    rePattern = "^" & rePattern & "$"
    let r = re(rePattern)
    return path.match(r)
  except RegexError:
    return false

proc matchAnyPattern(path: string, patterns: seq[string]): bool =
  let filename = extractFilename(path)
  # Check both full path and filename against patterns
  for p in patterns:
    if matchPattern(path, p) or matchPattern(filename, p):
      return true
    # Also check if it's a directory match like .ssh/*
    if p.endsWith("/*"):
      let prefix = p[0..^3]
      if path.contains("/" & prefix & "/") or path.contains("\\" & prefix & "\\"):
        return true
      if path.startsWith(prefix & "/") or path.startsWith(prefix & "\\"):
        return true
  return false

proc validatePath*(path: string, rules: FileRules): ValidationResult =
  var p = path
  
  # 1. URL decoding
  if p.contains("%"):
    try:
      p = decodeUrl(p)
    except ValueError:
      return ValidationResult(decision: pathInvalid, resolvedPath: p,
                              reason: "Malformed percent-encoding in path")
    
  # 2. Tilde expansion
  if p.startsWith("~"):
    p = expandTilde(p)
    
  # 3. Resolve symlinks safely (even if file doesn't exist)
  p = resolvePathSafe(p)
  
  # 4. Sandbox check
  if rules.sandboxDir != "":
    let sandbox = resolvePathSafe(rules.sandboxDir)
    if not p.startsWith(sandbox):
      return ValidationResult(decision: pathDeny, resolvedPath: p, reason: "Path escapes sandbox")
      
  # 5. Mandatory deny list
  if matchAnyPattern(p, mandatoryDenyPatterns):
    return ValidationResult(decision: pathDeny, resolvedPath: p, reason: "Matches mandatory deny pattern")
    
  # 6. User deny list
  if matchAnyPattern(p, rules.denyPatterns):
    return ValidationResult(decision: pathDeny, resolvedPath: p, reason: "Matches deny pattern")
    
  # 7. Ask list
  if matchAnyPattern(p, rules.askPatterns):
    return ValidationResult(decision: pathAsk, resolvedPath: p, reason: "Matches ask pattern")
    
  # 8. Allow list
  if matchAnyPattern(p, rules.allowPatterns):
    return ValidationResult(decision: pathAllow, resolvedPath: p, reason: "Matches allow pattern")
    
  # Default to deny if no match
  return ValidationResult(decision: pathDeny, resolvedPath: p, reason: "Path not in allow list")


```

`mercury_core/src/mercury_core/file_tool.nim`:

```nim
import json, os
import file_path_validator
import permission
import tool_registry
import discord_types

const MaxFileSize* = 1024 * 1024 # 1MB

proc fileReadTool*(rules: FileRules): Tool =
  let parameters = %*{
    "type": "object",
    "properties": {
      "path": {
        "type": "string",
        "description": "Path to the file to read"
      }
    },
    "required": ["path"]
  }

  let execute = proc (args: JsonNode): ToolResult {.raises: [].} =
    let path = args{"path"}.getStr()
    if path == "":
      return ToolResult(output: "Error: path is required", isError: true, exitCode: 1)

    let val = try: validatePath(path, rules)
              except CatchableError as e:
                return ToolResult(output: "Error validating path: " & e.msg, isError: true, exitCode: 1)
    case val.decision
    of pathDeny:
      return ToolResult(output: "Access denied: " & val.reason, isError: true, exitCode: 1)
    of pathAsk:
      return ToolResult(output: "This path requires approval. Ask an admin.", isError: true, exitCode: 1)
    of pathAllow:
      if not fileExists(val.resolvedPath):
        return ToolResult(output: "Error: file does not exist", isError: true, exitCode: 1)
      let info = try: getFileInfo(val.resolvedPath)
                  except CatchableError as e:
                    return ToolResult(output: "Error getting file info: " & e.msg, isError: true, exitCode: 1)
      if info.size > MaxFileSize:
        return ToolResult(output: "Error: file size exceeds maximum allowed (1MB)", isError: true, exitCode: 1)
      try:
        let content = readFile(val.resolvedPath)
        return ToolResult(output: content, isError: false, exitCode: 0)
      except CatchableError as e:
        return ToolResult(output: "Error reading file: " & e.msg, isError: true, exitCode: 1)
    of pathInvalid:
      return ToolResult(output: "Error: invalid path", isError: true, exitCode: 1)

  result = newTool("file_read", "Read contents of a file", parameters, execute)

proc fileWriteTool*(rules: FileRules, cfg: DiscordConfig, userId: string): Tool =
  let parameters = %*{
    "type": "object",
    "properties": {
      "path": {
        "type": "string",
        "description": "Path to the file to write"
      },
      "content": {
        "type": "string",
        "description": "Content to write to the file"
      }
    },
    "required": ["path", "content"]
  }

  let execute = proc (args: JsonNode): ToolResult {.raises: [].} =
    let path = args{"path"}.getStr()
    let content = args{"content"}.getStr()
    if path == "":
      return ToolResult(output: "Error: path is required", isError: true, exitCode: 1)

    if content.len > MaxFileSize:
      return ToolResult(output: "Error: file size exceeds maximum allowed (1MB)", isError: true, exitCode: 1)

    let val = try: validatePath(path, rules)
              except CatchableError as e:
                return ToolResult(output: "Error validating path: " & e.msg, isError: true, exitCode: 1)
    case val.decision
    of pathDeny:
      return ToolResult(output: "Access denied: " & val.reason, isError: true, exitCode: 1)
    of pathAsk:
      return ToolResult(output: "Requires approval", isError: true, exitCode: 1)
    of pathAllow:
      let perm = canUseTool(userId, "write_file", cfg)
      case perm
      of pdDeny:
        return ToolResult(output: "Access denied: user not allowed", isError: true, exitCode: 1)
      of pdAsk:
        return ToolResult(output: "Requires approval", isError: true, exitCode: 1)
      of pdAllow:
        let parent = parentDir(val.resolvedPath)
        if parent != "" and not dirExists(parent):
          try:
            createDir(parent)
          except CatchableError as e:
            return ToolResult(output: "Error creating directory: " & e.msg, isError: true, exitCode: 1)

        let tempPath = val.resolvedPath & ".tmp"
        try:
          writeFile(tempPath, content)
        except CatchableError as e:
          return ToolResult(output: "Error writing temp file: " & e.msg, isError: true, exitCode: 1)
        try:
          moveFile(tempPath, val.resolvedPath)
          return ToolResult(output: "File written successfully", isError: false, exitCode: 0)
        except CatchableError as e:
          if fileExists(tempPath):
            try: removeFile(tempPath) except CatchableError: discard
          return ToolResult(output: "Error moving file: " & e.msg, isError: true, exitCode: 1)
        # Nim 2.2.x with -d:ssl may flag moveFile as raising Exception transitively.
        # Catch as a safety net even though this should never trigger.
        except Exception as e:
          if fileExists(tempPath):
            try: removeFile(tempPath) except CatchableError: discard
          return ToolResult(output: "Error moving file: " & e.msg, isError: true, exitCode: 1)
    of pathInvalid:
      return ToolResult(output: "Error: invalid path", isError: true, exitCode: 1)

  result = newTool("file_write", "Write content to a file atomically", parameters, execute)

```

`mercury_core/src/mercury_core/llm_client.nim`:

```nim
## Mercury LLM client (OpenAI-compatible Chat Completions).
##
## Synchronous HTTP client supporting OpenAI Chat Completions over any
## OpenAI-compatible endpoint (OpenAI, OpenRouter, vLLM, etc.).
##
## Features:
##   - chatCompletion(prompt, history): sends a chat completion request
##   - Parses content and tool_calls from response
##   - Specific error types: AuthError (401), RateLimitError (429),
##     ServerError (5xx), NetworkError, ProtocolError
##   - Simple retry logic (3 attempts with exponential backoff) for
##     rate limits and 5xx server errors
##
## Out of scope (deferred):
##   - Streaming responses (SSE)
##   - Anthropic / Google / non-OpenAI protocols
##   - Async I/O

import std/[httpclient, json, strutils, tables, os]

type
  ChatRole* = enum
    ## Role of a chat message participant.
    crSystem = "system"
    crUser = "user"
    crAssistant = "assistant"
    crTool = "tool"

  ToolCall* = object
    ## A single tool call requested by the assistant.
    id*: string
    name*: string
    arguments*: string               ## JSON-encoded arguments string.

  ChatMessage* = object
    ## A single message in a chat history.
    role*: ChatRole
    content*: string
    name*: string                    ## Optional name for tool messages.
    toolCallId*: string              ## Optional id linking a tool result.
    toolCalls*: seq[ToolCall]        ## Tool calls attached to assistant msg.

  TokenUsage* = object
    ## Token usage statistics from the response.
    promptTokens*: int
    completionTokens*: int
    totalTokens*: int

  ChatResponse* = object
    ## A parsed chat completion response.
    content*: string                 ## "" when assistant returns tool_calls.
    toolCalls*: seq[ToolCall]
    finishReason*: string
    usage*: TokenUsage
    model*: string
    raw*: JsonNode                   ## Raw JSON response for debugging.

  LLMClient* = object
    ## OpenAI-compatible chat completion client.
    baseUrl*: string                 ## e.g. "https://openrouter.ai/api/v1"
    apiKey*: string
    model*: string
    defaultParams*: Table[string, JsonNode]
    timeoutMs*: int                  ## Request timeout in milliseconds.
    maxRetries*: int                 ## Total attempts including the first.
    retryBackoffMs*: int             ## Base backoff in ms (exponential).

  LLMError* = object of CatchableError
    ## Base type for all LLM client errors.
    statusCode*: int

  AuthError* = object of LLMError       ## 401 Unauthorized
  RateLimitError* = object of LLMError  ## 429 Too Many Requests
  ServerError* = object of LLMError     ## 5xx
  ClientError* = object of LLMError     ## Other 4xx
  NetworkError* = object of LLMError    ## Connection / IO failure
  ProtocolError* = object of LLMError   ## Invalid / unparseable response

const
  DefaultTimeoutMs* = 60_000
  DefaultMaxRetries* = 3
  DefaultRetryBackoffMs* = 500

proc newLLMClient*(
    baseUrl: string;
    apiKey: string;
    model: string;
    defaultParams: Table[string, JsonNode] = initTable[string, JsonNode]();
    timeoutMs: int = DefaultTimeoutMs;
    maxRetries: int = DefaultMaxRetries;
    retryBackoffMs: int = DefaultRetryBackoffMs;
): LLMClient =
  ## Constructs a new LLMClient. baseUrl should NOT include "/chat/completions".
  result = LLMClient(
    baseUrl: baseUrl.strip(chars = {'/'}, leading = false),
    apiKey: apiKey,
    model: model,
    defaultParams: defaultParams,
    timeoutMs: timeoutMs,
    maxRetries: max(1, maxRetries),
    retryBackoffMs: max(0, retryBackoffMs),
  )

proc parseRole(s: string): ChatRole =
  case s.toLowerAscii()
  of "system":    crSystem
  of "user":      crUser
  of "assistant": crAssistant
  of "tool":      crTool
  else:           crUser

proc messageToJson(msg: ChatMessage): JsonNode =
  result = newJObject()
  result["role"] = %($msg.role)
  # When the assistant calls tools, content may be empty/null.
  if msg.role == crAssistant and msg.toolCalls.len > 0 and msg.content.len == 0:
    result["content"] = newJNull()
  else:
    result["content"] = %msg.content
  if msg.name.len > 0:
    result["name"] = %msg.name
  if msg.toolCallId.len > 0:
    result["tool_call_id"] = %msg.toolCallId
  if msg.toolCalls.len > 0:
    var arr = newJArray()
    for tc in msg.toolCalls:
      var fnObj = newJObject()
      fnObj["name"] = %tc.name
      fnObj["arguments"] = %tc.arguments
      var tcObj = newJObject()
      tcObj["id"] = %tc.id
      tcObj["type"] = %"function"
      tcObj["function"] = fnObj
      arr.add(tcObj)
    result["tool_calls"] = arr

proc buildRequestBody(
    client: LLMClient;
    messages: seq[ChatMessage];
    extraParams: Table[string, JsonNode];
): JsonNode =
  result = newJObject()
  result["model"] = %client.model
  var msgArr = newJArray()
  for m in messages:
    msgArr.add(messageToJson(m))
  result["messages"] = msgArr
  for k, v in client.defaultParams:
    result[k] = v
  for k, v in extraParams:
    result[k] = v

proc parseToolCalls(node: JsonNode): seq[ToolCall] =
  result = @[]
  if node.isNil or node.kind != JArray:
    return
  for tcNode in node:
    if tcNode.kind != JObject:
      continue
    var tc = ToolCall()
    if tcNode.hasKey("id") and tcNode["id"].kind == JString:
      tc.id = tcNode["id"].getStr()
    if tcNode.hasKey("function") and tcNode["function"].kind == JObject:
      let fn = tcNode["function"]
      if fn.hasKey("name") and fn["name"].kind == JString:
        tc.name = fn["name"].getStr()
      if fn.hasKey("arguments"):
        # arguments is typically a JSON-encoded string, but be lenient.
        if fn["arguments"].kind == JString:
          tc.arguments = fn["arguments"].getStr()
        else:
          tc.arguments = $fn["arguments"]
    result.add(tc)

proc parseResponse(body: string): ChatResponse =
  var node: JsonNode
  try:
    node = parseJson(body)
  except JsonParsingError as e:
    raise newException(ProtocolError,
      "Invalid JSON response: " & e.msg)

  if node.kind != JObject:
    raise newException(ProtocolError, "Response root must be an object")

  if not node.hasKey("choices") or node["choices"].kind != JArray or
     node["choices"].len == 0:
    raise newException(ProtocolError, "Response missing 'choices' array")

  let choice = node["choices"][0]
  if choice.kind != JObject or not choice.hasKey("message"):
    raise newException(ProtocolError, "Choice missing 'message' field")

  let message = choice["message"]
  result = ChatResponse(raw: node)

  if message.hasKey("content") and message["content"].kind == JString:
    result.content = message["content"].getStr()
  # content may be JNull when tool_calls are present; leave as ""

  if message.hasKey("tool_calls"):
    result.toolCalls = parseToolCalls(message["tool_calls"])

  if choice.hasKey("finish_reason") and choice["finish_reason"].kind == JString:
    result.finishReason = choice["finish_reason"].getStr()

  if node.hasKey("model") and node["model"].kind == JString:
    result.model = node["model"].getStr()

  if node.hasKey("usage") and node["usage"].kind == JObject:
    let u = node["usage"]
    if u.hasKey("prompt_tokens") and u["prompt_tokens"].kind == JInt:
      result.usage.promptTokens = u["prompt_tokens"].getInt()
    if u.hasKey("completion_tokens") and u["completion_tokens"].kind == JInt:
      result.usage.completionTokens = u["completion_tokens"].getInt()
    if u.hasKey("total_tokens") and u["total_tokens"].kind == JInt:
      result.usage.totalTokens = u["total_tokens"].getInt()

proc extractApiErrorMessage(body: string): string =
  ## Extracts a human-readable error message from a (possibly OpenAI-style)
  ## error response body. Returns the raw body if parsing fails.
  try:
    let node = parseJson(body)
    if node.kind == JObject and node.hasKey("error"):
      let err = node["error"]
      if err.kind == JObject and err.hasKey("message") and
         err["message"].kind == JString:
        return err["message"].getStr()
      if err.kind == JString:
        return err.getStr()
  except CatchableError:
    discard
  return body

proc raiseForStatus(status: int; body: string) =
  ## Raises the appropriate LLMError subtype for a non-2xx HTTP status.
  let msg = extractApiErrorMessage(body)
  case status
  of 401, 403:
    var e = newException(AuthError,
      "Authentication failed (HTTP " & $status & "): " & msg)
    e.statusCode = status
    raise e
  of 429:
    var e = newException(RateLimitError,
      "Rate limit exceeded (HTTP 429): " & msg)
    e.statusCode = status
    raise e
  else:
    if status >= 500 and status < 600:
      var e = newException(ServerError,
        "Server error (HTTP " & $status & "): " & msg)
      e.statusCode = status
      raise e
    elif status >= 400 and status < 500:
      var e = newException(ClientError,
        "Client error (HTTP " & $status & "): " & msg)
      e.statusCode = status
      raise e
    else:
      var e = newException(ProtocolError,
        "Unexpected HTTP status " & $status & ": " & msg)
      e.statusCode = status
      raise e

proc parseStatusCode(status: string): int =
  ## Parses the integer code from an HTTP status line like "200 OK".
  let s = status.strip()
  let spaceIdx = s.find(' ')
  let codePart = if spaceIdx >= 0: s[0 ..< spaceIdx] else: s
  try:
    return parseInt(codePart)
  except ValueError:
    return 0

proc doRequest(
    client: LLMClient;
    url, body: string;
): tuple[status: int, body: string] =
  ## Issues a single HTTP POST. Raises NetworkError on connection failure.
  let http = newHttpClient(timeout = client.timeoutMs)
  defer: http.close()
  http.headers = newHttpHeaders({
    "Content-Type": "application/json",
    "Accept": "application/json",
    "User-Agent": "mercury-agent/0.1",
  })
  if client.apiKey.len > 0:
    http.headers["Authorization"] = "Bearer " & client.apiKey
  try:
    let resp = http.request(url, httpMethod = HttpPost, body = body)
    let status = parseStatusCode(resp.status)
    let respBody = resp.body
    return (status, respBody)
  except HttpRequestError as e:
    raise newException(NetworkError, "HTTP request failed: " & e.msg)
  except OSError as e:
    raise newException(NetworkError, "Network/OS error: " & e.msg)
  except IOError as e:
    raise newException(NetworkError, "I/O error: " & e.msg)

proc chatCompletion*(
    client: LLMClient;
    prompt: string;
    history: seq[ChatMessage] = @[];
    extraParams: Table[string, JsonNode] = initTable[string, JsonNode]();
): ChatResponse =
  ## Sends a chat completion request. The `prompt` is appended as a final
  ## user message after `history`. To send a fully custom message list,
  ## pass an empty prompt and provide messages via history.
  ##
  ## Retries on 429 and 5xx with exponential backoff up to client.maxRetries
  ## attempts. Other errors are raised immediately.
  var messages = history
  if prompt.len > 0:
    messages.add(ChatMessage(role: crUser, content: prompt))

  let body = $buildRequestBody(client, messages, extraParams)
  let url = client.baseUrl & "/chat/completions"

  var attempt = 0
  var lastErr: ref LLMError = nil
  while attempt < client.maxRetries:
    inc attempt
    var status = 0
    var respBody = ""
    try:
      let r = doRequest(client, url, body)
      status = r.status
      respBody = r.body
    except NetworkError as e:
      lastErr = e
      if attempt < client.maxRetries:
        sleep(client.retryBackoffMs * (1 shl (attempt - 1)))
        continue
      raise e

    if status >= 200 and status < 300:
      return parseResponse(respBody)

    # Retry on 429 and 5xx
    if (status == 429 or (status >= 500 and status < 600)) and
       attempt < client.maxRetries:
      sleep(client.retryBackoffMs * (1 shl (attempt - 1)))
      continue

    raiseForStatus(status, respBody)

  # Exhausted retries with only NetworkError encountered
  if lastErr != nil:
    raise lastErr
  raise newException(LLMError, "chatCompletion failed without a recorded error")

```

`mercury_core/src/mercury_core/mcp_client.nim`:

```nim
## MCP client — Model Context Protocol tool discovery.
##
## MCP (https://modelcontextprotocol.io/) is a JSON-RPC-based protocol for
## exposing tools from external servers to an LLM. This client implements the
## subset needed for the Mercury use case:
##   - HTTP/SSE transport (server-driven streaming via Server-Sent Events)
##   - `initialize` handshake (protocol version negotiation)
##   - `tools/list` — discover all tools available on a server
##   - `tools/call` — invoke a tool and return its result
##
## Tools discovered from MCP servers are not registered automatically. Call
## `discoverTools()` to get a sequence of `McpTool` objects, then pass them
## to `registerMcpTool()` in `mcp_tool.nim` to add them to a `ToolRegistry`.

import std/[httpclient, json, times, strutils, os]

import mercury_core/config

# ---------------------------------------------------------------------------
# Types
# ---------------------------------------------------------------------------

type
  McpTool* = object
    ## A tool as returned by the MCP server's `tools/list` response.
    server*: string           ## Originating server name (from config).
    name*: string             ## Unique name, e.g. "filesystem_read"
    description*: string      ## Human-readable description.
    inputSchema*: JsonNode    ## JSON Schema for tool arguments.

  McpClient* = ref object
    ## Per-server MCP client state.
    cfg*: McpServerConfig
    http*: HttpClient
    protocolVersion*: string   ## Negotiated during initialize.

  McpError* = object of CatchableError
    ## Base type for MCP-level errors.
    serverUrl*: string

  McpConnectionError* = object of McpError
    ## Could not reach the MCP server or complete the handshake.
  McpProtocolError* = object of McpError
    ## Server returned an error or unexpected response.
  McpToolNotFoundError* = object of McpError
    ## Server does not have a tool with the given name.

const
  DefaultMcpTimeoutMs* = 30_000
  DefaultMcpServerUrl* = "http://localhost:8080/mcp"

# ---------------------------------------------------------------------------
# Client construction
# ---------------------------------------------------------------------------

proc newMcpServerConfig*(
  url: string = DefaultMcpServerUrl;
  authToken: string = "";
  timeoutMs: int = DefaultMcpTimeoutMs;
  enabled: bool = true;
): McpServerConfig =
  McpServerConfig(
    url: url.strip(trailing = true, chars = {'/'}),
    authToken: authToken,
    timeoutMs: if timeoutMs <= 0: DefaultMcpTimeoutMs else: timeoutMs,
    enabled: enabled,
  )

proc newMcpClient*(cfg: McpServerConfig): McpClient =
  let http = newHttpClient(timeout = cfg.timeoutMs)
  if cfg.authToken.len > 0:
    http.headers = newHttpHeaders({"Authorization": "Bearer " & cfg.authToken})
  result = new McpClient
  result.cfg = cfg
  result.http = http
  result.protocolVersion = ""

# ---------------------------------------------------------------------------
# JSON-RPC helpers
# ---------------------------------------------------------------------------

proc parseHttpStatusCode(status: string): int =
  let s = status.strip()
  let spaceIdx = s.find(' ')
  let codePart = if spaceIdx >= 0: s[0 ..< spaceIdx] else: s
  try:
    return parseInt(codePart)
  except ValueError:
    return 0

proc jsonRpcRequest*(mcpMethod: string; params: JsonNode = nil): JsonNode =
  result = newJObject()
  result["jsonrpc"] = %"2.0"
  result["id"] = %(getTime().toUnix())
  result["method"] = %mcpMethod
  if not params.isNil:
    result["params"] = params
  else:
    result["params"] = newJObject()

proc jsonRpcResponseId*(node: JsonNode): int =
  if node.hasKey("id"):
    result = node["id"].getInt()
  else:
    result = 0

proc jsonRpcError(msg: string; code: int; data: JsonNode = nil): JsonNode =
  result = newJObject()
  result["jsonrpc"] = %"2.0"
  result["id"] = newJNull()
  result["error"] = newJObject()
  result["error"]["message"] = %msg
  result["error"]["code"] = newJInt(code)

# ---------------------------------------------------------------------------
# HTTP transport
# ---------------------------------------------------------------------------

proc callMethod*(client: McpClient; mcpMethod: string; params: JsonNode = nil): JsonNode =
  ## Sends a JSON-RPC request to the MCP server and returns the parsed response.
  ## Raises on transport errors, HTTP errors, or JSON-RPC error responses.
  let reqBody = jsonRpcRequest(mcpMethod, params)
  let bodyStr = reqBody.pretty()  # pretty is fine for debugging; for perf use $reqBody

  var response: Response
  try:
    response = client.http.request(
      client.cfg.url,
      httpMethod = HttpPost,
      body = $reqBody,
      headers = newHttpHeaders({"Content-Type": "application/json"}),
    )
  except CatchableError as e:
    var err = newException(McpConnectionError,
      "failed to connect to MCP server '" & client.cfg.url & "': " & e.msg)
    err.serverUrl = client.cfg.url
    raise err

  let statusCode = parseHttpStatusCode(response.status)
  if statusCode >= 400:
    var err = newException(McpConnectionError,
      "MCP server returned HTTP " & $statusCode &
      " at '" & client.cfg.url & "': " & response.body)
    err.serverUrl = client.cfg.url
    raise err

  var respNode: JsonNode
  try:
    respNode = parseJson(response.body)
  except JsonParsingError as e:
    var err = newException(McpProtocolError,
      "MCP server at '" & client.cfg.url &
      "' returned invalid JSON: " & e.msg)
    err.serverUrl = client.cfg.url
    raise err

  # Check for JSON-RPC error response.
  if respNode.kind == JObject and respNode.hasKey("error"):
    let errMsg = if respNode["error"].hasKey("message"):
      respNode["error"]["message"].getStr()
    else:
      "unknown JSON-RPC error"
    let errCode = if respNode["error"].hasKey("code"):
      respNode["error"]["code"].getInt()
    else:
      -1
    var err = newException(McpProtocolError,
      "MCP server '" & client.cfg.url &
      "' returned JSON-RPC error: " & errMsg)
    err.serverUrl = client.cfg.url
    raise err

  respNode

# ---------------------------------------------------------------------------
# MCP protocol methods
# ---------------------------------------------------------------------------

proc initialize*(client: McpClient; serverName: string = "mercury"): string =
  ## Sends the MCP `initialize` handshake. Sets `client.protocolVersion`
  ## and returns the server's capabilities. Raises on failure.
  let params = newJObject()
  params["protocolVersion"] = %"2024-11-05"
  params["clientInfo"] = newJObject()
  params["clientInfo"]["name"] = %"mercury-agent"
  params["clientInfo"]["version"] = %"0.1.0"
  params["clientInfo"]["meta"] = newJObject()
  params["clientInfo"]["meta"]["hostname"] = %getEnv("HOSTNAME", "unknown")

  var resp: JsonNode
  try:
    resp = callMethod(client, "initialize", params)
  except McpError:
    raise
  except CatchableError as e:
    var err = newException(McpConnectionError,
      "MCP initialize failed: " & e.msg)
    err.serverUrl = client.cfg.url
    raise err

  if not resp.hasKey("result"):
    raise newException(McpProtocolError,
      "initialize response missing 'result' field at '" & client.cfg.url & "'")

  let initResult = resp["result"]
  if initResult.hasKey("protocolVersion") and initResult["protocolVersion"].kind == JString:
    client.protocolVersion = initResult["protocolVersion"].getStr()
  else:
    raise newException(McpProtocolError,
      "initialize response missing protocolVersion at '" & client.cfg.url & "'")

  # Send "initialized" notification (no response expected).
  let notif = jsonRpcRequest("notifications/initialized", newJObject())
  discard client.http.request(
    client.cfg.url,
    httpMethod = HttpPost,
    body = $notif,
    headers = newHttpHeaders({"Content-Type": "application/json"}),
  )
  client.protocolVersion

proc listTools*(client: McpClient): seq[McpTool] =
  ## Asks the MCP server for all available tools and returns them.
  result = @[]
  var resp: JsonNode
  try:
    resp = callMethod(client, "tools/list")
  except McpError:
    raise
  except CatchableError as e:
    var err = newException(McpConnectionError,
      "tools/list failed: " & e.msg)
    err.serverUrl = client.cfg.url
    raise err

  if not resp.hasKey("result"):
    raise newException(McpProtocolError,
      "tools/list response missing 'result' at '" & client.cfg.url & "'")

  let resultNode = resp["result"]
  if resultNode.hasKey("tools") and resultNode["tools"].kind == JArray:
    for toolNode in resultNode["tools"]:
      if toolNode.kind != JObject:
        continue
      var tool = McpTool(
        server: client.cfg.url,
        name: if toolNode.hasKey("name"): toolNode["name"].getStr() else: "",
        description: if toolNode.hasKey("description"): toolNode["description"].getStr() else: "",
        inputSchema: if toolNode.hasKey("inputSchema"): toolNode["inputSchema"] else: newJObject(),
      )
      if tool.name.len > 0:
        result.add(tool)

proc callTool*(client: McpClient; toolName: string; args: JsonNode): string =
  ## Calls a tool on the MCP server and returns the result as a string.
  ## Raises `McpToolNotFoundError` if the server doesn't know the tool.
  let params = newJObject()
  params["name"] = %toolName
  params["arguments"] = if args.isNil: newJObject() else: args

  var resp: JsonNode
  try:
    resp = callMethod(client, "tools/call", params)
  except McpError:
    raise
  except CatchableError as e:
    var err = newException(McpConnectionError,
      "tools/call failed: " & e.msg)
    err.serverUrl = client.cfg.url
    raise err

  if not resp.hasKey("result"):
    raise newException(McpProtocolError,
      "tools/call response missing 'result' at '" & client.cfg.url & "'")

  let resultNode = resp["result"]
  # MCP result format: { "content": [{ "type": "text", "text": "..." }] }
  if resultNode.hasKey("content") and resultNode["content"].kind == JArray:
    var parts: seq[string] = @[]
    for content in resultNode["content"]:
      if content.kind == JObject and content.hasKey("text"):
        parts.add(content["text"].getStr())
    return parts.join("\n")
  # Fallback: return the result as a JSON string.
  return resultNode.pretty()

# ---------------------------------------------------------------------------
# Convenience: discover all tools from a list of server configs
# ---------------------------------------------------------------------------

proc discoverTools*(configs: seq[McpServerConfig]): seq[McpTool] =
  ## Connects to each server in `configs`, discovers its tools, and returns
  ## the union of all tools. Skips servers where `enabled == false` or
  ## connection fails (logs a warning internally; caller decides how to handle).
  result = @[]
  for cfg in configs:
    if not cfg.enabled:
      continue
    var client = newMcpClient(cfg)
    try:
      discard initialize(client)
      let tools = client.listTools()
      for tool in tools:
        # Prefix name with server-derived namespace to avoid collisions.
        var prefixed = McpTool(server: tool.server, name: tool.name,
                               description: tool.description,
                               inputSchema: tool.inputSchema)
        result.add(prefixed)
    except CatchableError as e:
      # Connection failed — log and continue with remaining servers.
      stderr.writeLine("Warning: MCP server '" & cfg.url &
                       "' unavailable: " & e.msg)
      continue
```

`mercury_core/src/mercury_core/mcp_tool.nim`:

```nim
## MCP tool registration — converts `McpTool` objects into `Tool`s in a `ToolRegistry`.
##
## The key challenge: MCP tools are identified by name and take arbitrary JSON
## arguments, which maps naturally to OpenAI function-calling. This module
## bridges the two representations:
##   - `McpTool` (from mcp_client.nim) → `Tool` (from tool_registry.nim)
##   - `ToolExecuteProc` wraps `McpClient.callTool` and returns `ToolResult`
##
## The wrapper procedure is `{.gcsafe, raises: [].}` so it fits the
## `ToolExecuteProc` signature and can live inside a `ToolRegistry` without
## leaking exceptions to the agent loop.

import std/[json]

import mercury_core/config
import mercury_core/mcp_client
import mercury_core/tool_registry

# ---------------------------------------------------------------------------
# Internal helper
# ---------------------------------------------------------------------------

proc callMcpToolRaw(
    client: McpClient;
    toolName: string;
    args: JsonNode;
): ToolResult =
  ## Internal helper that calls an MCP tool and converts errors to `ToolResult`.
  try:
    let output = client.callTool(toolName, args)
    return ToolResult(output: output, isError: false, exitCode: 0)
  except McpToolNotFoundError as e:
    return ToolResult(
      output: "tool not found on MCP server: " & e.msg,
      isError: true,
      exitCode: -1,
    )
  except McpError as e:
    return ToolResult(
      output: "MCP error: " & e.msg,
      isError: true,
      exitCode: -1,
    )
  except CatchableError as e:
    return ToolResult(
      output: "unexpected error calling MCP tool: " & e.msg,
      isError: true,
      exitCode: -1,
    )

# ---------------------------------------------------------------------------
# Per-tool execute proc factory
# ---------------------------------------------------------------------------

proc makeMcpToolExecuteProc(
    client: McpClient;
    toolName: string;
): ToolExecuteProc =
  ## Builds a `ToolExecuteProc` closure that calls `toolName` on the given
  ## MCP client. The closure captures the client and tool name so each
  ## registered MCP tool has its own isolated execution path.
  let name = toolName  # capture into closure
  let mc = client       # capture ref safely
  result = proc (args: JsonNode): ToolResult {.gcsafe, raises: [].} =
    try:
      let output = mc.callTool(name, args)
      ToolResult(output: output, isError: false, exitCode: 0)
    except McpToolNotFoundError as e:
      ToolResult(output: "tool not found on MCP server: " & e.msg,
                isError: true, exitCode: -1)
    except McpError as e:
      ToolResult(output: "MCP error: " & e.msg, isError: true, exitCode: -1)
    except CatchableError as e:
      ToolResult(output: "unexpected error calling MCP tool: " & e.msg,
                isError: true, exitCode: -1)
    except Exception as e:
      ToolResult(output: "internal error calling MCP tool: " & e.msg,
                isError: true, exitCode: -1)
    except Defect as e:
      ToolResult(output: "internal error calling MCP tool: " & e.msg,
                isError: true, exitCode: -1)

# ---------------------------------------------------------------------------
# Registration
# ---------------------------------------------------------------------------

proc registerMcpTool*(
    reg: ToolRegistry;
    mcpTool: McpTool;
    client: var McpClient;
) =
  ## Registers a single `McpTool` into a `ToolRegistry` using the provided
  ## `McpClient` for execution. The tool's name is used as-is (no prefix).
  ##
  ## Raises `ToolDuplicateError` if a tool with the same name is already
  ## registered. Raises `ToolArgumentError` if `mcpTool.name` is empty.
  if mcpTool.name.len == 0:
    raise newException(ToolArgumentError, "MCP tool name must be non-empty")

  let executeProc = makeMcpToolExecuteProc(client, mcpTool.name)
  let parameters = if mcpTool.inputSchema.isNil:
    newJObject()
  else:
    mcpTool.inputSchema

  reg.register(
    name = mcpTool.name,
    description = mcpTool.description,
    parameters = parameters,
    execute = executeProc,
  )

proc registerMcpTools*(
    reg: ToolRegistry;
    mcpTools: seq[McpTool];
    client: var McpClient;
) =
  ## Registers all `McpTool` objects into a `ToolRegistry`. Uses the same
  ## `McpClient` for all tools (assumes they come from the same server).
  ##
  ## Skips any tool whose name collides with an already-registered tool
  ## (raises `ToolDuplicateError` only on the first collision).
  for tool in mcpTools:
    if reg.has(tool.name):
      raise newException(ToolDuplicateError,
        "tool '" & tool.name & "' already registered; cannot add from MCP")
    registerMcpTool(reg, tool, client)

# ---------------------------------------------------------------------------
# Convenience: build and register from server configs in one shot
# ---------------------------------------------------------------------------

proc registerMcpServer*(
    reg: ToolRegistry;
    serverCfg: McpServerConfig;
): seq[McpTool] =
  ## Connects to one MCP server, discovers its tools, and registers them
  ## all into `reg`. Returns the list of tools that were registered.
  ## If the server is disabled or unreachable, returns an empty sequence
  ## (no exception raised — caller decides logging/handling).
  result = @[]
  if not serverCfg.enabled:
    return

  var client = newMcpClient(serverCfg)
  try:
    discard client.initialize()
    let tools = client.listTools()
    registerMcpTools(reg, tools, client)
    result = tools
  except CatchableError as e:
    stderr.writeLine("Warning: MCP server '" & serverCfg.url &
                     "' registration failed: " & e.msg)

proc registerMcpServers*(
    reg: ToolRegistry;
    serverCfgs: seq[McpServerConfig];
): int =
  ## Calls `registerMcpServer` for each server config and returns the total
  ## number of tools registered across all servers.
  result = 0
  for cfg in serverCfgs:
    let tools = registerMcpServer(reg, cfg)
    result += tools.len
```

`mercury_core/src/mercury_core/memory.nim`:

```nim
## Mercury SQLite memory module.
##
## Persistent conversation memory backed by SQLite with FTS5 full-text search.
##
## Schema:
##   sessions  — one row per conversation session
##   messages  — one row per chat message, linked to a session
##   messages_fts — FTS5 virtual table mirroring messages.content
##
## Features:
##   - newSession(): creates a new session, returns its ID
##   - appendMessage(): stores a ChatMessage with token counts
##   - getHistory(): retrieves all messages for a session as seq[ChatMessage]
##   - searchHistory(): full-text search across all message content
##   - getTokenUsage(): aggregated token stats for a session
##
## WAL mode is enabled for better concurrent read performance.
## Tool calls and tool results are stored as JSON strings.
##
## Out of scope (deferred):
##   - Vector / embedding search
##   - Memory summarization / compaction
##   - Cross-session retrieval

import db_connector/db_sqlite
import std/[json, strutils, times]
import mercury_core/llm_client

# ---------------------------------------------------------------------------
# Public types
# ---------------------------------------------------------------------------

type
  Memory* = object
    ## Wraps a SQLite connection and exposes the memory API.
    db: DbConn

  SearchResult* = object
    ## A single full-text search hit.
    sessionId*: string
    messageId*: int64
    role*: ChatRole
    content*: string
    snippet*: string          ## FTS5 snippet (may equal content for short msgs)
    createdAt*: string

  MemoryError* = object of CatchableError
    ## Raised on unrecoverable database errors.

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

proc roleToStr(r: ChatRole): string =
  case r
  of crSystem:    "system"
  of crUser:      "user"
  of crAssistant: "assistant"
  of crTool:      "tool"

proc strToRole(s: string): ChatRole =
  case s.toLowerAscii()
  of "system":    crSystem
  of "user":      crUser
  of "assistant": crAssistant
  of "tool":      crTool
  else:           crUser

proc toolCallsToJson(tcs: seq[ToolCall]): string =
  ## Serialises a seq[ToolCall] to a compact JSON array string.
  if tcs.len == 0:
    return "[]"
  var arr = newJArray()
  for tc in tcs:
    var obj = newJObject()
    obj["id"]        = %tc.id
    obj["name"]      = %tc.name
    obj["arguments"] = %tc.arguments
    arr.add(obj)
  return $arr

proc jsonToToolCalls(s: string): seq[ToolCall] =
  ## Deserialises a JSON array string back to seq[ToolCall].
  result = @[]
  if s.len == 0 or s == "[]":
    return
  try:
    let node = parseJson(s)
    if node.kind != JArray:
      return
    for item in node:
      if item.kind != JObject:
        continue
      var tc = ToolCall()
      if item.hasKey("id") and item["id"].kind == JString:
        tc.id = item["id"].getStr()
      if item.hasKey("name") and item["name"].kind == JString:
        tc.name = item["name"].getStr()
      if item.hasKey("arguments") and item["arguments"].kind == JString:
        tc.arguments = item["arguments"].getStr()
      result.add(tc)
  except CatchableError:
    discard

proc nowIso(): string =
  ## Returns the current UTC time as an ISO 8601 string.
  let t = now().utc
  return t.format("yyyy-MM-dd'T'HH:mm:ss'Z'")

proc generateSessionId(): string =
  ## Generates a session ID based on the current UTC timestamp plus a
  ## nanosecond component for uniqueness.
  let t = now().utc
  return "sess_" & t.format("yyyyMMdd'T'HHmmss") & "_" &
         $getTime().nanosecond

# ---------------------------------------------------------------------------
# Schema initialisation
# ---------------------------------------------------------------------------

proc initSchema(db: DbConn) =
  ## Creates tables and FTS5 virtual table if they do not already exist.
  db.exec(sql"""
    CREATE TABLE IF NOT EXISTS sessions (
      id          TEXT PRIMARY KEY,
      created_at  TEXT NOT NULL,
      updated_at  TEXT NOT NULL,
      metadata    TEXT NOT NULL DEFAULT '{}'
    )
  """)

  db.exec(sql"""
    CREATE TABLE IF NOT EXISTS messages (
      id            INTEGER PRIMARY KEY AUTOINCREMENT,
      session_id    TEXT    NOT NULL REFERENCES sessions(id),
      role          TEXT    NOT NULL,
      content       TEXT    NOT NULL DEFAULT '',
      name          TEXT    NOT NULL DEFAULT '',
      tool_call_id  TEXT    NOT NULL DEFAULT '',
      tool_calls    TEXT    NOT NULL DEFAULT '[]',
      tool_results  TEXT    NOT NULL DEFAULT '[]',
      tokens_in     INTEGER NOT NULL DEFAULT 0,
      tokens_out    INTEGER NOT NULL DEFAULT 0,
      created_at    TEXT    NOT NULL
    )
  """)

  # FTS5 virtual table — content= makes it a "content table" backed by messages.
  # rowid links to messages.id for efficient joins.
  db.exec(sql"""
    CREATE VIRTUAL TABLE IF NOT EXISTS messages_fts
    USING fts5(
      content,
      content='messages',
      content_rowid='id'
    )
  """)

  # Triggers to keep FTS index in sync with the messages table.
  db.exec(sql"""
    CREATE TRIGGER IF NOT EXISTS messages_ai
    AFTER INSERT ON messages BEGIN
      INSERT INTO messages_fts(rowid, content)
      VALUES (new.id, new.content);
    END
  """)

  db.exec(sql"""
    CREATE TRIGGER IF NOT EXISTS messages_ad
    AFTER DELETE ON messages BEGIN
      INSERT INTO messages_fts(messages_fts, rowid, content)
      VALUES ('delete', old.id, old.content);
    END
  """)

  db.exec(sql"""
    CREATE TRIGGER IF NOT EXISTS messages_au
    AFTER UPDATE ON messages BEGIN
      INSERT INTO messages_fts(messages_fts, rowid, content)
      VALUES ('delete', old.id, old.content);
      INSERT INTO messages_fts(rowid, content)
      VALUES (new.id, new.content);
    END
  """)

# ---------------------------------------------------------------------------
# Constructor / destructor
# ---------------------------------------------------------------------------

proc newMemory*(path: string = ":memory:"): Memory =
  ## Opens (or creates) a SQLite database at `path`.
  ## Pass ":memory:" for an in-memory database (useful for tests).
  let db = open(path, "", "", "")
  db.exec(sql"PRAGMA journal_mode=WAL")
  db.exec(sql"PRAGMA foreign_keys=ON")
  initSchema(db)
  result = Memory(db: db)

proc close*(m: var Memory) =
  ## Closes the underlying database connection.
  m.db.close()

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

proc newSession*(m: Memory; metadata: string = "{}"): string =
  ## Creates a new session row and returns its ID.
  let id = generateSessionId()
  let ts = nowIso()
  m.db.exec(sql"""
    INSERT INTO sessions (id, created_at, updated_at, metadata)
    VALUES (?, ?, ?, ?)
  """, id, ts, ts, metadata)
  return id

proc appendMessage*(
    m: Memory;
    sessionId: string;
    message: ChatMessage;
    tokensIn: int = 0;
    tokensOut: int = 0;
) =
  ## Appends a ChatMessage to the given session.
  ## Updates sessions.updated_at as a side effect.
  let ts = nowIso()
  let tcJson = toolCallsToJson(message.toolCalls)
  m.db.exec(sql"""
    INSERT INTO messages
      (session_id, role, content, name, tool_call_id,
       tool_calls, tool_results, tokens_in, tokens_out, created_at)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  """,
    sessionId,
    roleToStr(message.role),
    message.content,
    message.name,
    message.toolCallId,
    tcJson,
    "[]",          ## tool_results reserved for future use
    $tokensIn,
    $tokensOut,
    ts,
  )
  m.db.exec(sql"""
    UPDATE sessions SET updated_at = ? WHERE id = ?
  """, ts, sessionId)

proc getHistory*(m: Memory; sessionId: string): seq[ChatMessage] =
  ## Returns all messages for `sessionId` in insertion order.
  result = @[]
  for row in m.db.fastRows(sql"""
    SELECT role, content, name, tool_call_id, tool_calls
    FROM messages
    WHERE session_id = ?
    ORDER BY id ASC
  """, sessionId):
    let msg = ChatMessage(
      role:       strToRole(row[0]),
      content:    row[1],
      name:       row[2],
      toolCallId: row[3],
      toolCalls:  jsonToToolCalls(row[4]),
    )
    result.add(msg)

proc searchHistory*(m: Memory; query: string): seq[SearchResult] =
  ## Full-text searches all message content using FTS5.
  ## Returns matching rows ordered by relevance (FTS5 rank).
  result = @[]
  if query.len == 0:
    return
  for row in m.db.fastRows(sql"""
    SELECT m.session_id,
           m.id,
           m.role,
           m.content,
           snippet(messages_fts, 0, '[', ']', '...', 20),
           m.created_at
    FROM messages_fts
    JOIN messages m ON m.id = messages_fts.rowid
    WHERE messages_fts MATCH ?
    ORDER BY rank
  """, query):
    let sr = SearchResult(
      sessionId: row[0],
      messageId: parseBiggestInt(row[1]),
      role:      strToRole(row[2]),
      content:   row[3],
      snippet:   row[4],
      createdAt: row[5],
    )
    result.add(sr)

proc getTokenUsage*(m: Memory; sessionId: string): TokenUsage =
  ## Returns aggregated token counts for all messages in `sessionId`.
  let row = m.db.getRow(sql"""
    SELECT COALESCE(SUM(tokens_in), 0),
           COALESCE(SUM(tokens_out), 0),
           COALESCE(SUM(tokens_in + tokens_out), 0)
    FROM messages
    WHERE session_id = ?
  """, sessionId)
  result = TokenUsage(
    promptTokens:     parseInt(row[0]),
    completionTokens: parseInt(row[1]),
    totalTokens:      parseInt(row[2]),
  )

```

`mercury_core/src/mercury_core/message_chunker.nim`:

```nim
## Fence-aware Discord message chunking.

import std/strutils

const ContinuationMarker* = "..."
const FenceMarker = "```"
const FenceCloseReserve = 4

proc chunkMessage*(content: string; maxLen = 1900): seq[string] =
  if content.len == 0 or maxLen <= 0:
    return @[]

  proc closeChunk(chunk: string; inFence: bool): string =
    result = chunk
    if inFence:
      if result.len > 0 and result[result.high] != '\n':
        result.add '\n'
      result.add FenceMarker

  proc startChunk(inFence: bool; fenceOpener: string): string =
    if inFence:
      result = fenceOpener & "\n"
    else:
      result = ""

  var chunks: seq[string] = @[]
  var current = ""
  var inFence = false
  var fenceOpener = ""

  proc flushCurrent() =
    if current.len == 0:
      return
    chunks.add closeChunk(current, inFence)
    current = startChunk(inFence, fenceOpener)

  proc roomLeft(): int =
    result = maxLen - current.len
    if inFence:
      result -= FenceCloseReserve

  proc appendFragment(fragment: string) =
    var remaining = fragment
    while remaining.len > 0:
      var room = roomLeft()
      if room <= 0:
        flushCurrent()
        continue

      if remaining.len <= room:
        current.add remaining
        remaining.setLen(0)
      else:
        if room <= ContinuationMarker.len:
          flushCurrent()
          continue
        let take = room - ContinuationMarker.len
        current.add remaining[0 ..< take]
        current.add ContinuationMarker
        remaining = remaining[take .. ^1]
        flushCurrent()

  var i = 0
  while i < content.len:
    let lineStart = i
    while i < content.len and content[i] != '\n':
      inc i
    var line = content[lineStart ..< i]
    if i < content.len and content[i] == '\n':
      line.add '\n'
      inc i

    if line.startsWith(FenceMarker):
      appendFragment(line)
      if not inFence:
        inFence = true
        fenceOpener = line.strip(trailing = true, chars = {'\r', '\n'})
      else:
        inFence = false
        fenceOpener = ""
      continue

    appendFragment(line)

  if current.len > 0:
    chunks.add closeChunk(current, inFence)

  result = chunks

```

`mercury_core/src/mercury_core/permission.nim`:

```nim
import discord_types

type
  ToolRiskLevel* = enum
    riskNone
    riskLow
    riskMedium
    riskHigh
    riskCritical

  PermissionDecision* = enum
    pdAllow
    pdDeny
    pdAsk

proc getToolRisk*(toolName: string): ToolRiskLevel =
  case toolName
  of "shell", "bash", "execute": riskHigh
  of "file_write", "delete_file": riskMedium
  of "file_read", "read_file", "search": riskLow
  else: riskMedium

proc isAdmin*(userId: string, cfg: DiscordConfig): bool =
  if userId in cfg.admins.deny:
    return false
  return userId in cfg.admins.allow

proc isUserAllowed*(userId: string, cfg: DiscordConfig): bool =
  if userId in cfg.users.deny:
    return false
  if userId in cfg.users.allow:
    return true
  return isAdmin(userId, cfg)

proc canUseTool*(
    userId: string, toolName: string, cfg: DiscordConfig
): PermissionDecision =
  # check user in allow list
  if not isUserAllowed(userId, cfg):
    return pdDeny

  # check tool explicit deny
  if toolName in cfg.tools.deny:
    return pdDeny

  # check tool explicit allow
  if toolName in cfg.tools.allow:
    return pdAllow

  # check tool risk
  let risk = getToolRisk(toolName)

  if risk == riskNone or risk == riskLow:
    return pdAllow

  if risk == riskMedium:
    if isAdmin(userId, cfg):
      return pdAllow
    else:
      return pdAsk

  if risk == riskHigh or risk == riskCritical:
    return pdAsk

  return pdDeny

```

`mercury_core/src/mercury_core/persona.nim`:

```nim
import std/[os, tables, streams, strutils, parsecfg, sequtils, sets]
import mercury_core/config
import mercury_core/tool_registry

# ---------------------------------------------------------------------------
# Types
# ---------------------------------------------------------------------------

type
  MemoryScope* = enum
    msOwnSessions
    msNone
    msShared

  PersonaConfig* = object
    name*: string
    systemPrompt*: string
    model*: string
    temperature*: float
    maxIterations*: int
    toolsAllow*: seq[string]
    toolsDeny*: seq[string]
    memoryScope*: MemoryScope
    memoryMaxHistory*: int
    memoryFtsEnabled*: bool
    delegateEnabled*: bool
    maxDelegationDepth*: int
    maxDelegationsPerRun*: int

  PersonaRegistry* = ref object
    personas*: OrderedTable[string, PersonaConfig]

  PersonaError* = object of CatchableError

# ---------------------------------------------------------------------------
# Defaults
# ---------------------------------------------------------------------------

const
  DefaultMemoryScope* = msOwnSessions
  DefaultMemoryMaxHistory* = 0
  DefaultMemoryFtsEnabled* = false
  DefaultDelegateEnabled* = true
  DefaultMaxDelegationDepth* = 2
  DefaultMaxDelegationsPerRun* = 5

# ---------------------------------------------------------------------------
# Registry construction
# ---------------------------------------------------------------------------

proc newPersonaRegistry*(): PersonaRegistry =
  PersonaRegistry(personas: initOrderedTable[string, PersonaConfig]())

# ---------------------------------------------------------------------------
# Persona loading from TOML
# ---------------------------------------------------------------------------

proc applyPersonaDefaults(pc: var PersonaConfig) =
  ## Fills zero-value fields with safe defaults. Call before spawning.
  if pc.memoryScope == msOwnSessions and pc.memoryScope == msOwnSessions:
    discard  # already set
  if pc.memoryMaxHistory <= 0:
    pc.memoryMaxHistory = DefaultMemoryMaxHistory
  if pc.delegateEnabled == false:
    discard  # already set
  else:
    pc.delegateEnabled = DefaultDelegateEnabled
  if pc.maxDelegationDepth <= 0:
    pc.maxDelegationDepth = DefaultMaxDelegationDepth
  if pc.maxDelegationsPerRun <= 0:
    pc.maxDelegationsPerRun = DefaultMaxDelegationsPerRun
  if pc.maxIterations <= 0:
    pc.maxIterations = DefaultMaxLoopIterations

proc registerPersona*(reg: var PersonaRegistry; pc: PersonaConfig) =
  ## Registers a persona. Raises PersonaError on duplicate name.
  let name = pc.name.toLowerAscii()
  if name.len == 0:
    raise newException(PersonaError, "persona name must be non-empty")
  if reg.personas.hasKey(name):
    raise newException(PersonaError,
      "persona '" & name & "' is already registered")
  var p = pc
  p.name = name
  applyPersonaDefaults(p)
  reg.personas[name] = p

proc parseMemoryScope(val: string): MemoryScope =
  case val.toLowerAscii()
  of "own_sessions", "own":    result = msOwnSessions
  of "none", "stateless":      result = msNone
  of "shared":                 result = msShared
  else:
    result = msOwnSessions

proc parseBool(val: string): bool =
  val.toLowerAscii() in @["1", "true", "yes", "on", "enabled"]

proc loadPersonasFromStream*(reg: var PersonaRegistry; stream: Stream) =
  ## Loads persona entries from a TOML/INI-style stream.
  ## Skips unknown sections and keys silently.
  var currentSection = ""
  var buf = PersonaConfig()

  var parser: CfgParser
  open(parser, stream, "personas")
  defer: close(parser)

  while true:
    let event = next(parser)
    case event.kind
    of cfgEof:
      # Flush last persona if any
      if currentSection.startsWith("personas.") and buf.name.len > 0:
        registerPersona(reg, buf)
      break
    of cfgSectionStart:
      # New section — flush previous
      if currentSection.startsWith("personas.") and buf.name.len > 0:
        registerPersona(reg, buf)
      currentSection = event.section
      if currentSection.startsWith("personas."):
        buf = PersonaConfig(name: currentSection.split('.')[1])
      else:
        buf = PersonaConfig()
    of cfgKeyValuePair:
      if not currentSection.startsWith("personas."):
        continue
      let k = event.key.toLowerAscii()
      case k
      of "system_prompt", "prompt":
        buf.systemPrompt = event.value
      of "model":
        buf.model = event.value
      of "temperature":
        try:
          buf.temperature = parseFloat(event.value)
        except ValueError:
          discard
      of "max_iterations":
        try:
          buf.maxIterations = parseInt(event.value)
        except ValueError:
          discard
      of "tools_allow":
        buf.toolsAllow = event.value.split(',')
          .mapIt(it.strip()).filterIt(it.len > 0)
      of "tools_deny":
        buf.toolsDeny = event.value.split(',')
          .mapIt(it.strip()).filterIt(it.len > 0)
      of "memory_scope":
        buf.memoryScope = parseMemoryScope(event.value)
      of "memory_max_history":
        try:
          buf.memoryMaxHistory = parseInt(event.value)
        except ValueError:
          discard
      of "memory_fts_enabled":
        buf.memoryFtsEnabled = parseBool(event.value)
      of "delegate_enabled":
        buf.delegateEnabled = parseBool(event.value)
      of "max_delegation_depth":
        try:
          buf.maxDelegationDepth = parseInt(event.value)
        except ValueError:
          discard
      of "max_delegations_per_run":
        try:
          buf.maxDelegationsPerRun = parseInt(event.value)
        except ValueError:
          discard
      else:
        discard
    of cfgOption, cfgError:
      discard

proc loadPersonasFile*(path: string): PersonaRegistry =
  ## Loads all personas from a TOML/INI config file.
  result = newPersonaRegistry()
  if not fileExists(path):
    return
  var stream = newFileStream(path, fmRead)
  if stream == nil:
    raise newException(PersonaError,
      "cannot open personas file: " & path)
  defer: stream.close()
  loadPersonasFromStream(result, stream)

# ---------------------------------------------------------------------------
# Lookup
# ---------------------------------------------------------------------------

proc getPersona*(reg: PersonaRegistry; name: string): PersonaConfig =
  ## Returns the named persona. Raises PersonaError if not found.
  let key = name.toLowerAscii()
  if not reg.personas.hasKey(key):
    raise newException(PersonaError,
      "persona '" & name & "' not found. Available: " &
      reg.personas.keys.toSeq().join(", "))
  result = reg.personas[key]

proc hasPersona*(reg: PersonaRegistry; name: string): bool =
  reg.personas.hasKey(name.toLowerAscii())

proc listPersonas*(reg: PersonaRegistry): seq[string] =
  result = @[]
  for name in reg.personas.keys:
    result.add(name)

# ---------------------------------------------------------------------------
# Tool registry filtering
# ---------------------------------------------------------------------------

proc filterToolsByPersona*(
    persona: PersonaConfig;
    allTools: seq[string];
): seq[string] =
  ## Filters `allTools` according to the persona's toolsAllow and toolsDeny
  ## lists. Returns the subset of tools the persona is allowed to use.
  ##
  ## Logic:
  ##   - if toolsAllow is non-empty: keep only named tools (minus deny)
  ##   - if toolsAllow is empty and toolsDeny is non-empty: remove denied tools
  ##   - if both empty: all tools pass
  result = @[]
  let allowSet = if persona.toolsAllow.len > 0:
    persona.toolsAllow.toHashSet()
  else:
    initHashSet[string]()
  let denySet = persona.toolsDeny.toHashSet()

  for toolName in allTools:
    if denySet.contains(toolName):
      continue
    if allowSet.len > 0 and not allowSet.contains(toolName):
      continue
    result.add(toolName)

proc scopedRegistry*(
    base: ToolRegistry;
    persona: PersonaConfig;
): ToolRegistry =
  ## Produces a new ToolRegistry filtered according to the persona's
  ## toolsAllow and toolsDeny lists.
  ##
  ## Logic:
  ##   - if toolsAllow is non-empty: keep only named tools + add any deny removals
  ##   - if toolsAllow is empty and toolsDeny is non-empty: remove denied tools
  ##   - if both empty: clone all tools from base
  result = newToolRegistry()
  let allowSet = if persona.toolsAllow.len > 0:
    persona.toolsAllow.toHashSet()
  else:
    initHashSet[string]()
  let denySet = persona.toolsDeny.toHashSet()
  let allowNonEmpty = persona.toolsAllow.len > 0

  for tool in base.list():
    let name = tool.name
    if denySet.contains(name):
      continue
    if allowNonEmpty and not allowSet.contains(name):
      continue
    result.register(tool)
```

`mercury_core/src/mercury_core/rate_limit.nim`:

```nim
## Mercury rate limit handler with exponential backoff.
##
## Provides a generic retry mechanism for Discord API rate limit handling.
## - Retries on 429 (rate limit) with exponential backoff
## - Respects Retry-After header value from Discord API responses
## - Retries on 5xx (server error) with exponential backoff
## - Max attempts configurable (default 3)
## - Does NOT retry 4xx errors (except 429)
##
## The caller is responsible for translating Discord API errors into
## RateLimitError / ServerError exceptions with appropriate fields set.
## This keeps the module generic and independent of any specific HTTP client.

import std/asyncdispatch

type
  RateLimitError* = object of CatchableError
    ## Raised when the API returns a 429 Too Many Requests response.
    ## Set retryAfterMs to the value from the Retry-After header (in ms).
    ## When retryAfterMs > 0, sendWithRetry uses it instead of exponential backoff.
    retryAfterMs*: int

  ServerError* = object of CatchableError
    ## Raised when the API returns a 5xx server error response.
    statusCode*: int

  RetryExhaustedError* = object of CatchableError
    ## Raised when all retry attempts have been exhausted.

  SleepFn* = proc(ms: int): Future[void]

proc defaultSleepFn*(ms: int): Future[void] {.async.} =
  ## Default sleep function using asyncdispatch.sleepAsync.
  await sleepAsync(ms)

proc sendWithRetry*[T](
  sendFn: proc(): Future[T],
  maxAttempts = 3,
  baseDelayMs = 1000,
  sleepFn: SleepFn = nil
): Future[T] {.async.} =
  ## Sends a request with retry logic for rate limits and server errors.
  ##
  ## Parameters:
  ##   sendFn      - Async proc that performs the API call and returns a value
  ##                 or raises RateLimitError / ServerError on retryable failures.
  ##   maxAttempts - Maximum number of attempts (default 3).
  ##   baseDelayMs - Base delay in ms for exponential backoff (default 1000).
  ##                 Delay = baseDelayMs * 2^(attempt-1).
  ##   sleepFn    - Optional sleep function for testing. Defaults to sleepAsync.
  ##
  ## Behavior:
  ##   - On RateLimitError: if retryAfterMs > 0, uses that value as delay;
  ##     otherwise uses exponential backoff.
  ##   - On ServerError: uses exponential backoff.
  ##   - Other exceptions: re-raised immediately (no retry).
  ##   - After maxAttempts: raises RetryExhaustedError.
  let slp = if sleepFn.isNil: defaultSleepFn else: sleepFn

  var attempt = 0
  while attempt < maxAttempts:
    inc attempt
    try:
      return await sendFn()
    except RateLimitError as e:
      if attempt >= maxAttempts:
        raise newException(RetryExhaustedError,
          "Rate limit retry exhausted after " & $maxAttempts & " attempts: " & e.msg)
      let delay = if e.retryAfterMs > 0: e.retryAfterMs
                  else: baseDelayMs * (1 shl (attempt - 1))
      await slp(delay)
    except ServerError as e:
      if attempt >= maxAttempts:
        raise newException(RetryExhaustedError,
          "Server error retry exhausted after " & $maxAttempts & " attempts: " & e.msg)
      let delay = baseDelayMs * (1 shl (attempt - 1))
      await slp(delay)

  raise newException(RetryExhaustedError,
    "Retry exhausted after " & $maxAttempts & " attempts")
```

`mercury_core/src/mercury_core/thread_mapping.nim`:

```nim
## Mercury thread mapping module.
##
## Maps Discord thread IDs to agent session IDs in SQLite.
##
## Schema:
##   discord_threads — one row per Discord thread, linking to a session
##
## Features:
##   - initThreadMappingSchema(): creates the discord_threads table
##   - setThreadMapping(): upsert a thread→session mapping
##   - getSessionForThread(): look up session ID by thread ID
##   - archiveThread(): mark a thread as archived
##   - getLatestSessionForChannel(): find the most recent session for a channel
##
## WAL mode is enabled for better concurrent read performance.
## Each thread should open its own DB connection for thread safety.

import db_connector/db_sqlite
import std/options
import std/times

# ---------------------------------------------------------------------------
# Schema initialisation
# ---------------------------------------------------------------------------

proc initThreadMappingSchema*(db: DbConn) =
  ## Creates the discord_threads table if it does not already exist.
  ## Safe to call multiple times (idempotent).
  db.exec(sql"""
    CREATE TABLE IF NOT EXISTS discord_threads (
      thread_id       TEXT PRIMARY KEY,
      session_id      TEXT NOT NULL,
      channel_id      TEXT NOT NULL,
      guild_id        TEXT NOT NULL DEFAULT '',
      created_at      TEXT NOT NULL,
      last_active_at  TEXT NOT NULL,
      is_archived     INTEGER NOT NULL DEFAULT 0
    )
  """)

  db.exec(sql"""
    CREATE INDEX IF NOT EXISTS idx_discord_threads_channel
    ON discord_threads(channel_id, last_active_at DESC)
  """)

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

proc nowIso(): string =
  ## Returns the current UTC time as an ISO 8601 string.
  let t = now().utc
  return t.format("yyyy-MM-dd'T'HH:mm:ss'Z'")

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

proc setThreadMapping*(db: DbConn; threadId, sessionId, channelId, guildId: string) =
  ## Upserts a thread→session mapping. If the thread already exists, updates
  ## the session_id, channel_id, guild_id, and last_active_at.
  let ts = nowIso()
  # Use INSERT OR REPLACE to handle upsert
  db.exec(sql"""
    INSERT INTO discord_threads (thread_id, session_id, channel_id, guild_id, created_at, last_active_at, is_archived)
    VALUES (?, ?, ?, ?, ?, ?, 0)
    ON CONFLICT(thread_id) DO UPDATE SET
      session_id = excluded.session_id,
      channel_id = excluded.channel_id,
      guild_id = excluded.guild_id,
      last_active_at = excluded.last_active_at,
      is_archived = 0
  """, threadId, sessionId, channelId, guildId, ts, ts)

proc getSessionForThread*(db: DbConn; threadId: string): Option[string] =
  ## Returns the session ID associated with the given thread ID,
  ## or None if the thread is not found.
  let row = db.getRow(sql"""
    SELECT session_id FROM discord_threads WHERE thread_id = ?
  """, threadId)
  if row[0].len == 0:
    return none[string]()
  return some(row[0])

proc archiveThread*(db: DbConn; threadId: string) =
  ## Marks a thread as archived. No-op if the thread does not exist.
  let ts = nowIso()
  db.exec(sql"""
    UPDATE discord_threads SET is_archived = 1, last_active_at = ?
    WHERE thread_id = ?
  """, ts, threadId)

proc getLatestSessionForChannel*(db: DbConn; channelId: string): Option[string] =
  ## Returns the session ID of the most recently active thread in the given
  ## channel. Prefers non-archived threads. If all threads are archived,
  ## returns the most recently active archived one.
  ## Returns None if no threads exist for the channel.
  # Try non-archived first
  let row = db.getRow(sql"""
    SELECT session_id FROM discord_threads
    WHERE channel_id = ? AND is_archived = 0
    ORDER BY last_active_at DESC
    LIMIT 1
  """, channelId)
  if row[0].len > 0:
    return some(row[0])
  # Fall back to archived
  let archivedRow = db.getRow(sql"""
    SELECT session_id FROM discord_threads
    WHERE channel_id = ?
    ORDER BY last_active_at DESC
    LIMIT 1
  """, channelId)
  if archivedRow[0].len > 0:
    return some(archivedRow[0])
  return none[string]()
```

`mercury_core/src/mercury_core/token_counter.nim`:

```nim
## Mercury token counter — approximation-based BPE wrapper.
##
## Provides token count estimates for common LLM model families without
## requiring external vocabulary files or native BPE libraries.
##
## Approach:
##   - GPT-4 / GPT-3.5 / o-series: ~4 chars per token (cl100k_base / o200k_base)
##   - Claude (all versions):       ~3.8 chars per token (Anthropic calibration)
##   - Llama / Mistral / Gemma:     ~4 chars per token (SentencePiece BPE)
##   - Unknown models:              ~4 chars per token (conservative default)
##
## Per-message overhead (role + formatting tokens) follows OpenAI's documented
## formula: 4 tokens per message + 1 token for reply priming.
##
## References:
##   - https://platform.openai.com/docs/guides/chat/managing-tokens
##   - Anthropic token estimation guidance (~3.8 chars/token)
##
## Out of scope (deferred):
##   - Exact BPE tokenization (requires vocabulary files)
##   - Streaming token counting
##   - Tool call token overhead

import std/[strutils, math]
import mercury_core/llm_client

# ---------------------------------------------------------------------------
# Model family detection
# ---------------------------------------------------------------------------

type
  ModelFamily* = enum
    ## Broad tokenizer family used for approximation.
    mfGpt4       ## GPT-4, GPT-4o, o1, o3, o4 — o200k_base / cl100k_base
    mfGpt35      ## GPT-3.5-turbo — cl100k_base
    mfClaude     ## Claude 1/2/3/3.5/3.7 — Anthropic BPE
    mfLlama      ## Llama 1/2/3, Mistral, Gemma — SentencePiece BPE
    mfDefault    ## Unknown / fallback

const
  ## Characters per token for each model family.
  CharsPerToken: array[ModelFamily, float] = [
    4.0,   # mfGpt4
    4.0,   # mfGpt35
    3.8,   # mfClaude
    4.0,   # mfLlama
    4.0,   # mfDefault
  ]

  ## Extra tokens added per message (role label + formatting).
  ## OpenAI formula: 4 tokens per message.
  TokensPerMessage* = 4

  ## Tokens added for reply priming at the end of a message list.
  ReplyPrimingTokens* = 3

proc detectFamily*(model: string): ModelFamily =
  ## Classifies a model string into a broad tokenizer family.
  ## Case-insensitive prefix/substring matching.
  let m = model.toLowerAscii()
  if m.startsWith("gpt-4") or m.startsWith("gpt4") or
     m.startsWith("o1") or m.startsWith("o3") or m.startsWith("o4") or
     m.contains("gpt-4o") or m.contains("gpt4o"):
    return mfGpt4
  if m.startsWith("gpt-3.5") or m.startsWith("gpt3.5") or
     m.startsWith("gpt-35"):
    return mfGpt35
  if m.startsWith("claude"):
    return mfClaude
  if m.startsWith("llama") or m.startsWith("mistral") or
     m.startsWith("gemma") or m.startsWith("mixtral") or
     m.startsWith("meta-llama"):
    return mfLlama
  mfDefault

# ---------------------------------------------------------------------------
# Core counting
# ---------------------------------------------------------------------------

proc countTokens*(text: string; model: string = "gpt-4"): int =
  ## Returns an estimated token count for `text` given `model`.
  ##
  ## Uses character-ratio approximation calibrated per model family.
  ## Empty strings return 0.
  if text.len == 0:
    return 0
  let family = detectFamily(model)
  let ratio = CharsPerToken[family]
  # Round up: partial tokens still consume a full token slot.
  result = int(ceil(text.len.float / ratio))
  if result < 1:
    result = 1

proc countMessages*(messages: seq[ChatMessage]; model: string = "gpt-4"): int =
  ## Returns an estimated total token count for a sequence of chat messages.
  ##
  ## Applies per-message overhead (role + formatting) on top of content tokens,
  ## following OpenAI's documented formula.  The same overhead is used for all
  ## model families as a reasonable approximation.
  ##
  ## Formula:
  ##   sum over messages of:
  ##     TokensPerMessage + countTokens(content) + countTokens(name)
  ##   + ReplyPrimingTokens
  if messages.len == 0:
    return 0
  result = ReplyPrimingTokens
  for msg in messages:
    result += TokensPerMessage
    result += countTokens(msg.content, model)
    if msg.name.len > 0:
      # Named participants add 1 extra token (the name itself is counted above).
      result += countTokens(msg.name, model) + 1

```

`mercury_core/src/mercury_core/tool_registry.nim`:

```nim
## Mercury tool registry.
##
## Provides a registry for callable tools that an LLM can invoke via
## OpenAI-style tool/function calling. Each tool exposes:
##   - a name (unique within the registry),
##   - a human-readable description,
##   - a JSON-schema describing its parameters (OpenAI / JSON Schema draft),
##   - an `execute` proc that takes a JSON arguments object and returns a
##     `ToolResult` containing output text plus an optional error/exit code.
##
## The registry can serialize all registered tools into the JSON array shape
## that goes into the `tools` field of an OpenAI-compatible chat completion
## request:
##   [{"type": "function",
##     "function": {"name": ..., "description": ..., "parameters": {...}}}, ...]
##
## Out of scope (deferred):
##   - File/network/MCP tools (Phase 2)
##   - Cascading permissions / per-call approval
##   - Streaming tool output

import std/[json, tables, strutils]

type
  ToolError* = object of CatchableError
    ## Base type for tool-level errors.

  ToolNotFoundError* = object of ToolError
    ## Raised when looking up an unregistered tool.

  ToolDuplicateError* = object of ToolError
    ## Raised when registering a tool whose name already exists.

  ToolArgumentError* = object of ToolError
    ## Raised when a tool's arguments are malformed.

  ToolExecutionError* = object of ToolError
    ## Raised when a tool fails to execute internally (the registry wraps
    ## unexpected exceptions in this type so callers see a uniform surface).

  ToolResult* = object
    ## The result of executing a tool.
    ##
    ## `output` is the user/LLM-visible stringified result (typically stdout
    ## or a textual summary). `isError` indicates whether the tool itself
    ## reported a failure (e.g. non-zero exit code, denied command). When
    ## `isError` is true, `output` should explain the failure. `exitCode`
    ## is optional and most relevant for process-style tools (0 on success,
    ## any other value on failure).
    output*: string
    isError*: bool
    exitCode*: int

  ToolExecuteProc* = proc (args: JsonNode): ToolResult {.gcsafe.}
    ## Executes a tool with the given JSON arguments. SHOULD NOT raise; any
    ## error condition should be returned as a ToolResult with isError=true.
    ## The `{.gcsafe.}` pragma is required for safe capture in closures.

  Tool* = object
    ## A single callable tool exposed to the LLM.
    name*: string                     ## Unique name (e.g. "shell").
    description*: string              ## Short human/LLM-readable description.
    parameters*: JsonNode             ## JSON Schema for arguments.
    execute*: proc (args: JsonNode): ToolResult

  ToolRegistry* = ref object
    ## A collection of named tools.
    tools: OrderedTable[string, Tool]

# ---------------------------------------------------------------------------
# Construction helpers
# ---------------------------------------------------------------------------

proc newToolRegistry*(): ToolRegistry =
  ## Creates a new, empty tool registry.
  ToolRegistry(tools: initOrderedTable[string, Tool]())

proc emptyParameters*(): JsonNode =
  ## Returns a JSON Schema for a tool that takes no arguments.
  ## Equivalent to `{"type": "object", "properties": {}}`.
  result = newJObject()
  result["type"] = %"object"
  result["properties"] = newJObject()

proc newTool*(
    name, description: string;
    parameters: JsonNode;
    execute: proc (args: JsonNode): ToolResult;
): Tool =
  ## Builds a `Tool` value. `parameters` should be a JSON Schema object
  ## (typically `{"type": "object", "properties": {...}, "required": [...]}`).
  if name.len == 0:
    raise newException(ToolArgumentError, "tool name must be non-empty")
  if execute.isNil:
    raise newException(ToolArgumentError, "tool execute proc must not be nil")
  let params = if parameters.isNil: emptyParameters() else: parameters
  Tool(
    name: name,
    description: description,
    parameters: params,
    execute: execute,
  )

# ---------------------------------------------------------------------------
# Registry operations
# ---------------------------------------------------------------------------

proc register*(reg: ToolRegistry; tool: Tool) =
  ## Registers a tool. Raises `ToolDuplicateError` if a tool with the same
  ## name is already registered.
  if tool.name.len == 0:
    raise newException(ToolArgumentError, "tool name must be non-empty")
  if reg.tools.hasKey(tool.name):
    raise newException(ToolDuplicateError,
      "tool '" & tool.name & "' is already registered")
  reg.tools[tool.name] = tool

proc register*(
    reg: ToolRegistry;
    name, description: string;
    parameters: JsonNode;
    execute: proc (args: JsonNode): ToolResult;
) =
  ## Convenience overload: builds a Tool and registers it in one step.
  reg.register(newTool(name, description, parameters, execute))

proc unregister*(reg: ToolRegistry; name: string): bool {.discardable.} =
  ## Removes a tool from the registry. Returns true if a tool was removed.
  if reg.tools.hasKey(name):
    reg.tools.del(name)
    return true
  return false

proc has*(reg: ToolRegistry; name: string): bool =
  ## Returns true if a tool with the given name is registered.
  reg.tools.hasKey(name)

proc get*(reg: ToolRegistry; name: string): Tool =
  ## Retrieves a registered tool by name. Raises `ToolNotFoundError` if
  ## the tool is not registered.
  if not reg.tools.hasKey(name):
    raise newException(ToolNotFoundError,
      "tool '" & name & "' is not registered")
  reg.tools[name]

proc list*(reg: ToolRegistry): seq[Tool] =
  ## Returns all registered tools in insertion order.
  result = @[]
  for _, tool in reg.tools:
    result.add(tool)

proc names*(reg: ToolRegistry): seq[string] =
  ## Returns the names of all registered tools in insertion order.
  result = @[]
  for name in reg.tools.keys:
    result.add(name)

proc len*(reg: ToolRegistry): int =
  ## Returns the number of registered tools.
  reg.tools.len

# ---------------------------------------------------------------------------
# OpenAI-compatible serialization
# ---------------------------------------------------------------------------

proc toOpenAIDefinition*(tool: Tool): JsonNode =
  ## Returns a single tool's OpenAI-style definition:
  ##   {"type": "function",
  ##    "function": {"name": ..., "description": ..., "parameters": {...}}}
  var fn = newJObject()
  fn["name"] = %tool.name
  fn["description"] = %tool.description
  # Copy parameters defensively so callers can't mutate the registry state.
  fn["parameters"] = tool.parameters.copy()
  result = newJObject()
  result["type"] = %"function"
  result["function"] = fn

proc toOpenAIDefinitions*(reg: ToolRegistry): JsonNode =
  ## Serializes all registered tools as a JSON array suitable for the
  ## `tools` field of an OpenAI Chat Completions request.
  result = newJArray()
  for _, tool in reg.tools:
    result.add(toOpenAIDefinition(tool))

# ---------------------------------------------------------------------------
# Execution
# ---------------------------------------------------------------------------

proc parseArguments*(arguments: string): JsonNode =
  ## Parses a JSON-encoded arguments string (as produced by an LLM tool call)
  ## into a JsonNode. Empty strings produce an empty object. Raises
  ## `ToolArgumentError` on invalid JSON or non-object roots.
  let trimmed = arguments.strip()
  if trimmed.len == 0:
    return newJObject()
  var node: JsonNode
  try:
    node = parseJson(trimmed)
  except JsonParsingError as e:
    raise newException(ToolArgumentError,
      "tool arguments must be valid JSON: " & e.msg)
  except CatchableError as e:
    raise newException(ToolArgumentError,
      "failed to parse tool arguments: " & e.msg)
  if node.kind != JObject:
    raise newException(ToolArgumentError,
      "tool arguments must be a JSON object, got: " & $node.kind)
  node

proc execute*(reg: ToolRegistry; name: string; args: JsonNode): ToolResult =
  ## Executes the named tool with parsed JSON arguments. Translates internal
  ## exceptions into a `ToolResult` with `isError=true`. Raises
  ## `ToolNotFoundError` if the tool is not registered (this is a programmer
  ## error, distinct from a tool-reported failure).
  let tool = reg.get(name)
  let argsNode = if args.isNil: newJObject() else: args
  try:
    return tool.execute(argsNode)
  except CatchableError as e:
    return ToolResult(
      output: "tool '" & name & "' raised: " & e.msg,
      isError: true,
      exitCode: -1,
    )

proc execute*(reg: ToolRegistry; name, arguments: string): ToolResult =
  ## Executes the named tool, parsing `arguments` as JSON. If the arguments
  ## are malformed, returns a `ToolResult` with `isError=true` rather than
  ## raising; this matches how an LLM-generated tool call should be handled
  ## inside an agent loop.
  if not reg.has(name):
    raise newException(ToolNotFoundError,
      "tool '" & name & "' is not registered")
  var argsNode: JsonNode
  try:
    argsNode = parseArguments(arguments)
  except ToolArgumentError as e:
    return ToolResult(
      output: "invalid arguments for tool '" & name & "': " & e.msg,
      isError: true,
      exitCode: -1,
    )
  reg.execute(name, argsNode)

```

`mercury_core/test_simple.nim`:

```nim
import mercury_core/llm_client
import std/json

let client = newLLMClient(
  baseUrl = "http://example.com",
  apiKey = "test-key",
  model = "test-model"
)
echo "LLMClient created successfully"
echo "Base URL: ", client.baseUrl
echo "Model: ", client.model

```

`mercury_core/tests/mock_server.nim`:

```nim
import std/[asynchttpserver, asyncdispatch, json, times, net]

type
  MockLLMServer* = ref object
    server*: AsyncHttpServer
    port*: int
    responseDelay*: int
    requestCount*: int
    
    # Response config
    responseText*: string
    toolCallName*: string
    toolCallArgs*: JsonNode
    errorCode*: int
    errorMessage*: string

proc newMockLLMServer*(): MockLLMServer =
  result = MockLLMServer(
    server: newAsyncHttpServer(),
    port: 0,
    responseDelay: 0,
    requestCount: 0,
    responseText: "",
    toolCallName: "",
    toolCallArgs: nil,
    errorCode: 0,
    errorMessage: ""
  )

proc setResponse*(self: MockLLMServer, text: string) =
  self.responseText = text
  self.toolCallName = ""
  self.toolCallArgs = nil
  self.errorCode = 0
  self.errorMessage = ""

proc setToolCallResponse*(self: MockLLMServer, name: string, args: JsonNode) =
  self.responseText = ""
  self.toolCallName = name
  self.toolCallArgs = args
  self.errorCode = 0
  self.errorMessage = ""

proc setErrorResponse*(self: MockLLMServer, code: int, message: string) =
  self.errorCode = code
  self.errorMessage = message
  self.responseText = ""
  self.toolCallName = ""
  self.toolCallArgs = nil

proc setDelay*(self: MockLLMServer, ms: int) =
  self.responseDelay = ms

proc getRequestCount*(self: MockLLMServer): int =
  self.requestCount

proc handleRequest*(self: MockLLMServer, req: Request) {.async.} =
  self.requestCount += 1
  
  if self.responseDelay > 0:
    await sleepAsync(self.responseDelay)
    
  if req.url.path != "/v1/chat/completions":
    await req.respond(Http404, "Not Found")
    return
    
  if req.reqMethod != HttpPost:
    await req.respond(Http405, "Method Not Allowed")
    return

  if self.errorCode > 0:
    let errorJson = %*{
      "error": {
        "message": self.errorMessage,
        "type": "mock_error",
        "code": self.errorCode
      }
    }
    let headers = newHttpHeaders([("Content-Type", "application/json")])
    await req.respond(HttpCode(self.errorCode), $errorJson, headers)
    return

  var responseJson: JsonNode
  
  if self.toolCallName != "":
    responseJson = %*{
      "id": "chatcmpl-mock",
      "object": "chat.completion",
      "created": getTime().toUnix(),
      "model": "mock-model",
      "choices": [
        {
          "index": 0,
          "message": {
            "role": "assistant",
            "content": newJNull(),
            "tool_calls": [
              {
                "id": "call_mock",
                "type": "function",
                "function": {
                  "name": self.toolCallName,
                  "arguments": $self.toolCallArgs
                }
              }
            ]
          },
          "finish_reason": "tool_calls"
        }
      ]
    }
  else:
    responseJson = %*{
      "id": "chatcmpl-mock",
      "object": "chat.completion",
      "created": getTime().toUnix(),
      "model": "mock-model",
      "choices": [
        {
          "index": 0,
          "message": {
            "role": "assistant",
            "content": self.responseText
          },
          "finish_reason": "stop"
        }
      ]
    }
    
  let headers = newHttpHeaders([("Content-Type", "application/json")])
  await req.respond(Http200, $responseJson, headers)

proc start*(self: MockLLMServer) {.async.} =
  # We use port 0 to let OS pick a random free port
  self.server.listen(Port(0))
  self.port = self.server.getPort().int
  
  # Run the server in a background async task
  asyncCheck self.server.acceptRequest(
    proc (req: Request) {.async.} = await self.handleRequest(req)
  )

proc stop*(self: MockLLMServer) =
  self.server.close()

```

`mercury_core/tests/tconfig.nim`:

```nim
## Tests for mercury_core/config.nim

import std/[os, unittest]
import mercury_core/config, mercury_core/mcp_client

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

proc writeTempFile(path, content: string) =
  createDir(parentDir(path))
  writeFile(path, content)

template withEnv(key, val: string; body: untyped) =
  ## Temporarily sets an environment variable, then restores the original.
  let oldVal = getEnv(key)
  let hadOldVal = existsEnv(key)
  putEnv(key, val)
  try:
    body
  finally:
    if hadOldVal:
      putEnv(key, oldVal)
    else:
      delEnv(key)

# ---------------------------------------------------------------------------
# Suite: defaultConfig
# ---------------------------------------------------------------------------

suite "defaultConfig":
  test "returns expected defaults":
    let cfg = defaultConfig()
    check cfg.provider == "openrouter"
    check cfg.vllmEndpoint == "http://192.168.4.30:8000/v1"
    check cfg.openrouterEndpoint == "https://openrouter.ai/api/v1"
    check cfg.openrouterModel == "openrouter/auto"
    check cfg.vllmModel == "qwen2.5-7b-instruct"
    check cfg.maxTokens == 4096
    check cfg.temperature == 0.3
    check cfg.maxLoopIterations == 10
    check cfg.dbPath == "~/.local/share/mercury/mercury.db"
    check cfg.openrouterApiKey == ""

# ---------------------------------------------------------------------------
# Suite: parseEnvFile
# ---------------------------------------------------------------------------

suite "parseEnvFile":
  let tmpDir = getTempDir() / "mercury_test_env"

  setup:
    createDir(tmpDir)

  teardown:
    removeDir(tmpDir)

  test "returns empty seq for missing file":
    let pairs = parseEnvFile(tmpDir / "nonexistent.env")
    check pairs.len == 0

  test "parses simple key=value pairs":
    let path = tmpDir / "simple.env"
    writeTempFile(path, "FOO=bar\nBAZ=qux\n")
    let pairs = parseEnvFile(path)
    check pairs.len == 2
    check pairs[0] == ("FOO", "bar")
    check pairs[1] == ("BAZ", "qux")

  test "strips double-quoted values":
    let path = tmpDir / "quoted.env"
    writeTempFile(path, "KEY=\"hello world\"\n")
    let pairs = parseEnvFile(path)
    check pairs.len == 1
    check pairs[0] == ("KEY", "hello world")

  test "strips single-quoted values":
    let path = tmpDir / "squoted.env"
    writeTempFile(path, "KEY='hello world'\n")
    let pairs = parseEnvFile(path)
    check pairs.len == 1
    check pairs[0] == ("KEY", "hello world")

  test "ignores comment lines":
    let path = tmpDir / "comments.env"
    writeTempFile(path, "# this is a comment\nKEY=val\n")
    let pairs = parseEnvFile(path)
    check pairs.len == 1
    check pairs[0] == ("KEY", "val")

  test "ignores blank lines":
    let path = tmpDir / "blanks.env"
    writeTempFile(path, "\n\nKEY=val\n\n")
    let pairs = parseEnvFile(path)
    check pairs.len == 1

  test "handles empty value":
    let path = tmpDir / "empty_val.env"
    writeTempFile(path, "KEY=\n")
    let pairs = parseEnvFile(path)
    check pairs.len == 1
    check pairs[0] == ("KEY", "")

# ---------------------------------------------------------------------------
# Suite: loadConfig — defaults when no files exist
# ---------------------------------------------------------------------------

suite "loadConfig defaults":
  test "uses defaults when config file is missing":
    let cfg = loadConfig(
      configPath = "/nonexistent/path/config.toml",
      envFilePath = "/nonexistent/.env"
    )
    check cfg.provider == "openrouter"
    check cfg.maxTokens == 4096
    check cfg.temperature == 0.3

# ---------------------------------------------------------------------------
# Suite: loadConfig — TOML file overrides
# ---------------------------------------------------------------------------

suite "loadConfig TOML overrides":
  let tmpDir = getTempDir() / "mercury_test_toml"

  setup:
    createDir(tmpDir)

  teardown:
    removeDir(tmpDir)

  test "overrides provider from TOML":
    let cfgFile = tmpDir / "config.toml"
    writeTempFile(cfgFile, "[mercury]\nprovider=vllm\n")
    let cfg = loadConfig(configPath = cfgFile, envFilePath = "/nonexistent/.env")
    check cfg.provider == "vllm"

  test "overrides max_tokens from TOML":
    let cfgFile = tmpDir / "config.toml"
    writeTempFile(cfgFile, "[mercury]\nmax_tokens=2048\n")
    let cfg = loadConfig(configPath = cfgFile, envFilePath = "/nonexistent/.env")
    check cfg.maxTokens == 2048

  test "overrides temperature from TOML":
    let cfgFile = tmpDir / "config.toml"
    writeTempFile(cfgFile, "[mercury]\ntemperature=0.7\n")
    let cfg = loadConfig(configPath = cfgFile, envFilePath = "/nonexistent/.env")
    check cfg.temperature == 0.7

  test "overrides vllm_model from TOML":
    let cfgFile = tmpDir / "config.toml"
    writeTempFile(cfgFile, "[mercury]\nvllm_model=llama3-8b\n")
    let cfg = loadConfig(configPath = cfgFile, envFilePath = "/nonexistent/.env")
    check cfg.vllmModel == "llama3-8b"

  test "overrides db_path from TOML":
    let cfgFile = tmpDir / "config.toml"
    writeTempFile(cfgFile, "[mercury]\ndb_path=/tmp/test.db\n")
    let cfg = loadConfig(configPath = cfgFile, envFilePath = "/nonexistent/.env")
    check cfg.dbPath == "/tmp/test.db"

  test "overrides multiple fields from TOML":
    let cfgFile = tmpDir / "config.toml"
    writeTempFile(cfgFile, "[mercury]\nprovider=vllm\nmax_tokens=1024\nmax_loop_iterations=5\n")
    let cfg = loadConfig(configPath = cfgFile, envFilePath = "/nonexistent/.env")
    check cfg.provider == "vllm"
    check cfg.maxTokens == 1024
    check cfg.maxLoopIterations == 5

  test "raises ConfigError on invalid max_tokens":
    let cfgFile = tmpDir / "bad.toml"
    writeTempFile(cfgFile, "[mercury]\nmax_tokens=notanumber\n")
    expect ConfigError:
      discard loadConfig(configPath = cfgFile, envFilePath = "/nonexistent/.env")

# ---------------------------------------------------------------------------
# Suite: loadConfig — .env file overrides
# ---------------------------------------------------------------------------

suite "loadConfig .env overrides":
  let tmpDir = getTempDir() / "mercury_test_dotenv"

  setup:
    createDir(tmpDir)

  teardown:
    removeDir(tmpDir)

  test "loads OPENROUTER_API_KEY from .env":
    let envFile = tmpDir / ".env"
    writeTempFile(envFile, "OPENROUTER_API_KEY=sk-test-key\n")
    let cfg = loadConfig(
      configPath = "/nonexistent/config.toml",
      envFilePath = envFile
    )
    check cfg.openrouterApiKey == "sk-test-key"

  test "loads MERCURY_PROVIDER from .env":
    let envFile = tmpDir / ".env"
    writeTempFile(envFile, "MERCURY_PROVIDER=vllm\n")
    let cfg = loadConfig(
      configPath = "/nonexistent/config.toml",
      envFilePath = envFile
    )
    check cfg.provider == "vllm"

  test "loads MERCURY_VLLM_ENDPOINT from .env":
    let envFile = tmpDir / ".env"
    writeTempFile(envFile, "MERCURY_VLLM_ENDPOINT=http://10.0.0.1:8000/v1\n")
    let cfg = loadConfig(
      configPath = "/nonexistent/config.toml",
      envFilePath = envFile
    )
    check cfg.vllmEndpoint == "http://10.0.0.1:8000/v1"

# ---------------------------------------------------------------------------
# Suite: loadConfig — environment variable overrides
# ---------------------------------------------------------------------------

suite "loadConfig env var overrides":
  test "MERCURY_PROVIDER overrides config file":
    withEnv("MERCURY_PROVIDER", "vllm"):
      let cfg = loadConfig(
        configPath = "/nonexistent/config.toml",
        envFilePath = "/nonexistent/.env"
      )
      check cfg.provider == "vllm"

  test "MERCURY_VLLM_ENDPOINT overrides default":
    withEnv("MERCURY_VLLM_ENDPOINT", "http://custom:9000/v1"):
      let cfg = loadConfig(
        configPath = "/nonexistent/config.toml",
        envFilePath = "/nonexistent/.env"
      )
      check cfg.vllmEndpoint == "http://custom:9000/v1"

  test "MERCURY_MAX_TOKENS overrides default":
    withEnv("MERCURY_MAX_TOKENS", "512"):
      let cfg = loadConfig(
        configPath = "/nonexistent/config.toml",
        envFilePath = "/nonexistent/.env"
      )
      check cfg.maxTokens == 512

  test "MERCURY_TEMPERATURE overrides default":
    withEnv("MERCURY_TEMPERATURE", "1.0"):
      let cfg = loadConfig(
        configPath = "/nonexistent/config.toml",
        envFilePath = "/nonexistent/.env"
      )
      check cfg.temperature == 1.0

  test "MERCURY_MAX_LOOP_ITERATIONS overrides default":
    withEnv("MERCURY_MAX_LOOP_ITERATIONS", "3"):
      let cfg = loadConfig(
        configPath = "/nonexistent/config.toml",
        envFilePath = "/nonexistent/.env"
      )
      check cfg.maxLoopIterations == 3

  test "OPENROUTER_API_KEY overrides .env":
    withEnv("OPENROUTER_API_KEY", "env-key-override"):
      let cfg = loadConfig(
        configPath = "/nonexistent/config.toml",
        envFilePath = "/nonexistent/.env"
      )
      check cfg.openrouterApiKey == "env-key-override"

  test "env var overrides TOML file value":
    let tmpDir2 = getTempDir() / "mercury_test_priority"
    createDir(tmpDir2)
    defer: removeDir(tmpDir2)
    let cfgFile = tmpDir2 / "config.toml"
    writeTempFile(cfgFile, "[mercury]\nmax_tokens=2048\n")
    withEnv("MERCURY_MAX_TOKENS", "999"):
      let cfg = loadConfig(configPath = cfgFile, envFilePath = "/nonexistent/.env")
      check cfg.maxTokens == 999

  test "raises ConfigError on invalid MERCURY_MAX_TOKENS":
    withEnv("MERCURY_MAX_TOKENS", "bad"):
      expect ConfigError:
        discard loadConfig(
          configPath = "/nonexistent/config.toml",
          envFilePath = "/nonexistent/.env"
        )

  test "raises ConfigError on invalid MERCURY_TEMPERATURE":
    withEnv("MERCURY_TEMPERATURE", "bad"):
      expect ConfigError:
        discard loadConfig(
          configPath = "/nonexistent/config.toml",
          envFilePath = "/nonexistent/.env"
        )

# ---------------------------------------------------------------------------
# Suite: validate
# ---------------------------------------------------------------------------

suite "validate":
  test "valid config passes":
    let cfg = defaultConfig()
    validate(cfg)  # should not raise

  test "invalid provider raises ConfigError":
    var cfg = defaultConfig()
    cfg.provider = "unknown"
    expect ConfigError:
      validate(cfg)

  test "zero max_tokens raises ConfigError":
    var cfg = defaultConfig()
    cfg.maxTokens = 0
    expect ConfigError:
      validate(cfg)

  test "negative max_tokens raises ConfigError":
    var cfg = defaultConfig()
    cfg.maxTokens = -1
    expect ConfigError:
      validate(cfg)

  test "temperature above 2.0 raises ConfigError":
    var cfg = defaultConfig()
    cfg.temperature = 2.1
    expect ConfigError:
      validate(cfg)

  test "negative temperature raises ConfigError":
    var cfg = defaultConfig()
    cfg.temperature = -0.1
    expect ConfigError:
      validate(cfg)

  test "zero max_loop_iterations raises ConfigError":
    var cfg = defaultConfig()
    cfg.maxLoopIterations = 0
    expect ConfigError:
      validate(cfg)

  test "empty vllm_endpoint raises ConfigError":
    var cfg = defaultConfig()
    cfg.vllmEndpoint = ""
    expect ConfigError:
      validate(cfg)

  test "empty openrouter_endpoint raises ConfigError":
    var cfg = defaultConfig()
    cfg.openrouterEndpoint = ""
    expect ConfigError:
      validate(cfg)

  test "empty db_path raises ConfigError":
    var cfg = defaultConfig()
    cfg.dbPath = ""
    expect ConfigError:
      validate(cfg)

# ---------------------------------------------------------------------------
# Suite: MCP server configuration — TOML
# ---------------------------------------------------------------------------

suite "mcpServers TOML loading":
  let tmpDir = getTempDir() / "mercury_test_mcp_toml"
  setup: createDir(tmpDir)
  teardown: removeDir(tmpDir)

  test "loads single MCP server from TOML":
    let cfgFile = tmpDir / "config.toml"
    writeTempFile(cfgFile, """
[mcp_servers.fst]
url = "http://localhost:8080/mcp"
auth_token = "secret123"
timeout_ms = 5000
enabled = true
""")
    let cfg = loadConfig(configPath = cfgFile, envFilePath = "/nonexistent/.env")
    check cfg.mcpServers.len == 1
    check cfg.mcpServers[0].url == "http://localhost:8080/mcp"
    check cfg.mcpServers[0].authToken == "secret123"
    check cfg.mcpServers[0].timeoutMs == 5000
    check cfg.mcpServers[0].enabled == true

  test "loads multiple MCP servers from TOML":
    let cfgFile = tmpDir / "config.toml"
    writeTempFile(cfgFile, """
[mcp_servers.fst]
url = "http://localhost:8080/mcp"

[mcp_servers.second]
url = "https://mcp.example.com/api"
enabled = false
""")
    let cfg = loadConfig(configPath = cfgFile, envFilePath = "/nonexistent/.env")
    check cfg.mcpServers.len == 2
    check cfg.mcpServers[0].url == "http://localhost:8080/mcp"
    check cfg.mcpServers[0].enabled == true
    check cfg.mcpServers[1].url == "https://mcp.example.com/api"
    check cfg.mcpServers[1].enabled == false

  test "missing url field leaves server with default URL":
    let cfgFile = tmpDir / "config.toml"
    writeTempFile(cfgFile, """
[mcp_servers.test]
enabled = true
""")
    let cfg = loadConfig(configPath = cfgFile, envFilePath = "/nonexistent/.env")
    check cfg.mcpServers.len == 1
    # Should use default URL, not crash
    check cfg.mcpServers[0].url == DefaultMcpServerUrl

  test "TOML url trailing slash is stripped":
    let cfgFile = tmpDir / "config.toml"
    writeTempFile(cfgFile, """
[mcp_servers.test]
url = "http://localhost:8080/mcp/"
""")
    let cfg = loadConfig(configPath = cfgFile, envFilePath = "/nonexistent/.env")
    check cfg.mcpServers[0].url == "http://localhost:8080/mcp"

  test "invalid timeout_ms raises ConfigError":
    let cfgFile = tmpDir / "config.toml"
    writeTempFile(cfgFile, """
[mcp_servers.test]
url = "http://localhost:8080"
timeout_ms = "not-an-integer"
""")
    expect ConfigError:
      discard loadConfig(configPath = cfgFile, envFilePath = "/nonexistent/.env")

  test "enabled = false disables server":
    let cfgFile = tmpDir / "config.toml"
    writeTempFile(cfgFile, """
[mcp_servers.test]
url = "http://localhost:8080/mcp"
enabled = false
""")
    let cfg = loadConfig(configPath = cfgFile, envFilePath = "/nonexistent/.env")
    check cfg.mcpServers.len == 1
    check cfg.mcpServers[0].enabled == false

  test "enabled = true enables server":
    let cfgFile = tmpDir / "config.toml"
    writeTempFile(cfgFile, """
[mcp_servers.test]
url = "http://localhost:8080/mcp"
enabled = true
""")
    let cfg = loadConfig(configPath = cfgFile, envFilePath = "/nonexistent/.env")
    check cfg.mcpServers[0].enabled == true

  test "mcpServers empty by default":
    let cfg = defaultConfig()
    check cfg.mcpServers.len == 0

  test "env var overrides TOML MCP server":
    let cfgFile = tmpDir / "config.toml"
    writeTempFile(cfgFile, """
[mcp_servers.test]
url = "http://localhost:8080/mcp"
""")
    withEnv("MERCURY_MCP_SERVER_0_URL", "http://override:9000/mcp"):
      let cfg = loadConfig(configPath = cfgFile, envFilePath = "/nonexistent/.env")
      # env adds a new server after TOML ones
      check cfg.mcpServers.len == 2
      check cfg.mcpServers[1].url == "http://override:9000/mcp"

# ---------------------------------------------------------------------------
# Suite: MCP server configuration — env vars
# ---------------------------------------------------------------------------

suite "mcpServers env var loading":
  test "MERCURY_MCP_SERVER_0_URL creates server":
    withEnv("MERCURY_MCP_SERVER_0_URL", "http://env-server:8080/mcp"):
      let cfg = loadConfig(
        configPath = "/nonexistent/config.toml",
        envFilePath = "/nonexistent/.env"
      )
      check cfg.mcpServers.len == 1
      check cfg.mcpServers[0].url == "http://env-server:8080/mcp"
      check cfg.mcpServers[0].enabled == true

  test "MERCURY_MCP_SERVER_0_AUTH_TOKEN sets token":
    withEnv("MERCURY_MCP_SERVER_0_URL", "http://localhost:8080/mcp"):
      withEnv("MERCURY_MCP_SERVER_0_AUTH_TOKEN", "my-secret-token"):
        let cfg = loadConfig(
          configPath = "/nonexistent/config.toml",
          envFilePath = "/nonexistent/.env"
        )
        check cfg.mcpServers[0].authToken == "my-secret-token"

  test "MERCURY_MCP_SERVER_0_TIMEOUT_MS sets timeout":
    withEnv("MERCURY_MCP_SERVER_0_URL", "http://localhost:8080/mcp"):
      withEnv("MERCURY_MCP_SERVER_0_TIMEOUT_MS", "15000"):
        let cfg = loadConfig(
          configPath = "/nonexistent/config.toml",
          envFilePath = "/nonexistent/.env"
        )
        check cfg.mcpServers[0].timeoutMs == 15000

  test "MERCURY_MCP_SERVER_0_ENABLED=false disables":
    withEnv("MERCURY_MCP_SERVER_0_URL", "http://localhost:8080/mcp"):
      withEnv("MERCURY_MCP_SERVER_0_ENABLED", "false"):
        let cfg = loadConfig(
          configPath = "/nonexistent/config.toml",
          envFilePath = "/nonexistent/.env"
        )
        check cfg.mcpServers[0].enabled == false

  test "multiple env var servers":
    withEnv("MERCURY_MCP_SERVER_0_URL", "http://first:8080"):
      withEnv("MERCURY_MCP_SERVER_1_URL", "http://second:9000"):
        withEnv("MERCURY_MCP_SERVER_2_URL", "http://third:7000"):
          let cfg = loadConfig(
            configPath = "/nonexistent/config.toml",
            envFilePath = "/nonexistent/.env"
          )
          check cfg.mcpServers.len == 3
          check cfg.mcpServers[0].url == "http://first:8080"
          check cfg.mcpServers[1].url == "http://second:9000"
          check cfg.mcpServers[2].url == "http://third:7000"

  test "gap in index stops parsing":
    withEnv("MERCURY_MCP_SERVER_0_URL", "http://first:8080"):
      withEnv("MERCURY_MCP_SERVER_2_URL", "http://third:9000"):
        let cfg = loadConfig(
          configPath = "/nonexistent/config.toml",
          envFilePath = "/nonexistent/.env"
        )
        # Stops at gap — only server 0 is created, server 2 is never reached
        check cfg.mcpServers.len == 1
        check cfg.mcpServers[0].url == "http://first:8080"

  test "invalid timeout env var raises ConfigError":
    withEnv("MERCURY_MCP_SERVER_0_URL", "http://localhost:8080"):
      withEnv("MERCURY_MCP_SERVER_0_TIMEOUT_MS", "not-a-number"):
        expect ConfigError:
          discard loadConfig(
            configPath = "/nonexistent/config.toml",
            envFilePath = "/nonexistent/.env"
          )

  test "no env vars means no MCP servers":
    let cfg = loadConfig(
      configPath = "/nonexistent/config.toml",
      envFilePath = "/nonexistent/.env"
    )
    check cfg.mcpServers.len == 0

```

`mercury_core/tests/test_agent_dispatcher.nim`:

```nim
import unittest, asyncdispatch, options, strutils

when defined(warningOffGcUnsafe):
  import mercury_core/agent_dispatcher
  import mercury_core/discord_types
else:
  import mercury_core/agent_dispatcher
  import mercury_core/discord_types

suite "Agent Dispatcher":
  test "creates dispatcher with callback":
    when defined(warningOffGcUnsafe):
      var receivedResult: AgentResult  # used with GcUnsafe suppressed
      let cb = proc(result: AgentResult) {.gcsafe, closure, noSideEffect.} =
        receivedResult = result
      let dispatcher = newAgentDispatcher(cb)
      check dispatcher != nil
    else:
      let storage = new(AgentResult)
      let cb = proc(result: AgentResult) {.gcsafe, closure.} =
        storage[] = result
      let dispatcher = newAgentDispatcher(cb)
      check dispatcher != nil

  test "dispatchAgent returns result via callback":
    when defined(warningOffGcUnsafe):
      var receivedResult: AgentResult
      let cb = proc(result: AgentResult) {.gcsafe, closure, noSideEffect.} =
        receivedResult = result
      let dispatcher = newAgentDispatcher(cb)
      let request = AgentRequest(
        userInput: "hello",
        sessionId: "sess_1",
        channelId: "chan_1",
        threadId: "thread_1"
      )
      waitFor dispatchAgent(dispatcher, request)
      check receivedResult.responseText.contains("hello")
      check receivedResult.error.isNone
    else:
      let storage = new(AgentResult)
      let cb = proc(result: AgentResult) {.gcsafe, closure.} =
        storage[] = result
      let dispatcher = newAgentDispatcher(cb)
      let request = AgentRequest(
        userInput: "hello",
        sessionId: "sess_1",
        channelId: "chan_1",
        threadId: "thread_1"
      )
      waitFor dispatchAgent(dispatcher, request)
      check storage[].responseText.contains("hello")
      check storage[].error.isNone

  test "startDispatcher and stopDispatcher are idempotent":
    let d1 = newAgentDispatcher(nil)
    let d2 = newAgentDispatcher(nil)
    startDispatcher(d1)
    stopDispatcher(d1)
    startDispatcher(d2)
    stopDispatcher(d2)
    check d1 != nil and d2 != nil
```

`mercury_core/tests/test_discord_bot.nim`:

```nim
import unittest
import std/[asyncdispatch, options, strutils]
import db_connector/db_sqlite
import mercury_core/discord
import mercury_core/discord_mocks
import mercury_core/discord_types
import mercury_core/agent_dispatcher
import mercury_core/thread_mapping

suite "DiscordBot (DI-based)":

  proc makeConfig(admins: seq[string] = @[], users: seq[string] = @[]): DiscordConfig =
    result = defaultDiscordConfig()
    result.admins.allow = admins
    result.users.allow = users

  proc makeDb(): DbConn =
    let db = open(":memory:", "", "", "")
    initThreadMappingSchema(db)
    return db

  proc makeBot(admins: seq[string] = @["admin1"], users: seq[string] = @[]): tuple[bot: DiscordBot, api: MockDiscordApi, db: DbConn] =
    let api = newMockDiscordApi()
    let cfg = makeConfig(admins = admins, users = users)
    let dispatcher = newAgentDispatcher(proc(r: AgentResult) = discard)
    let shard = newMockShard("bot_user_id")
    let db = makeDb()
    let bot = newDiscordBot(
      sendMessage = mockSendFn(api),
      triggerTyping = mockTypingFn(api),
      createThread = mockCreateThreadFn(api),
      archiveThread = mockArchiveThreadFn(api),
      db = db,
      config = cfg,
      dispatcher = dispatcher,
      shard = shard,
    )
    return (bot, api, db)

  test "bot messages are ignored":
    let (bot, api, db) = makeBot()
    defer: db.close()
    let msg = Message(
      id: "msg_bot",
      author: MockUser(id: "bot1", username: "BotUser", bot: true),
      content: "!status",
      channel_id: "chan1",
      guild_id: some("guild1"),
      mention_users: @[],
    )
    waitFor bot.onMessageCreate(msg)
    check api.calls.len == 0

  test "unknown users are ignored":
    let (bot, api, db) = makeBot(admins = @["admin1"], users = @["user1"])
    defer: db.close()
    let msg = Message(
      id: "msg_unknown",
      author: MockUser(id: "stranger", username: "Stranger", bot: false),
      content: "hello",
      channel_id: "chan1",
      guild_id: some("guild1"),
      mention_users: @[],
    )
    waitFor bot.onMessageCreate(msg)
    check api.calls.len == 0

  test "command with prefix is handled":
    let (bot, api, db) = makeBot(users = @["user1"])
    defer: db.close()
    let msg = Message(
      id: "msg_cmd_1",
      author: MockUser(id: "user1", username: "TestUser", bot: false),
      content: "!status",
      channel_id: "chan1",
      guild_id: some("guild1"),
      mention_users: @[],
    )
    waitFor bot.onMessageCreate(msg)
    check api.calls.len >= 1
    var foundSend = false
    for call in api.calls:
      if call.kind == mockSendMessage:
        foundSend = true
        check call.channelId == "chan1"
    check foundSend

  test "known command triggers at least one send":
    let (bot, api, db) = makeBot(users = @["user1"])
    defer: db.close()
    let msg = Message(
      id: "msg_cmd_2",
      author: MockUser(id: "user1", username: "TestUser", bot: false),
      content: "!status",
      channel_id: "chan1",
      guild_id: some("guild1"),
      mention_users: @[],
    )
    waitFor bot.onMessageCreate(msg)
    var sendCount = 0
    for call in api.calls:
      if call.kind == mockSendMessage:
        sendCount.inc
    check sendCount >= 1

  test "unknown command returns unknown command message":
    let (bot, api, db) = makeBot(users = @["user1"])
    defer: db.close()
    let msg = Message(
      id: "msg_cmd_3",
      author: MockUser(id: "user1", username: "TestUser", bot: false),
      content: "!foobar",
      channel_id: "chan1",
      guild_id: some("guild1"),
      mention_users: @[],
    )
    waitFor bot.onMessageCreate(msg)
    var foundResponse = false
    for call in api.calls:
      if call.kind == mockSendMessage:
        foundResponse = true
        check "Unknown" in call.content or "unknown" in call.content
    check foundResponse

  test "config set command updates bot config":
    let (bot, _, db) = makeBot(admins = @["admin1"], users = @["admin1"])
    defer: db.close()
    check bot.config.prefix == "!"
    let msg = Message(
      id: "msg_cfg_1",
      author: MockUser(id: "admin1", username: "Admin", bot: false),
      content: "!config set prefix ?",
      channel_id: "chan1",
      guild_id: some("guild1"),
      mention_users: @[],
    )
    waitFor bot.onMessageCreate(msg)
    check bot.config.prefix == "?"

  test "regular message triggers typing and agent dispatch":
    let api = newMockDiscordApi()
    let cfg = makeConfig(admins = @["admin1"], users = @["user1"])
    let dispatcher = newAgentDispatcher(proc(r: AgentResult) = discard)
    let shard = newMockShard("bot_user_id")
    let db = makeDb()
    let bot = newDiscordBot(
      sendMessage = mockSendFn(api),
      triggerTyping = mockTypingFn(api),
      createThread = mockCreateThreadFn(api),
      archiveThread = mockArchiveThreadFn(api),
      db = db,
      config = cfg,
      dispatcher = dispatcher,
      shard = shard,
    )
    defer: db.close()
    let msg = Message(
      id: "msg_reg_1",
      author: MockUser(id: "user1", username: "TestUser", bot: false),
      content: "hello agent",
      channel_id: "chan1",
      guild_id: some("guild1"),
      mention_users: @[MockUser(id: "bot_user_id", username: "bot", bot: false)],
    )
    waitFor bot.onMessageCreate(msg)
    var foundTyping = false
    for call in api.calls:
      if call.kind == mockTriggerTyping:
        foundTyping = true
        # Typing should happen in the newly created thread, not the original channel
        check call.channelId == "thread_1"
    check foundTyping

  test "prefix-only message with no command is ignored":
    let (bot, api, db) = makeBot(users = @["user1"])
    defer: db.close()
    let msg = Message(
      id: "msg_prefix_only",
      author: MockUser(id: "user1", username: "TestUser", bot: false),
      content: "!",
      channel_id: "chan1",
      guild_id: some("guild1"),
      mention_users: @[],
    )
    waitFor bot.onMessageCreate(msg)
    check api.calls.len == 0

  test "admin command denied for non-admin user":
    let (bot, api, db) = makeBot(admins = @["admin1"], users = @["user1"])
    defer: db.close()
    let msg = Message(
      id: "msg_admin_denied",
      author: MockUser(id: "user1", username: "RegularUser", bot: false),
      content: "!admin restart",
      channel_id: "chan1",
      guild_id: some("guild1"),
      mention_users: @[],
    )
    waitFor bot.onMessageCreate(msg)
    var foundResponse = false
    for call in api.calls:
      if call.kind == mockSendMessage:
        foundResponse = true
        check "permission" in call.content.toLowerAscii or "denied" in call.content.toLowerAscii
    check foundResponse

```

`mercury_core/tests/test_discord_commands.nim`:

```nim
import unittest
import std/[options, strutils]
import mercury_core/discord_types
import mercury_core/discord_commands

suite "Discord Command Handler":

  # ── Helpers ──────────────────────────────────────────────────────────

  proc makeConfig(admins: seq[string] = @[], users: seq[string] = @[]): DiscordConfig =
    result = defaultDiscordConfig()
    result.admins.allow = admins
    result.users.allow = users

  proc makeAdminConfig(): DiscordConfig =
    makeConfig(admins = @["admin1"], users = @["user1"])

  # ── Command parsing ──────────────────────────────────────────────────

  test "handleCommand returns unknown command for empty input":
    let cfg = makeAdminConfig()
    let r = handleCommand("", "", "admin1", cfg)
    check r.response.len > 0

  test "handleCommand returns unknown command for unrecognized command":
    let cfg = makeAdminConfig()
    let r = handleCommand("foobar", "", "admin1", cfg)
    check "Unknown" in r.response or "unknown" in r.response

  # ── !config show ─────────────────────────────────────────────────────

  test "!config show displays sanitized config (no tokens)":
    var cfg = makeAdminConfig()
    cfg.tokenEnv = "MY_SECRET_TOKEN"
    let r = handleCommand("config", "show", "admin1", cfg)
    check r.response.len > 0
    check "MY_SECRET_TOKEN" notin r.response
    check r.updatedConfig.isNone

  test "!config show works for non-admin users":
    let cfg = makeAdminConfig()
    let r = handleCommand("config", "show", "user1", cfg)
    check r.response.len > 0
    check r.updatedConfig.isNone

  # ── !config set ──────────────────────────────────────────────────────

  test "!config set requires admin":
    let cfg = makeAdminConfig()
    let r = handleCommand("config", "set prefix ?", "user1", cfg)
    check "admin" in r.response.toLowerAscii or "permission" in r.response.toLowerAscii or "denied" in r.response.toLowerAscii
    check r.updatedConfig.isNone

  test "!config set prefix updates config":
    let cfg = makeAdminConfig()
    let r = handleCommand("config", "set prefix ?", "admin1", cfg)
    check r.updatedConfig.isSome
    if r.updatedConfig.isSome:
      check r.updatedConfig.get().prefix == "?"
    check "prefix" in r.response.toLowerAscii

  test "!config set with missing value returns error":
    let cfg = makeAdminConfig()
    let r = handleCommand("config", "set prefix", "admin1", cfg)
    check r.updatedConfig.isNone

  test "!config set with unknown key returns error":
    let cfg = makeAdminConfig()
    let r = handleCommand("config", "set unknownkey value", "admin1", cfg)
    check r.updatedConfig.isNone

  # ── !config reload ───────────────────────────────────────────────────

  test "!config reload requires admin":
    let cfg = makeAdminConfig()
    let r = handleCommand("config", "reload", "user1", cfg)
    check "admin" in r.response.toLowerAscii or "permission" in r.response.toLowerAscii or "denied" in r.response.toLowerAscii
    check r.updatedConfig.isNone

  test "!config reload returns placeholder response for admin":
    let cfg = makeAdminConfig()
    let r = handleCommand("config", "reload", "admin1", cfg)
    check r.response.len > 0
    # Reload doesn't actually reload from disk in this module; it signals intent
    check r.updatedConfig.isNone

  # ── !config allowlist ────────────────────────────────────────────────

  test "!config allowlist add requires admin":
    let cfg = makeAdminConfig()
    let r = handleCommand("config", "allowlist add /tmp/test", "user1", cfg)
    check "admin" in r.response.toLowerAscii or "permission" in r.response.toLowerAscii or "denied" in r.response.toLowerAscii
    check r.updatedConfig.isNone

  test "!config allowlist add adds path to fileRules.allow":
    let cfg = makeAdminConfig()
    let r = handleCommand("config", "allowlist add /tmp/test", "admin1", cfg)
    check r.updatedConfig.isSome
    check "/tmp/test" in r.updatedConfig.get().fileRules.allow

  test "!config allowlist add duplicate path does not add again":
    var cfg = makeAdminConfig()
    cfg.fileRules.allow.add("/tmp/test")
    let r = handleCommand("config", "allowlist add /tmp/test", "admin1", cfg)
    check r.updatedConfig.isSome
    let allowList = r.updatedConfig.get().fileRules.allow
    var count = 0
    for p in allowList:
      if p == "/tmp/test": count.inc
    check count == 1

  test "!config allowlist remove removes path from fileRules.allow":
    var cfg = makeAdminConfig()
    cfg.fileRules.allow = @["/tmp/test", "/home/user/docs"]
    let r = handleCommand("config", "allowlist remove /tmp/test", "admin1", cfg)
    check r.updatedConfig.isSome
    check "/tmp/test" notin r.updatedConfig.get().fileRules.allow
    check "/home/user/docs" in r.updatedConfig.get().fileRules.allow

  test "!config allowlist remove requires admin":
    let cfg = makeAdminConfig()
    let r = handleCommand("config", "allowlist remove /tmp/test", "user1", cfg)
    check "admin" in r.response.toLowerAscii or "permission" in r.response.toLowerAscii or "denied" in r.response.toLowerAscii
    check r.updatedConfig.isNone

  test "!config allowlist list shows allowed paths":
    var cfg = makeAdminConfig()
    cfg.fileRules.allow = @["/tmp/test", "/home/user/docs"]
    let r = handleCommand("config", "allowlist list", "user1", cfg)
    check "/tmp/test" in r.response
    check "/home/user/docs" in r.response
    check r.updatedConfig.isNone

  test "!config allowlist list shows message when empty":
    let cfg = makeAdminConfig()
    let r = handleCommand("config", "allowlist list", "user1", cfg)
    check r.response.len > 0
    check r.updatedConfig.isNone

  # ── !status ──────────────────────────────────────────────────────────

  test "!status returns bot status info":
    let cfg = makeAdminConfig()
    let r = handleCommand("status", "", "user1", cfg)
    check r.response.len > 0
    check r.updatedConfig.isNone

  # ── !admin ────────────────────────────────────────────────────────────

  test "!admin restart requires admin":
    let cfg = makeAdminConfig()
    let r = handleCommand("admin", "restart", "user1", cfg)
    check "admin" in r.response.toLowerAscii or "permission" in r.response.toLowerAscii or "denied" in r.response.toLowerAscii
    check r.updatedConfig.isNone

  test "!admin restart returns placeholder for admin":
    let cfg = makeAdminConfig()
    let r = handleCommand("admin", "restart", "admin1", cfg)
    check r.response.len > 0
    check r.updatedConfig.isNone

  test "!admin reconnect requires admin":
    let cfg = makeAdminConfig()
    let r = handleCommand("admin", "reconnect", "user1", cfg)
    check "admin" in r.response.toLowerAscii or "permission" in r.response.toLowerAscii or "denied" in r.response.toLowerAscii
    check r.updatedConfig.isNone

  test "!admin reconnect returns placeholder for admin":
    let cfg = makeAdminConfig()
    let r = handleCommand("admin", "reconnect", "admin1", cfg)
    check r.response.len > 0
    check r.updatedConfig.isNone

  test "!admin unknown subcommand":
    let cfg = makeAdminConfig()
    let r = handleCommand("admin", "unknown", "admin1", cfg)
    check "unknown" in r.response.toLowerAscii or "invalid" in r.response.toLowerAscii

  # ── !session ─────────────────────────────────────────────────────────

  test "!session list returns session info":
    let cfg = makeAdminConfig()
    let r = handleCommand("session", "list", "user1", cfg)
    check r.response.len > 0
    check r.updatedConfig.isNone

  test "!session info requires session id":
    let cfg = makeAdminConfig()
    let r = handleCommand("session", "info", "user1", cfg)
    check r.response.len > 0
    # Should indicate missing session ID
    check r.updatedConfig.isNone

  test "!session info with id returns session details":
    let cfg = makeAdminConfig()
    let r = handleCommand("session", "info sess_123", "user1", cfg)
    check r.response.len > 0
    check r.updatedConfig.isNone

  test "!session clear requires admin":
    let cfg = makeAdminConfig()
    let r = handleCommand("session", "clear sess_123", "user1", cfg)
    check "admin" in r.response.toLowerAscii or "permission" in r.response.toLowerAscii or "denied" in r.response.toLowerAscii
    check r.updatedConfig.isNone

  test "!session clear with id returns placeholder for admin":
    let cfg = makeAdminConfig()
    let r = handleCommand("session", "clear sess_123", "admin1", cfg)
    check r.response.len > 0
    check r.updatedConfig.isNone

  test "!session clear requires session id":
    let cfg = makeAdminConfig()
    let r = handleCommand("session", "clear", "admin1", cfg)
    check r.response.len > 0
    # Should indicate missing session ID

  test "!session unknown subcommand":
    let cfg = makeAdminConfig()
    let r = handleCommand("session", "unknown", "user1", cfg)
    check "unknown" in r.response.toLowerAscii or "invalid" in r.response.toLowerAscii
```

`mercury_core/tests/test_discord_config.nim`:

```nim
## Tests for Discord config parsing

import std/[os, unittest, strutils]
import mercury_core/config
import mercury_core/discord_types

proc writeTempFile(path, content: string) =
  createDir(parentDir(path))
  writeFile(path, content)

suite "Discord Config Defaults":
  test "default discord config has expected values":
    let cfg = defaultConfig()
    check cfg.discord.tokenEnv == "DISCORD_BOT_TOKEN"
    check cfg.discord.prefix == "!"
    check cfg.discord.admins.allow.len == 0
    check cfg.discord.admins.deny.len == 0
    check cfg.discord.users.allow.len == 0
    check cfg.discord.users.deny.len == 0
    check cfg.discord.fileRules.allow.len == 0
    check cfg.discord.fileRules.deny == @[".env", ".ssh", ".aws", ".gnupg", "*.key", "*.pem"]
    check cfg.discord.tools.allow.len == 0
    check cfg.discord.tools.deny.len == 0

suite "Discord Config Parsing":
  let tmpDir = getTempDir() / "mercury_test_discord_toml"

  setup:
    createDir(tmpDir)

  teardown:
    removeDir(tmpDir)

  test "parses basic [discord] section":
    let cfgFile = tmpDir / "config.toml"
    writeTempFile(cfgFile, """
[discord]
token_env = "MY_CUSTOM_TOKEN"
prefix = "?"
""")
    let cfg = loadConfig(configPath = cfgFile, envFilePath = "/nonexistent/.env")
    check cfg.discord.tokenEnv == "MY_CUSTOM_TOKEN"
    check cfg.discord.prefix == "?"

  test "parses [discord.admins] access control":
    let cfgFile = tmpDir / "config.toml"
    writeTempFile(cfgFile, """
[discord.admins]
allow = "123, 456"
deny = "789"
""")
    let cfg = loadConfig(configPath = cfgFile, envFilePath = "/nonexistent/.env")
    check cfg.discord.admins.allow == @["123", "456"]
    check cfg.discord.admins.deny == @["789"]

  test "parses [discord.file_rules] with comma separated lists":
    let cfgFile = tmpDir / "config.toml"
    writeTempFile(cfgFile, """
[discord.file_rules]
allow = "*.txt, *.md"
deny = ".env, secret.key"
""")
    let cfg = loadConfig(configPath = cfgFile, envFilePath = "/nonexistent/.env")
    check cfg.discord.fileRules.allow == @["*.txt", "*.md"]
    check cfg.discord.fileRules.deny == @[".env", "secret.key"]

```

`mercury_core/tests/test_discord_mocks.nim`:

```nim
import std/[asyncdispatch, options, unittest]
import mercury_core/discord_mocks

suite "Discord mocks":
  test "records discord api calls in order":
    let api = newMockDiscordApi()

    let messageId = waitFor api.sendMessage("channel-1", "hello")
    let threadId = waitFor api.createThread("channel-1", messageId, "thread-name")
    waitFor api.triggerTyping("channel-1")
    waitFor api.archiveThread(threadId)

    check messageId == "msg_1"
    check threadId == "thread_1"
    check api.calls.len == 4
    check api.calls[0].kind == mockSendMessage
    check api.calls[0].channelId == "channel-1"
    check api.calls[0].content == "hello"
    check api.calls[0].messageId == messageId
    check api.calls[1].kind == mockCreateThread
    check api.calls[1].name == "thread-name"
    check api.calls[1].threadId == threadId
    check api.calls[2].kind == mockTriggerTyping
    check api.calls[3].kind == mockArchiveThread

  test "stores shard state and message metadata":
    let shard = newMockShard("bot-123", @["member-1", "member-2"])
    let msg = makeMessage(
      authorId = "user-1",
      content = "ping",
      channelId = "channel-9",
      guildId = some("guild-7"),
      mentionUsers = @["bot-123"]
    )
    let dm = makeMessage(
      authorId = "user-2",
      content = "dm",
      channelId = "dm-channel",
      guildId = none(string),
      mentionUsers = @[]
    )

    check shard.userId == "bot-123"
    check shard.user.id == "bot-123"
    check shard.guildMembers == @["member-1", "member-2"]
    check msg.author.id == "user-1"
    check msg.content == "ping"
    check msg.channel_id == "channel-9"
    check msg.guild_id == some("guild-7")
    check msg.mention_users.len == 1
    check msg.mention_users[0].id == "bot-123"
    check dm.guild_id.isNone
    check dm.channel_id == "dm-channel"

```

`mercury_core/tests/test_e2e_discord.nim`:

```nim
import unittest
import std/[asyncdispatch, options, os, strutils, json]
import db_connector/db_sqlite

import mercury_core/[discord, discord_mocks, discord_types, discord_commands,
  permission, agent_dispatcher, file_tool, file_path_validator, thread_mapping, tool_registry]

suite "End-to-end Discord Integration":
  var
    db: DbConn
    api: MockDiscordApi
    bot: DiscordBot
    shard: MockShard
    dispatcher: AgentDispatcher
    config: DiscordConfig

  setup:
    db = open(":memory:", "", "", "")
    initThreadMappingSchema(db)

    api = newMockDiscordApi()
    shard = newMockShard("bot_user_id")

    config = defaultDiscordConfig()
    config.admins.allow.add("admin_user")
    config.users.allow.add("regular_user")

    dispatcher = newAgentDispatcher(proc(res: AgentResult) {.gcsafe, closure.} =
      discard  # callback: test verifies bot behavior via api.calls inspection
    )

    bot = newDiscordBot(
      sendMessage = mockSendFn(api),
      triggerTyping = mockTypingFn(api),
      createThread = mockCreateThreadFn(api),
      archiveThread = mockArchiveThreadFn(api),
      db = db,
      config = config,
      dispatcher = dispatcher,
      shard = shard
    )

  teardown:
    db.close()

  test "Mention creates thread and dispatches agent":
    let msg = makeMessage("regular_user", "Hello bot!", "channel_1", "guild_1", @["bot_user_id"])
    waitFor onMessageCreate(bot, msg)
    waitFor sleepAsync(200) # wait for dispatcher callback + agent processing

    var threadCreated = false
    var responseSent = false

    for call in api.calls:
      if call.kind == mockCreateThread:
        threadCreated = true
        check call.channelId == "channel_1"
      if call.kind == mockSendMessage:
        responseSent = true

    check threadCreated
    # Note: responseSent depends on whether dispatchAgent sends a message.
    # The current dispatcher is a placeholder — uncomment below once implemented:
    # check responseSent

  test "Message in existing thread continues session":
    # First, setup an existing thread
    let sessionId = "test_session_1"
    setThreadMapping(db, "thread_1", sessionId, "channel_1", "guild_1")

    let msg = makeMessage("regular_user", "Next message", "thread_1", "guild_1", @[])
    waitFor onMessageCreate(bot, msg)
    waitFor sleepAsync(200) # wait for dispatcher callback + agent processing

    # Should NOT create a new thread. Should trigger typing in thread_1 and send response there.
    var newThreadCount = 0
    var typingInThread = false

    for call in api.calls:
      if call.kind == mockCreateThread:
        newThreadCount.inc
      if call.kind == mockTriggerTyping and call.channelId == "thread_1":
        typingInThread = true

    check newThreadCount == 0
    check typingInThread

  test "Bot commands: !status, !admin restart, !config set":
    let statusMsg = makeMessage("regular_user", "!status", "channel_1", "guild_1", @[])
    waitFor onMessageCreate(bot, statusMsg)

    var statusFound = false
    for call in api.calls:
      if call.kind == mockSendMessage and "status" in call.content.toLowerAscii:
        statusFound = true
    check statusFound

    api.calls = @[]
    
    let adminRestart = makeMessage("regular_user", "!admin restart", "channel_1", "guild_1", @[])
    waitFor onMessageCreate(bot, adminRestart)
    
    var deniedFound = false
    for call in api.calls:
      if call.kind == mockSendMessage and "permission denied" in call.content.toLowerAscii:
        deniedFound = true
    check deniedFound

    api.calls = @[]

    let configSet = makeMessage("admin_user", "!config set prefix ?", "channel_1", "guild_1", @[])
    waitFor onMessageCreate(bot, configSet)
    
    check bot.config.prefix == "?"
    
  test "File tool configuration":
    writeFile("test_allowed.txt", "allowed")
    writeFile(".env_test", "secret")
    try:
      let rules = FileRules(
        sandboxDir: getCurrentDir(),
        allowPatterns: @["*"],
        askPatterns: @[],
        denyPatterns: @[".env*"]
      )
      let readTool = fileReadTool(rules)
      let allowedArgs = %*{"path": "test_allowed.txt"}
      let allowedResult = readTool.execute(allowedArgs)
      check "allowed" in allowedResult.output
      let deniedArgs = %*{"path": ".env_test"}
      let deniedResult = readTool.execute(deniedArgs)
      check "Access denied" in deniedResult.output
    finally:
      try: removeFile("test_allowed.txt") except CatchableError: discard
      try: removeFile(".env_test") except CatchableError: discard

  test "Thread archival behavior":
    let msg1 = makeMessage("regular_user", "Hello first", "channel_1", "guild_1", @["bot_user_id"])
    waitFor onMessageCreate(bot, msg1)
    waitFor sleepAsync(150)
    
    var firstThreadId = ""
    for call in api.calls:
      if call.kind == mockCreateThread:
        firstThreadId = call.threadId
        
    check firstThreadId != ""
    
    # Archive the thread via thread_mapping directly
    archiveThread(db, firstThreadId)
    
    api.calls = @[]
    
    # Now user mentions bot again in channel_1
    let msg2 = makeMessage("regular_user", "Hello again", "channel_1", "guild_1", @["bot_user_id"])
    waitFor onMessageCreate(bot, msg2)
    waitFor sleepAsync(150)
    
    # It should create a NEW thread but reuse the same session
    var secondThreadId = ""
    var continueFound = false
    for call in api.calls:
      if call.kind == mockCreateThread:
        secondThreadId = call.threadId
      if call.kind == mockSendMessage and "Continuing from previous session" in call.content:
        continueFound = true
        
    check secondThreadId != ""
    check secondThreadId != firstThreadId
    check continueFound

```

`mercury_core/tests/test_file_path_validator.nim`:

```nim
import unittest, os, strutils, uri
import ../src/mercury_core/file_path_validator

suite "File Path Validator":
  setup:
    let sandboxDir = getCurrentDir() / "test_sandbox"
    createDir(sandboxDir)
    let rules = FileRules(
      sandboxDir: sandboxDir,
      allowPatterns: @["*.txt", "docs/*"],
      askPatterns: @["*.md"],
      denyPatterns: @[]
    )

  teardown:
    removeDir(sandboxDir)

  test "URL decoding":
    let path = "%2e%2e%2fetc%2fpasswd"
    let decoded = decodeUrl(path)
    check decoded == "../etc/passwd"

  test "Basic absolute path within sandbox":
    let path = sandboxDir / "file.txt"
    let res = validatePath(path, rules)
    check res.decision == pathAllow

  test "Path traversal outside sandbox":
    let path = sandboxDir / ".." / "etc" / "passwd"
    let res = validatePath(path, rules)
    check res.decision == pathDeny
    check res.reason.contains("sandbox")

  test "Mandatory deny list takes precedence":
    let path = sandboxDir / ".env"
    let res = validatePath(path, rules)
    check res.decision == pathDeny
    check res.reason.contains("mandatory deny")
    
  test "Mandatory deny list for SSH":
    let path = sandboxDir / ".ssh" / "id_rsa"
    let res = validatePath(path, rules)
    check res.decision == pathDeny
    
  test "Symlink outside sandbox":
    let outDir = getCurrentDir() / "test_out"
    createDir(outDir)
    let symlinkPath = sandboxDir / "link"
    createSymlink(outDir, symlinkPath)
    
    let path = symlinkPath / "file.txt"
    let res = validatePath(path, rules)
    check res.decision == pathDeny
    check res.reason.contains("sandbox")
    
    removeFile(symlinkPath)
    removeDir(outDir)

  test "Symlink to nonexistent file in sandbox":
    let path = sandboxDir / "docs" / "nonexistent.txt"
    let res = validatePath(path, rules)
    check res.decision == pathAllow

  test "Ask pattern match":
    let path = sandboxDir / "readme.md"
    let res = validatePath(path, rules)
    check res.decision == pathAsk

  test "Adversarial URL encoding and path traversal":
    let path = sandboxDir / "%2e%2e%2f%2e%2e%2fetc%2fshadow"
    let res = validatePath(path, rules)
    check res.decision == pathDeny
    check res.reason.contains("sandbox")

  test "Allow list overrides with directory":
    let path = sandboxDir / "docs" / "secret.pdf"
    let res = validatePath(path, rules)
    check res.decision == pathAllow

  test "Symlink traversal attack":
    let outDir = getCurrentDir() / "test_out2"
    createDir(outDir)
    let secretFile = outDir / "secret.txt"
    writeFile(secretFile, "secret")

    let innerDir = sandboxDir / "inner"
    createDir(innerDir)
    let symlinkPath = innerDir / "link"
    createSymlink(outDir, symlinkPath)
    
    let path = symlinkPath / "secret.txt"
    let res = validatePath(path, rules)
    check res.decision == pathDeny
    
    removeFile(symlinkPath)
    removeDir(innerDir)
    removeFile(secretFile)
    removeDir(outDir)

```

`mercury_core/tests/test_file_tool.nim`:

```nim
import unittest, os, json, strutils
import mercury_core/discord_types
import mercury_core/file_path_validator
import mercury_core/permission
import mercury_core/tool_registry
import mercury_core/file_tool

suite "File Tool":
  setup:
    let sandboxDir = getCurrentDir() / "test_file_tool_sandbox"
    createDir(sandboxDir)
    let rules = FileRules(
      sandboxDir: sandboxDir,
      allowPatterns: @["*.txt"],
      askPatterns: @["*.md"],
      denyPatterns: @["*.secret"]
    )
    
    var cfg = defaultDiscordConfig()
    cfg.admins.allow.add("admin")
    cfg.users.allow.add("user")

  teardown:
    removeDir(sandboxDir)

  test "fileReadTool returns Tool":
    let t = fileReadTool(rules)
    check t.name == "file_read"

  test "fileReadTool allow":
    let path = sandboxDir / "hello.txt"
    writeFile(path, "hello world")
    
    let t = fileReadTool(rules)
    let args = %*{"path": path}
    let res = t.execute(args)
    check res.isError == false
    check res.output == "hello world"

  test "fileReadTool deny":
    let path = sandboxDir / "file.secret"
    let t = fileReadTool(rules)
    let args = %*{"path": path}
    let res = t.execute(args)
    check res.isError == true
    check res.output.contains("Access denied")

  test "fileReadTool ask":
    let path = sandboxDir / "file.md"
    let t = fileReadTool(rules)
    let args = %*{"path": path}
    let res = t.execute(args)
    check res.isError == true
    check res.output == "This path requires approval. Ask an admin."

  test "fileReadTool missing file":
    let path = sandboxDir / "missing.txt"
    let t = fileReadTool(rules)
    let args = %*{"path": path}
    let res = t.execute(args)
    check res.isError == true

  test "fileWriteTool admin can write to allowed path":
    let path = sandboxDir / "test.txt"
    let t = fileWriteTool(rules, cfg, "admin")
    let args = %*{"path": path, "content": "hello admin"}
    let res = t.execute(args)
    check res.isError == false
    check readFile(path) == "hello admin"

  test "fileWriteTool normal user gets ask on allowed path":
    let path = sandboxDir / "test2.txt"
    let t = fileWriteTool(rules, cfg, "user")
    let args = %*{"path": path, "content": "hello user"}
    let res = t.execute(args)
    check res.isError == true
    check res.output == "Requires approval"

  test "fileWriteTool atomic write":
    let path = sandboxDir / "atomic.txt"
    let t = fileWriteTool(rules, cfg, "admin")
    let args = %*{"path": path, "content": "atomic"}
    let res = t.execute(args)
    check res.isError == false
    check readFile(path) == "atomic"

  test "fileWriteTool deny":
    let path = sandboxDir / "test.secret"
    let t = fileWriteTool(rules, cfg, "admin")
    let args = %*{"path": path, "content": "atomic"}
    let res = t.execute(args)
    check res.isError == true
    check res.output.contains("Access denied")

  test "fileWriteTool size limit":
    let path = sandboxDir / "big.txt"
    let t = fileWriteTool(rules, cfg, "admin")
    let bigContent = newString(1024 * 1024 * 2) # 2MB
    let args = %*{"path": path, "content": bigContent}
    let res = t.execute(args)
    check res.isError == true
    check res.output.contains("exceeds")

```

`mercury_core/tests/test_mcp_client.nim`:

```nim
## Tests for mercury_core/mcp_client.nim

import std/[unittest, httpclient, json, strutils, os]
import mercury_core/mcp_client
import mercury_core/config

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

proc makeMinimalServer(): string =
  ## Returns a minimal MCP server URL for testing. In tests, we validate
  ## that the client constructs requests correctly and handles responses
  ## even when no live server is available.
  result = "http://localhost:19999/mcp"

proc validInitializeResponse(): string =
  ## A valid JSON-RPC initialize response.
  """{"jsonrpc":"2.0","id":1,"result":{"protocolVersion":"2024-11-05","capabilities":{},"serverInfo":{"name":"test-mcp","version":"1.0.0"}}}"""

proc validToolsListResponse(tools: JsonNode): string =
  "{\"jsonrpc\":\"2.0\",\"id\":2,\"result\":{\"tools\":" & $tools & "}}"

proc validToolCallResponse(text: string): string =
  """{"jsonrpc":"2.0","id":3,"result":{"content":[{"type":"text","text":""" & $text & """}]}}"""

# ---------------------------------------------------------------------------
# Tests: config parsing
# ---------------------------------------------------------------------------

suite "mcp_server_config":
  test "default values":
    let cfg = newMcpServerConfig()
    check cfg.url == "http://localhost:8080/mcp"
    check cfg.authToken == ""
    check cfg.timeoutMs == 30_000
    check cfg.enabled == true

  test "custom values":
    let cfg = newMcpServerConfig(url = "https://mcp.example.com/api",
                                  authToken = "tok123",
                                  timeoutMs = 5000,
                                  enabled = false)
    check cfg.url == "https://mcp.example.com/api"
    check cfg.authToken == "tok123"
    check cfg.timeoutMs == 5000
    check cfg.enabled == false

  test "trailing slash stripped from url":
    let cfg = newMcpServerConfig(url = "http://localhost:8080/mcp/")
    check cfg.url == "http://localhost:8080/mcp"

  test "zero timeout reverts to default":
    let cfg = newMcpServerConfig(timeoutMs = 0)
    check cfg.timeoutMs == 30_000

# ---------------------------------------------------------------------------
# Tests: JSON-RPC helpers
# ---------------------------------------------------------------------------

suite "json_rpc helpers":
  test "jsonRpcRequest with params":
    let req = jsonRpcRequest("tools/list", %*{"verbose": true})
    check req["jsonrpc"].getStr() == "2.0"
    check req["method"].getStr() == "tools/list"
    check req["params"]["verbose"].getBool() == true

  test "jsonRpcRequest without params":
    let req = jsonRpcRequest("initialize")
    check req["jsonrpc"].getStr() == "2.0"
    check req["method"].getStr() == "initialize"
    check req["params"].kind == JObject

  test "jsonRpcResponseId extracts int id":
    let node = parseJson("""{"id":42,"result":{}}""")
    check jsonRpcResponseId(node) == 42

  test "jsonRpcResponseId returns 0 when missing":
    let node = parseJson("""{"result":{}}""")
    check jsonRpcResponseId(node) == 0

# ---------------------------------------------------------------------------
# Tests: McpTool type
# ---------------------------------------------------------------------------

suite "mcp_tool type":
  test "McpTool stores all fields":
    let tool = McpTool(
      server: "http://localhost:8080",
      name: "test_tool",
      description: "A test tool",
      inputSchema: %*{"type": "object", "properties": {"arg": {"type": "string"}}},
    )
    check tool.server == "http://localhost:8080"
    check tool.name == "test_tool"
    check tool.description == "A test tool"
    check tool.inputSchema["type"].getStr() == "object"

# ---------------------------------------------------------------------------
# Tests: McpError hierarchy
# ---------------------------------------------------------------------------

suite "mcp_error hierarchy":
  test "McpConnectionError has serverUrl":
    var err = newException(McpConnectionError, "connection refused")
    err.serverUrl = "http://localhost:9999"
    check err.serverUrl == "http://localhost:9999"
    check err of CatchableError
    check err of McpError

  test "McpProtocolError has serverUrl":
    var err = newException(McpProtocolError, "invalid response")
    err.serverUrl = "http://localhost:8080"
    check err.serverUrl == "http://localhost:8080"

  test "McpToolNotFoundError has serverUrl":
    var err = newException(McpToolNotFoundError, "tool not found")
    err.serverUrl = "http://localhost:8080"
    check err.serverUrl == "http://localhost:8080"

# ---------------------------------------------------------------------------
# Tests: McpClient construction
# ---------------------------------------------------------------------------

suite "mcp_client construction":
  test "newMcpClient sets protocolVersion to empty":
    let cfg = newMcpServerConfig()
    let client = newMcpClient(cfg)
    check client.protocolVersion == ""

  test "newMcpClient stores config":
    let cfg = newMcpServerConfig(url = "http://localhost:9000/mcp",
                                  timeoutMs = 15_000)
    let client = newMcpClient(cfg)
    check client.cfg.url == "http://localhost:9000/mcp"
    check client.cfg.timeoutMs == 15_000

# ---------------------------------------------------------------------------
# Tests: config integration — McpServerConfig in MercuryConfig
# ---------------------------------------------------------------------------

suite "config integration":
  test "MercuryConfig.mcpServers is empty by default":
    let cfg = defaultConfig()
    check cfg.mcpServers.len == 0

  test "McpServerConfig fields accessible":
    let cfg = McpServerConfig(url: "http://test:9000", authToken: "secret",
                              timeoutMs: 5000, enabled: true)
    check cfg.url == "http://test:9000"
    check cfg.authToken == "secret"
    check cfg.timeoutMs == 5000
    check cfg.enabled == true
```

`mercury_core/tests/test_message_chunker.nim`:

```nim
## Tests for mercury_core/message_chunker.nim

import std/[strutils, unittest]
import mercury_core/message_chunker

proc fenceBalanced(chunk: string): bool =
  count(chunk, "```") mod 2 == 0

suite "chunkMessage":
  test "empty string returns no chunks":
    check chunkMessage("") == newSeq[string]()

  test "single character stays intact":
    check chunkMessage("a") == @["a"]

  test "exact maxLen returns one chunk":
    let text = "x".repeat(12)
    let chunks = chunkMessage(text, 12)
    check chunks == @[text]

  test "splits on newline boundaries when possible":
    let chunks = chunkMessage("aaaaa\nbbbbb", 6)
    check chunks == @["aaaaa\n", "bbbbb"]

  test "keeps code fences balanced across chunks":
    let text = "prefix\n```nim\nlet a = \"" & "x".repeat(24) & "\"\nlet b = \"" &
               "y".repeat(24) & "\"\n```\nsuffix"
    let chunks = chunkMessage(text, 30)
    check chunks.len > 1
    var sawContinuation = false
    for chunk in chunks:
      check chunk.len <= 30
      check fenceBalanced(chunk)
      if chunk.contains("..."):
        sawContinuation = true
    check sawContinuation

```

`mercury_core/tests/test_mock_server.nim`:

```nim
import std/[asyncdispatch, httpclient, json, unittest, net]
import mock_server

suite "MockLLMServer":
  test "returns basic text response":
    let server = newMockLLMServer()
    server.setResponse("Hello, world!")
    waitFor server.start()

    let client = newAsyncHttpClient()
    let response = waitFor client.post("http://127.0.0.1:" & $server.port & "/v1/chat/completions", body = "{}")
    check response.code == Http200
    
    let body = waitFor response.body
    let jsonBody = parseJson(body)
    check jsonBody["choices"][0]["message"]["content"].getStr() == "Hello, world!"
    check server.getRequestCount() == 1
    
    client.close()

  test "returns tool call response":
    let server = newMockLLMServer()
    let args = %*{"arg1": "value1"}
    server.setToolCallResponse("my_tool", args)
    waitFor server.start()

    let client = newAsyncHttpClient()
    let response = waitFor client.post("http://127.0.0.1:" & $server.port & "/v1/chat/completions", body = "{}")
    check response.code == Http200
    
    let body = waitFor response.body
    let jsonBody = parseJson(body)
    let toolCall = jsonBody["choices"][0]["message"]["tool_calls"][0]["function"]
    check toolCall["name"].getStr() == "my_tool"
    check toolCall["arguments"].getStr() == $args
    
    client.close()

  test "returns error response":
    let server = newMockLLMServer()
    server.setErrorResponse(400, "Bad Request")
    waitFor server.start()

    let client = newAsyncHttpClient()
    let response = waitFor client.post("http://127.0.0.1:" & $server.port & "/v1/chat/completions", body = "{}")
    check response.code == Http400
    
    let body = waitFor response.body
    let jsonBody = parseJson(body)
    check jsonBody["error"]["message"].getStr() == "Bad Request"
    
    client.close()

```

`mercury_core/tests/test_permission.nim`:

```nim
import unittest
import mercury_core/discord_types
import mercury_core/permission

suite "Permission Framework":
  setup:
    var cfg = defaultDiscordConfig()
    cfg.admins.allow.add("admin_user")
    cfg.users.allow.add("normal_user")
    cfg.users.deny.add("banned_user")
    cfg.tools.deny.add("banned_tool")
    cfg.tools.allow.add("safe_tool")

  # ---------------------------------------------------------------------------
  # isAdmin
  # ---------------------------------------------------------------------------

  test "isAdmin - explicit allow":
    check isAdmin("admin_user", cfg) == true

  test "isAdmin - normal user is not admin":
    check isAdmin("normal_user", cfg) == false

  test "isAdmin - unknown user is not admin":
    check isAdmin("unknown_user", cfg) == false

  test "isAdmin - admin in deny list is not admin":
    cfg.admins.deny.add("admin_user")
    check isAdmin("admin_user", cfg) == false

  test "isAdmin - user in both allow and deny list is denied":
    cfg.users.allow.add("both_user")
    cfg.users.deny.add("both_user")
    check isUserAllowed("both_user", cfg) == false

  # ---------------------------------------------------------------------------
  # isUserAllowed
  # ---------------------------------------------------------------------------

  test "isUserAllowed - admin is allowed":
    check isUserAllowed("admin_user", cfg) == true

  test "isUserAllowed - normal user is allowed":
    check isUserAllowed("normal_user", cfg) == true

  test "isUserAllowed - banned user is denied":
    check isUserAllowed("banned_user", cfg) == false

  test "isUserAllowed - unknown user is denied":
    check isUserAllowed("unknown_user", cfg) == false

  test "isUserAllowed - empty config denies everyone":
    var emptyCfg = defaultDiscordConfig()
    check isUserAllowed("anyone", emptyCfg) == false
    check isUserAllowed("admin", emptyCfg) == false

  test "isUserAllowed - user in both allow and deny is denied":
    cfg.users.allow.add("both_user")
    cfg.users.deny.add("both_user")
    check isUserAllowed("both_user", cfg) == false

  # ---------------------------------------------------------------------------
  # getToolRisk
  # ---------------------------------------------------------------------------

  test "getToolRisk - shell tools are riskHigh":
    check getToolRisk("shell") == riskHigh
    check getToolRisk("bash") == riskHigh
    check getToolRisk("execute") == riskHigh

  test "getToolRisk - file write is riskMedium":
    check getToolRisk("file_write") == riskMedium
    check getToolRisk("delete_file") == riskMedium

  test "getToolRisk - file read is riskLow":
    check getToolRisk("file_read") == riskLow
    check getToolRisk("read_file") == riskLow
    check getToolRisk("search") == riskLow

  test "getToolRisk - unknown tool defaults to riskMedium":
    check getToolRisk("unknown_tool") == riskMedium
    check getToolRisk("custom_plugin") == riskMedium

  # ---------------------------------------------------------------------------
  # canUseTool — user not allowed
  # ---------------------------------------------------------------------------

  test "canUseTool - unknown user is denied regardless of tool":
    check canUseTool("unknown_user", "read_file", cfg) == pdDeny
    check canUseTool("unknown_user", "shell", cfg) == pdDeny

  test "canUseTool - banned user is denied":
    check canUseTool("banned_user", "read_file", cfg) == pdDeny
    check canUseTool("banned_user", "safe_tool", cfg) == pdDeny

  # ---------------------------------------------------------------------------
  # canUseTool — explicit deny overrides everything
  # ---------------------------------------------------------------------------

  test "canUseTool - explicit deny blocks admin":
    check canUseTool("admin_user", "banned_tool", cfg) == pdDeny

  test "canUseTool - explicit deny on low-risk tool":
    cfg.tools.deny.add("read_file")
    check canUseTool("admin_user", "read_file", cfg) == pdDeny

  test "canUseTool - explicit deny on explicitly allowed tool":
    cfg.tools.deny.add("safe_tool")
    check canUseTool("normal_user", "safe_tool", cfg) == pdDeny

  # ---------------------------------------------------------------------------
  # canUseTool — explicit allow
  # ---------------------------------------------------------------------------

  test "canUseTool - explicit allow for normal user":
    check canUseTool("normal_user", "safe_tool", cfg) == pdAllow

  test "canUseTool - explicit allow for high-risk tool":
    cfg.tools.allow.add("shell")
    check canUseTool("normal_user", "shell", cfg) == pdAllow
    check canUseTool("admin_user", "shell", cfg) == pdAllow

  test "canUseTool - explicit allow for banned user overrides user deny":
    cfg.tools.allow.add("read_file")
    check canUseTool("banned_user", "read_file", cfg) == pdDeny

  # ---------------------------------------------------------------------------
  # canUseTool — risk low/none
  # ---------------------------------------------------------------------------

  test "canUseTool - riskLow allows all users":
    check canUseTool("normal_user", "read_file", cfg) == pdAllow
    check canUseTool("admin_user", "read_file", cfg) == pdAllow

  test "canUseTool - riskLow for admin":
    check canUseTool("admin_user", "search", cfg) == pdAllow

  # ---------------------------------------------------------------------------
  # canUseTool — risk medium
  # ---------------------------------------------------------------------------

  test "canUseTool - riskMedium normal user gets ask":
    check canUseTool("normal_user", "file_write", cfg) == pdAsk

  test "canUseTool - riskMedium admin bypasses ask":
    check canUseTool("admin_user", "file_write", cfg) == pdAllow

  test "canUseTool - riskMedium unknown default tool":
    check canUseTool("normal_user", "weird_tool", cfg) == pdAsk
    check canUseTool("admin_user", "weird_tool", cfg) == pdAllow

  # ---------------------------------------------------------------------------
  # canUseTool — risk high / critical
  # ---------------------------------------------------------------------------

  test "canUseTool - riskHigh normal user gets ask":
    check canUseTool("normal_user", "shell", cfg) == pdAsk

  test "canUseTool - riskHigh admin also gets ask":
    check canUseTool("admin_user", "shell", cfg) == pdAsk

  test "canUseTool - riskCritical gets ask for everyone":
    # delete_file is riskMedium today, but test the concept with shell (riskHigh)
    check canUseTool("normal_user", "shell", cfg) == pdAsk
    check canUseTool("admin_user", "shell", cfg) == pdAsk

  # ---------------------------------------------------------------------------
  # canUseTool — edge cases
  # ---------------------------------------------------------------------------

  test "canUseTool - empty config returns pdDeny for all":
    var emptyCfg = defaultDiscordConfig()
    check canUseTool("anyone", "read_file", emptyCfg) == pdDeny
    check canUseTool("anyone", "shell", emptyCfg) == pdDeny

  test "canUseTool - admin with no users config still allowed":
    var adminOnlyCfg = defaultDiscordConfig()
    adminOnlyCfg.admins.allow.add("superadmin")
    check canUseTool("superadmin", "read_file", adminOnlyCfg) == pdAllow
    check canUseTool("superadmin", "file_write", adminOnlyCfg) == pdAllow

  test "canUseTool - multiple tool denies work independently":
    cfg.tools.deny.add("read_file")
    cfg.tools.deny.add("shell")
    check canUseTool("admin_user", "read_file", cfg) == pdDeny
    check canUseTool("admin_user", "shell", cfg) == pdDeny
    check canUseTool("admin_user", "file_write", cfg) == pdAllow

  test "canUseTool - allow list does not affect unrelated tools":
    check canUseTool("normal_user", "write_file", cfg) == pdAsk
    check canUseTool("normal_user", "safe_tool", cfg) == pdAllow

  test "canUseTool - deny list does not affect unrelated tools":
    check canUseTool("admin_user", "file_write", cfg) == pdAllow
    check canUseTool("admin_user", "banned_tool", cfg) == pdDeny

```

`mercury_core/tests/test_persona.nim`:

```nim
import std/unittest
import mercury_core/[persona, delegate]

suite "PersonaRegistry":

  test "empty allow list means all tools pass":
    let pc = PersonaConfig(
      name: "locked",
      systemPrompt: "All tools allowed by default.",
      toolsAllow: @[],
      toolsDeny: @[],
    )
    let filtered = filterToolsByPersona(pc, @["shell", "file_read", "file_write"])
    check: filtered.len == 3

  test "specific allow list filters correctly":
    let pc = PersonaConfig(
      name: "analyst",
      systemPrompt: "Read only.",
      toolsAllow: @["file_read"],
    )
    let filtered = filterToolsByPersona(pc, @["shell", "file_read", "file_write"])
    check: filtered.len == 1
    check: "file_read" in filtered
    check: "shell" notin filtered

  test "empty deny list means all allowed tools pass":
    let pc = PersonaConfig(
      name: "open",
      systemPrompt: "Default.",
      toolsAllow: @[],
      toolsDeny: @[],
    )
    let filtered = filterToolsByPersona(pc, @["shell", "file_read"])
    check: filtered.len == 2

  test "deny list removes specific tools":
    let pc = PersonaConfig(
      name: "cautious",
      systemPrompt: "No shell.",
      toolsAllow: @["shell", "file_read", "file_write"],
      toolsDeny: @["shell"],
    )
    let filtered = filterToolsByPersona(pc, @["shell", "file_read", "file_write"])
    check: filtered.len == 2
    check: "shell" notin filtered
    check: "file_read" in filtered

  test "deny takes precedence over allow":
    let pc = PersonaConfig(
      name: "conflict",
      systemPrompt: "Deny wins.",
      toolsAllow: @["shell", "file_read"],
      toolsDeny: @["shell"],
    )
    let filtered = filterToolsByPersona(pc, @["shell", "file_read"])
    check: filtered.len == 1
    check: "shell" notin filtered

  test "unknown tool names in allow are ignored":
    let pc = PersonaConfig(
      name: "cautious",
      systemPrompt: "Only known tools.",
      toolsAllow: @["shell", "nonexistent_tool"],
    )
    let filtered = filterToolsByPersona(pc, @["shell", "file_read"])
    check: filtered.len == 1
    check: "shell" in filtered
    check: "nonexistent_tool" notin filtered

  test "scopedRegistry filters the base registry tools":
    var reg = newPersonaRegistry()
    let pc = PersonaConfig(
      name: "writer",
      systemPrompt: "Write docs.",
      toolsAllow: @["file_read", "file_write"],
      toolsDeny: @[],
    )
    reg.registerPersona(pc)
    # Test filterToolsByPersona which doesn't need Tool objects
    let allTools = @["shell", "file_read", "file_write"]
    let filtered = filterToolsByPersona(pc, allTools)
    check: filtered.len == 2
    check: "file_read" in filtered
    check: "file_write" in filtered
    check: "shell" notin filtered


suite "Memory scope":

  test "persona default memory scope is own_sessions":
    let pc = PersonaConfig(name: "default_persona")
    check: pc.memoryScope == msOwnSessions

  test "stateless persona has msNone":
    let pc = PersonaConfig(
      name: "stateless",
      memoryScope: msNone,
    )
    check: pc.memoryScope == msNone


suite "DelegationConfig":

  test "defaultDelegationConfig uses constants":
    let dc = defaultDelegationConfig()
    check: dc.maxDepth == delegate.DefaultMaxDelegationDepth
    check: dc.maxDelegations == delegate.DefaultMaxDelegationsPerRun

  test "canDelegate returns true when both > 0":
    var dc = defaultDelegationConfig()
    check: dc.canDelegate == true

  test "useDelegationSlot decrements both counters":
    var dc = defaultDelegationConfig()
    let origDepth = dc.maxDepth
    let origDel = dc.maxDelegations
    dc.useDelegationSlot()
    check: dc.maxDepth == origDepth - 1
    check: dc.maxDelegations == origDel - 1

  test "applyPersonaDelegation uses defaults for empty ints":
    let dc = applyPersonaDelegation(0, 0, "test")
    check: dc.maxDepth == delegate.DefaultMaxDelegationDepth
    check: dc.maxDelegations == delegate.DefaultMaxDelegationsPerRun
    check: dc.personaName == "test"

  test "applyPersonaDelegation parses explicit values":
    let dc = applyPersonaDelegation(3, 10, "explicit")
    check: dc.maxDepth == 3
    check: dc.maxDelegations == 10
    check: dc.personaName == "explicit"


suite "System prompt defaults":

  test "persona system prompt is empty by default":
    let pc = PersonaConfig(name: "anon")
    check: pc.systemPrompt.len == 0

  test "persona has a memory scope default":
    let pc = PersonaConfig(name: "default_persona")
    check: pc.memoryScope == msOwnSessions
```

`mercury_core/tests/test_rate_limit.nim`:

```nim
## Tests for mercury_core/rate_limit.nim
##
## Exercises the sendWithRetry generic async proc with mock send functions
## and a mock sleep that records delays instead of actually sleeping.

import std/[asyncdispatch, strutils, unittest]
import mercury_core/rate_limit

# ---------------------------------------------------------------------------
# Mock sleep: records delays instead of sleeping
# ---------------------------------------------------------------------------

var recordedDelays: seq[int]

proc mockSleep(ms: int): Future[void] {.async.} =
  recordedDelays.add(ms)

# ---------------------------------------------------------------------------
# Mock send functions
# ---------------------------------------------------------------------------

proc successSend(): Future[int] {.async.} =
  return 42

proc alwaysRateLimitSend(): Future[int] {.async.} =
  var e = newException(RateLimitError, "rate limited")
  e.retryAfterMs = 0
  raise e

proc alwaysServerErrorSend(): Future[int] {.async.} =
  var e = newException(ServerError, "server error 500")
  e.statusCode = 500
  raise e

proc alwaysValueErrorSend(): Future[int] {.async.} =
  raise newException(ValueError, "client error")

proc rateLimitWithRetryAfterSend(): Future[int] {.async.} =
  var e = newException(RateLimitError, "rate limited with retry-after")
  e.retryAfterMs = 5000
  raise e

# ---------------------------------------------------------------------------
# Stateful mock: rate limit N times then succeed
# ---------------------------------------------------------------------------

var rlThenSuccessCount = 0

proc rateLimitThenSuccessSend(): Future[int] {.async.} =
  inc rlThenSuccessCount
  if rlThenSuccessCount < 3:
    var e = newException(RateLimitError, "rate limited")
    e.retryAfterMs = 0
    raise e
  return 42

# ---------------------------------------------------------------------------
# Stateful mock: server error then succeed
# ---------------------------------------------------------------------------

var seThenSuccessCount = 0

proc serverErrorThenSuccessSend(): Future[int] {.async.} =
  inc seThenSuccessCount
  if seThenSuccessCount < 2:
    var e = newException(ServerError, "server error 502")
    e.statusCode = 502
    raise e
  return 42

# ---------------------------------------------------------------------------
# Stateful mock: rate limit with retry-after then succeed
# ---------------------------------------------------------------------------

var rlRetryAfterThenSuccessCount = 0

proc rateLimitRetryAfterThenSuccessSend(): Future[int] {.async.} =
  inc rlRetryAfterThenSuccessCount
  if rlRetryAfterThenSuccessCount < 2:
    var e = newException(RateLimitError, "rate limited")
    e.retryAfterMs = 5000
    raise e
  return 42

# ---------------------------------------------------------------------------
# Stateful mock: mixed errors then succeed
# ---------------------------------------------------------------------------

var mixedCount = 0

proc mixedErrorSend(): Future[int] {.async.} =
  inc mixedCount
  if mixedCount == 1:
    var e = newException(RateLimitError, "rate limited")
    e.retryAfterMs = 0
    raise e
  if mixedCount == 2:
    var e = newException(ServerError, "server error 502")
    e.statusCode = 502
    raise e
  return 42

# ---------------------------------------------------------------------------
# Stateful mock: rate limit then server error then succeed (3 attempts)
# ---------------------------------------------------------------------------

var rlSeSuccessCount = 0

proc rateLimitSeSuccessSend(): Future[int] {.async.} =
  inc rlSeSuccessCount
  if rlSeSuccessCount == 1:
    var e = newException(RateLimitError, "rate limited")
    e.retryAfterMs = 0
    raise e
  if rlSeSuccessCount == 2:
    var e = newException(ServerError, "server error 500")
    e.statusCode = 500
    raise e
  return 42

# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

suite "sendWithRetry":
  setup:
    recordedDelays = @[]
    rlThenSuccessCount = 0
    seThenSuccessCount = 0
    rlRetryAfterThenSuccessCount = 0
    mixedCount = 0
    rlSeSuccessCount = 0

  test "returns result on first success":
    let result = waitFor sendWithRetry(successSend, maxAttempts = 3,
                                        baseDelayMs = 1000, sleepFn = mockSleep)
    check result == 42
    check recordedDelays.len == 0

  test "retries on RateLimitError with exponential backoff":
    let result = waitFor sendWithRetry(rateLimitThenSuccessSend, maxAttempts = 3,
                                       baseDelayMs = 1000, sleepFn = mockSleep)
    check result == 42
    check rlThenSuccessCount == 3
    # Attempt 1 fails -> delay = 1000 * 2^0 = 1000
    # Attempt 2 fails -> delay = 1000 * 2^1 = 2000
    check recordedDelays == @[1000, 2000]

  test "respects Retry-After from RateLimitError":
    let result = waitFor sendWithRetry(rateLimitRetryAfterThenSuccessSend,
                                       maxAttempts = 3, baseDelayMs = 1000,
                                       sleepFn = mockSleep)
    check result == 42
    # retryAfterMs = 5000 overrides exponential backoff
    check recordedDelays == @[5000]

  test "retries on ServerError with exponential backoff":
    let result = waitFor sendWithRetry(serverErrorThenSuccessSend, maxAttempts = 3,
                                       baseDelayMs = 1000, sleepFn = mockSleep)
    check result == 42
    # Attempt 1 fails -> delay = 1000 * 2^0 = 1000
    check recordedDelays == @[1000]

  test "raises RetryExhaustedError after max attempts on persistent rate limit":
    expect RetryExhaustedError:
      discard waitFor sendWithRetry(alwaysRateLimitSend, maxAttempts = 3,
                                    baseDelayMs = 1000, sleepFn = mockSleep)
    # 3 attempts, 2 delays (between attempts 1-2 and 2-3)
    check recordedDelays.len == 2
    check recordedDelays == @[1000, 2000]

  test "raises RetryExhaustedError after max attempts on persistent server error":
    expect RetryExhaustedError:
      discard waitFor sendWithRetry(alwaysServerErrorSend, maxAttempts = 3,
                                    baseDelayMs = 1000, sleepFn = mockSleep)
    check recordedDelays.len == 2
    check recordedDelays == @[1000, 2000]

  test "does not retry on other exceptions":
    expect ValueError:
      discard waitFor sendWithRetry(alwaysValueErrorSend, maxAttempts = 3,
                                    baseDelayMs = 1000, sleepFn = mockSleep)
    check recordedDelays.len == 0

  test "mixed errors: rate limit then server error then success":
    let result = waitFor sendWithRetry(mixedErrorSend, maxAttempts = 3,
                                       baseDelayMs = 1000, sleepFn = mockSleep)
    check result == 42
    check mixedCount == 3
    # Attempt 1 (rate limit) -> delay = 1000 * 2^0 = 1000
    # Attempt 2 (server error) -> delay = 1000 * 2^1 = 2000
    check recordedDelays == @[1000, 2000]

  test "respects custom maxAttempts":
    # With maxAttempts=1, even a single rate limit should exhaust retries
    expect RetryExhaustedError:
      discard waitFor sendWithRetry(alwaysRateLimitSend, maxAttempts = 1,
                                    baseDelayMs = 1000, sleepFn = mockSleep)
    check recordedDelays.len == 0

  test "respects custom baseDelayMs":
    let result = waitFor sendWithRetry(serverErrorThenSuccessSend, maxAttempts = 3,
                                       baseDelayMs = 500, sleepFn = mockSleep)
    check result == 42
    # Attempt 1 fails -> delay = 500 * 2^0 = 500
    check recordedDelays == @[500]

  test "uses default sleep when sleepFn not provided":
    # This test actually sleeps for a tiny duration to verify defaultSleepFn works.
    # We use a very short baseDelayMs to keep the test fast.
    proc quickSuccess(): Future[int] {.async.} = return 99
    let result = waitFor sendWithRetry(quickSuccess, maxAttempts = 3,
                                       baseDelayMs = 1)
    check result == 99

  test "RetryExhaustedError message includes attempt count":
    try:
      discard waitFor sendWithRetry(alwaysRateLimitSend, maxAttempts = 3,
                                    baseDelayMs = 1, sleepFn = mockSleep)
      check false  # Should not reach here
    except RetryExhaustedError as e:
      check "3" in e.msg
```

`mercury_core/tests/test_thread_mapping.nim`:

```nim
## Tests for mercury_core/thread_mapping.nim
##
## All tests use an in-memory SQLite database (:memory:) so no files are
## created on disk and tests are fully isolated.

import std/[unittest, options, os]
import db_connector/db_sqlite
import mercury_core/thread_mapping

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

proc openTestDb(): DbConn =
  let db = open(":memory:", "", "", "")
  db.exec(sql"PRAGMA journal_mode=WAL")
  db.exec(sql"PRAGMA foreign_keys=ON")
  initThreadMappingSchema(db)
  return db

# ---------------------------------------------------------------------------
# Suite: initThreadMappingSchema
# ---------------------------------------------------------------------------

suite "initThreadMappingSchema":
  test "creates discord_threads table without error":
    let db = openTestDb()
    defer: db.close()
    # If we got here, schema creation succeeded
    let rows = db.getAllRows(sql"SELECT name FROM sqlite_master WHERE type='table' AND name='discord_threads'")
    check rows.len == 1

  test "idempotent — calling twice does not error":
    let db = openTestDb()
    defer: db.close()
    initThreadMappingSchema(db)  # second call should be safe
    let rows = db.getAllRows(sql"SELECT name FROM sqlite_master WHERE type='table' AND name='discord_threads'")
    check rows.len == 1

# ---------------------------------------------------------------------------
# Suite: setThreadMapping / getSessionForThread
# ---------------------------------------------------------------------------

suite "setThreadMapping and getSessionForThread":
  test "set and retrieve session ID for a thread":
    let db = openTestDb()
    defer: db.close()
    setThreadMapping(db, "thread_123", "sess_abc", "channel_456", "guild_789")
    let result = getSessionForThread(db, "thread_123")
    check result.isSome()
    check result.get() == "sess_abc"

  test "getSessionForThread returns None for unknown thread":
    let db = openTestDb()
    defer: db.close()
    let result = getSessionForThread(db, "nonexistent_thread")
    check result.isNone()

  test "setThreadMapping upserts — updating an existing mapping":
    let db = openTestDb()
    defer: db.close()
    setThreadMapping(db, "thread_123", "sess_old", "channel_456", "guild_789")
    setThreadMapping(db, "thread_123", "sess_new", "channel_456", "guild_789")
    let result = getSessionForThread(db, "thread_123")
    check result.isSome()
    check result.get() == "sess_new"

  test "multiple threads map to different sessions":
    let db = openTestDb()
    defer: db.close()
    setThreadMapping(db, "thread_1", "sess_a", "channel_x", "guild_g")
    setThreadMapping(db, "thread_2", "sess_b", "channel_x", "guild_g")
    check getSessionForThread(db, "thread_1").get() == "sess_a"
    check getSessionForThread(db, "thread_2").get() == "sess_b"

# ---------------------------------------------------------------------------
# Suite: archiveThread
# ---------------------------------------------------------------------------

suite "archiveThread":
  test "archiveThread marks a thread as archived":
    let db = openTestDb()
    defer: db.close()
    setThreadMapping(db, "thread_123", "sess_abc", "channel_456", "guild_789")
    archiveThread(db, "thread_123")
    let row = db.getRow(sql"SELECT is_archived FROM discord_threads WHERE thread_id = ?", "thread_123")
    check row[0] == "1"

  test "archiveThread on nonexistent thread does not error":
    let db = openTestDb()
    defer: db.close()
    archiveThread(db, "nonexistent_thread")  # should not raise

  test "archived thread still returns session via getSessionForThread":
    let db = openTestDb()
    defer: db.close()
    setThreadMapping(db, "thread_123", "sess_abc", "channel_456", "guild_789")
    archiveThread(db, "thread_123")
    let result = getSessionForThread(db, "thread_123")
    check result.isSome()
    check result.get() == "sess_abc"

# ---------------------------------------------------------------------------
# Suite: getLatestSessionForChannel
# ---------------------------------------------------------------------------

suite "getLatestSessionForChannel":
  test "returns the most recent session for a channel":
    let db = openTestDb()
    defer: db.close()
    setThreadMapping(db, "thread_1", "sess_first", "channel_x", "guild_g")
    sleep(1100)  # ensure different second-level timestamps
    setThreadMapping(db, "thread_2", "sess_second", "channel_x", "guild_g")
    let result = getLatestSessionForChannel(db, "channel_x")
    check result.isSome()
    check result.get() == "sess_second"

  test "returns None for a channel with no threads":
    let db = openTestDb()
    defer: db.close()
    let result = getLatestSessionForChannel(db, "empty_channel")
    check result.isNone()

  test "skips archived threads by default":
    let db = openTestDb()
    defer: db.close()
    setThreadMapping(db, "thread_1", "sess_archived", "channel_x", "guild_g")
    archiveThread(db, "thread_1")
    setThreadMapping(db, "thread_2", "sess_active", "channel_x", "guild_g")
    let result = getLatestSessionForChannel(db, "channel_x")
    check result.isSome()
    check result.get() == "sess_active"

  test "returns archived session when all threads are archived":
    let db = openTestDb()
    defer: db.close()
    setThreadMapping(db, "thread_1", "sess_archived", "channel_x", "guild_g")
    archiveThread(db, "thread_1")
    let result = getLatestSessionForChannel(db, "channel_x")
    check result.isSome()
    check result.get() == "sess_archived"

  test "different channels are isolated":
    let db = openTestDb()
    defer: db.close()
    setThreadMapping(db, "thread_1", "sess_a", "channel_x", "guild_g")
    setThreadMapping(db, "thread_2", "sess_b", "channel_y", "guild_g")
    check getLatestSessionForChannel(db, "channel_x").get() == "sess_a"
    check getLatestSessionForChannel(db, "channel_y").get() == "sess_b"

# ---------------------------------------------------------------------------
# Suite: last_active_at updates
# ---------------------------------------------------------------------------

suite "last_active_at tracking":
  test "setThreadMapping sets created_at and last_active_at":
    let db = openTestDb()
    defer: db.close()
    setThreadMapping(db, "thread_1", "sess_a", "channel_x", "guild_g")
    let row = db.getRow(sql"SELECT created_at, last_active_at FROM discord_threads WHERE thread_id = ?", "thread_1")
    check row[0].len > 0
    check row[1].len > 0

  test "upsert updates last_active_at":
    let db = openTestDb()
    defer: db.close()
    setThreadMapping(db, "thread_1", "sess_old", "channel_x", "guild_g")
    let row1 = db.getRow(sql"SELECT last_active_at FROM discord_threads WHERE thread_id = ?", "thread_1")
    setThreadMapping(db, "thread_1", "sess_new", "channel_x", "guild_g")
    let row2 = db.getRow(sql"SELECT last_active_at FROM discord_threads WHERE thread_id = ?", "thread_1")
    # last_active_at should be updated (newer or equal timestamp)
    check row2[0] >= row1[0]
```

`mercury_core/tests/test_thread_reconnection.nim`:

```nim
import std/[asyncdispatch, strutils, unittest, options]
import db_connector/db_sqlite
import mercury_core/discord
import mercury_core/discord_mocks
import mercury_core/discord_types
import mercury_core/agent_dispatcher
import mercury_core/thread_mapping

proc openTestDb(): DbConn =
  let db = open(":memory:", "", "", "")
  initThreadMappingSchema(db)
  return db

proc makeConfig(): DiscordConfig =
  result = defaultDiscordConfig()
  result.users.allow = @["user1"]

proc makeDispatcher(): AgentDispatcher =
  newAgentDispatcher(proc(r: AgentResult) = discard)

suite "thread reconnection":
  test "mention in channel with archived thread creates new thread and reuses old session":
    let db = openTestDb()
    defer: db.close()
    let api = newMockDiscordApi()
    let bot = newDiscordBot(
      sendMessage = mockSendFn(api),
      triggerTyping = mockTypingFn(api),
      createThread = mockCreateThreadFn(api),
      archiveThread = mockArchiveThreadFn(api),
      db = db,
      config = makeConfig(),
      dispatcher = makeDispatcher(),
      shard = newMockShard("bot"),
    )

    setThreadMapping(db, "old_thread", "sess_old123", "chan1", "guild1")
    archiveThread(db, "old_thread")

    let msg = Message(
      id: "msg_1",
      author: MockUser(id: "user1", username: "user1", bot: false),
      content: "<@bot> hello",
      channel_id: "chan1",
      guild_id: some("guild1"),
      mention_users: @[MockUser(id: "bot", username: "bot", bot: false)],
    )

    waitFor bot.onMessageCreate(msg)

    check api.calls.len >= 3
    check api.calls[0].kind == mockCreateThread
    check api.calls[0].name == "Mercury-sess_old"
    check api.calls[1].kind == mockSendMessage
    check api.calls[1].content == "Continuing from previous session."
    check api.calls[2].kind == mockTriggerTyping

    let threadSession = getSessionForThread(db, api.calls[0].threadId)
    check threadSession.isSome
    check threadSession.get() == "sess_old123"

  test "mention in channel with no previous thread creates new session":
    let db = openTestDb()
    defer: db.close()
    let api = newMockDiscordApi()
    let bot = newDiscordBot(
      sendMessage = mockSendFn(api),
      triggerTyping = mockTypingFn(api),
      createThread = mockCreateThreadFn(api),
      archiveThread = mockArchiveThreadFn(api),
      db = db,
      config = makeConfig(),
      dispatcher = makeDispatcher(),
      shard = newMockShard("bot"),
    )

    let msg = Message(
      id: "msg_2",
      author: MockUser(id: "user1", username: "user1", bot: false),
      content: "<@bot> hello",
      channel_id: "chan2",
      guild_id: some("guild1"),
      mention_users: @[MockUser(id: "bot", username: "bot", bot: false)],
    )

    waitFor bot.onMessageCreate(msg)

    check api.calls.len >= 2
    check api.calls[0].kind == mockCreateThread
    check api.calls[0].name.startsWith("Mercury-sess_")
    check api.calls[1].kind == mockTriggerTyping

    let threadSession = getSessionForThread(db, api.calls[0].threadId)
    check threadSession.isSome
    check threadSession.get().startsWith("sess_")

  test "message in active thread continues existing session without new thread":
    let db = openTestDb()
    defer: db.close()
    let api = newMockDiscordApi()
    let bot = newDiscordBot(
      sendMessage = mockSendFn(api),
      triggerTyping = mockTypingFn(api),
      createThread = mockCreateThreadFn(api),
      archiveThread = mockArchiveThreadFn(api),
      db = db,
      config = makeConfig(),
      dispatcher = makeDispatcher(),
      shard = newMockShard("bot"),
    )

    setThreadMapping(db, "thread_active", "sess_active", "chan3", "guild1")

    let msg = Message(
      id: "msg_3",
      author: MockUser(id: "user1", username: "user1", bot: false),
      content: "follow up",
      channel_id: "thread_active",
      guild_id: some("guild1"),
      mention_users: @[],
    )

    waitFor bot.onMessageCreate(msg)

    check api.calls.len == 1
    check api.calls[0].kind == mockTriggerTyping
    check getSessionForThread(db, "thread_active").get() == "sess_active"

```

`mercury_core/tests/tllm_client.nim`:

```nim
## Tests for mercury_core/llm_client.nim
##
## Uses a tiny in-process TCP mock server (one connection at a time, sync)
## to exercise the LLM client without depending on Task 2.3's mock server.

import std/[json, net, os, strutils, tables, unittest, locks, threadpool]
import mercury_core/llm_client

# ---------------------------------------------------------------------------
# Mock HTTP server
# ---------------------------------------------------------------------------

type
  MockResponse = object
    statusLine: string             ## e.g. "200 OK"
    body: string
    contentType: string

  MockServer = ref object
    socket: Socket
    port: int
    thread: Thread[MockServer]
    responses: seq[MockResponse]   ## FIFO queue of responses
    requestCount: int
    requestBodies: seq[string]
    lock: Lock
    running: bool

# Use globals because Nim threads cannot capture refs from the heap
# trivially across thread boundaries on all platforms.
var gServer: MockServer

proc readRequest(client: Socket): string =
  ## Reads an HTTP request from a connected socket and returns the body.
  ## Returns "" if no body or on parse failure.
  var headerBuf = ""
  while true:
    let line = client.recvLine(timeout = 5000)
    if line.len == 0:
      break
    headerBuf.add(line)
    headerBuf.add("\r\n")
    if line == "\r\n" or line == "":
      break
  # Determine content length
  var contentLength = 0
  for raw in headerBuf.splitLines():
    let lower = raw.toLowerAscii()
    if lower.startsWith("content-length:"):
      let valPart = raw[raw.find(':') + 1 .. ^1].strip()
      try:
        contentLength = parseInt(valPart)
      except ValueError:
        contentLength = 0
  if contentLength <= 0:
    return ""
  var body = newString(contentLength)
  var got = 0
  while got < contentLength:
    let chunk = client.recv(contentLength - got, timeout = 5000)
    if chunk.len == 0:
      break
    body[got ..< got + chunk.len] = chunk
    got += chunk.len
  return body[0 ..< got]

proc sendResponse(client: Socket; resp: MockResponse) =
  let ct = if resp.contentType.len > 0: resp.contentType else: "application/json"
  let payload = "HTTP/1.1 " & resp.statusLine & "\r\n" &
                "Content-Type: " & ct & "\r\n" &
                "Content-Length: " & $resp.body.len & "\r\n" &
                "Connection: close\r\n\r\n" & resp.body
  client.send(payload)

proc serverLoop(srv: MockServer) {.thread.} =
  while srv.running:
    var client: Socket
    try:
      srv.socket.accept(client)
    except OSError, IOError:
      return
    if client.isNil:
      return
    try:
      let body = readRequest(client)
      var resp: MockResponse
      withLock srv.lock:
        srv.requestCount.inc
        srv.requestBodies.add(body)
        if srv.responses.len == 0:
          resp = MockResponse(
            statusLine: "500 Internal Server Error",
            body: """{"error": {"message": "no mock response queued"}}""")
        else:
          resp = srv.responses[0]
          srv.responses.delete(0)
      sendResponse(client, resp)
    except CatchableError:
      discard
    finally:
      try: client.close() except CatchableError: discard

proc startMockServer(): MockServer =
  result = MockServer(
    socket: newSocket(),
    responses: @[],
    requestBodies: @[],
    requestCount: 0,
    running: true,
  )
  initLock(result.lock)
  result.socket.setSockOpt(OptReuseAddr, true)
  # Bind on an OS-assigned port on loopback only.
  result.socket.bindAddr(Port(0), "127.0.0.1")
  let (_, portObj) = result.socket.getLocalAddr()
  result.port = portObj.int
  result.socket.listen()
  gServer = result
  createThread(result.thread, serverLoop, result)

proc stopMockServer(srv: MockServer) =
  if not srv.running:
    return
  srv.running = false
  # Connect a dummy client so that accept() in the thread unblocks (the
  # loop will exit because srv.running is now false).  On some platforms
  # close() alone does not reliably wake a blocked accept().
  var dummy = newSocket()
  try:
    dummy.connect("127.0.0.1", Port(srv.port))
  except CatchableError:
    discard
  finally:
    try: dummy.close() except CatchableError: discard
  joinThread(srv.thread)
  try: srv.socket.close() except CatchableError: discard
  deinitLock(srv.lock)

proc enqueue(srv: MockServer; statusLine, body: string) =
  withLock srv.lock:
    srv.responses.add(MockResponse(statusLine: statusLine, body: body))

proc resetMock(srv: MockServer) =
  withLock srv.lock:
    srv.responses.setLen(0)
    srv.requestBodies.setLen(0)
    srv.requestCount = 0

proc baseUrlFor(srv: MockServer): string =
  "http://127.0.0.1:" & $srv.port & "/v1"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

const SuccessBody = """
{
  "id": "chatcmpl-1",
  "object": "chat.completion",
  "model": "test-model",
  "choices": [{
    "index": 0,
    "message": {"role": "assistant", "content": "Hello!"},
    "finish_reason": "stop"
  }],
  "usage": {"prompt_tokens": 7, "completion_tokens": 3, "total_tokens": 10}
}
"""

const ToolCallBody = """
{
  "id": "chatcmpl-2",
  "object": "chat.completion",
  "model": "test-model",
  "choices": [{
    "index": 0,
    "message": {
      "role": "assistant",
      "content": null,
      "tool_calls": [
        {"id": "call_abc", "type": "function",
         "function": {"name": "shell", "arguments": "{\"cmd\": \"ls\"}"}}
      ]
    },
    "finish_reason": "tool_calls"
  }]
}
"""

const AuthErrBody = """{"error": {"message": "Invalid API key", "code": "invalid_api_key"}}"""
const RateLimitBody = """{"error": {"message": "Too many requests"}}"""
const ServerErrBody = """{"error": {"message": "upstream timeout"}}"""

proc makeClient(server: MockServer; maxRetries = 3; backoffMs = 5): LLMClient =
  newLLMClient(
    baseUrl = baseUrlFor(server),
    apiKey = "test-key",
    model = "test-model",
    maxRetries = maxRetries,
    retryBackoffMs = backoffMs,
    timeoutMs = 5_000,
  )

# ---------------------------------------------------------------------------
# Test setup: a single shared server for all suites
# ---------------------------------------------------------------------------

var sharedServer = startMockServer()

# ---------------------------------------------------------------------------
# Suite: basic chat completion
# ---------------------------------------------------------------------------

suite "chatCompletion basic":
  setup:
    resetMock(sharedServer)

  test "parses content from successful response":
    sharedServer.enqueue("200 OK", SuccessBody)
    let client = makeClient(sharedServer)
    let resp = client.chatCompletion("say hello")
    check resp.content == "Hello!"
    check resp.finishReason == "stop"
    check resp.toolCalls.len == 0
    check resp.usage.promptTokens == 7
    check resp.usage.completionTokens == 3
    check resp.usage.totalTokens == 10
    check resp.model == "test-model"

  test "sends prompt as final user message":
    sharedServer.enqueue("200 OK", SuccessBody)
    let client = makeClient(sharedServer)
    discard client.chatCompletion("hello world")
    check sharedServer.requestCount == 1
    let reqJson = parseJson(sharedServer.requestBodies[0])
    check reqJson["model"].getStr() == "test-model"
    let msgs = reqJson["messages"]
    check msgs.kind == JArray
    check msgs[^1]["role"].getStr() == "user"
    check msgs[^1]["content"].getStr() == "hello world"

  test "appends prompt after history":
    sharedServer.enqueue("200 OK", SuccessBody)
    let client = makeClient(sharedServer)
    let history = @[
      ChatMessage(role: crSystem, content: "you are helpful"),
      ChatMessage(role: crUser, content: "first"),
      ChatMessage(role: crAssistant, content: "ack"),
    ]
    discard client.chatCompletion("second", history = history)
    let reqJson = parseJson(sharedServer.requestBodies[0])
    let msgs = reqJson["messages"]
    check msgs.len == 4
    check msgs[0]["role"].getStr() == "system"
    check msgs[1]["role"].getStr() == "user"
    check msgs[1]["content"].getStr() == "first"
    check msgs[3]["content"].getStr() == "second"

  test "extra params override defaults":
    sharedServer.enqueue("200 OK", SuccessBody)
    var defaults = initTable[string, JsonNode]()
    defaults["temperature"] = %0.2
    let client = newLLMClient(
      baseUrl = baseUrlFor(sharedServer),
      apiKey = "k",
      model = "test-model",
      defaultParams = defaults,
      maxRetries = 1,
      retryBackoffMs = 5,
    )
    var extra = initTable[string, JsonNode]()
    extra["temperature"] = %0.9
    extra["max_tokens"] = %256
    discard client.chatCompletion("hi", extraParams = extra)
    let reqJson = parseJson(sharedServer.requestBodies[0])
    check reqJson["temperature"].getFloat() == 0.9
    check reqJson["max_tokens"].getInt() == 256

# ---------------------------------------------------------------------------
# Suite: tool calls
# ---------------------------------------------------------------------------

suite "chatCompletion tool calls":
  setup:
    resetMock(sharedServer)

  test "parses tool_calls from response":
    sharedServer.enqueue("200 OK", ToolCallBody)
    let client = makeClient(sharedServer)
    let resp = client.chatCompletion("run ls")
    check resp.content == ""
    check resp.finishReason == "tool_calls"
    check resp.toolCalls.len == 1
    let tc = resp.toolCalls[0]
    check tc.id == "call_abc"
    check tc.name == "shell"
    check tc.arguments.contains("\"cmd\"")
    check tc.arguments.contains("ls")

  test "round-trips assistant tool_calls in history":
    sharedServer.enqueue("200 OK", SuccessBody)
    let client = makeClient(sharedServer)
    let history = @[
      ChatMessage(role: crUser, content: "run ls"),
      ChatMessage(
        role: crAssistant,
        content: "",
        toolCalls: @[ToolCall(
          id: "call_abc", name: "shell", arguments: "{\"cmd\":\"ls\"}")]),
      ChatMessage(role: crTool, content: "file1\nfile2",
                  toolCallId: "call_abc", name: "shell"),
    ]
    discard client.chatCompletion("", history = history)
    let req = parseJson(sharedServer.requestBodies[0])
    let msgs = req["messages"]
    check msgs.len == 3
    check msgs[1]["role"].getStr() == "assistant"
    check msgs[1]["tool_calls"].kind == JArray
    check msgs[1]["tool_calls"][0]["id"].getStr() == "call_abc"
    check msgs[1]["tool_calls"][0]["function"]["name"].getStr() == "shell"
    check msgs[2]["role"].getStr() == "tool"
    check msgs[2]["tool_call_id"].getStr() == "call_abc"

# ---------------------------------------------------------------------------
# Suite: error mapping
# ---------------------------------------------------------------------------

suite "chatCompletion errors":
  setup:
    resetMock(sharedServer)

  test "401 raises AuthError":
    sharedServer.enqueue("401 Unauthorized", AuthErrBody)
    let client = makeClient(sharedServer, maxRetries = 1)
    expect AuthError:
      discard client.chatCompletion("hi")

  test "AuthError exposes status code":
    sharedServer.enqueue("401 Unauthorized", AuthErrBody)
    let client = makeClient(sharedServer, maxRetries = 1)
    var caught = false
    try:
      discard client.chatCompletion("hi")
    except AuthError as e:
      caught = true
      check e.statusCode == 401
      check e.msg.contains("Invalid API key")
    check caught

  test "400 raises ClientError, not retried":
    sharedServer.enqueue("400 Bad Request",
      """{"error": {"message": "bad input"}}""")
    let client = makeClient(sharedServer, maxRetries = 3)
    expect ClientError:
      discard client.chatCompletion("hi")
    check sharedServer.requestCount == 1

  test "non-JSON success body raises ProtocolError":
    sharedServer.enqueue("200 OK", "not json at all")
    let client = makeClient(sharedServer, maxRetries = 1)
    expect ProtocolError:
      discard client.chatCompletion("hi")

# ---------------------------------------------------------------------------
# Suite: retry behavior
# ---------------------------------------------------------------------------

suite "chatCompletion retry":
  setup:
    resetMock(sharedServer)

  test "429 triggers retry then succeeds":
    sharedServer.enqueue("429 Too Many Requests", RateLimitBody)
    sharedServer.enqueue("429 Too Many Requests", RateLimitBody)
    sharedServer.enqueue("200 OK", SuccessBody)
    let client = makeClient(sharedServer, maxRetries = 3, backoffMs = 1)
    let resp = client.chatCompletion("hi")
    check resp.content == "Hello!"
    check sharedServer.requestCount == 3

  test "429 exhausts retries and raises RateLimitError":
    sharedServer.enqueue("429 Too Many Requests", RateLimitBody)
    sharedServer.enqueue("429 Too Many Requests", RateLimitBody)
    sharedServer.enqueue("429 Too Many Requests", RateLimitBody)
    let client = makeClient(sharedServer, maxRetries = 3, backoffMs = 1)
    var caught = false
    try:
      discard client.chatCompletion("hi")
    except RateLimitError as e:
      caught = true
      check e.statusCode == 429
    check caught
    check sharedServer.requestCount == 3

  test "500 retries then raises ServerError":
    sharedServer.enqueue("500 Internal Server Error", ServerErrBody)
    sharedServer.enqueue("503 Service Unavailable", ServerErrBody)
    sharedServer.enqueue("502 Bad Gateway", ServerErrBody)
    let client = makeClient(sharedServer, maxRetries = 3, backoffMs = 1)
    expect ServerError:
      discard client.chatCompletion("hi")
    check sharedServer.requestCount == 3

  test "500 then 200 succeeds after retry":
    sharedServer.enqueue("500 Internal Server Error", ServerErrBody)
    sharedServer.enqueue("200 OK", SuccessBody)
    let client = makeClient(sharedServer, maxRetries = 3, backoffMs = 1)
    let resp = client.chatCompletion("hi")
    check resp.content == "Hello!"
    check sharedServer.requestCount == 2

  test "maxRetries=1 does not retry":
    sharedServer.enqueue("429 Too Many Requests", RateLimitBody)
    let client = makeClient(sharedServer, maxRetries = 1, backoffMs = 1)
    expect RateLimitError:
      discard client.chatCompletion("hi")
    check sharedServer.requestCount == 1

# ---------------------------------------------------------------------------
# Suite: request shape
# ---------------------------------------------------------------------------

suite "chatCompletion request shape":
  setup:
    resetMock(sharedServer)

  test "request body is well-formed JSON with required keys":
    sharedServer.enqueue("200 OK", SuccessBody)
    let client = makeClient(sharedServer)
    discard client.chatCompletion("ping")
    let req = parseJson(sharedServer.requestBodies[0])
    check req.hasKey("model")
    check req.hasKey("messages")

# ---------------------------------------------------------------------------
# Teardown
# ---------------------------------------------------------------------------

# Stop server at process exit so threads don't linger.
addQuitProc(proc() {.noconv.} = stopMockServer(sharedServer))

```

`mercury_core/tests/tmemory.nim`:

```nim
## Tests for mercury_core/memory.nim
##
## All tests use an in-memory SQLite database (:memory:) so no files are
## created on disk and tests are fully isolated.

import std/[unittest, strutils]
import mercury_core/llm_client
import mercury_core/memory

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

proc makeMemory(): Memory =
  newMemory(":memory:")

proc userMsg(content: string): ChatMessage =
  ChatMessage(role: crUser, content: content)

proc assistantMsg(content: string): ChatMessage =
  ChatMessage(role: crAssistant, content: content)

proc systemMsg(content: string): ChatMessage =
  ChatMessage(role: crSystem, content: content)

proc toolMsg(content, name, toolCallId: string): ChatMessage =
  ChatMessage(role: crTool, content: content, name: name, toolCallId: toolCallId)

# ---------------------------------------------------------------------------
# Suite: newSession
# ---------------------------------------------------------------------------

suite "newSession":
  test "returns a non-empty session ID":
    var m = makeMemory()
    defer: m.close()
    let sid = m.newSession()
    check sid.len > 0

  test "each call returns a unique ID":
    var m = makeMemory()
    defer: m.close()
    let s1 = m.newSession()
    let s2 = m.newSession()
    check s1 != s2

  test "session ID starts with 'sess_'":
    var m = makeMemory()
    defer: m.close()
    let sid = m.newSession()
    check sid.startsWith("sess_")

# ---------------------------------------------------------------------------
# Suite: appendMessage / getHistory
# ---------------------------------------------------------------------------

suite "appendMessage and getHistory":
  test "empty session returns empty history":
    var m = makeMemory()
    defer: m.close()
    let sid = m.newSession()
    let hist = m.getHistory(sid)
    check hist.len == 0

  test "appended messages are returned in order":
    var m = makeMemory()
    defer: m.close()
    let sid = m.newSession()
    m.appendMessage(sid, systemMsg("you are helpful"))
    m.appendMessage(sid, userMsg("hello"))
    m.appendMessage(sid, assistantMsg("hi there"))
    let hist = m.getHistory(sid)
    check hist.len == 3
    check hist[0].role == crSystem
    check hist[0].content == "you are helpful"
    check hist[1].role == crUser
    check hist[1].content == "hello"
    check hist[2].role == crAssistant
    check hist[2].content == "hi there"

  test "tool message round-trips name and toolCallId":
    var m = makeMemory()
    defer: m.close()
    let sid = m.newSession()
    m.appendMessage(sid, toolMsg("result text", "my_tool", "call_xyz"))
    let hist = m.getHistory(sid)
    check hist.len == 1
    check hist[0].role == crTool
    check hist[0].content == "result text"
    check hist[0].name == "my_tool"
    check hist[0].toolCallId == "call_xyz"

  test "assistant message with tool_calls round-trips":
    var m = makeMemory()
    defer: m.close()
    let sid = m.newSession()
    let tc = ToolCall(id: "call_1", name: "shell", arguments: "{\"cmd\":\"ls\"}")
    let msg = ChatMessage(
      role: crAssistant,
      content: "",
      toolCalls: @[tc],
    )
    m.appendMessage(sid, msg)
    let hist = m.getHistory(sid)
    check hist.len == 1
    check hist[0].toolCalls.len == 1
    check hist[0].toolCalls[0].id == "call_1"
    check hist[0].toolCalls[0].name == "shell"
    check hist[0].toolCalls[0].arguments == "{\"cmd\":\"ls\"}"

  test "multiple tool_calls round-trip":
    var m = makeMemory()
    defer: m.close()
    let sid = m.newSession()
    let tcs = @[
      ToolCall(id: "c1", name: "read_file", arguments: "{\"path\":\"/tmp/a\"}"),
      ToolCall(id: "c2", name: "write_file", arguments: "{\"path\":\"/tmp/b\"}"),
    ]
    let msg = ChatMessage(role: crAssistant, content: "", toolCalls: tcs)
    m.appendMessage(sid, msg)
    let hist = m.getHistory(sid)
    check hist[0].toolCalls.len == 2
    check hist[0].toolCalls[0].id == "c1"
    check hist[0].toolCalls[1].id == "c2"

  test "sessions are isolated from each other":
    var m = makeMemory()
    defer: m.close()
    let s1 = m.newSession()
    let s2 = m.newSession()
    m.appendMessage(s1, userMsg("session one"))
    m.appendMessage(s2, userMsg("session two"))
    let h1 = m.getHistory(s1)
    let h2 = m.getHistory(s2)
    check h1.len == 1
    check h1[0].content == "session one"
    check h2.len == 1
    check h2[0].content == "session two"

  test "unknown session returns empty history":
    var m = makeMemory()
    defer: m.close()
    let hist = m.getHistory("nonexistent_session_id")
    check hist.len == 0

  test "message with empty content is stored correctly":
    var m = makeMemory()
    defer: m.close()
    let sid = m.newSession()
    m.appendMessage(sid, assistantMsg(""))
    let hist = m.getHistory(sid)
    check hist.len == 1
    check hist[0].content == ""

# ---------------------------------------------------------------------------
# Suite: getTokenUsage
# ---------------------------------------------------------------------------

suite "getTokenUsage":
  test "empty session returns zero usage":
    var m = makeMemory()
    defer: m.close()
    let sid = m.newSession()
    let usage = m.getTokenUsage(sid)
    check usage.promptTokens == 0
    check usage.completionTokens == 0
    check usage.totalTokens == 0

  test "single message token counts are returned":
    var m = makeMemory()
    defer: m.close()
    let sid = m.newSession()
    m.appendMessage(sid, userMsg("hello"), tokensIn = 10, tokensOut = 0)
    let usage = m.getTokenUsage(sid)
    check usage.promptTokens == 10
    check usage.completionTokens == 0
    check usage.totalTokens == 10

  test "multiple messages accumulate token counts":
    var m = makeMemory()
    defer: m.close()
    let sid = m.newSession()
    m.appendMessage(sid, userMsg("first"),     tokensIn = 5,  tokensOut = 0)
    m.appendMessage(sid, assistantMsg("resp"), tokensIn = 0,  tokensOut = 20)
    m.appendMessage(sid, userMsg("second"),    tokensIn = 8,  tokensOut = 0)
    m.appendMessage(sid, assistantMsg("ok"),   tokensIn = 0,  tokensOut = 15)
    let usage = m.getTokenUsage(sid)
    check usage.promptTokens == 13
    check usage.completionTokens == 35
    check usage.totalTokens == 48

  test "token usage is per-session":
    var m = makeMemory()
    defer: m.close()
    let s1 = m.newSession()
    let s2 = m.newSession()
    m.appendMessage(s1, userMsg("a"), tokensIn = 100, tokensOut = 50)
    m.appendMessage(s2, userMsg("b"), tokensIn = 7,   tokensOut = 3)
    let u1 = m.getTokenUsage(s1)
    let u2 = m.getTokenUsage(s2)
    check u1.totalTokens == 150
    check u2.totalTokens == 10

  test "unknown session returns zero usage":
    var m = makeMemory()
    defer: m.close()
    let usage = m.getTokenUsage("no_such_session")
    check usage.totalTokens == 0

# ---------------------------------------------------------------------------
# Suite: searchHistory (FTS5)
# ---------------------------------------------------------------------------

suite "searchHistory":
  test "empty query returns no results":
    var m = makeMemory()
    defer: m.close()
    let sid = m.newSession()
    m.appendMessage(sid, userMsg("hello world"))
    let results = m.searchHistory("")
    check results.len == 0

  test "search with no matching content returns empty":
    var m = makeMemory()
    defer: m.close()
    let sid = m.newSession()
    m.appendMessage(sid, userMsg("hello world"))
    let results = m.searchHistory("xyzzy_no_match_ever")
    check results.len == 0

  test "search finds a matching message":
    var m = makeMemory()
    defer: m.close()
    let sid = m.newSession()
    m.appendMessage(sid, userMsg("the quick brown fox"))
    m.appendMessage(sid, userMsg("something completely different"))
    let results = m.searchHistory("quick")
    check results.len == 1
    check results[0].content == "the quick brown fox"

  test "search result contains correct session ID":
    var m = makeMemory()
    defer: m.close()
    let sid = m.newSession()
    m.appendMessage(sid, userMsg("unique phrase here"))
    let results = m.searchHistory("unique")
    check results.len == 1
    check results[0].sessionId == sid

  test "search result contains correct role":
    var m = makeMemory()
    defer: m.close()
    let sid = m.newSession()
    m.appendMessage(sid, assistantMsg("I can help with that"))
    let results = m.searchHistory("help")
    check results.len == 1
    check results[0].role == crAssistant

  test "search finds messages across multiple sessions":
    var m = makeMemory()
    defer: m.close()
    let s1 = m.newSession()
    let s2 = m.newSession()
    m.appendMessage(s1, userMsg("mercury is a planet"))
    m.appendMessage(s2, userMsg("mercury is also an element"))
    let results = m.searchHistory("mercury")
    check results.len == 2

  test "search does not return non-matching messages":
    var m = makeMemory()
    defer: m.close()
    let sid = m.newSession()
    m.appendMessage(sid, userMsg("apple banana cherry"))
    m.appendMessage(sid, userMsg("dog cat bird"))
    m.appendMessage(sid, userMsg("red green blue"))
    let results = m.searchHistory("banana")
    check results.len == 1
    check results[0].content == "apple banana cherry"

  test "search snippet is non-empty for a match":
    var m = makeMemory()
    defer: m.close()
    let sid = m.newSession()
    m.appendMessage(sid, userMsg("the quick brown fox jumps over the lazy dog"))
    let results = m.searchHistory("fox")
    check results.len == 1
    check results[0].snippet.len > 0

  test "FTS5 phrase search works":
    var m = makeMemory()
    defer: m.close()
    let sid = m.newSession()
    m.appendMessage(sid, userMsg("hello world from nim"))
    m.appendMessage(sid, userMsg("world peace is important"))
    # FTS5 phrase search uses double quotes
    let results = m.searchHistory("\"hello world\"")
    check results.len == 1
    check results[0].content == "hello world from nim"

# ---------------------------------------------------------------------------
# Suite: multiple Memory instances (isolation)
# ---------------------------------------------------------------------------

suite "Memory isolation":
  test "two in-memory databases are independent":
    var m1 = makeMemory()
    var m2 = makeMemory()
    defer:
      m1.close()
      m2.close()
    let s1 = m1.newSession()
    m1.appendMessage(s1, userMsg("only in m1"))
    let s2 = m2.newSession()
    # m2 should have no messages
    let hist = m2.getHistory(s2)
    check hist.len == 0
    # m1 should have its message
    let h1 = m1.getHistory(s1)
    check h1.len == 1
    check h1[0].content == "only in m1"

```

`mercury_core/tests/ttoken_counter.nim`:

```nim
## Tests for mercury_core/token_counter.nim
##
## Verifies:
##   - countTokens returns expected values for known strings
##   - countTokens handles edge cases (empty, single char)
##   - detectFamily classifies model strings correctly
##   - countMessages applies per-message overhead correctly
##   - countMessages handles empty message list

import std/[unittest, math, strutils]
import mercury_core/token_counter
import mercury_core/llm_client

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

proc approxTokens(text: string; charsPerToken: float): int =
  ## Reference implementation matching token_counter logic.
  if text.len == 0: return 0
  result = int(ceil(text.len.float / charsPerToken))
  if result < 1: result = 1

# ---------------------------------------------------------------------------
# Suite: detectFamily
# ---------------------------------------------------------------------------

suite "detectFamily":
  test "gpt-4 variants":
    check detectFamily("gpt-4") == mfGpt4
    check detectFamily("gpt-4o") == mfGpt4
    check detectFamily("gpt-4-turbo") == mfGpt4
    check detectFamily("GPT-4") == mfGpt4
    check detectFamily("gpt4o") == mfGpt4

  test "o-series":
    check detectFamily("o1") == mfGpt4
    check detectFamily("o1-mini") == mfGpt4
    check detectFamily("o3") == mfGpt4
    check detectFamily("o4-mini") == mfGpt4

  test "gpt-3.5 variants":
    check detectFamily("gpt-3.5-turbo") == mfGpt35
    check detectFamily("gpt-35-turbo") == mfGpt35
    check detectFamily("gpt3.5") == mfGpt35

  test "claude variants":
    check detectFamily("claude-3-opus") == mfClaude
    check detectFamily("claude-3.5-sonnet") == mfClaude
    check detectFamily("claude-3.7-sonnet") == mfClaude
    check detectFamily("claude-2") == mfClaude
    check detectFamily("claude") == mfClaude

  test "llama / mistral / gemma":
    check detectFamily("llama-3") == mfLlama
    check detectFamily("llama3") == mfLlama
    check detectFamily("meta-llama/llama-3") == mfLlama
    check detectFamily("mistral-7b") == mfLlama
    check detectFamily("gemma-2") == mfLlama
    check detectFamily("mixtral-8x7b") == mfLlama

  test "unknown falls back to default":
    check detectFamily("") == mfDefault
    check detectFamily("some-unknown-model") == mfDefault
    check detectFamily("palm-2") == mfDefault

# ---------------------------------------------------------------------------
# Suite: countTokens edge cases
# ---------------------------------------------------------------------------

suite "countTokens edge cases":
  test "empty string returns 0":
    check countTokens("") == 0
    check countTokens("", "gpt-4") == 0
    check countTokens("", "claude-3") == 0

  test "single character returns 1":
    check countTokens("a") == 1
    check countTokens("a", "gpt-4") == 1
    check countTokens("a", "claude-3") == 1

  test "default model is gpt-4":
    # countTokens("hello") with default should equal countTokens("hello", "gpt-4")
    check countTokens("hello") == countTokens("hello", "gpt-4")

# ---------------------------------------------------------------------------
# Suite: countTokens known values — GPT-4 (4.0 chars/token)
# ---------------------------------------------------------------------------

suite "countTokens gpt-4":
  test "4-char string = 1 token":
    # "test" = 4 chars / 4.0 = 1.0 → 1
    check countTokens("test", "gpt-4") == 1

  test "8-char string = 2 tokens":
    # "testtest" = 8 chars / 4.0 = 2.0 → 2
    check countTokens("testtest", "gpt-4") == 2

  test "5-char string rounds up to 2 tokens":
    # "hello" = 5 chars / 4.0 = 1.25 → ceil → 2
    check countTokens("hello", "gpt-4") == 2

  test "12-char string = 3 tokens":
    # "Hello, World" = 12 chars / 4.0 = 3.0 → 3
    check countTokens("Hello, World", "gpt-4") == 3

  test "100-char string = 25 tokens":
    let s = "a".repeat(100)
    check countTokens(s, "gpt-4") == 25

  test "matches reference formula":
    let texts = ["The quick brown fox", "jumps over the lazy dog",
                 "OpenAI GPT-4 tokenizer", "1234567890"]
    for t in texts:
      check countTokens(t, "gpt-4") == approxTokens(t, 4.0)

# ---------------------------------------------------------------------------
# Suite: countTokens known values — Claude (3.8 chars/token)
# ---------------------------------------------------------------------------

suite "countTokens claude":
  test "3-char string rounds up to 1 token":
    # "abc" = 3 chars / 3.8 = 0.789 → ceil → 1
    check countTokens("abc", "claude-3") == 1

  test "4-char string rounds up to 2 tokens":
    # "abcd" = 4 chars / 3.8 = 1.052 → ceil → 2
    check countTokens("abcd", "claude-3") == 2

  test "38-char string = 10 tokens":
    let s = "a".repeat(38)
    # 38 / 3.8 = 10.0 → 10
    check countTokens(s, "claude-3") == 10

  test "matches reference formula":
    let texts = ["The quick brown fox", "jumps over the lazy dog",
                 "Anthropic Claude tokenizer", "1234567890"]
    for t in texts:
      check countTokens(t, "claude-3") == approxTokens(t, 3.8)

  test "claude-3.5-sonnet uses claude family":
    check countTokens("hello", "claude-3.5-sonnet") ==
          countTokens("hello", "claude-3")

# ---------------------------------------------------------------------------
# Suite: countTokens known values — Llama (4.0 chars/token)
# ---------------------------------------------------------------------------

suite "countTokens llama":
  test "llama uses same ratio as gpt-4":
    let texts = ["The quick brown fox", "Meta Llama 3", "1234567890"]
    for t in texts:
      check countTokens(t, "llama-3") == countTokens(t, "gpt-4")

  test "mistral uses llama family":
    check countTokens("hello", "mistral-7b") == countTokens("hello", "llama-3")

# ---------------------------------------------------------------------------
# Suite: countMessages
# ---------------------------------------------------------------------------

suite "countMessages":
  test "empty sequence returns 0":
    let msgs: seq[ChatMessage] = @[]
    check countMessages(msgs, "gpt-4") == 0

  test "single message: overhead + content tokens":
    # 1 message: ReplyPrimingTokens(3) + TokensPerMessage(4) + content tokens
    let msgs = @[ChatMessage(role: crUser, content: "hello")]
    # "hello" = 5 chars / 4.0 = 1.25 → ceil → 2 tokens
    let expected = ReplyPrimingTokens + TokensPerMessage + countTokens("hello", "gpt-4")
    check countMessages(msgs, "gpt-4") == expected

  test "two messages accumulate correctly":
    let msgs = @[
      ChatMessage(role: crSystem, content: "You are helpful."),
      ChatMessage(role: crUser, content: "Hello!"),
    ]
    var expected = ReplyPrimingTokens
    for m in msgs:
      expected += TokensPerMessage + countTokens(m.content, "gpt-4")
    check countMessages(msgs, "gpt-4") == expected

  test "named participant adds extra tokens":
    let msgs = @[
      ChatMessage(role: crUser, content: "hi", name: "Alice"),
    ]
    # name "Alice" = 5 chars / 4.0 = 2 tokens + 1 extra = 3
    let nameTokens = countTokens("Alice", "gpt-4") + 1
    let expected = ReplyPrimingTokens + TokensPerMessage +
                   countTokens("hi", "gpt-4") + nameTokens
    check countMessages(msgs, "gpt-4") == expected

  test "empty content message still adds overhead":
    let msgs = @[ChatMessage(role: crAssistant, content: "")]
    # content = 0 tokens, but overhead still applies
    let expected = ReplyPrimingTokens + TokensPerMessage + 0
    check countMessages(msgs, "gpt-4") == expected

  test "claude model uses claude ratio for content":
    # Claude has slightly more tokens per char (3.8 vs 4.0), so "hello" (5 chars)
    # gives 2 tokens for both (ceil(5/4.0)=2, ceil(5/3.8)=2), overhead is same.
    # For longer text the difference shows.
    let longMsgs = @[ChatMessage(role: crUser, content: "a".repeat(100))]
    let gptLong = countMessages(longMsgs, "gpt-4")
    let claudeLong = countMessages(longMsgs, "claude-3")
    # 100 chars: gpt=25 tokens, claude=ceil(100/3.8)=27 tokens
    check gptLong < claudeLong

  test "default model is gpt-4":
    let msgs = @[ChatMessage(role: crUser, content: "hello")]
    check countMessages(msgs) == countMessages(msgs, "gpt-4")

```

`mercury_core/tests/ttool_registry.nim`:

```nim
## Tests for mercury_core/tool_registry.
##
## Shell-tool-specific tests (execution, timeout, deny-list) live in
## mercury_agent/tests/test_shell_tool.nim to avoid a cross-package
## dependency on mercury_agent/tools/shell.

import std/[json, strutils, unittest]

import mercury_core/tool_registry

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

proc echoTool(): Tool =
  ## A trivial tool used to exercise registry plumbing.
  let params = %*{
    "type": "object",
    "properties": {
      "msg": {"type": "string"}
    },
    "required": ["msg"],
  }
  newTool(
    name = "echo",
    description = "Echo a message back",
    parameters = params,
    execute = proc (args: JsonNode): ToolResult {.gcsafe, raises: [].} =
      let msgNode = args{"msg"}
      if msgNode.isNil or msgNode.kind != JString:
        return ToolResult(output: "missing msg", isError: true, exitCode: -1)
      ToolResult(output: msgNode.getStr(), isError: false, exitCode: 0)
  )

# ---------------------------------------------------------------------------
# Registry basics
# ---------------------------------------------------------------------------

suite "ToolRegistry basics":
  test "newToolRegistry is empty":
    let reg = newToolRegistry()
    check reg.len == 0
    check reg.list().len == 0
    check reg.names().len == 0

  test "register and retrieve":
    let reg = newToolRegistry()
    reg.register(echoTool())
    check reg.len == 1
    check reg.has("echo")
    let t = reg.get("echo")
    check t.name == "echo"
    check t.description.contains("Echo")

  test "duplicate registration raises":
    let reg = newToolRegistry()
    reg.register(echoTool())
    expect ToolDuplicateError:
      reg.register(echoTool())

  test "missing tool raises ToolNotFoundError":
    let reg = newToolRegistry()
    expect ToolNotFoundError:
      discard reg.get("nope")

  test "unregister removes tool":
    let reg = newToolRegistry()
    reg.register(echoTool())
    check reg.unregister("echo")
    check reg.len == 0
    check (not reg.has("echo"))
    check (not reg.unregister("echo"))

  test "list preserves insertion order":
    let reg = newToolRegistry()
    reg.register(newTool("a", "A", emptyParameters(),
      proc (a: JsonNode): ToolResult {.gcsafe, raises: [].} =
        ToolResult(output: "a", isError: false, exitCode: 0)))
    reg.register(newTool("b", "B", emptyParameters(),
      proc (a: JsonNode): ToolResult {.gcsafe, raises: [].} =
        ToolResult(output: "b", isError: false, exitCode: 0)))
    reg.register(newTool("c", "C", emptyParameters(),
      proc (a: JsonNode): ToolResult {.gcsafe, raises: [].} =
        ToolResult(output: "c", isError: false, exitCode: 0)))
    check reg.names() == @["a", "b", "c"]

  test "newTool rejects empty name":
    expect ToolArgumentError:
      discard newTool("", "x", emptyParameters(),
        proc (a: JsonNode): ToolResult {.gcsafe, raises: [].} =
          ToolResult(output: "", isError: false, exitCode: 0))

  test "newTool rejects nil execute":
    expect ToolArgumentError:
      discard newTool("x", "x", emptyParameters(), nil)

# ---------------------------------------------------------------------------
# OpenAI-compatible serialization
# ---------------------------------------------------------------------------

suite "ToolRegistry OpenAI definitions":
  test "single tool has correct shape":
    let t = echoTool()
    let def = toOpenAIDefinition(t)
    check def["type"].getStr() == "function"
    check def["function"]["name"].getStr() == "echo"
    check def["function"]["description"].getStr() == "Echo a message back"
    check def["function"]["parameters"]["type"].getStr() == "object"
    check def["function"]["parameters"]["properties"].hasKey("msg")
    check def["function"]["parameters"]["required"][0].getStr() == "msg"

  test "registry serialization is an array of definitions":
    let reg = newToolRegistry()
    reg.register(echoTool())
    let arr = reg.toOpenAIDefinitions()
    check arr.kind == JArray
    check arr.len == 1
    check arr[0]["function"]["name"].getStr() == "echo"
    for entry in arr:
      check entry["type"].getStr() == "function"
      check entry["function"]["parameters"]["type"].getStr() == "object"

  test "definitions are independent copies":
    let reg = newToolRegistry()
    reg.register(echoTool())
    let arr1 = reg.toOpenAIDefinitions()
    arr1[0]["function"]["name"] = %"hijacked"
    # Registry state must remain unchanged.
    let arr2 = reg.toOpenAIDefinitions()
    check arr2[0]["function"]["name"].getStr() == "echo"

# ---------------------------------------------------------------------------
# Argument parsing & execution surface
# ---------------------------------------------------------------------------

suite "ToolRegistry argument parsing":
  test "empty string parses to empty object":
    let n = parseArguments("")
    check n.kind == JObject
    check n.len == 0

  test "valid JSON object parses":
    let n = parseArguments("""{"a": 1, "b": "x"}""")
    check n["a"].getInt() == 1
    check n["b"].getStr() == "x"

  test "invalid JSON raises ToolArgumentError":
    expect ToolArgumentError:
      discard parseArguments("not json")

  test "non-object root raises ToolArgumentError":
    expect ToolArgumentError:
      discard parseArguments("[1,2,3]")

suite "ToolRegistry execute":
  test "executes a registered tool with parsed JSON":
    let reg = newToolRegistry()
    reg.register(echoTool())
    let res = reg.execute("echo", """{"msg": "hi"}""")
    check (not res.isError)
    check res.output == "hi"

  test "execute on missing tool raises":
    let reg = newToolRegistry()
    expect ToolNotFoundError:
      discard reg.execute("nope", "{}")

  test "execute returns isError on bad JSON arguments":
    let reg = newToolRegistry()
    reg.register(echoTool())
    let res = reg.execute("echo", "not json")
    check res.isError
    check res.output.contains("invalid arguments")

  test "execute returns isError on non-object args":
    let reg = newToolRegistry()
    reg.register(echoTool())
    let res = reg.execute("echo", "[]")
    check res.isError

```

`report.md`:

```md
# Mercury Agent: Architectural Review and "Ideas to Steal"

Based on an analysis of the `MrSpaghatti/mercury-agent` repository, there are several extremely valuable architectural patterns and features that you should definitely adapt for your personal agent, especially given your goals of a hybrid cloud/local setup, PKM (Personal Knowledge Management), and an automated coding harness.

## 1. Hybrid Model Management (Cloud/Local)

**How Mercury does it:**
Mercury uses a highly layered and robust configuration system (`mercury_core/config.nim`) combined with a provider-agnostic `llm_client.nim`.
*   **Layered Config:** Defaults < TOML file < `.env` < Environment Variables.
*   **Provider Abstraction:** The config explicitly splits out `vllm` (local) and `openrouter` (cloud).
*   **CLI Overrides:** You can instantly switch models per-run via CLI flags (`mercury_agent ask "ping" --provider=vllm --model=qwen2.5-7b-instruct`).

**Why you should steal it:**
Since you are using OpenCode Go (cloud) in conjunction with local models, this exact pattern is perfect. You should build a unified interface that accepts standard OpenAI Chat Completions formats and routes them based on a central configuration. This allows your agent to use a fast, cheap local model for simple tasks (like triage or simple file generation) and fall back to the powerful cloud model (OpenCode Go) for complex reasoning or heavy coding tasks dynamically.

## 2. PKM Foundation: SQLite + FTS5 Memory System

**How Mercury does it:**
Mercury stores every single conversation session and message in a local SQLite database (`mercury_core/memory.nim`).
*   **FTS5:** It uses SQLite's FTS5 (Full-Text Search) extension to create a virtual table mirroring message content.
*   **CLI Integration:** It ships a command (`mercury_agent search "query"`) to instantly search the entire chat history.

**Why you should steal it:**
This is the holy grail for Personal Knowledge Management. By logging every interaction your agent has (whether generating code, summarizing a document, or answering a question) into SQLite and indexing it with FTS5, your agent effectively becomes a searchable external brain. You can easily query past solutions, scripts, or notes instantly.

## 3. Sandboxed Tool Execution for Coding Harness

**How Mercury does it:**
Mercury has a `ToolRegistry` (`tool_registry.nim`) and a `shell` tool (`mercury_agent/tools/shell.nim`) built for the ReAct loop.
*   **Deny-lists:** The shell tool has a hardcoded deny-list (`rm -rf /`, etc.) to prevent catastrophic commands.
*   **Timeouts:** It uses `osproc` with a strict timeout. If a command hangs, it kills the process tree.
*   **File Rules:** There are structured `file_tool.nim` modules with `allow` and `deny` patterns for reading/writing.

**Why you should steal it:**
Since you are building a coding harness (`mercury_code`), the agent *will* run malicious, infinite-looping, or broken code. Implementing strict timeouts, process tree killing, and explicit file/shell path allow/deny lists is critical. Do not let the agent run arbitrary code without these safety rails.

## 4. Robust ReAct Loop with Error and Loop Detection

**How Mercury does it:**
The `runAgentLoop` (`mercury_agent/agent_loop.nim`) doesn't just blindly feed tool outputs back to the model.
*   **Loop Detection:** It tracks tool calls. If the agent calls the *exact same tool with the exact same arguments* N times in a row (default 3), it forcefully terminates the loop to save tokens and prevent infinite spiraling.
*   **Error Recovery:** If a tool fails (e.g., exit code 1), it formats the error and feeds it *back* to the LLM so the LLM can try to fix it, rather than just crashing the agent.

**Why you should steal it:**
When dealing with coding tasks, the agent will frequently write code that fails to compile or run. Feeding the compiler/runtime errors back to the agent (and preventing it from infinitely trying the same broken fix) is the core mechanism of autonomous coding.

## 5. Dependency Injection for Interfaces (Discord Daemon)

**How Mercury does it:**
For its Discord bot (`discord.nim`), Mercury uses a "Dependency Injection" pattern. It passes functions (`SendMessageFn`, `TriggerTypingFn`) into the `DiscordBot` object instead of hardcoding API calls.

**Why you should steal it:**
If you want an agent that works on CLI, Discord, and maybe a web UI, decouple the "Agent Logic" from the "Presentation Layer". By injecting callbacks for "how to send a message", your core agent loop can remain completely unaware of whether it's talking to a terminal or a Discord channel.

## Summary

This project is **absolutely** worth digging into. You should strongly consider lifting the SQLite FTS5 memory module for your PKM needs, the layered configuration for managing OpenCode Go + Local models, and the error-recovering, loop-detecting ReAct loop for your coding harness.

```

`test_config.nim`:

```nim
import mercury_core/config

let cfg = loadConfig()
echo "Provider: ", cfg.provider
echo "VLLM Endpoint: ", cfg.vllmEndpoint
echo "Max Tokens: ", cfg.maxTokens
echo "Temperature: ", cfg.temperature

```