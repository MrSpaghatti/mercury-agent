# Mercury Agent - Development Status
## Current State: Phase 1, Wave 3 (Completed) & Audit Phase

**Last Updated**: October 2026
**Project Path**: `/home/jules/mercury`

## Completed Tasks

### Phase 0: Infrastructure (100% Complete)
- ✅ 0.1: Verify vLLM on Raven
- ✅ 0.2: Create GitHub repo + Nim project skeleton
- ✅ 0.3: Install desloppify + configure as lint step

### Phase 1, Wave 1: Foundation (100% Complete)
- ✅ 1.1: Config module (TOML parsing + .env)
- ✅ 1.2: LLM client (OpenAI Chat Completions)
- ✅ 1.3: Token counter (tattletale wrapper)
- ✅ 1.4: SQLite memory module (`mercury_core/memory.nim`)

### Phase 1, Wave 2: Agent Loop (100% Complete)
- ✅ 2.1: Tool registry + shell tool (`mercury_core/tool_registry.nim`, `mercury_agent/tools/shell.nim`)
- ✅ 2.2: ReAct agent loop (`mercury_agent/agent_loop.nim`)
- ✅ 2.3: Mock HTTP server for tests (`mercury_core/tests/mock_server.nim`)

### Phase 1, Wave 3: CLI + Integration (100% Complete)
- ✅ 3.1: CLI interface (cligen, `mercury_agent.nim`)
- ✅ 3.2: Integration: wire everything together
- ✅ 3.3: End-to-end tests + documentation

## Current Architecture

```
mercury/
├── mercury_core/              # Shared library
│   ├── src/mercury_core/
│   │   ├── config.nim        ✅ Config loading (TOML, .env, env vars)
│   │   ├── llm_client.nim    ✅ OpenAI-compatible LLM client
│   │   ├── token_counter.nim ✅ Token estimation
│   │   ├── tool_registry.nim ✅ Tool registration and invocation
│   │   ├── memory.nim        ✅ SQLite persistence and FTS5 search
│   │   └── discord.nim       ✅ Discord bot integration
│   └── tests/
│       ├── test_e2e_discord.nim
│       └── tllm_client.nim
├── mercury_agent/            # Personal agent binary
│   ├── src/
│   │   ├── agent_loop.nim    ✅ ReAct loop logic
│   │   ├── tools/shell.nim   ✅ System shell tool
│   │   └── mercury_agent.nim ✅ CLI tool entrypoint
│   └── tests/
├── mercury_code/             # Coding harness (future)
└── tests/                    # Shared tests
```

## Known Issues (Discovered during Code Audit)

1. **Compilation Errors in Test Suite**: Several tests fail because nimble configurations lacked `-d:ssl`, causing `raiseSSLError` undefined identifier errors. PCRE dynamic dependencies break integration tests without `libpcre3`.
2. **Discord to Agent Integration**: The `agent_dispatcher.nim` uses a dummy `sleepAsync(100)` rather than properly routing the ReAct agent in a background thread.
3. **SQLite Concurrency**: Multiple thread access to SQLite needs configuration for WAL mode to prevent locking.
4. **Error Handling**: `except CatchableError:` is used heavily with `discard`, swallowing potential critical errors silently.

## Next Steps

1. **Resolve Audit Findings**: Address bugs and architecture tasks documented in `AUDIT_REPORT.md`, `PLAN_TESTING_FIXES.md`, `PLAN_CORE_ARCHITECTURE.md`, and `PLAN_MINOR_ISSUES.md`.
2. **Move Agent Loop**: Refactor `agent_loop.nim` into `mercury_core` to allow bidirectional use across the Discord bot and the CLI.
3. **Migrate Regex**: Move from `nre/pcre` to `nim-regex` to fix dynamic linking dependencies in testing environments.

## Development Notes

- Project uses Nim 2.2.10
- Build system: Nimble with `config.nims` for compiler flags (enforces `-d:ssl`)
- Testing framework: std/unittest
- Detailed audit reports are available in root (`AUDIT_REPORT.md`).
