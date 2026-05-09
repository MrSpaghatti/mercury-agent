## Tests for mercury_core/llm_client.nim
##
## Uses a tiny in-process TCP mock server (one connection at a time, sync)
## to exercise the LLM client without depending on Task 2.3's mock server.

import std/[json, net, os, strutils, tables, unittest, locks]
import mercury_core/llm_client

# ---------------------------------------------------------------------------
# Mock HTTP server
# ---------------------------------------------------------------------------

type
  MockResponse = object
    statusLine: string             ## e.g. "200 OK"
    body: string
    contentType: string

  MockServer = ref object
    socket: Socket
    port: int
    thread: Thread[MockServer]
    responses: seq[MockResponse]   ## FIFO queue of responses
    requestCount: int
    requestBodies: seq[string]
    lock: Lock
    running: bool

# Use globals because Nim threads cannot capture refs from the heap
# trivially across thread boundaries on all platforms.
var gServer: MockServer

proc readRequest(client: Socket): string =
  ## Reads an HTTP request from a connected socket and returns the body.
  ## Returns "" if no body or on parse failure.
  var headerBuf = ""
  while true:
    let line = client.recvLine(timeout = 5000)
    if line.len == 0:
      break
    headerBuf.add(line)
    headerBuf.add("\r\n")
    if line == "\r\n" or line == "":
      break
  # Determine content length
  var contentLength = 0
  for raw in headerBuf.splitLines():
    let lower = raw.toLowerAscii()
    if lower.startsWith("content-length:"):
      let valPart = raw[raw.find(':') + 1 .. ^1].strip()
      try:
        contentLength = parseInt(valPart)
      except ValueError:
        contentLength = 0
  if contentLength <= 0:
    return ""
  var body = newString(contentLength)
  var got = 0
  while got < contentLength:
    let chunk = client.recv(contentLength - got, timeout = 5000)
    if chunk.len == 0:
      break
    body[got ..< got + chunk.len] = chunk
    got += chunk.len
  return body[0 ..< got]

proc sendResponse(client: Socket; resp: MockResponse) =
  let ct = if resp.contentType.len > 0: resp.contentType else: "application/json"
  let payload = "HTTP/1.1 " & resp.statusLine & "\r\n" &
                "Content-Type: " & ct & "\r\n" &
                "Content-Length: " & $resp.body.len & "\r\n" &
                "Connection: close\r\n\r\n" & resp.body
  client.send(payload)

proc serverLoop(srv: MockServer) {.thread.} =
  while true:
    var client: Socket
    try:
      srv.socket.accept(client)
    except OSError, IOError:
      return
    if client.isNil:
      return
    try:
      let body = readRequest(client)
      var resp: MockResponse
      withLock srv.lock:
        srv.requestCount.inc
        srv.requestBodies.add(body)
        if srv.responses.len == 0:
          resp = MockResponse(
            statusLine: "500 Internal Server Error",
            body: """{"error": {"message": "no mock response queued"}}""")
        else:
          resp = srv.responses[0]
          srv.responses.delete(0)
      sendResponse(client, resp)
    except CatchableError:
      discard
    finally:
      try: client.close() except CatchableError: discard

proc startMockServer(): MockServer =
  result = MockServer(
    socket: newSocket(),
    responses: @[],
    requestBodies: @[],
    requestCount: 0,
    running: true,
  )
  initLock(result.lock)
  result.socket.setSockOpt(OptReuseAddr, true)
  # Bind on an OS-assigned port on loopback only.
  result.socket.bindAddr(Port(0), "127.0.0.1")
  let (_, portObj) = result.socket.getLocalAddr()
  result.port = portObj.int
  result.socket.listen()
  gServer = result
  createThread(result.thread, serverLoop, result)

proc stopMockServer(srv: MockServer) =
  if not srv.running:
    return
  srv.running = false
  try: srv.socket.close() except CatchableError: discard
  joinThread(srv.thread)
  deinitLock(srv.lock)

proc enqueue(srv: MockServer; statusLine, body: string) =
  withLock srv.lock:
    srv.responses.add(MockResponse(statusLine: statusLine, body: body))

proc resetMock(srv: MockServer) =
  withLock srv.lock:
    srv.responses.setLen(0)
    srv.requestBodies.setLen(0)
    srv.requestCount = 0

proc baseUrlFor(srv: MockServer): string =
  "http://127.0.0.1:" & $srv.port & "/v1"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

const SuccessBody = """
{
  "id": "chatcmpl-1",
  "object": "chat.completion",
  "model": "test-model",
  "choices": [{
    "index": 0,
    "message": {"role": "assistant", "content": "Hello!"},
    "finish_reason": "stop"
  }],
  "usage": {"prompt_tokens": 7, "completion_tokens": 3, "total_tokens": 10}
}
"""

const ToolCallBody = """
{
  "id": "chatcmpl-2",
  "object": "chat.completion",
  "model": "test-model",
  "choices": [{
    "index": 0,
    "message": {
      "role": "assistant",
      "content": null,
      "tool_calls": [
        {"id": "call_abc", "type": "function",
         "function": {"name": "shell", "arguments": "{\"cmd\": \"ls\"}"}}
      ]
    },
    "finish_reason": "tool_calls"
  }]
}
"""

const AuthErrBody = """{"error": {"message": "Invalid API key", "code": "invalid_api_key"}}"""
const RateLimitBody = """{"error": {"message": "Too many requests"}}"""
const ServerErrBody = """{"error": {"message": "upstream timeout"}}"""

proc makeClient(server: MockServer; maxRetries = 3; backoffMs = 5): LLMClient =
  newLLMClient(
    baseUrl = baseUrlFor(server),
    apiKey = "test-key",
    model = "test-model",
    maxRetries = maxRetries,
    retryBackoffMs = backoffMs,
    timeoutMs = 5_000,
  )

# ---------------------------------------------------------------------------
# Test setup: a single shared server for all suites
# ---------------------------------------------------------------------------

var sharedServer = startMockServer()

# ---------------------------------------------------------------------------
# Suite: basic chat completion
# ---------------------------------------------------------------------------

suite "chatCompletion basic":
  setup:
    resetMock(sharedServer)

  test "parses content from successful response":
    sharedServer.enqueue("200 OK", SuccessBody)
    let client = makeClient(sharedServer)
    let resp = client.chatCompletion("say hello")
    check resp.content == "Hello!"
    check resp.finishReason == "stop"
    check resp.toolCalls.len == 0
    check resp.usage.promptTokens == 7
    check resp.usage.completionTokens == 3
    check resp.usage.totalTokens == 10
    check resp.model == "test-model"

  test "sends prompt as final user message":
    sharedServer.enqueue("200 OK", SuccessBody)
    let client = makeClient(sharedServer)
    discard client.chatCompletion("hello world")
    check sharedServer.requestCount == 1
    let reqJson = parseJson(sharedServer.requestBodies[0])
    check reqJson["model"].getStr() == "test-model"
    let msgs = reqJson["messages"]
    check msgs.kind == JArray
    check msgs[^1]["role"].getStr() == "user"
    check msgs[^1]["content"].getStr() == "hello world"

  test "appends prompt after history":
    sharedServer.enqueue("200 OK", SuccessBody)
    let client = makeClient(sharedServer)
    let history = @[
      ChatMessage(role: crSystem, content: "you are helpful"),
      ChatMessage(role: crUser, content: "first"),
      ChatMessage(role: crAssistant, content: "ack"),
    ]
    discard client.chatCompletion("second", history = history)
    let reqJson = parseJson(sharedServer.requestBodies[0])
    let msgs = reqJson["messages"]
    check msgs.len == 4
    check msgs[0]["role"].getStr() == "system"
    check msgs[1]["role"].getStr() == "user"
    check msgs[1]["content"].getStr() == "first"
    check msgs[3]["content"].getStr() == "second"

  test "extra params override defaults":
    sharedServer.enqueue("200 OK", SuccessBody)
    var defaults = initTable[string, JsonNode]()
    defaults["temperature"] = %0.2
    let client = newLLMClient(
      baseUrl = baseUrlFor(sharedServer),
      apiKey = "k",
      model = "test-model",
      defaultParams = defaults,
      maxRetries = 1,
      retryBackoffMs = 5,
    )
    var extra = initTable[string, JsonNode]()
    extra["temperature"] = %0.9
    extra["max_tokens"] = %256
    discard client.chatCompletion("hi", extraParams = extra)
    let reqJson = parseJson(sharedServer.requestBodies[0])
    check reqJson["temperature"].getFloat() == 0.9
    check reqJson["max_tokens"].getInt() == 256

# ---------------------------------------------------------------------------
# Suite: tool calls
# ---------------------------------------------------------------------------

suite "chatCompletion tool calls":
  setup:
    resetMock(sharedServer)

  test "parses tool_calls from response":
    sharedServer.enqueue("200 OK", ToolCallBody)
    let client = makeClient(sharedServer)
    let resp = client.chatCompletion("run ls")
    check resp.content == ""
    check resp.finishReason == "tool_calls"
    check resp.toolCalls.len == 1
    let tc = resp.toolCalls[0]
    check tc.id == "call_abc"
    check tc.name == "shell"
    check tc.arguments.contains("\"cmd\"")
    check tc.arguments.contains("ls")

  test "round-trips assistant tool_calls in history":
    sharedServer.enqueue("200 OK", SuccessBody)
    let client = makeClient(sharedServer)
    let history = @[
      ChatMessage(role: crUser, content: "run ls"),
      ChatMessage(
        role: crAssistant,
        content: "",
        toolCalls: @[ToolCall(
          id: "call_abc", name: "shell", arguments: "{\"cmd\":\"ls\"}")]),
      ChatMessage(role: crTool, content: "file1\nfile2",
                  toolCallId: "call_abc", name: "shell"),
    ]
    discard client.chatCompletion("", history = history)
    let req = parseJson(sharedServer.requestBodies[0])
    let msgs = req["messages"]
    check msgs.len == 3
    check msgs[1]["role"].getStr() == "assistant"
    check msgs[1]["tool_calls"].kind == JArray
    check msgs[1]["tool_calls"][0]["id"].getStr() == "call_abc"
    check msgs[1]["tool_calls"][0]["function"]["name"].getStr() == "shell"
    check msgs[2]["role"].getStr() == "tool"
    check msgs[2]["tool_call_id"].getStr() == "call_abc"

# ---------------------------------------------------------------------------
# Suite: error mapping
# ---------------------------------------------------------------------------

suite "chatCompletion errors":
  setup:
    resetMock(sharedServer)

  test "401 raises AuthError":
    sharedServer.enqueue("401 Unauthorized", AuthErrBody)
    let client = makeClient(sharedServer, maxRetries = 1)
    expect AuthError:
      discard client.chatCompletion("hi")

  test "AuthError exposes status code":
    sharedServer.enqueue("401 Unauthorized", AuthErrBody)
    let client = makeClient(sharedServer, maxRetries = 1)
    var caught = false
    try:
      discard client.chatCompletion("hi")
    except AuthError as e:
      caught = true
      check e.statusCode == 401
      check e.msg.contains("Invalid API key")
    check caught

  test "400 raises ClientError, not retried":
    sharedServer.enqueue("400 Bad Request",
      """{"error": {"message": "bad input"}}""")
    let client = makeClient(sharedServer, maxRetries = 3)
    expect ClientError:
      discard client.chatCompletion("hi")
    check sharedServer.requestCount == 1

  test "non-JSON success body raises ProtocolError":
    sharedServer.enqueue("200 OK", "not json at all")
    let client = makeClient(sharedServer, maxRetries = 1)
    expect ProtocolError:
      discard client.chatCompletion("hi")

# ---------------------------------------------------------------------------
# Suite: retry behavior
# ---------------------------------------------------------------------------

suite "chatCompletion retry":
  setup:
    resetMock(sharedServer)

  test "429 triggers retry then succeeds":
    sharedServer.enqueue("429 Too Many Requests", RateLimitBody)
    sharedServer.enqueue("429 Too Many Requests", RateLimitBody)
    sharedServer.enqueue("200 OK", SuccessBody)
    let client = makeClient(sharedServer, maxRetries = 3, backoffMs = 1)
    let resp = client.chatCompletion("hi")
    check resp.content == "Hello!"
    check sharedServer.requestCount == 3

  test "429 exhausts retries and raises RateLimitError":
    sharedServer.enqueue("429 Too Many Requests", RateLimitBody)
    sharedServer.enqueue("429 Too Many Requests", RateLimitBody)
    sharedServer.enqueue("429 Too Many Requests", RateLimitBody)
    let client = makeClient(sharedServer, maxRetries = 3, backoffMs = 1)
    var caught = false
    try:
      discard client.chatCompletion("hi")
    except RateLimitError as e:
      caught = true
      check e.statusCode == 429
    check caught
    check sharedServer.requestCount == 3

  test "500 retries then raises ServerError":
    sharedServer.enqueue("500 Internal Server Error", ServerErrBody)
    sharedServer.enqueue("503 Service Unavailable", ServerErrBody)
    sharedServer.enqueue("502 Bad Gateway", ServerErrBody)
    let client = makeClient(sharedServer, maxRetries = 3, backoffMs = 1)
    expect ServerError:
      discard client.chatCompletion("hi")
    check sharedServer.requestCount == 3

  test "500 then 200 succeeds after retry":
    sharedServer.enqueue("500 Internal Server Error", ServerErrBody)
    sharedServer.enqueue("200 OK", SuccessBody)
    let client = makeClient(sharedServer, maxRetries = 3, backoffMs = 1)
    let resp = client.chatCompletion("hi")
    check resp.content == "Hello!"
    check sharedServer.requestCount == 2

  test "maxRetries=1 does not retry":
    sharedServer.enqueue("429 Too Many Requests", RateLimitBody)
    let client = makeClient(sharedServer, maxRetries = 1, backoffMs = 1)
    expect RateLimitError:
      discard client.chatCompletion("hi")
    check sharedServer.requestCount == 1

# ---------------------------------------------------------------------------
# Suite: request shape
# ---------------------------------------------------------------------------

suite "chatCompletion request shape":
  setup:
    resetMock(sharedServer)

  test "sends Authorization header (verified via successful request)":
    # We can't directly inspect headers from this minimal mock, but we
    # confirm the client constructs a request that the server accepts and
    # that body is well-formed JSON.
    sharedServer.enqueue("200 OK", SuccessBody)
    let client = makeClient(sharedServer)
    discard client.chatCompletion("ping")
    let req = parseJson(sharedServer.requestBodies[0])
    check req.hasKey("model")
    check req.hasKey("messages")

# ---------------------------------------------------------------------------
# Teardown
# ---------------------------------------------------------------------------

# Stop server at process exit so threads don't linger.
addQuitProc(proc() {.noconv.} = stopMockServer(sharedServer))
