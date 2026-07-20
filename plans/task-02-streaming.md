# Task 2: Streaming Responses (SSE)

**Status**: 🟢 Done — with scope changes from the original plan (see below)
**Dependencies**: Task 1 (Agent Loop relocation)
**Complexity**: Large

**Scope change (2026-07-20 audit)**: Phase 2a–2c (SSE parsing, agent_loop
wiring, CLI token-by-token output + `--no-stream`) are implemented as
specified. Phase 2d (Discord progressive message edits) was intentionally
**not** implemented — replaced with a typing-indicator refresh instead.
Discord's typing indicator expires after ~10s and `dispatchAgent` blocks
synchronously per turn (see Task 1's threading deferral), so true
token-by-token streamed edits aren't achievable without either an async
LLM client or real dispatcher threading, both out of scope here. Instead,
`agent_loop.AgentConfig.turnCallback` fires once per ReAct iteration and
`agent_dispatcher.AgentDispatcher.turnCallback` wires it to
`triggerTyping`, so the indicator stays lit across multi-turn runs instead
of lapsing after the first ~10s. `DiscordConfig.streamDebounceMs` was not
added since there's no debounced edit stream to configure.

---

## Target

- `mercury_core/src/mercury_core/llm_client.nim`
- `mercury_core/src/mercury_core/agent_loop.nim` (after Task 1 relocation)
- `mercury_agent/src/mercury_agent.nim`
- `mercury_core/src/mercury_core/agent_dispatcher.nim`

## Current State

- `llm_client.nim` uses synchronous `httpclient.request()` — reads the full response body before returning.
- The comment says `"Out of scope (deferred): Streaming responses (SSE)"`.
- `agent_loop.nim` calls `llm.chatCompletion()` which blocks until the full response arrives.
- CLI and Discord both display the full response at once after the agent loop finishes.

## Change

### Phase 2a — Add streaming to llm_client.nim
1. Add a `ChatCompletionStreamEvent` object:
   ```nim
   type
     StreamEventKind* = enum
       sekContent = "content"        # content_block_delta
       sekToolCallDelta = "tool_call_delta"
       sekFinish = "finish"          # message_stop or done
       sekError = "error"

     ChatCompletionStreamEvent* = object
       kind*: StreamEventKind
       delta*: string                # text delta or tool call delta
       toolCallId*: string           # index for streaming tool calls
       toolName*: string             # tool name (on first delta)
       finishReason*: string         # on sekFinish
       usage*: TokenUsage            # on sekFinish (if present)
   ```
2. Add `OnStreamEvent* = proc(event: ChatCompletionStreamEvent) {.gcsafe, raises: [].}`
3. Add a new proc:
   ```nim
   proc chatCompletionStream*(
       client: LLMClient;
       prompt: string;
       history: seq[ChatMessage] = @[];
       extraParams: Table[string, JsonNode] = initTable[string, JsonNode]();
       onEvent: OnStreamEvent;
   ): ChatResponse  # returns final aggregated response
   ```
4. Implementation:
   - Set `"stream": true` in the request body.
   - Use `httpclient` with streaming — read the response body line-by-line via a lower-level socket or use `AsyncHttpClient` for async streaming.
   - Parse SSE lines: `data: {"choices": [{"delta": {"content": "Hello"}}]}`.
   - Call `onEvent` for each delta.
   - Aggregate tool calls (streamed deltas need reassembly by index).
   - Return the final aggregated `ChatResponse` with usage stats.
5. The current sync `chatCompletion` remains as-is (backward compat). `chatCompletionStream` is additive.

### Phase 2b — Wire streaming into agent_loop.nim
1. Add `streamCallback*: OnStreamEvent` to `AgentConfig`.
2. In `runAgentLoop`, if `streamCallback != nil`, call `chatCompletionStream` instead of `chatCompletion`. Pass the callback through.
3. Tool call handling already works: if the stream finishes with `finishReason == "tool_calls"`, the existing tool execution path runs. Deltas during streaming are just for display.

### Phase 2c — CLI token-by-token output
1. In `mercury_agent.nim`'s `cmdChat`/`cmdAsk`, create an `onEvent` callback that writes to `stdout` immediately (no newline).
2. After the agent loop returns, print a newline and the final stats.
3. Add `--no-stream` flag to disable streaming (fall back to `chatCompletion`).

### Phase 2d — Discord streaming
1. In the daemon's `callbackProc` (inside `cmdDaemon`), pass a stream callback that triggers typing and edits a Discord message progressively.
2. Discord API: send an initial message, then `editMessage` with appended content every N deltas or every M milliseconds (debounced).
3. Add `DiscordConfig.streamDebounceMs` (default 500ms) to control edit frequency.

## Acceptance

- `chatCompletionStream` parses SSE events correctly. Unit test with a mock SSE server.
- CLI shows token-by-token output. Smoke test: `./mercury_agent chat` → text appears incrementally.
- `--no-stream` flag works and uses the old blocking path.
- Discord messages update progressively (debounced edits) during agent response.
- Tool call streaming: deltas for tool arguments appear incrementally in CLI/Discord.
- All 460 existing tests pass. Streaming is additive.