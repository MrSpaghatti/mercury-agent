# NOTE: This project has been renamed from Mercury Agent to Talos Agent.

> **Status (2026-07-19)**: Most findings below were resolved in the
> hardening pass — see CHANGELOG `[Unreleased]`. Specifically: no
> `dummy.nim` files remain; `file_path_validator.nim` uses `std/re`
> (not `nre`); `asyncdispatch` imports are in place; `-d:ssl` is
> enforced via `config.nims`. Remaining open questions: agent loop
> location / dispatcher threading, SQLite WAL mode, and `discard`-ed
> `CatchableError` instances.

# Comprehensive Codebase Audit Report

This report summarizes the findings from a deep dive into the `mercury` project (`mercury_core` and `mercury_agent`), including testing issues, architectural flaws, minor issues, and actionable next steps for future agent sessions.

The audit focused on compilation errors, unit test stability, error handling, bad coding practices, and integration concerns.

## Detailed Plans

For structured, step-by-step instructions on resolving the identified issues, please refer to the following companion documents:
- **`PLAN_CORE_ARCHITECTURE.md`**: Addresses major architectural integration issues between `agent_loop.nim`, the agent dispatcher, and SQLite concurrency.
- **`PLAN_TESTING_FIXES.md`**: Addresses compilation errors in the test suite, macro usage, C dependencies (PCRE vs regex), and the `raiseSSLError` bug in Nim `asyncnet`.
- **`PLAN_MINOR_ISSUES.md`**: Covers bad coding practices, unused imports, empty discard statements, and edge cases in config loading.

## Summary of Key Findings

1. **Test Suite Stability & Compilation:**
   - The `mercury_core` test suite was failing to compile because the Nimble tasks used `nim c -r` instead of `nim c --path:src -d:ssl -r`. Adding `-d:ssl` is critical because the LLM and Discord clients use HTTPS, and Nim's `asyncnet`/`httpclient` throws `raiseSSLError` undeclared identifier bugs without it. This has been patched locally with `config.nims` and Nimble task updates, but needs permanent integration.
   - Some tests (like `test_discord_mocks.nim`) lacked `import std/asyncdispatch`, causing the `waitFor` macro to fail.
   - `file_path_validator.nim` imports `nre` (which dynamically links to PCRE via `libpcre.so`). This caused integration tests to fail on systems without `libpcre3`. A migration to the native `nim-regex` package (already in nimble) is highly recommended.

2. **Core Architecture Integration:**
   - **Agent Dispatcher:** Currently, `mercury_core/src/mercury_core/agent_dispatcher.nim` mocks the agent response (`sleepAsync(100)`). To complete Phase 1 / Wave 2 & 3, the Discord bot needs to spawn a background thread, execute the actual `runAgentLoop`, and return the true LLM output.
   - **Circular Dependency Risk:** `agent_loop.nim` is currently situated in `mercury_agent`. If `mercury_core`'s dispatcher is to use it, it should probably be moved to `mercury_core/` to allow the Discord bot (in `mercury_core`) to natively depend on it without causing circular imports.
   - **SQLite Concurrency:** The agent loop logs messages to memory, and the Discord bot also checks sessions. Concurrent access to the SQLite database from different threads might cause `database is locked` errors if WAL mode (`PRAGMA journal_mode=WAL`) isn't enforced or if connections aren't pooled properly.

3. **Bad Coding Practices / Minor Issues:**
   - **Silent Error Swallowing:** There are multiple instances of `except CatchableError:` followed by `discard` (especially in `shell.nim`, file tools, and cleanup code). These should at least log to stderr so debuggers can trace silent failures.
   - **Dead Code:** `dummy.nim` files exist in both packages and should be removed. Several test files and modules have unused imports (`std/options`, `dimscord`).
   - **Deprecation Warnings:** Dependencies like `jsony` and `dimscord` raise `CaseTransition` warnings in Nim 2.2.x. While technically upstream issues, wrapping them or contributing PRs might be necessary if `-d:strict` is ever used.

## Immediate Next Steps for Next Agent

1. Read the `PLAN_*.md` files.
2. Implement the test fixes to ensure a green build pipeline on clean environments.
3. Address the `except CatchableError` swallowed exceptions.
4. Refactor `agent_loop.nim` to be accessible by `agent_dispatcher.nim` and implement thread spawning for real agent requests from Discord.
