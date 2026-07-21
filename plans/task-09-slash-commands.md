## NOTE: This project has been renamed from Mercury Agent to Talos Agent. All package names (mercury_core, mercury_agent, mercury_code) are now (talos_core, talos_agent, talos_code).

# Task 9: Slash Commands

**Status**: 🔴 Not Started
**Dependencies**: Task 8 (TUI) — slash commands are parsed in the input bar and display results in the TUI
**Complexity**: Small

---

## Target

- `mercury_agent/src/mercury_agent/tui/slash_commands.nim` (new)
- `mercury_agent/src/mercury_agent/tui/input_bar.nim` (modified — command dispatch)
- `mercury_agent/src/mercury_agent/tui/chat_tui.nim` (modified — command handlers)

## Current State

- The chat REPL has one hardcoded command: `:quit` (and `:q`, `:exit`)
- `isExitCommand()` checks for these exact strings
- All other input is sent directly to the LLM
- No help system, no model switching, no session management at runtime

## Design

Slash commands are **client-side** — processed in the input bar before the message reaches the agent loop. They never consume an LLM round-trip.

### Command set

| Command | Args | Action |
|---------|------|--------|
| `/help` | `[command]` | List all commands, or show help for one |
| `/model` | `[name]` | Show current model, or switch model |
| `/provider` | `[name]` | Show current provider, or switch provider |
| `/session` | `[id]` | Show current session info, or switch to session by ID |
| `/sessions` | — | List recent sessions (from `memory.listSessions()`) |
| `/search` | `<query>` | Full-text search conversation history (from `memory.searchHistory()`) |
| `/clear` | — | Clear the current transcript (start a new session) |
| `/save` | `[path]` | Export current session to a file |
| `/config` | — | Show current configuration (model, provider, temperature, etc.) |
| `/quit` | — | Exit (replaces `:quit`) |
| `/exit` | — | Alias for `/quit` |

### Implementation

```nim
type
  SlashCommand* = object
    name*: string
    aliases*: seq[string]
    help*: string          # one-line description
    usage*: string         # e.g. "/model [name]"
    handler*: proc(args: string, ctx: var CommandContext): bool
      ## Returns true if the input was consumed (don't send to LLM).

  CommandContext* = ref object
    cfg*: var MercuryConfig       # mutable — model/provider switches write back
    llm*: var LLMClient           # rebuilt on model/provider switch
    mem*: var Memory              # for /session, /search, /save
    transcript*: TranscriptRegion # for /clear
    statusBar*: StatusBar         # for status updates
    quitRequested*: bool          # set by /quit
    output*: string               # command output to display
```

### Input bar integration

The input bar checks if the submitted line starts with `/`. If so, it dispatches to `SlashCommand`:

```nim
proc handleSubmit(input: string, ctx: var CommandContext): bool =
  if input.startsWith("/"):
    let parts = input.split(" ", maxsplit=1)
    let cmd = parts[0]
    let args = if parts.len > 1: parts[1] else: ""
    for sc in slashCommands:
      if cmd == "/" & sc.name or cmd in sc.aliases.mapIt("/" & it):
        return sc.handler(args, ctx)
    ctx.output = "Unknown command: " & cmd & ". Type /help for available commands."
    return true  # consumed — don't send to LLM
  return false   # not a command — send to LLM
```

### Display

Command output appears as a system message in the transcript (styled differently from user/assistant messages):

```
[/help]
Available commands:
  /help [command]  - Show this help
  /model [name]    - Show or switch model
  /provider [name] - Show or switch provider
  ...
```

### Backward compatibility

`:quit`, `:q`, `:exit` continue to work in the bare `readLine("> ")` REPL. In the TUI, they're aliased to `/quit` and `/exit`. The `isExitCommand()` function is extended to also recognize the new `/quit` form.

### Model/provider switching

`/model gpt-4o` rebuilds the `LLMClient` for the new model (same provider). `/provider openrouter` rebuilds for the new provider (falling back to the provider's default model if none specified). Switching writes through `MercuryConfig` so it persists for the session.

## Files Created

| File | Purpose |
|------|---------|
| `mercury_agent/src/mercury_agent/tui/slash_commands.nim` | Command registry and handlers |

## Acceptance

- `/help` lists all available commands
- `/model` shows current model; `/model gpt-4o` switches
- `/provider` shows current provider; `/provider vllm` switches
- `/session` shows current session; `/session <id>` resumes another session
- `/search <query>` displays FTS5 results in the transcript
- `/clear` starts a new session, clears the transcript display
- `/quit` exits cleanly with terminal restore
- Unknown command shows an error message in the transcript
- Commands do NOT consume an LLM round-trip (no API call)
- `:quit` still works in the bare REPL
- All existing 479 tests pass