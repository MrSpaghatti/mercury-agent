# Core Architecture Plan

1. **Improve Agent Loop and LLM Interface:**
   - Currently, `agent_loop.nim` handles ReAct loops correctly. However, `mercury_agent` initializes and couples the LLM and the Agent directly in `mercury_agent.nim`.
   - Consider abstracting the `runAgentLoop` further, so it can be managed by `mercury_core` entirely. This would allow `agent_dispatcher.nim` (which currently fakes a response) to invoke `runAgentLoop` natively without circular dependencies.

2. **Complete the Agent Dispatcher:**
   - `mercury_core/src/mercury_core/agent_dispatcher.nim` currently simulates a response with `sleepAsync(100)`.
   - To finish Task 4.16, `dispatchAgent` must spawn a background thread, execute `runAgentLoop` (which belongs to `mercury_agent` now?), and return the actual LLM output.
   - Refactor `agent_loop.nim` into `mercury_core/` so the Discord bot can use it directly.

3. **Memory Persistence Fixes:**
   - `mercury_core/memory.nim` works well. But `mercury_agent/mercury_agent.nim` opens the memory database separately.
   - We need a robust concurrency model for SQLite if multiple threads (Discord bot events + Agent background threads) access it simultaneously. Consider enabling SQLite WAL mode (`PRAGMA journal_mode=WAL`) or implementing a memory access channel.

4. **Address `CatchableError` usages:**
   - The codebase has several `except CatchableError:` blocks that silently discard errors (e.g., in `shell.nim`, `mercury_agent.nim`). These should be logged to stderr or `db` instead of silently swallowed, to ease debugging.

5. **Fix Deprecation Warnings in Dependencies:**
   - Libraries like `jsony` and `dimscord` raise `Potential object case transition, instantiate new object instead` warnings under Nim 2.x.
