# Task 4: Code Quality Pass

**Status**: 🔴 Not Started
**Dependencies**: None (standalone, but best after Task 1 to avoid merge conflicts on moved files)
**Complexity**: Small-Medium

---

## Target

All source files across `mercury_core/`, `mercury_agent/`, `mercury_code/`.

## Current State

From `PLAN_MINOR_ISSUES.md` (items #1, #3, #4 still open):
- `except CatchableError: discard` in `shell.nim`, file tools, cleanup code.
- Unused imports: `std/options`, `dimscord`, etc. in several files.
- Config edge cases: no warning when API key is missing.
- Remaining TODOs in code (e.g., `agent_dispatcher.nim` TODO about threading).
- `mercury_code/compile.nim` uses bare `except:` (was `except CatchableError:` but may have regressed).

## Change

### Phase 4a — CatchableError audit and logging
1. `grep` for `except CatchableError:` across all `src/` files.
2. For each instance, evaluate:
   - If the error is truly ignorable (cleanup, shutdown), add `stderr.writeLine("mercury: ... " & e.msg)`.
   - If the error indicates a real problem, log and re-raise or propagate.
   - Never leave `discard` alone.
3. Specific files known to have silent discards:
   - `tools/shell.nim`: cleanup after timeout/kill.
   - `file_tool.nim`: cleanup after read/write failures.
   - `mercury_agent.nim`: various `except CatchableError: discard` in CLI cleanup.
   - `discord.nim`: message send failures.
4. For `mercury_code/compile.nim`, verify `except CatchableError:` (not bare `except:`).

### Phase 4b — Unused imports cleanup
1. Run `nim check` on each package to detect unused imports.
2. Remove unused imports. Check each file manually since `nim check` isn't always accurate with conditional imports.
3. Known candidates from audit: `std/options` in several files, unused `dimscord` imports, stale `mcp_client` imports.

### Phase 4c — Config edge cases
1. In `config.nim`, after loading config, check:
   - If `provider == "openrouter"` and `OPENROUTER_API_KEY` env var is empty → emit warning to stderr.
   - If `provider == "vllm"` and `vllm_endpoint` is unreachable (optional: quick TCP probe).
   - If `db_path` directory doesn't exist → attempt `createDir` with a log message, or warn.
2. Add a `logWarning(msg: string)` helper that writes to stderr with a `[mercury]` prefix. Centralize warning output.

### Phase 4d — TODO resolution
1. `grep` for `TODO` across all `src/` files.
2. For each:
   - Resolve if trivial (e.g., "TODO: add test" → check if test exists).
   - Convert to GitHub issues if non-trivial.
   - Remove TODO comments that are stale or already done.
3. Known TODOs:
   - `agent_dispatcher.nim:8`: threading TODO — update to reflect current state (Task 1 outcome).
   - Any remaining from code comments.

## Acceptance

- Zero `except CatchableError: discard` (without at least a log).
- `nim check` on both packages produces zero unused-import warnings.
- Missing API key produces a visible stderr warning at startup.
- All remaining TODOs are either resolved or tracked as GitHub issues.
- 460 existing tests pass.
- `make build` clean.