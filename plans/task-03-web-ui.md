# Task 3: Web UI

**Status**: 🟢 Done — with scope changes from the original plan (see below)
**Dependencies**: Task 1 (Agent Loop relocation). Task 2 (Streaming) is nice-to-have.
**Complexity**: Medium-Large

**Scope change (2026-07-20 audit)**: Phases 3a–3c implemented as specified,
except SSE streaming on `/api/chat` (deferred — `asynchttpserver` doesn't
support long-lived chunked responses after the initial `respond()` call;
the endpoint returns the full result as JSON instead). Phase 3d (security
hardening): input validation (>10KB rejection) implemented as specified.
CSRF protection is implemented as an `Origin` header check rather than a
token, since the server is same-origin-only. Rate limiting is a
per-client fixed-window limiter in `web_server.nim` itself, not a reuse
of `rate_limit.nim` — that module implements outbound retry-with-backoff
for calling other APIs (e.g. Discord), which doesn't fit inbound request
throttling; reusing it as specified wasn't actually possible.

---

## Target

- `mercury_agent/src/mercury_agent/web_server.nim` (new)
- `mercury_agent/src/mercury_agent/web_assets/` (new — static HTML/CSS/JS)
- `mercury_agent/src/mercury_agent.nim` (new `web` subcommand)

## Current State

- No HTTP server or UI exists. The ROADMAP lists it as P3 (Low, deferred).
- `mercury_core` has `llm_client`, `memory`, `tool_registry`, `agent_loop` (after Task 1) — all usable server-side.
- No web framework dependency. Nim's stdlib includes `asynchttpserver`.

## Change

### Phase 3a — HTTP server scaffold
1. Create `web_server.nim`:
   - Uses `asynchttpserver` from stdlib (no extra deps).
   - Routes:
     - `GET /` → serve `index.html`
     - `GET /assets/*` → serve static files from `web_assets/`
     - `POST /api/chat` → accept `{message, sessionId?}`, run agent loop, return SSE stream or full response
     - `GET /api/sessions` → list recent sessions from memory
     - `GET /api/sessions/:id` → get session history
     - `GET /api/search?q=...` → FTS5 search
   - Config port via `MERCURY_WEB_PORT` (default 8080).
   - CORS headers for local dev.
   - Optional: embed assets at compile time via `staticRead` so the binary is self-contained.

### Phase 3b — Chat UI
1. Create `web_assets/index.html`:
   - Single-page chat interface.
   - Message list (scrollable), input box, send button.
   - Session selector (dropdown of recent sessions).
   - Markdown rendering (simple regex-based or include a lightweight lib like `marked.js` via CDN).
2. Create `web_assets/style.css`: clean, dark-theme, responsive.
3. Create `web_assets/app.js`:
   - Connect to `/api/chat` via `fetch` or `EventSource` (SSE).
   - Display streaming tokens as they arrive.
   - Session management (list, select, new).
4. No framework — vanilla JS, ~500 lines max.

### Phase 3c — CLI integration
1. Add `web` subcommand to `mercury_agent.nim`:
   ```nim
   proc cmdWeb*(port: int = 8080; config = ""; envFile = ".env"): int
   ```
2. Loads config, creates LLM client + tool registry + memory, starts HTTP server.
3. Graceful shutdown on SIGINT.

### Phase 3d — Security hardening
1. CSRF protection: check `Origin`/`Referer` headers for POST endpoints, or use a simple token.
2. Rate limiting: reuse `rate_limit.nim` per IP.
3. Input validation: reject oversized messages (>10KB).

## Acceptance

- `./mercury_agent web` starts an HTTP server on port 8080.
- Browser at `http://localhost:8080` shows a chat UI.
- Typing a message and pressing Enter sends it to the agent, response appears (streaming if Task 2 is done).
- Session list loads from memory.
- Search works.
- Mobile-responsive layout.
- Static assets served correctly (CSS loads, JS runs).
- Existing tests pass (new package doesn't break mercury_core).