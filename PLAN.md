# Plan: Task 8 — Advanced TUI

## Goal
Replace the bare `readLine("> ")` REPL with a fullscreen illwill-based terminal UI: scrollable transcript, streaming token-by-token rendering, multi-line input with history, status bar, and theme support.

## Approach
Follow `plans/task-08-tui.md` spec closely. Single-threaded — illwill's event loop and agent loop share the main thread. Five new modules in `mercury_agent/src/mercury_agent/tui/`. Wire into `mercury_agent.nim` as a new `tui` subcommand.

## Tasks

### 🟢 Small
- [ ] Add `illwill >= 0.4.0` to `mercury_agent.nimble` — nimble dep
- [ ] Create `tui/theme.nim` — color palette, `TuiTheme` type

### 🟡 Medium
- [ ] Create `tui/input_bar.nim` — single-line input with cursor, backspace/delete, history (up/down), multi-line (Shift+Enter)
- [ ] Create `tui/streaming.nim` — append-only streaming text region, `append()`/`freeze()`

### 🔴 Large
- [ ] Create `tui/transcript.nim` — scrollable message list, `addMessage()`/`addToolCall()`/`addToolResult()`, scroll tracking with auto-scroll/pause
- [ ] Create `tui/chat_tui.nim` — main loop: illwill init, layout (transcript + status bar + input bar), event dispatch, agent loop integration
- [ ] Add `cmdTui` to `mercury_agent.nim` + `dispatchMulti` entry
- [ ] Build + compile check + smoke test

## Dependencies
- theme ← nothing
- input_bar ← theme
- streaming ← nothing (pure data)
- transcript ← theme
- chat_tui ← input_bar, transcript, streaming, theme
- cmdTui ← chat_tui

## Risks
- Low: illwill is a well-tested pure-Nim library; no C deps
- Low: Existing agent_loop API (`AgentConfig.streamCallback`, `runAgentLoop`) is already designed for the TUI's streaming needs