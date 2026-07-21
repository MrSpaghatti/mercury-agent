# Rename: Mercury → Talos — ✅ COMPLETED 2026-07-20

**Decision**: 2026-07-20. "Mercury Agent" already taken.
**New name**: **Talos** — bronze automaton from Greek myth. `talos_core`, `talos_agent`, `talos_code`.
**Status**: Done. All source, docs, and config files updated. Backward compat for env vars and TOML section preserved.
---

## Files that need a rename notice (one-line header added at top)

These are historical/log files whose body content should NOT be rewritten — just prepend a rename note:

- `CHANGELOG.md`
- `AUDIT_REPORT.md`
- `PLAN_CORE_ARCHITECTURE.md`
- `PLAN_MINOR_ISSUES.md`
- `PLAN_TESTING_FIXES.md`
- `.sisyphus.legacy/boulder.json`
- `.sisyphus.legacy/notepads/mercury-agent/` (both files)
- `.sisyphus.legacy/notepads/phase2-discord/learnings.md`
- `.sisyphus.legacy/plans/phase2-discord.md`
- `.sisyphus.legacy/plans/roadmap.md`
- `.opencode/magic-context/historian/*.xml` (add rename note in a comment at top)
- `plans/` (all task-*.md files)

---

## Changes that MUST be applied everywhere

### 1. Directory renames

| Old | New |
|-----|-----|
| `mercury_core/` | `talos_core/` |
| `mercury_agent/` | `talos_agent/` |
| `mercury_code/` | `talos_code/` |
| `mercury/` (in docs/diagrams) | `talos/` |

### 2. Nimble files

All `.nimble` files need:

| Field | Old | New |
|-------|-----|-----|
| `author` | `"Mercury"` | `"Talos"` |
| `description` | `"Mercury core shared library"` | `"Talos core shared library"` |
| `description` | `"Mercury agent binary"` | `"Talos agent binary"` |
| `description` | `"Mercury coding harness…"` | `"Talos coding harness…"` |
| `bin` | `@["mercury_agent"]` | `@["talos_agent"]` |
| `bin` | `@["mercury_code"]` | `@["talos_code"]` |
| `switch("path", "../mercury_core/src")` | → `../talos_core/src` |
| `switch("path", "../mercury_core/tests")` | → `../talos_core/tests` |

### 3. config.nims files

- `mercury_code/config.nims` line 2–3: hardcoded `/home/spag/mercury-agent/mercury_core/src` → `talos_core/src` (use relative paths if possible)

### 4. Type renames (Nim source)

| Old | New | Files |
|-----|-----|-------|
| `MercuryConfig` | `TalosConfig` | `config.nim`, `agent_loop.nim`, `agent_dispatcher.nim`, `build_llm_client.nim`, `mercury_agent.nim`, `code_runner.nim`, all callers |
| `setMercuryConfig()` | `setTalosConfig()` | `mercury_agent.nim` |
| `mercuryConfig` field | `talosConfig` | `mercury_agent.nim` (`AgentGlobals`) |

### 5. Import paths (all Nim files)

Every `import mercury_core/…` → `import talos_core/…`
Every `import mercury_agent/…` → `import talos_agent/…`
Every `import mercury_code/…` → `import talos_code/…`

Affected files: `mercury_agent.nim`, `mercury_code.nim`, all test files, `code_runner.nim`, `code_tool.nim`, `compile.nim`, `mercury_core.nim` (barrel), `build_llm_client.nim`.

### 6. System prompt (agent_loop.nim:47-49)

```
"You are Mercury, a helpful AI assistant."  →  "You are Talos, a helpful AI assistant."
```

### 7. CLI output strings (mercury_agent.nim)

| Line | Old | New |
|------|-----|-----|
| 627, 732 | `"Mercury> "` | `"Talos> "` |

### 8. CLI dispatch comments (mercury_agent.nim:1203-1209)

```
##   mercury_agent chat          →  ##   talos_agent chat
##   mercury_agent ask "..."     →  ##   talos_agent ask "..."
##   mercury_agent session ...   →  ##   talos_agent session ...
…
```

### 9. Config defaults (config.nim)

| Line | Old | New |
|------|-----|-----|
| 54 | `DefaultDbPath* = "~/.local/share/mercury/mercury.db"` | `"~/.local/share/talos/talos.db"` |
| 414 | `getHomeDir() / ".config" / "mercury" / "config.toml"` | `".config" / "talos" / "config.toml"` |
| 5 (doc) | `TOML config file at ~/.config/mercury/config.toml` | `~/.config/talos/config.toml` |
| 404 (doc) | `Defaults to ~/.config/mercury/config.toml` | `~/.config/talos/config.toml` |

### 10. Personas path (mercury_agent.nim:789,793)

```
~/.config/mercury/personas.toml  →  ~/.config/talos/personas.toml
```

### 11. TOML section name (config.nim:180)

The TOML root section `"mercury"` is matched in `applyTomlSection`. Change to `"talos"`. **Consider**: keep both `"mercury"` and `"talos"` as valid section names for backward compat during migration.

### 12. Environment variables

| Old | New |
|-----|-----|
| `MERCURY_PROVIDER` | `TALOS_PROVIDER` |
| `MERCURY_VLLM_ENDPOINT` | `TALOS_VLLM_ENDPOINT` |
| `MERCURY_OPENROUTER_ENDPOINT` | `TALOS_OPENROUTER_ENDPOINT` |
| `MERCURY_OPENROUTER_MODEL` | `TALOS_OPENROUTER_MODEL` |
| `MERCURY_VLLM_MODEL` | `TALOS_VLLM_MODEL` |
| `MERCURY_MAX_TOKENS` | `TALOS_MAX_TOKENS` |
| `MERCURY_TEMPERATURE` | `TALOS_TEMPERATURE` |
| `MERCURY_MAX_LOOP_ITERATIONS` | `TALOS_MAX_LOOP_ITERATIONS` |
| `MERCURY_WEB_PORT` | `TALOS_WEB_PORT` |
| `MERCURY_DB_PATH` | `TALOS_DB_PATH` |
| `MERCURY_MCP_SERVER_*` | `TALOS_MCP_SERVER_*` |
| `MERCURY_SANDBOX_ROOT` | `TALOS_SANDBOX_ROOT` |

Files: `config.nim`, `.env.example`, `README.md` (config table).

### 13. User-Agent string (llm_client.nim:297, 519)

```
"mercury-agent/0.1"  →  "talos-agent/0.1"
```

### 14. MCP client identity (mcp_client.nim:178, 184)

```
serverName = "mercury"          →  serverName = "talos"
"clientInfo"]["name"] = %"mercury-agent"  →  %"talos-agent"
```

### 15. Discord thread names (discord.nim:124, 139)

```
"Mercury-" & sessionId[...]  →  "Talos-" & sessionId[...]
```

### 16. Warning/error messages

| File | Old | New |
|------|-----|-----|
| `config.nim:391` | `"mercury: warning — provider is…"` | `"talos: warning — provider is…"` |
| `llm_client.nim:243` | `"mercury: extractApiErrorMessage failed…"` | `"talos: extractApiErrorMessage failed…"` |

### 17. Web UI (web_assets/)

| File | Line | Old | New |
|------|------|-----|-----|
| `index.html` | 6 | `<title>Mercury Agent</title>` | `<title>Talos Agent</title>` |
| `index.html` | 12 | `<h1>☿ Mercury</h1>` | `<h1>🛡️ Talos</h1>` |
| `app.js` | 1 | `// Mercury Agent — Web UI` | `// Talos Agent — Web UI` |
| `app.js` | 80 | `"Mercury"` (label fallback) | `"Talos"` |

### 18. Test files

| File | Old | New |
|------|-----|-----|
| `tintegration.nim:369` | `[mercury]\nprovider=vllm…` | `[talos]\nprovider=vllm…` |
| `tintegration.nim:374` | `db_path=/tmp/mercury-integration.db` | `db_path=/tmp/talos-integration.db` |
| `tintegration.nim:384` | `cfg.dbPath == "/tmp/mercury-integration.db"` | `"/tmp/talos-integration.db"` |
| `tintegration.nim:387` | `getTempDir() / "mercury_integration_env"` | `"talos_integration_env"` |
| `tintegration.nim:391` | `[mercury]\nmax_tokens=2048…` | `[talos]\nmax_tokens=2048…` |
| `tintegration.nim:434` | `"you are mercury"` | `"you are talos"` |
| `tintegration.nim:460` | `check history[0].content == "you are mercury"` | `"you are talos"` |
| `tcli.nim:165` | `"~/.local/share/mercury/test.db"` | `"~/.local/share/talos/test.db"` |
| `tcli.nim:168` | `.endsWith("/.local/share/mercury/test.db")` | `"/.local/share/talos/test.db"` |
| `tcli.nim:475` (changelog ref) | `/tmp/mercury-cli-resolved.db` | `/tmp/talos-cli-resolved.db` |
| `test_shell_tool.nim:68` | `"hello-mercury"` | `"hello-talos"` |
| `test_shell_tool.nim:72` | `contains("hello-mercury")` | `contains("hello-talos")` |
| `tbench.nim:1,64` | `## Mercury Agent Benchmark…` / `Mercury Agent — Benchmark…` | `Talos Agent…` |

### 19. Docstrings (every source file header)

Every `## Mercury …` module docstring → `## Talos …`. Affected files:

- `mercury_core.nim` (barrel)
- `config.nim`, `agent_loop.nim`, `agent_dispatcher.nim`
- `llm_client.nim`, `memory.nim`, `rate_limit.nim`, `thread_mapping.nim`, `token_counter.nim`
- `build_llm_client.nim`
- `mercury_agent.nim`
- `web_server.nim`
- `shell.nim`
- `tui/chat_tui.nim`, `tui/input_bar.nim`, `tui/streaming.nim`, `tui/theme.nim`, `tui/transcript.nim`
- `mercury_code.nim`
- `code_runner.nim`
- All test files with `## Mercury …` headers

### 20. .gitignore

All entries with `mercury_core/`, `mercury_agent/`, `mercury_code/` prefixes → `talos_core/`, `talos_agent/`, `talos_code/`.

### 21. Makefile

| Line | Old | New |
|------|-----|-----|
| 6 | `cd mercury_core && nimble build -y` | `cd talos_core && nimble build -y` |
| 7 | `cd mercury_agent && nimble build -y` | `cd talos_agent && nimble build -y` |
| 10 | `cd mercury_core && nimble test -y` | `cd talos_core && nimble test -y` |
| 11 | `cd mercury_agent && nimble test -y` | `cd talos_agent && nimble test -y` |
| 16 | `src/mercury_core/src/mercury_core/*.nim` | `src/talos_core/src/talos_core/*.nim` |

### 22. CI workflow (.github/workflows/ci.yml)

| Line | Old | New |
|------|-----|-----|
| 45, 48, 54 | `working-directory: mercury_core` | `talos_core` |
| 50, 60, 64 | `working-directory: mercury_agent` | `talos_agent` |
| 70, 74 | `working-directory: mercury_code` | `talos_code` |

### 23. Documentation (full rewrite, not just rename notice)

These are living docs — rename headings, body text, examples, and paths:

- `README.md` — all `Mercury Agent` → `Talos Agent`, paths, env vars, config table, diagrams
- `CONTRIBUTING.md` — all paths, imports, directory tree
- `STATUS.md` — all paths, package names, test counts
- `ROADMAP.md` — all package references
- `DISCORD.md` — all `mercury daemon` → `talos daemon`, paths

### 24. Other

| File | Change |
|------|--------|
| `.env.example` | All `MERCURY_*` vars → `TALOS_*` |
| `.github/ISSUE_TEMPLATE/config.yml` | URL: `mercury-agent` → `talos-agent` |
| `.github/PULL_REQUEST_TEMPLATE/pull_request_template.md` | `mercury_core/`, `mercury_agent/`, `mercury_code/` → talos equivalents |
| `config/personas.example.toml` | (no mercury mentions — clean) |

---

## GitHub-side

- Rename repo: `MrSpaghatti/mercury-agent` → `MrSpaghatti/talos-agent`
- Update CI badge URL in README
- Update all `github.com/MrSpaghatti/mercury-agent` links in docs

---

## Migration note for users

Existing config paths (`~/.config/mercury/`, `~/.local/share/mercury/`) and env vars (`MERCURY_*`) should still be supported for at least one release. Code should:

1. Check for `TALOS_*` env vars first, fall back to `MERCURY_*` with a deprecation warning.
2. Check for `~/.config/talos/` first, fall back to `~/.config/mercury/`.
3. TOML section `[talos]` preferred; `[mercury]` still accepted with a warning.