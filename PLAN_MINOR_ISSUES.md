> **Status (2026-07-19)**: `dummy.nim` files (#2) and the `-d:ssl`
> `config.nims` item (#5) are resolved. Items #1 (discard/unused
> imports cleanup), #3 (TODOs), and #4 (config edge cases) remain open.

# Minor Issues & Bad Practices Plan

1. **Remove Empty Discards and Unused Imports:**
   - Multiple files have `discard` blocks or unused imports (`std/options`, `dimscord`, etc). Run a comprehensive pass to clean up unused code and imports across `mercury_agent.nim`, `test_e2e_discord.nim`, etc.

2. **Clean up Dummy Files:**
   - There are `dummy.nim` files in `mercury_agent/src/mercury_agent/dummy.nim` and `mercury_core/src/mercury_core/dummy.nim` containing just `discard`. These were likely placeholders and should be removed.

3. **Missing Docs / TODOs:**
   - `DISCORD.md` and `WAVE_3_SPEC.md` contain documentation, but any `TODO`s scattered in the code or missing module documentation should be fulfilled.

4. **Configuration loading edge cases:**
   - If `MERCURY_PROVIDER` is missing but `OPENROUTER_API_KEY` exists, the config fails silently or gracefully without a warning.
   - Refactor `config.nim` to yield clear error messages when API keys are completely missing for the active provider.

5. **`config.nims` and `-d:ssl`:**
   - To fix the `raiseSSLError` bug across the board, `config.nims` should be added to the root of the project (and `mercury_core`/`mercury_agent`) to enforce `-d:ssl`.
   - E.g., `switch("define", "ssl")` in `config.nims`.
