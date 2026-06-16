# Mercury Agent — Project Roadmap

**Last updated**: June 16, 2026
**Current state**: All planned phases complete (~441 tests, CI green on Nim 2.0.8 + 2.2.2)

---

## ✅ Complete

| Area | Deliverable | Status |
|------|-------------|--------|
| **Phase 1 — Foundation** | config, llm_client, token_counter, memory (SQLite+FTS5) | 100% |
| **Phase 2 — Agent Core** | tool_registry, shell_tool, agent_loop, mock_server | 100% |
| **Phase 3 — CLI + Integration** | mercury_agent CLI, integration wiring, docs | 100% |
| **Phase 2 — Discord Bot** | DI-based bot, permission, file_tools, rate_limit, thread_mapping, agent_dispatcher | 100% |
| **P0 — SSL + CI + Audits** | Nim 2.2.x build fix, GitHub Actions CI, deep code audits | 100% |
| **P1 — mercury_code** | Autonomous coding harness (code_runner, code_tool, compile) | 100% |
| **P2 — MCP Support** | Model Context Protocol client + tool bridge (36 tests) | 100% |
| **P2 — Persona + Delegation** | Persona system, agent-to-agent delegation, scoped tool filtering (33 tests) | 100% |

All 3 packages (`mercury_core`, `mercury_agent`, `mercury_code`) build and test on both Nim 2.0.x and 2.2.x.

---

## 🗺️ Future

| Item | Priority | Notes |
|------|----------|-------|
| **P3 — Web UI** | Low (deferred) | Lightweight HTTP server + basic chat UI. Will reuse `agent_loop.nim`. |
| **SSE/streaming MCP transport** | Low | Deferred — HTTP/JSON-RPC polling sufficient for current use. |
| **Plan-Execute mode** | Low | Deferred from original spec. Sub-agent delegation covers some of this. |
| **Reflection / self-critique** | Low | Agent reviewing its own output before responding. |
| **Vector memory / semantic retrieval** | Low | Beyond current SQLite+FTS5 scope. |
| **Streaming responses** | Low | Token-by-token output for CLI/Discord/Web. |

---

## 📊 Test Suite

| Package | Test Files | Tests | Status |
|---------|-----------|-------|--------|
| mercury_core | 22 | ~350 | ✅ All pass |
| mercury_agent | 6 | ~79 | ✅ All pass |
| mercury_code | 1 | 11 | ✅ All pass |
| **Total** | **29** | **~441** | **✅ 0 FAILED** |
