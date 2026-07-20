# Task 7: MCP Streaming Transport (SSE)

**Status**: 🔴 Not Started
**Dependencies**: Task 2 (Streaming) — shares SSE parsing patterns. Can be done independently but benefits from Task 2 infrastructure.
**Complexity**: Medium

---

## Target

- `mercury_core/src/mercury_core/mcp_client.nim`
- `mercury_core/src/mercury_core/mcp_tool.nim`
- `mercury_core/tests/mock_mcp_server.nim`

## Current State

- `mcp_client.nim` uses HTTP/JSON-RPC over `httpclient` for:
  - `POST /initialize` + `POST /notifications/initialized`
  - `POST /tools/list`
  - `POST /tools/call`
- All synchronous request/response. No server-initiated events.
- The ROADMAP lists SSE/streaming MCP transport as "Low (deferred)".

## Change

### Phase 7a — SSE client infrastructure
1. Add to `mcp_client.nim`:
   ```nim
   type
     McpSseEvent* = object
       eventType*: string         # "message", "ping", etc.
       data*: string              # JSON payload
       id*: string                # event ID (for resume)

     McpSseCallback* = proc(event: McpSseEvent) {.gcsafe, raises: [].}

     McpStreamingClient* = ref object
       http*: AsyncHttpClient
       baseUrl*: string
       onEvent*: McpSseCallback
       running*: bool
   ```
2. Implement SSE connection:
   - `GET /sse` → server returns `text/event-stream`.
   - Parse `event:`, `data:`, `id:` lines.
   - Call `onEvent` for each parsed event.
   - Handle reconnection with `Last-Event-Id` header.
3. Run SSE listening in an async loop (separate from the sync HTTP client for tool calls).

### Phase 7b — Server-initiated tool updates
1. Extend `mcp_tool.nim` to handle `tool_list_changed` events:
   - When MCP server sends `event: tool_list_changed`, re-discover tools via `POST /tools/list`.
   - Update the tool registry with new/removed tools dynamically.
2. Thread safety: tool registry updates must be atomic or use a lock if the agent loop is running.

### Phase 7c — Streaming tool results
1. For `tools/call`, if the server supports streaming results:
   - Server sends SSE events with incremental tool output.
   - `McpTool.execute` receives a callback for streaming output.
2. Wire into `agent_loop.nim`: streaming tool results forwarded to the stream callback (from Task 2).

### Phase 7d — Config and registration
1. Add `transport: "http" | "sse"` to `McpServerConfig` in `config.nim`.
2. In `mcp_tool.registerMcpServer`, if transport is SSE:
   - Connect SSE first, then initialize.
   - Keep the SSE connection alive for server-initiated events.
3. Clean shutdown: close SSE connection on `unregisterMcpServer`.

## Acceptance

- `McpStreamingClient` connects to an SSE endpoint and parses events. Unit test with mock SSE server (extend `mock_mcp_server.nim` with SSE support).
- `tool_list_changed` event triggers tool rediscovery. Test: mock server sends event, registry updates.
- Streaming tool call: server sends incremental output, callback receives deltas.
- HTTP-only transport still works (backward compat).
- All 36 MCP tests pass + new SSE tests.
- All 460 existing tests pass.