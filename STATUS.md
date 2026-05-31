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
