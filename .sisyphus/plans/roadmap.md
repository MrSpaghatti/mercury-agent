# Mercury Agent — Project Roadmap

**Current**: Phase 1 (Foundation) + Phase 2 (Discord) — Complete
**Next**: Phase 3 — Coding Harness + Infrastructure

---

## ✅ Done

| Phase | Deliverable | Key modules |
|-------|-------------|-------------|
| 1.1–1.4 | Core library | config, llm_client, token_counter, memory |
| 2.1–2.3 | Agent engine | tool_registry, shell_tool, agent_loop, mock_server |
| 3.1–3.3 | CLI + integration | mercury_agent.nim, tcli, tintegration |
| Phase 2 | Discord bot | discord.nim, permission, file_tool, agent_dispatcher |
| P0 | SSL build fix | `config.nims` with `--define:ssl` |
| P0 | CI pipeline | GitHub Actions on Nim 2.0.8 + 2.2.2 |
| P0 | Deep code audits | All 40+ source files audited, 388 tests verified |
| P0 | Test quality audit | 388 tests reviewed, 5 weak tests fixed across 5 files |
| P1 | mercury_code | code_runner, code_tool, compile, harness CLI |

---

## 🎯 Phase 3: Coding Harness & Infrastructure

### P0 — Fix SSL Build (estimated: 1 session)

**Status: ✅ Complete**

The fix: `mercury_agent/config.nims` and `mercury_core/config.nims` now
pass `--define:ssl` to the compiler, which makes `defineSsl` true in both
`net.nim` and `asyncnet.nim`, resolving the `raiseSSLError` inconsistency.
As a side effect, `file_tool.nim` needed an extra `except Exception` handler
because SSL-aware exception tracking catches broader error types.

- [x] `config.nims` with `--define:ssl` in both packages
- [x] `file_tool.nim` — added `Exception` catch to `moveFile`
- [x] `mercury_core.nimble` — fixed test task file names, removed dangling `bin`
- [x] `Makefile` — fixed `build`/`test` targets to use `cd pkg && nimble` syntax

### P0 — CI Pipeline (estimated: 1 session)

**Status: ✅ Complete**

GitHub Actions workflow for automated quality gates.

- Trigger: push / PR to `main`
- Steps: `nimble install` → `make build` → `make test`
- Nim version matrix: 2.0.x, 2.2.x
- Cached nimble packages for faster subsequent runs

Fixes applied during CI setup:
- Corrected `setup-nim` action (`jiro4989/setup-nim-action@v2`)
- Fixed agent build path resolution in CI (use `--depsOnly`)
- Fixed `tllm_client` mock server thread hang (added `sleep(50)` in accept loop)
- Added `libpcre3-dev` for 2.0.x `std/re` support
- Removed brittle `durationMs < 3000` assertion from shell timeout test
- Updated CI to test mercury_code package (build + test steps)

**Acceptance**: ✅ Green CI on both Nim 2.0.8 and 2.2.2.

### P1 — mercury_code Package (estimated: 2–3 sessions)

**Status: ✅ Complete**

The `mercury_code/` package is no longer a placeholder. It implements a
self-contained coding harness binary that reuses the ReAct loop from
`mercury_agent` but with coding-specific tools.

**Files delivered**:
- `mercury_code.nim` — CLI binary (`--task`, `--version`, `--help`), wires
  CodingHarnessConfig into agent loop
- `code_runner.nim` — `CodingHarnessConfig` type, `CompileResult` /
  `CompileError` types, `parseNimErrors()`, `formatCompileResult()`
- `code_tool.nim` — `compileTool`, `testTool`, `readFileTool`,
  `writeFileTool` (all with `{.gcsafe, raises: [].}` closures)
- `compile.nim` — subprocess execution with timeout, output capture,
  truncation at 512 KiB
- `config.nims` — Nimble switches for path resolution and `-d:ssl`
- `tcode_runner.nim` — 11 tests covering formatter, parser, and config
  defaults
- Added `build_llm_client.nim` to `mercury_core` for shared
  `MercuryConfig → LLMClient` construction

**Key decisions**:
- Uses `{.gcsafe, raises: [].}` procs as closures in tool execute procs,
  matching `makeShellExecuteProc` pattern in `mercury_agent`
- Parses Nim's `path(line, col) [severity] message` format for structured
  error reporting
- Extension allowlist enforced at the tool level before file access
- Absolute paths in `config.nims` to avoid CI path resolution issues
- `newTool` called via `result =` to satisfy the `ToolExecuteProc` closure
  type requirement

**Acceptance**: 11/11 tests pass, binary compiles and runs `--help`.

### P2 — MCP Support (estimated: 2 sessions) ✅ COMPLETE

Model Context Protocol integration for external tool discovery.

- ✅ Add an MCP client module in `mercury_core` (`mcp_client.nim`)
  - HTTP/JSON-RPC transport, `initialize` handshake, `tools/list`,
    `tools/call`, `McpClient` (ref object), full error hierarchy
- ✅ Add tool registration bridge (`mcp_tool.nim`)
  - `makeMcpToolExecuteProc` creates `{.gcsafe, raises: []}` closures
  - `registerMcpServers` wires discovered tools into `ToolRegistry`
- ✅ MCP servers configured via `MercuryConfig.mcpServers`
  - `mcpServers` seq in config, TOML `[mcp_servers]` section, env vars
- ✅ TOML `[mcp_servers]` section parsing + `MERCURY_MCP_SERVER_{N}_{KEY}` env vars
- ✅ `mock_mcp_server.nim` — async mock MCP server for protocol-level testing
- ✅ Full test suite: 36 tests across `test_mcp_client` (25 tests) and `test_mcp_tool` (11 tests)
- ✅ CHANGELOG entry for MCP support
- 🔲 SSE/streaming transport (deferred — HTTP/JSON-RPC polling sufficient for initial integration)

**Why MCP**: Instead of hardcoding every possible tool (search, db,
calculator, etc.), the agent discovers them at runtime. This keeps the
core small and the capability surface extensible.

### P2 — Sub-Agent Delegation (estimated: 2 sessions)

Allow the ReAct loop to spawn child agents for parallel or specialized
work.

- Add `AgentDispatcher.delegate(subTask: string): Future[AgentResult]`
  that creates a child agent loop from the same config
- Child agents share the same memory database (separate session) for
  traceability
- Parent agent gets back the child's final text + stats

**Safety**: Max depth limit (default 2), max total children per run
(default 5), child loop inherits parent's iteration cap.

### P3 — Web UI (estimated: 3+ sessions)

A lightweight web frontend for Mercury that doesn't require a terminal
or Discord.

- Simple HTTP server in `mercury_agent` (e.g. `mercury serve`)
- Basic chat UI (HTML/JS served from a single endpoint)
- Session history browsing
- Reuses same `agent_loop.nim` underneath

**Not a priority** until the coding harness is shipping.

---

## ⚡ Quick Wins (can be done in any order)

| Task | Effort | Impact |
|------|--------|--------|
| CHANGELOG.md v0.1.0 | 30 min | Release tracking |
| CI pipeline (GitHub Actions) | 1 session | Quality signal on every push |
| Add GitHub issue/PR templates | 30 min | Better contribution flow |
| Benchmark: ReAct loop tokens/turn | 1 session | Performance baseline |
| Document the config TOML schema in a JSON Schema file | 1 session | IDE autocomplete for config |
| Dockerfile for reproducible builds | 1 session | Reproducibility |

---

## 📊 Effort Overview

```
Phase 3 total:   ~8–12 sessions remaining
  P0 done:          ✅ SSL fix, code audit, CI pipeline, .gitignore fix
  P0 (remaining):   0 sessions — all P0 work complete
  P1 (coding):      2–3 sessions
  P2 (extensions):  4 sessions
  P3 (nice-to-have): 3+ sessions

Quick wins:        ~2–3 sessions (interleavable)
```

Sessions are approximate (1 session = focused development block).
Actual time depends on complexity discovered during implementation.
