# Task 1: Agent Loop Relocation + Dispatcher Threading

**Status**: 🔴 Not Started
**Dependencies**: None
**Complexity**: Large

---

## Target

- `mercury_core/src/mercury_core/agent_loop.nim` (new location)
- `mercury_core/src/mercury_core/agent_dispatcher.nim`
- `mercury_agent/src/mercury_agent.nim`
- `mercury_agent/src/agent_loop.nim` (delete after move)

## Current State

- `agent_loop.nim` lives in `mercury_agent/`. It imports `mercury_core/{config,llm_client,tool_registry,memory,persona,delegate}`.
- `agent_dispatcher.nim` in `mercury_core/` has a production path that calls `runFn` synchronously (no threading). The `runFn` is injected from `mercury_agent` via `AgentRunFn` type.
- The dispatcher notes: *"Use a dedicated worker thread once dimscord's GC-safety issues with --threads:on are resolved."*
- SQLite: `thread_mapping.nim` already uses WAL mode. `memory.nim` does not.

## Change

### Phase 1a — Move agent_loop to mercury_core
1. Move `mercury_agent/src/agent_loop.nim` → `mercury_core/src/mercury_core/agent_loop.nim`.
2. Update imports in the moved file: drop the `mercury_core/` prefix (it's now a sibling).
3. Update `mercury_agent/src/mercury_agent.nim` to import `mercury_core/agent_loop` instead of the local module.
4. Update `mercury_agent/tests/tagent_loop.nim` to import from `mercury_core/agent_loop`.
5. Remove `AgentRunFn` and `AgentLoopResult` from `agent_dispatcher.nim` — they now import directly from `agent_loop.nim`. Update `AgentLoopResult` references.
6. Update `mercury_agent.nim`'s `cmdDaemon` to drop the `AgentRunFn` wrapper closure — `dispatcher` can call `runAgentLoop` directly via `agent_loop.nim`.
7. Verify: `make build && make test` — all 460 tests pass with the relocated module.

### Phase 1b — Enable SQLite WAL mode in memory.nim
1. In `memory.nim`, after `open()` on the SQLite DB, execute `PRAGMA journal_mode=WAL;` and `PRAGMA busy_timeout=5000;`.
2. Ensure `newMemory()` uses the same PRAGMAs. The DB handle should be safe for concurrent reads across threads.
3. Add a concurrency test: spawn 2 threads, one writing sessions, one reading/searching. Both complete without `SQLITE_BUSY`.

### Phase 1c — Thread the dispatcher (or pthread alternative)
1. Assess Nim 2.2.x thread support with dimscord. If `--threads:on` now works:
   - Add `--threads:on` to `mercury_agent/config.nims` and `mercury_core/config.nims`.
   - In `agent_dispatcher.dispatchAgent`, spawn a worker thread that calls `runAgentLoop`, then posts the result back to the main thread via a `Channel[AgentResult]`.
   - The async callback fires on the main thread after receiving the channel result.
2. If `--threads:on` still conflicts with dimscord (likely — dimscord uses `asyncdispatch` which is single-threaded):
   - Document the limitation clearly.
   - Consider `spawn`/`createThread` with its own memory connection (each thread gets its own SQLite handle).
   - Alternative: keep sync dispatch but add a timeout/context-switch yield via `sleepAsync(0)` between dispatches to avoid starving the Discord event loop.
3. The dispatcher's `startDispatcher` / `stopDispatcher` should manage thread lifecycle (create/join).
4. Add a `test_agent_dispatcher_threading.nim` test: dispatcher receives a request, runs a real agent loop with a mock LLM, callback receives the correct result.

### Phase 1d — Clean up after move
1. Delete `mercury_agent/src/agent_loop.nim`.
2. Remove any `mercury_agent`-specific imports from the moved `agent_loop.nim`.
3. Update `mercury_agent/mercury_agent.nimble` to remove the old source path if needed.
4. Full test suite: 460 tests pass. `make build && make test` green.

## Acceptance

- `agent_loop.nim` lives in `mercury_core` and is importable as `mercury_core/agent_loop`.
- No cross-package import hacks (no `mercury_agent` importing from `mercury_agent` when it means `mercury_core`).
- Discord daemon starts and processes agent requests (manual smoke test with a mock LLM endpoint or OpenRouter).
- SQLite WAL mode enabled in `memory.nim`. Concurrent read+write test passes.
- Dispatcher threading test passes (or clear documentation why threading is deferred).
- All 460 existing tests pass.