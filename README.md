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
- **Loop & error safety** — agent loop has loop-detection, max-iteration
  limits, and graceful handling of LLM/tool errors.
- **Layered configuration** — defaults < TOML config < .env <
  environment variables.

## Layout

```
mercury/
├── mercury_core/       # shared library (config, llm_client, memory,
│   ├── src/            # tool_registry, token_counter)
│   └── tests/          #   - mock_server for integration tests
├── mercury_agent/      # CLI binary (agent_loop + tools/shell)
│   ├── src/
│   └── tests/          #   - tagent_loop, tcli, tintegration
├── Makefile
└── README.md           # this file
```

## Quick start

### Prerequisites

- Nim ≥ 2.0
- `nimble`
- SQLite shared library (with FTS5 — included in standard SQLite ≥ 3.9)

### Build

```bash
make build           # builds both mercury_core and mercury_agent
# or, equivalently:
cd mercury_core   && nimble build
cd mercury_agent  && nimble build
```

### Configure

Mercury looks for configuration in three places, **highest priority first**:

1. Environment variables (e.g. `MERCURY_PROVIDER=openrouter`).
2. `.env` in the current directory (typically your API key).
3. `~/.config/mercury/config.toml` (or the path passed to `--config`).

Minimal `.env`:

```bash
OPENROUTER_API_KEY=sk-or-...
```

Optional `~/.config/mercury/config.toml`:

```toml
[mercury]
provider = "openrouter"
openrouter_model = "anthropic/claude-3.5-sonnet"
max_tokens = 4096
temperature = 0.3
max_loop_iterations = 10
db_path = "~/.local/share/mercury/mercury.db"
```

### Run

```bash
# One-shot question
./mercury_agent/mercury_agent ask "what is the capital of France?"

# Interactive chat
./mercury_agent/mercury_agent chat

# List recent sessions
./mercury_agent/mercury_agent history

# Full-text search across all stored messages
./mercury_agent/mercury_agent search "capital of France"

# Resume an existing session (history is shown read-only; new turns
# go to a fresh session)
./mercury_agent/mercury_agent session sess_20260101T120000_123456789

# Per-run overrides (no need to edit the config file)
./mercury_agent/mercury_agent ask "ping" \
    --provider=vllm --model=qwen2.5-7b-instruct --temperature=0.1
```

## CLI usage

```
mercury_agent <subcommand> [options]

Subcommands:
  chat                    Interactive REPL.
  ask <question>          Single-shot question.
  session <id>            Print history of a session and continue chatting
                          (new turns go to a new session).
  history                 List most recently updated sessions.
  search <query>          FTS5 search across stored messages.

Common options (chat / ask / session):
  --model=<name>          Override model name for the active provider.
  --provider=<name>       Override provider (openrouter | vllm).
  --temperature=<float>   Override sampling temperature (0..2). Negative
                          means leave at config default.
  --config=<path>         Path to TOML config (overrides default).
  --envFile=<path>        Path to .env (default: .env).

Options for history / search:
  --limit=<n>             Max sessions / matches to show.
  --config=<path>         Path to TOML config (overrides default).
  --envFile=<path>        Path to .env (default: .env).

Run `mercury_agent --help` or `mercury_agent <subcommand> --help` for
the full list.
```

## Configuration reference

| Key (TOML)            | Env var                       | Default                                      | Description                                      |
| --------------------- | ----------------------------- | -------------------------------------------- | ------------------------------------------------ |
| `provider`            | `MERCURY_PROVIDER`            | `openrouter`                                 | Active provider: `openrouter` or `vllm`.         |
| `openrouter_endpoint` | `MERCURY_OPENROUTER_ENDPOINT` | `https://openrouter.ai/api/v1`               | OpenRouter base URL.                             |
| `openrouter_model`    | `MERCURY_OPENROUTER_MODEL`    | `openrouter/auto`                            | Model name used when provider=openrouter.        |
| `vllm_endpoint`       | `MERCURY_VLLM_ENDPOINT`       | `http://192.168.4.30:8000/v1`                | vLLM base URL.                                   |
| `vllm_model`          | `MERCURY_VLLM_MODEL`          | `qwen2.5-7b-instruct`                        | Model name used when provider=vllm.              |
| `max_tokens`          | `MERCURY_MAX_TOKENS`          | `4096`                                       | Per-request `max_tokens`.                        |
| `temperature`         | `MERCURY_TEMPERATURE`         | `0.3`                                        | Sampling temperature in `[0, 2]`.                |
| `max_loop_iterations` | `MERCURY_MAX_LOOP_ITERATIONS` | `10`                                         | Hard cap on ReAct iterations per query.          |
| `db_path`             | `MERCURY_DB_PATH`             | `~/.local/share/mercury/mercury.db`          | SQLite database path. `~` expands to `$HOME`.    |
| (n/a)                 | `OPENROUTER_API_KEY`          | (empty)                                      | API key sent as `Authorization: Bearer ...`.     |

`.env` is also read (in `loadConfig`) for `OPENROUTER_API_KEY`,
`MERCURY_PROVIDER`, and `MERCURY_VLLM_ENDPOINT` — useful when you don't
want to export those variables globally.

## Architecture overview

### `mercury_core/`

| Module              | Responsibility                                                                  |
| ------------------- | ------------------------------------------------------------------------------- |
| `config.nim`        | Loads `MercuryConfig` from defaults + TOML + `.env` + env vars; validates.      |
| `llm_client.nim`    | Synchronous OpenAI-compatible Chat Completions client with retry/error types.   |
| `tool_registry.nim` | Named registry of tools; serializes to OpenAI `tools` array; safe execution.    |
| `memory.nim`        | SQLite + FTS5: sessions, messages, full-text search, token-usage aggregation.   |
| `token_counter.nim` | Cheap heuristic token counter used to size requests.                            |

### `mercury_agent/`

| Module                  | Responsibility                                                              |
| ----------------------- | --------------------------------------------------------------------------- |
| `agent_loop.nim`        | ReAct loop: build system+user, call LLM, dispatch tool calls, log to memory.|
| `tools/shell.nim`       | Shell tool with deny-list and per-call timeout.                             |
| `mercury_agent.nim`     | CLI wiring + subcommand entry points (`chat`, `ask`, `session`, …).         |

The agent loop's contract is simple:

```nim
proc runAgentLoop*(
    cfg: MercuryConfig;
    llm: LLMClient;
    registry: ToolRegistry;
    memory: var Memory;
    userInput: string;
): AgentResult
```

It returns once the model emits a final text answer, the iteration cap
is hit, or the loop detector fires (same tool + same args N times in a
row).

## Development

### Build & test

```bash
make build           # build both packages
make test            # run all tests (mercury_core + mercury_agent)
```

Equivalent commands:

```bash
cd mercury_core   && nimble test
cd mercury_agent  && nimble test
```

### Test layout

The test suite is split into focused modules:

- `mercury_core/tests/`
  - `tconfig.nim` — config defaults, TOML parsing, env-var precedence,
    `validate`.
  - `tllm_client.nim` — request building, response parsing, retry logic,
    typed errors.
  - `tmemory.nim` — sessions, append/getHistory, FTS5, token usage.
  - `ttool_registry.nim` — registration, execution, OpenAI serialization.
  - `ttoken_counter.nim` — heuristic counter sanity checks.
  - `mock_server.nim` — `MockLLMServer`, an in-process HTTP mock used by
    integration tests.

- `mercury_agent/tests/`
  - `tagent_loop.nim` — ReAct loop driven against the mock server: text
    answer, tool-call turn, max iterations, loop detection, tool errors,
    memory logging, the `MercuryConfig` overload.
  - `tcli.nim` — config-override layering, recent-session listing,
    `cmdHistory`/`cmdSearch`/`cmdAsk`/`cmdSession` argument validation,
    binary `--help` smoke test.
  - **`tintegration.nim`** — full end-to-end stack: `loadConfig` →
    `LLMClient` → `ToolRegistry` (with the real `shellTool`) →
    SQLite-backed `Memory` → `runAgentLoop`. Covers:
      1. **Full pipeline** — text-only response, tool-call response,
         LLM error path; verifies session is created and history is
         logged correctly.
      2. **Config loading** — defaults, TOML overrides, env-var
         precedence, `.env` API-key loading, validation rejection.
      3. **Memory persistence** — multi-message session round-trip,
         FTS5 search across multiple sessions, on-disk persistence
         across reopen.
      4. **Tool registry** — register `shellTool`, execute, deny-list,
         malformed JSON, OpenAI definition serialization, duplicate
         registration error.
      5. **Agent loop** — full ReAct turn (tool call → tool result →
         final answer) with full memory log assertions; on-disk
         persistence + FTS5 search of agent output across reopen.

### Running a single test file

```bash
cd mercury_agent
nimble c -r tests/tintegration.nim
```

### Coding style

- Modules have a docstring header summarizing intent and out-of-scope
  items.
- Public procs use `*` and have docstrings.
- Errors are typed (`ConfigError`, `LLMError` subtypes, `ToolError`
  subtypes, `MemoryError`) and never leak generic `CatchableError` to
  callers when avoidable.
- Tests use `unittest`, with one suite per behaviour cluster.

## Desloppify

Run the desloppify lint scan explicitly when you want to check the repo:

```bash
make desloppify
```

The target runs `python3 -m desloppify scan --path .` on demand.
`.desloppify/` is ignored so local scan output does not pollute the repo.

## License

MIT.
