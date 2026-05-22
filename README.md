# Mercury Agent

Mercury is a small, self-contained Nim **AI agent** built around the
OpenAI Chat Completions protocol. It speaks to any OpenAI-compatible
endpoint (OpenRouter, vLLM, OpenAI, …), exposes tools to the model via
function calling, persists every conversation to a local SQLite
database with FTS5 full-text search, and ships a CLI for chatting with
the agent or browsing past sessions.

```
+-----------------+     +-------------------+     +----------------+
|  mercury_agent  | --> | mercury_core/llm  | --> |  LLM endpoint  |
|     (CLI)       |     |     _client       |     |   (HTTP/JSON)  |
+--------+--------+     +-------------------+     +----------------+
         |
         |  ReAct loop
         v
+--------+--------+     +-------------------+     +----------------+
|   agent_loop    | --> |   tool_registry   | --> |  shell, ...    |
+--------+--------+     +-------------------+     +----------------+
         |
         |  appendMessage / getHistory / searchHistory
         v
+--------+--------+
|  memory (SQLite |
|     + FTS5)     |
+-----------------+
```

## Features

- **Provider agnostic** — works with any OpenAI-compatible Chat
  Completions endpoint. Built-in defaults for OpenRouter and vLLM.
- **Tool calling** — register Nim procs as tools; the model invokes
  them via OpenAI function-calling. Ships with a sandboxed `shell`
  tool (deny-list + per-call timeout).
- **Persistent memory** — every conversation is logged to SQLite with
  a FTS5 full-text index over message content.
- **CLI** — `chat`, `ask`, `session`, `history`, `search`.
- **Discord Bot Integration** - Exposes the Mercury agent to Discord channels and threads.
- **Layered configuration** — defaults < TOML config < .env <
  environment variables.

## Layout

```
mercury/
├── mercury_core/       # shared library (config, llm_client, memory,
│   ├── src/            # tool_registry, discord, token_counter)
│   └── tests/          #   - mock_server for integration tests
├── mercury_agent/      # CLI binary (agent_loop + tools/shell)
│   ├── src/
│   └── tests/          #   - tagent_loop, tcli, tintegration
├── Makefile
├── STATUS.md           # current state of the project
├── AUDIT_REPORT.md     # deep dive audit report and next steps
└── README.md           # this file
```

## Quick start

### Prerequisites

- Nim ≥ 2.0 (we use 2.2.10)
- `nimble`
- SQLite shared library (with FTS5 — included in standard SQLite ≥ 3.9)
- OpenSSL dependencies (`libssl-dev`)

### Build

```bash
make build           # builds both mercury_core and mercury_agent
# or, equivalently:
cd mercury_core   && nimble build
cd mercury_agent  && nimble build
```

## Further Reading

During an intensive code audit, multiple next-step architecture and testing documents were produced for agent iteration:
- `AUDIT_REPORT.md`: Comprehensive overview of findings.
- `PLAN_CORE_ARCHITECTURE.md`: Agent loop threading and SQLite connection pooling.
- `PLAN_TESTING_FIXES.md`: Resolution plans for `-d:ssl` build failures and dynamic linker errors (e.g. `pcre`).
- `PLAN_MINOR_ISSUES.md`: Discard cleanups, imports, and config edge cases.
