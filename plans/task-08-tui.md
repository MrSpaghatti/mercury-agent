## NOTE: This project has been renamed from Mercury Agent to Talos Agent. All package names (mercury_core, mercury_agent, mercury_code) are now (talos_core, talos_agent, talos_code).

# Task 8: Advanced Terminal UI (TUI)

**Status**: 🔴 Not Started
**Dependencies**: Task 2 (Streaming) — streaming callbacks are the data source for live-rendering
**Complexity**: Large

---

## Target

- `mercury_agent/src/mercury_agent/tui/` (new — TUI module directory)
  - `chat_tui.nim` — main loop, layout, event dispatch
  - `transcript.nim` — scrollable message history region
  - `input_bar.nim` — multi-line input with history
  - `streaming.nim` — append-only streaming text region
  - `theme.nim` — color palette, styles, theming
- `mercury_agent/src/mercury_agent.nim` (new `tui` subcommand)
- `mercury_agent/mercury_agent.nimble` (new `illwill` dependency)
- `plans/task-08-tui-research.md` — library evaluation (this document's companion)

## Current State

- `mercury_agent chat` uses a bare `readLine("> ")` REPL with zero cursor control:
  ```nim
  let (line, eof) = readLine("> ")
  ```
- Streaming output via `streamCallback` writes raw tokens to `stdout` with no layout awareness:
  ```nim
  streamCb = proc(event: ChatCompletionStreamEvent) =
    if event.kind == sekContent and event.delta.len > 0:
      stdout.write(event.delta)
      stdout.flushFile()
  ```
- No colors, no scrollback management, no input editing, no rendering pipeline.
- The Web UI (`mercury_agent web`) already has a modern chat interface (HTML/CSS/JS), proving the data layer supports everything a TUI needs.

## Design

### Library choice: **illwill** (johnnovak/illwill, 465★, WTFPL)

Evaluated alternatives and rejected:

| Library | Why rejected |
|---------|-------------|
| **nimwave** (546★) | Retained-mode node tree with mounting lifecycle. Targets terminal + desktop (OpenGL) + web (WASM). Overengineered for a fixed-layout chat TUI with 2-3 regions. Dormant since Sep 2023. |
| **ncurses bindings** | External C dependency, terminfo database requirement, awkward API. illwill is pure Nim. |
| **Raw escape codes** | Cross-platform keyboard handling is a nightmare. Windows Console vs POSIX terminals have incompatible input models. illwill solves this. |
| **illwillWidgets** (47★) | Mouse-enabled widgets for illwill. Useful reference but not a full solution. A chat TUI doesn't need generic buttons/checkboxes/tables. |

**illwill** provides exactly what we need and nothing more:
- `TerminalBuffer` with double-buffered diff-based rendering (only changed cells hit the terminal)
- Non-blocking keyboard input with key combination and special key support
- Mouse support with modifier reporting
- Fullscreen mode with terminal restore on exit
- Zero dependencies, pure Nim, cross-platform (Linux/macOS/Windows)
- UTF-8 box drawing for borders and separators

### Architecture

```
┌─────────────────────────────────────────────────────┐
│                  Terminal (fullscreen)               │
│ ┌─────────────────────────────────────────────────┐ │
│ │  Transcript Region (scrollable message history)  │ │
│ │                                                   │ │
│ │  [user] what can you tell me about...            │ │
│ │                                                   │ │
│ │  [assistant] Based on the files and codebase...  │ │
│ │  ...streaming tokens appear here incrementally   │ │
│ │                                                   │ │
│ │  ─── tool: shell (nimble build) ───              │ │
│ │  [tool-result] Build successful, 0 errors        │ │
│ │                                                   │ │
│ │  [assistant] The build passes. Next...           │ │
│ │                                                   │ │
│ └─────────────────────────────────────────────────┘ │
│ ─────────────────────────────────────────────────── │
│ │  Status bar: model, tokens used, session id       │ │
│ ─────────────────────────────────────────────────── │
│ │ > user input goes here...                    █    │ │
│ └─────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────┘
```

The layout is **fixed** — three regions with known roles. No need for a generic component tree.

### Component model (lightweight)

Each region implements a minimal interface:

```nim
type
  Region* = ref object of RootObj
    y*, height*: int         # position in terminal buffer

  Renderable* = concept r
    r.render(tb: var TerminalBuffer, width: int, focused: bool)

  InputHandler* = concept h
    h.handleInput(key: Key, mouse: MouseInfo): bool  # true = consumed
```

Regions:
1. **TranscriptRegion** — scrollable message list. Receives new messages from the agent loop, scrolls to follow streaming output, pauses scroll-on-output when user scrolls up.
2. **StreamingRegion** — the currently-streaming assistant response. Append-only within the frame: new tokens extend the last line or add lines. Embedded inside the transcript region.
3. **InputBar** — multi-line input with readline-style editing (left/right, home/end, backspace/delete), history navigation (up/down), paste support.
4. **StatusBar** — one fixed line at the bottom showing model name, token count, session ID, and a live spinner during tool execution.

### Key design decisions (stolen from Oh My Pi's TUI contract)

#### 1. Append-only scrollback

Once a message row scrolls past the viewport top, it's committed to terminal history (illwill's fullscreen restore preserves native scrollback). Rows already in scrollback are **never rewritten** — this avoids the "where is the user scrolled?" problem that requires guessing terminal scroll position (an unobservable variable on both POSIX and Windows).

Implementation: the transcript region tracks `scrollOffset` (how far the user has scrolled up). New content appends below the viewport; `tb.display()` diffs and scrolls only the changed region. When the user scrolls up, `scrollOffset > 0` and new output does NOT auto-scroll. A "jump to bottom" key (End or Ctrl+End) resets `scrollOffset = 0`.

#### 2. Double-buffered differential rendering (free from illwill)

illwill's `TerminalBuffer.display()` diffs against the previous frame and emits only changed cells. We don't need to build a differ — just write the frame and call display. The optimization: **skip `display()` when nothing changed** (most frames during LLM wait). Track a `dirty` flag set by: new token, user input, resize, or keypress.

#### 3. Streaming as append-only within the current message block

The streaming response area grows downward as tokens arrive. Implementation:
- `StreamingRegion` holds a `seq[string]` of wrapped lines for the current response
- `onStreamEvent` callback (from Task 2) appends tokens, re-wraps the last line if needed
- `render()` draws the wrapped lines into the transcript region at the current cursor position
- When the response completes (tool call or finish), the block is "frozen" into the transcript and a new streaming region starts

#### 4. Width-aware rendering

All text is wrapped to `terminalWidth()` before writing to the buffer. illwill's `terminalWidth()` gives the current terminal width. On resize (detected via `Key.Resize`), re-wrap the entire transcript. Markdown rendering (bold, italic, code spans) uses ANSI SGR codes — illwill supports inline ANSI in `write()` calls.

#### 5. Input handling

illwill returns `Key` enum values for all common keys, plus `Key.Mouse` for mouse events. Key bindings:

| Key | Action |
|-----|--------|
| Enter | Send message (submit input) |
| Shift+Enter | Newline in input (multi-line) |
| Up/Down | Input history navigation |
| Left/Right | Cursor movement in input |
| Home/End | Line start/end |
| Ctrl+C | Interrupt agent / exit |
| Ctrl+L | Redraw screen |
| PageUp/PageDown | Scroll transcript |
| Ctrl+End | Jump to bottom (un-pause scroll-on-output) |
| Esc | Clear input / cancel |
| Mouse scroll | Scroll transcript |

### Integration with existing `agent_loop`

The TUI replaces `runChatLoop`'s `readLine("> ")` with the fullscreen TUI loop. The existing `streamCallback` mechanism wires directly into the streaming region:

```nim
# In chat_tui.nim:
let streamCb = proc(event: ChatCompletionStreamEvent) {.gcsafe, raises: [].} =
  streamingRegion.append(event.delta)
  dirty = true

# Agent loop runs synchronously in the foreground (same as current chat mode).
# The TUI event loop runs between agent turns.
var res = runAgentLoop(cfg, llm, reg, mem, userInput, streamCb)
transcript.freezeStreamingBlock(res)
```

The TUI is **single-threaded** — illwill's event loop and the agent loop share the main thread. The agent loop blocks during LLM calls (same as today); illwill's `getKey()` is non-blocking and only called between frames.

### Theme

```nim
type
  TuiTheme* = object
    userMsg*: ForegroundColor      # user messages
    assistantMsg*: ForegroundColor  # assistant messages
    toolCall*: ForegroundColor      # tool call indicators
    toolResult*: ForegroundColor    # tool result text
    errorMsg*: ForegroundColor      # errors
    statusBar*: Style               # status bar background+foreground
    inputPrompt*: ForegroundColor   # "> " prompt
    muted*: ForegroundColor         # timestamps, metadata
    accent*: ForegroundColor        # highlights, spinner
```

Default: dark theme, 16-color ANSI palette (works on every terminal). Configurable via `config.toml` key `[tui.theme]` or `MERCURY_TUI_THEME` env var pointing to a theme file.

### Phased implementation

#### Phase 8a — illwill scaffold + input bar
1. Add `illwill >= 0.4.0` to `mercury_agent.nimble`
2. Create `tui/chat_tui.nim`: fullscreen init, main event loop, teardown
3. Create `tui/theme.nim`: default dark theme
4. Create `tui/input_bar.nim`: single-line input with cursor movement, backspace/delete, history (up/down)
5. Add `tui` subcommand to `mercury_agent.nim`:
   ```nim
   proc cmdTui*(
       model = "";
       provider = "";
       temperature = -1.0;
       config = "";
       envFile = ".env";
   ): int
   ```
6. Acceptance: `./mercury_agent tui` opens fullscreen, shows an input bar, accepts text, Enter prints it and clears input, Ctrl+C exits with terminal restore.

#### Phase 8b — Transcript region + message rendering
1. Create `tui/transcript.nim`: scrollable message list
   - `addMessage(role, content)` — append a message block
   - `addToolCall(name, args)` / `addToolResult(name, content)` — tool call blocks
   - Scroll tracking: auto-scroll to bottom on new content, pause when user scrolls up
   - PageUp/PageDown, Ctrl+End for jump-to-bottom
2. Create `tui/streaming.nim`: append-only streaming text
   - `append(token)` — add token, re-wrap last line
   - `freeze()` — finalize block into transcript
3. Wire into agent loop: messages flow from `runAgentLoop` → transcript region
4. Acceptance: full chat session renders with scrolling, user/assistant/tool messages visually distinct.

#### Phase 8c — Streaming + status bar
1. Wire `streamCallback` → `StreamingRegion.append()`
2. Create status bar: model name, token count (from `AgentResult.usage`), session ID, live spinner during tool calls
3. Token-by-token rendering: each delta writes immediately, text wraps in real-time
4. Acceptance: streaming tokens appear incrementally in the TUI, status bar updates per turn.

#### Phase 8d — Polish
1. Multi-line input (Shift+Enter for newline, Enter to submit)
2. Input paste handling (bracket paste mode via illwill)
3. Markdown rendering: bold (`**text**`), italic (`*text*`), inline code (`` `code` ``), code blocks (`` ``` ``) — rendered with ANSI SGR
4. Tool call visualization: expandable/collapsible tool call blocks
5. Session picker: `Ctrl+S` opens a session list overlay
6. Search: `Ctrl+F` opens a search bar, queries `memory.searchHistory`
7. Mouse support: click to position cursor in input, scroll wheel for transcript
8. Resize handling: re-wrap transcript on terminal resize
9. Theme support: load from TOML file

### Non-goals (explicitly out of scope)
- Syntax-highlighted code blocks (depends on tree-sitter or regex highlighter — future task)
- Desktop GUI (nimwave's OpenGL target) — this is a terminal agent
- Web rendering (nimwave's WASM target) — we already have a Web UI
- Mouse-driven widget system — chat TUI is keyboard-first
- Image rendering (Kitty graphics protocol) — text-only

## Files Created

| File | Purpose |
|------|---------|
| `mercury_agent/src/mercury_agent/tui/chat_tui.nim` | Main loop, layout, event dispatch |
| `mercury_agent/src/mercury_agent/tui/transcript.nim` | Scrollable message history |
| `mercury_agent/src/mercury_agent/tui/input_bar.nim` | Multi-line input with editing + history |
| `mercury_agent/src/mercury_agent/tui/streaming.nim` | Append-only streaming text |
| `mercury_agent/src/mercury_agent/tui/theme.nim` | Color palette and styles |
| `mercury_agent/tests/ttui.nim` | TUI component tests |
| `mercury_agent/tests/ttui_input.nim` | Input bar tests |
| `mercury_agent/tests/ttui_transcript.nim` | Transcript scrolling tests |

## Acceptance

- `./mercury_agent tui` opens a fullscreen terminal interface
- Input bar accepts text with cursor movement, backspace, history navigation
- Enter submits to agent; response appears in transcript region (streaming token-by-token if streaming is enabled)
- Tool calls and results are rendered distinctly in the transcript
- PageUp/PageDown scroll the transcript; scrolling up pauses auto-scroll; Ctrl+End resumes
- Status bar shows model, token usage, session ID
- Ctrl+C interrupts gracefully (terminal state restored)
- Terminal resize reflows the layout
- Ctrl+L redraws the screen
- Terminal state is restored on exit (no garbled terminal)
- `--no-stream` flag falls back to blocking mode (same as current chat)
- All existing 479 tests pass (new TUI module is additive to `mercury_agent`)
- New TUI component tests cover: input editing, history, transcript scroll tracking, streaming append+wrap

## Performance constraints

- **Frame budget**: < 16ms per frame (60fps). Achievable because: illwill diffs only changed cells, most frames during LLM wait are no-ops (dirty flag skips `display()`), and transcript re-wrap on resize is O(messages × line count) — acceptable for typical session sizes.
- **Memory**: transcript holds all messages in memory (same as current `Memory` module). Streaming region holds only the current response's wrapped lines. Input history capped at 1000 entries.
- **Binary size**: illwill adds ~50KB to the binary (no C deps). The TUI module itself is < 2000 lines of Nim — negligible.
- **No allocations in the render hot path**: `render()` methods reuse pre-allocated `TerminalBuffer`, strings are `write()`-only (no concatenation in the hot loop).