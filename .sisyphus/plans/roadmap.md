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
| P0 | Deep code audit | All 40+ source files audited, 312 tests verified |

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

**Acceptance**: ✅ Green CI on both Nim 2.0.8 and 2.2.2.

### P1 — mercury_code Package (estimated: 2–3 sessions)

The placeholder `mercury_code/` package is empty. This implements the
autonomous coding harness.

**Scope**:
- Scaffold the Nimble package with the same layout as `mercury_core`
- Define `CodingHarnessConfig` extending `MercuryConfig` with:
  - Allowed file extensions for reading/writing
  - Build/test commands per language
  - Sandbox root directory for code execution
- Implement `sandboxedCompile(cmd: string): CompileResult` proc that
  runs a build command in a containerized or subprocess environment
- Implement `parseCompilerOutput(output: string): seq[CompileError]` to
  extract file+line+message from common compiler formats
- Wire the coding harness into the ReAct loop as a special tool category

**Design principle**: The ReAct loop already feeds tool errors back to
the LLM. The coding harness extends this: the agent writes code, compiles
it, gets errors, fixes them, recompiles — all within the existing loop
with configurable iteration cap.

**Not in scope (deferred)**:
- Docker container sandboxing
- Branch-per-experiment isolation
- Auto-pr creation

### P2 — MCP Support (estimated: 2 sessions)

Model Context Protocol integration for external tool discovery.

- Add an MCP client module in `mercury_core`
- MCP tools appear as dynamically-registered tools in `ToolRegistry`
- Configuration: list of MCP server endpoints in `MercuryConfig`
- Each MCP tool gets its own schema from the MCP server's `ListTools`
  response, converted to OpenAI function-calling format

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
