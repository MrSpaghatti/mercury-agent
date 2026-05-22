# Mercury Agent: Architectural Review and "Ideas to Steal"

Based on an analysis of the `MrSpaghatti/mercury-agent` repository, there are several extremely valuable architectural patterns and features that you should definitely adapt for your personal agent, especially given your goals of a hybrid cloud/local setup, PKM (Personal Knowledge Management), and an automated coding harness.

## 1. Hybrid Model Management (Cloud/Local)

**How Mercury does it:**
Mercury uses a highly layered and robust configuration system (`mercury_core/config.nim`) combined with a provider-agnostic `llm_client.nim`.
*   **Layered Config:** Defaults < TOML file < `.env` < Environment Variables.
*   **Provider Abstraction:** The config explicitly splits out `vllm` (local) and `openrouter` (cloud).
*   **CLI Overrides:** You can instantly switch models per-run via CLI flags (`mercury_agent ask "ping" --provider=vllm --model=qwen2.5-7b-instruct`).

**Why you should steal it:**
Since you are using OpenCode Go (cloud) in conjunction with local models, this exact pattern is perfect. You should build a unified interface that accepts standard OpenAI Chat Completions formats and routes them based on a central configuration. This allows your agent to use a fast, cheap local model for simple tasks (like triage or simple file generation) and fall back to the powerful cloud model (OpenCode Go) for complex reasoning or heavy coding tasks dynamically.

## 2. PKM Foundation: SQLite + FTS5 Memory System

**How Mercury does it:**
Mercury stores every single conversation session and message in a local SQLite database (`mercury_core/memory.nim`).
*   **FTS5:** It uses SQLite's FTS5 (Full-Text Search) extension to create a virtual table mirroring message content.
*   **CLI Integration:** It ships a command (`mercury_agent search "query"`) to instantly search the entire chat history.

**Why you should steal it:**
This is the holy grail for Personal Knowledge Management. By logging every interaction your agent has (whether generating code, summarizing a document, or answering a question) into SQLite and indexing it with FTS5, your agent effectively becomes a searchable external brain. You can easily query past solutions, scripts, or notes instantly.

## 3. Sandboxed Tool Execution for Coding Harness

**How Mercury does it:**
Mercury has a `ToolRegistry` (`tool_registry.nim`) and a `shell` tool (`mercury_agent/tools/shell.nim`) built for the ReAct loop.
*   **Deny-lists:** The shell tool has a hardcoded deny-list (`rm -rf /`, etc.) to prevent catastrophic commands.
*   **Timeouts:** It uses `osproc` with a strict timeout. If a command hangs, it kills the process tree.
*   **File Rules:** There are structured `file_tool.nim` modules with `allow` and `deny` patterns for reading/writing.

**Why you should steal it:**
Since you are building a coding harness (`mercury_code`), the agent *will* run malicious, infinite-looping, or broken code. Implementing strict timeouts, process tree killing, and explicit file/shell path allow/deny lists is critical. Do not let the agent run arbitrary code without these safety rails.

## 4. Robust ReAct Loop with Error and Loop Detection

**How Mercury does it:**
The `runAgentLoop` (`mercury_agent/agent_loop.nim`) doesn't just blindly feed tool outputs back to the model.
*   **Loop Detection:** It tracks tool calls. If the agent calls the *exact same tool with the exact same arguments* N times in a row (default 3), it forcefully terminates the loop to save tokens and prevent infinite spiraling.
*   **Error Recovery:** If a tool fails (e.g., exit code 1), it formats the error and feeds it *back* to the LLM so the LLM can try to fix it, rather than just crashing the agent.

**Why you should steal it:**
When dealing with coding tasks, the agent will frequently write code that fails to compile or run. Feeding the compiler/runtime errors back to the agent (and preventing it from infinitely trying the same broken fix) is the core mechanism of autonomous coding.

## 5. Dependency Injection for Interfaces (Discord Daemon)

**How Mercury does it:**
For its Discord bot (`discord.nim`), Mercury uses a "Dependency Injection" pattern. It passes functions (`SendMessageFn`, `TriggerTypingFn`) into the `DiscordBot` object instead of hardcoding API calls.

**Why you should steal it:**
If you want an agent that works on CLI, Discord, and maybe a web UI, decouple the "Agent Logic" from the "Presentation Layer". By injecting callbacks for "how to send a message", your core agent loop can remain completely unaware of whether it's talking to a terminal or a Discord channel.

## Summary

This project is **absolutely** worth digging into. You should strongly consider lifting the SQLite FTS5 memory module for your PKM needs, the layered configuration for managing OpenCode Go + Local models, and the error-recovering, loop-detecting ReAct loop for your coding harness.
