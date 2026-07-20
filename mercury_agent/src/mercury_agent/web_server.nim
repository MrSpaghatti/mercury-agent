## Mercury web UI server.
##
## Serves a single-page chat interface and REST API using Nim's stdlib
## `asynchttpserver`. No external web framework dependencies.
##
## Routes:
##   GET  /                 → index.html
##   GET  /assets/*         → static files (CSS, JS)
##   POST /api/chat         → run agent loop, return JSON result
##   GET  /api/sessions     → list recent sessions
##   GET  /api/sessions/:id → get session history
##   GET  /api/search?q=    → FTS5 search across messages
##
## SSE streaming is deferred — `asynchttpserver` does not support
## chunked/long-lived responses after the initial respond() call.
##
## Pattern: create → configure → waitFor start() → test → stop().

import std/[asynchttpserver, asyncdispatch, json, strutils, os, uri]

import mercury_core/config
import mercury_core/llm_client
import mercury_core/agent_loop
import mercury_core/tool_registry
import mercury_core/memory

# ---------------------------------------------------------------------------
# Embedded assets (compiled into the binary via staticRead)
# ---------------------------------------------------------------------------

const
  AssetDir = currentSourcePath().parentDir / "web_assets"

when defined(embedAssets):
  const
    IndexHtml = staticRead(AssetDir / "index.html")
    StyleCss  = staticRead(AssetDir / "style.css")
    AppJs     = staticRead(AssetDir / "app.js")
else:
  proc readAsset(path: string): string =
    try:
      result = readFile(path)
    except IOError:
      result = ""

# ---------------------------------------------------------------------------
# Types
# ---------------------------------------------------------------------------

type
  WebServer* = ref object
    server*: AsyncHttpServer
    port*: int
    cfg*: MercuryConfig
    llm*: LLMClient
    registry*: ToolRegistry
    mem*: Memory

  WebServerContext* = ref object
    ## Per-request context capturing the shared server state.
    ws*: WebServer

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

proc isSafeAssetPath(path: string): bool =
  ## Rejects any path containing a ".." segment (path traversal) or an
  ## embedded NUL byte, before it's joined onto `AssetDir` and read.
  if '\0' in path:
    return false
  for part in path.split('/'):
    if part == "..":
      return false
  true

proc getContentType(ext: string): string =
  case ext.toLowerAscii()
  of ".html", ".htm": "text/html"
  of ".css":          "text/css"
  of ".js":           "application/javascript"
  of ".json":         "application/json"
  of ".png":          "image/png"
  of ".svg":          "image/svg+xml"
  of ".ico":          "image/x-icon"
  else:               "application/octet-stream"

proc respondJson(req: Request; code: HttpCode; body: JsonNode) {.async.} =
  # No CORS headers: the UI is always served same-origin by this process,
  # and a wildcard Access-Control-Allow-Origin would let any page the
  # user's browser visits read responses from this local agent server.
  let headers = newHttpHeaders([("Content-Type", "application/json")])
  await req.respond(code, $body, headers)

proc respondText(req: Request; code: HttpCode; body, contentType: string) {.async.} =
  let headers = newHttpHeaders([("Content-Type", contentType)])
  await req.respond(code, body, headers)

proc respondError(req: Request; code: HttpCode; msg: string) {.async.} =
  let body = %*{"error": msg}
  await respondJson(req, code, body)

# ---------------------------------------------------------------------------
# Request routing
# ---------------------------------------------------------------------------

proc handleChat(ctx: WebServerContext; req: Request) {.async.} =
  ## POST /api/chat — run the agent loop and return the full result as JSON.
  ## Streaming (SSE) is deferred until we have a server that supports it.
  try:
    let bodyJson = parseJson(req.body)
    let message = bodyJson{"message"}.getStr("")
    if message.len == 0:
      await respondError(req, Http400, "message is required")
      return
    if message.len > 10_000:
      await respondError(req, Http400, "message too large (>10KB)")
      return

    var agentCfg = newAgentConfig(ctx.ws.cfg)
    let res = runAgentLoop(
      agentCfg, ctx.ws.llm, ctx.ws.registry, ctx.ws.mem, message)

    let body = %*{
      "text": res.text,
      "sessionId": res.sessionId,
      "stopReason": $res.stopReason,
      "stats": {
        "totalTokens": res.stats.totalTokens,
        "promptTokens": res.stats.promptTokens,
        "completionTokens": res.stats.completionTokens,
        "totalTurns": res.stats.totalTurns,
        "toolCallsMade": res.stats.toolCallsMade,
      },
    }
    await respondJson(req, Http200, body)
  except JsonParsingError:
    await respondError(req, Http400, "invalid JSON body")
  except CatchableError as e:
    await respondError(req, Http500, e.msg)

proc handleSessions(ctx: WebServerContext; req: Request) {.async.} =
  ## GET /api/sessions — list recent sessions.
  try:
    let sessions = ctx.ws.mem.listSessions(limit = 50)
    let result = newJArray()
    for s in sessions:
      result.add(%*{
        "id": s.id,
        "createdAt": s.createdAt,
        "updatedAt": s.updatedAt,
        "messageCount": s.messageCount,
      })
    await respondJson(req, Http200, result)
  except CatchableError as e:
    await respondError(req, Http500, e.msg)

proc handleSessionById(ctx: WebServerContext; req: Request; sessionId: string) {.async.} =
  ## GET /api/sessions/:id — get session history.
  try:
    let history = ctx.ws.mem.getHistory(sessionId)
    let msgs = newJArray()
    for msg in history:
      var msgJson = %*{
        "role": $msg.role,
        "content": msg.content,
      }
      if msg.toolCalls.len > 0:
        var tcArr = newJArray()
        for tc in msg.toolCalls:
          tcArr.add(%*{"name": tc.name, "arguments": tc.arguments})
        msgJson["toolCalls"] = tcArr
      msgs.add(msgJson)
    let result = %*{
      "sessionId": sessionId,
      "messages": msgs,
    }
    await respondJson(req, Http200, result)
  except CatchableError as e:
    await respondError(req, Http500, e.msg)

proc handleSearch(ctx: WebServerContext; req: Request) {.async.} =
  ## GET /api/search?q= — FTS5 search across messages.
  var q = ""
  for (k, v) in decodeQuery(req.url.query):
    if k == "q":
      q = v
      break
  if q.len == 0:
    await respondError(req, Http400, "missing 'q' query parameter")
    return
  try:
    let results = ctx.ws.mem.searchHistory(q)
    let arr = newJArray()
    for r in results:
      arr.add(%*{
        "sessionId": r.sessionId,
        "role": $r.role,
        "content": r.content,
        "snippet": r.snippet,
      })
    await respondJson(req, Http200, arr)
  except CatchableError as e:
    await respondError(req, Http500, e.msg)

proc serveAsset(req: Request; path: string) {.async.} =
  ## Serves an embedded static asset.
  if not isSafeAssetPath(path):
    await respondError(req, Http400, "invalid path")
    return
  let ext = splitFile(path).ext
  let contentType = getContentType(ext)

  when defined(embedAssets):
    case path
    of "index.html":
      await respondText(req, Http200, IndexHtml, contentType)
    of "style.css":
      await respondText(req, Http200, StyleCss, contentType)
    of "app.js":
      await respondText(req, Http200, AppJs, contentType)
    else:
      await respondError(req, Http404, "not found")
  else:
    let filePath = AssetDir / path
    try:
      let content = readFile(filePath)
      await respondText(req, Http200, content, contentType)
    except IOError:
      await respondError(req, Http404, "not found")

proc parsePath(req: Request): string =
  ## Extracts the URL path from the request, stripping query string.
  let parsed = parseUri(req.url.path)
  result = parsed.path.strip(chars = {'/'})

proc handleRequest*(ctx: WebServerContext; req: Request) {.async.} =
  let path = parsePath(req)
  let httpMethod = req.reqMethod

  # Route dispatch.
  if httpMethod == HttpGet:
    if path == "" or path == "index.html":
      await serveAsset(req, "index.html")
    elif path.startsWith("assets/"):
      await serveAsset(req, path["assets/".len .. ^1])
    elif path == "api/sessions":
      await handleSessions(ctx, req)
    elif path.startsWith("api/sessions/"):
      let sessionId = path["api/sessions/".len .. ^1]
      if sessionId.len > 0:
        await handleSessionById(ctx, req, sessionId)
      else:
        await handleSessions(ctx, req)
    elif path == "api/search":
      await handleSearch(ctx, req)
    else:
      await respondError(req, Http404, "not found")

  elif httpMethod == HttpPost:
    if path == "api/chat":
      await handleChat(ctx, req)
    else:
      await respondError(req, Http404, "not found")

  else:
    await respondError(req, Http405, "method not allowed")

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

proc newWebServer*(
    cfg: MercuryConfig;
    llm: LLMClient;
    registry: ToolRegistry;
    mem: Memory;
): WebServer =
  new result
  result.server = newAsyncHttpServer()
  result.port = cfg.webPort
  result.cfg = cfg
  result.llm = llm
  result.registry = registry
  result.mem = mem

proc start*(self: WebServer) {.async.} =
  ## Binds to loopback only: the agent has shell/file tools and the API
  ## carries no authentication, so this must not be reachable off-host.
  let ctx = WebServerContext(ws: self)
  let port = Port(self.port)
  self.server.listen(port, address = "127.0.0.1")
  stderr.writeLine("[web] listening on http://localhost:" & $self.port)
  asyncCheck self.server.acceptRequest(
    proc (req: Request) {.async, gcsafe.} =
      await handleRequest(ctx, req)
  )

proc stop*(self: WebServer) =
  self.server.close()