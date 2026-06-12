## Tests for mercury_core/mcp_client.nim

import std/[unittest, json, asyncdispatch, httpclient]
import mercury_core/mcp_client
import mercury_core/config
import mock_mcp_server

# ---------------------------------------------------------------------------
# Tests: config parsing
# ---------------------------------------------------------------------------

suite "mcp_server_config":
  test "default values":
    let cfg = newMcpServerConfig()
    check cfg.url == "http://localhost:8080/mcp"
    check cfg.authToken == ""
    check cfg.timeoutMs == 30_000
    check cfg.enabled == true

  test "custom values":
    let cfg = newMcpServerConfig(url = "https://mcp.example.com/api",
                                  authToken = "tok123",
                                  timeoutMs = 5000,
                                  enabled = false)
    check cfg.url == "https://mcp.example.com/api"
    check cfg.authToken == "tok123"
    check cfg.timeoutMs == 5000
    check cfg.enabled == false

  test "trailing slash stripped from url":
    let cfg = newMcpServerConfig(url = "http://localhost:8080/mcp/")
    check cfg.url == "http://localhost:8080/mcp"

  test "zero timeout reverts to default":
    let cfg = newMcpServerConfig(timeoutMs = 0)
    check cfg.timeoutMs == 30_000

# ---------------------------------------------------------------------------
# Tests: JSON-RPC helpers
# ---------------------------------------------------------------------------

suite "json_rpc helpers":
  test "jsonRpcRequest with params":
    let req = jsonRpcRequest("tools/list", %*{"verbose": true})
    check req["jsonrpc"].getStr() == "2.0"
    check req["method"].getStr() == "tools/list"
    check req["params"]["verbose"].getBool() == true

  test "jsonRpcRequest without params":
    let req = jsonRpcRequest("initialize")
    check req["jsonrpc"].getStr() == "2.0"
    check req["method"].getStr() == "initialize"
    check req["params"].kind == JObject

  test "jsonRpcResponseId extracts int id":
    let node = parseJson("""{"id":42,"result":{}}""")
    check jsonRpcResponseId(node) == 42

  test "jsonRpcResponseId returns 0 when missing":
    let node = parseJson("""{"result":{}}""")
    check jsonRpcResponseId(node) == 0

# ---------------------------------------------------------------------------
# Tests: McpTool type
# ---------------------------------------------------------------------------

suite "mcp_tool type":
  test "McpTool stores all fields":
    let tool = McpTool(
      server: "http://localhost:8080",
      name: "test_tool",
      description: "A test tool",
      inputSchema: %*{"type": "object", "properties": {"arg": {"type": "string"}}},
    )
    check tool.server == "http://localhost:8080"
    check tool.name == "test_tool"
    check tool.description == "A test tool"
    check tool.inputSchema["type"].getStr() == "object"

# ---------------------------------------------------------------------------
# Tests: McpError hierarchy
# ---------------------------------------------------------------------------

suite "mcp_error hierarchy":
  test "McpConnectionError has serverUrl":
    var err = newException(McpConnectionError, "connection refused")
    err.serverUrl = "http://localhost:9999"
    check err.serverUrl == "http://localhost:9999"
    check err of CatchableError
    check err of McpError

  test "McpProtocolError has serverUrl":
    var err = newException(McpProtocolError, "invalid response")
    err.serverUrl = "http://localhost:8080"
    check err.serverUrl == "http://localhost:8080"

  test "McpToolNotFoundError has serverUrl":
    var err = newException(McpToolNotFoundError, "tool not found")
    err.serverUrl = "http://localhost:8080"
    check err.serverUrl == "http://localhost:8080"

# ---------------------------------------------------------------------------
# Tests: McpClient construction
# ---------------------------------------------------------------------------

suite "mcp_client construction":
  test "newMcpClient sets protocolVersion to empty":
    let cfg = newMcpServerConfig()
    let client = newMcpClient(cfg)
    check client.protocolVersion == ""

  test "newMcpClient stores config":
    let cfg = newMcpServerConfig(url = "http://localhost:9000/mcp",
                                  timeoutMs = 15_000)
    let client = newMcpClient(cfg)
    check client.cfg.url == "http://localhost:9000/mcp"
    check client.cfg.timeoutMs == 15_000

# ---------------------------------------------------------------------------
# Tests: config integration -- McpServerConfig in MercuryConfig
# ---------------------------------------------------------------------------

suite "config integration":
  test "MercuryConfig.mcpServers is empty by default":
    let cfg = defaultConfig()
    check cfg.mcpServers.len == 0

  test "McpServerConfig fields accessible":
    let cfg = McpServerConfig(url: "http://test:9000", authToken: "secret",
                              timeoutMs: 5000, enabled: true)
    check cfg.url == "http://test:9000"
    check cfg.authToken == "secret"
    check cfg.timeoutMs == 5000
    check cfg.enabled == true

# ---------------------------------------------------------------------------
# Integration tests: async mock server x async HTTP client
# These verify the MCP protocol JSON-RPC messages are correctly
# constructed and parsed by communicating with a mock server.
# ---------------------------------------------------------------------------

proc mcpPost(cl: AsyncHttpClient; url: string; body: string): Future[AsyncResponse] =
  ## Helper: POST with Content-Type header.
  let hdrs = newHttpHeaders([("Content-Type", "application/json")])
  result = cl.request(url, httpMethod = HttpPost, body = body, headers = hdrs)

suite "mcp protocol integration":
  test "initialize returns protocol version":
    let mock = newMockMcpServer()
    mock.setInitializeResponse("2024-11-05")
    waitFor mock.start()
    defer: mock.stop()

    let cl = newAsyncHttpClient()
    let resp = waitFor mcpPost(cl, mock.url(), $jsonRpcRequest("initialize", newJObject()))
    let body = waitFor resp.body
    let json = parseJson(body)
    check json["result"]["protocolVersion"].getStr() == "2024-11-05"

  test "listTools returns tool definitions":
    let mock = newMockMcpServer()
    mock.addTool("read_file", "Read a file from disk")
    mock.addTool("write_file", "Write content to disk",
                 """{"type":"object","properties":{"path":{"type":"string"}}}""")
    waitFor mock.start()
    defer: mock.stop()

    let cl = newAsyncHttpClient()
    let resp = waitFor mcpPost(cl, mock.url(), $jsonRpcRequest("tools/list"))
    let body = waitFor resp.body
    let json = parseJson(body)
    check json["result"]["tools"].len == 2
    check json["result"]["tools"][0]["name"].getStr() == "read_file"
    check json["result"]["tools"][1]["name"].getStr() == "write_file"
    check json["result"]["tools"][1]["description"].getStr() == "Write content to disk"

  test "listTools empty when no tools registered":
    let mock = newMockMcpServer()
    waitFor mock.start()
    defer: mock.stop()

    let cl = newAsyncHttpClient()
    let resp = waitFor mcpPost(cl, mock.url(), $jsonRpcRequest("tools/list"))
    let body = waitFor resp.body
    let json = parseJson(body)
    check json["result"]["tools"].len == 0

  test "callTool returns text content":
    let mock = newMockMcpServer()
    mock.setToolCallResult("command output")
    waitFor mock.start()
    defer: mock.stop()

    let cl = newAsyncHttpClient()
    let resp = waitFor mcpPost(cl, mock.url(),
      $jsonRpcRequest("tools/call", %*{"name": "test", "arguments": {}}))
    let body = waitFor resp.body
    let json = parseJson(body)
    check json["result"]["content"][0]["text"].getStr() == "command output"

  test "initialize error returns JSON-RPC error":
    let mock = newMockMcpServer()
    mock.setInitializeError(-32603, "init failed")
    waitFor mock.start()
    defer: mock.stop()

    let cl = newAsyncHttpClient()
    let resp = waitFor mcpPost(cl, mock.url(), $jsonRpcRequest("initialize", newJObject()))
    let body = waitFor resp.body
    let json = parseJson(body)
    check json.hasKey("error")
    check json["error"]["message"].getStr() == "init failed"

  test "callTool error returns JSON-RPC error":
    let mock = newMockMcpServer()
    mock.setToolCallError(-32603, "tool error")
    waitFor mock.start()
    defer: mock.stop()

    let cl = newAsyncHttpClient()
    let resp = waitFor mcpPost(cl, mock.url(),
      $jsonRpcRequest("tools/call", %*{"name": "bad", "arguments": {}}))
    let body = waitFor resp.body
    let json = parseJson(body)
    check json.hasKey("error")
    check json["error"]["message"].getStr() == "tool error"

  test "HTTP error returns error response":
    let mock = newMockMcpServer()
    mock.setHttpError(500)
    waitFor mock.start()
    defer: mock.stop()

    let cl = newAsyncHttpClient()
    let resp = waitFor mcpPost(cl, mock.url(), $jsonRpcRequest("initialize"))
    check $resp.code == "500 Internal Server Error"

  test "unknown method returns method not found":
    let mock = newMockMcpServer()
    waitFor mock.start()
    defer: mock.stop()

    let cl = newAsyncHttpClient()
    let resp = waitFor mcpPost(cl, mock.url(), $jsonRpcRequest("unknown_method"))
    let body = waitFor resp.body
    let json = parseJson(body)
    check json["error"]["code"].getInt() == -32601

  test "request counter tracks requests":
    let mock = newMockMcpServer()
    waitFor mock.start()
    defer: mock.stop()

    let cl = newAsyncHttpClient()
    discard waitFor mcpPost(cl, mock.url(), $jsonRpcRequest("initialize"))
    discard waitFor mcpPost(cl, mock.url(), $jsonRpcRequest("tools/list"))
    check mock.requestCount == 2
