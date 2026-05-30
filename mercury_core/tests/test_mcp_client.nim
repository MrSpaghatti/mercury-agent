## Tests for mercury_core/mcp_client.nim

import std/[unittest, httpclient, json, strutils, os]
import mercury_core/mcp_client
import mercury_core/config

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

proc makeMinimalServer(): string =
  ## Returns a minimal MCP server URL for testing. In tests, we validate
  ## that the client constructs requests correctly and handles responses
  ## even when no live server is available.
  result = "http://localhost:19999/mcp"

proc validInitializeResponse(): string =
  ## A valid JSON-RPC initialize response.
  """{"jsonrpc":"2.0","id":1,"result":{"protocolVersion":"2024-11-05","capabilities":{},"serverInfo":{"name":"test-mcp","version":"1.0.0"}}}"""

proc validToolsListResponse(tools: JsonNode): string =
  "{\"jsonrpc\":\"2.0\",\"id\":2,\"result\":{\"tools\":" & $tools & "}}"

proc validToolCallResponse(text: string): string =
  """{"jsonrpc":"2.0","id":3,"result":{"content":[{"type":"text","text":""" & $text & """}]}}"""

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
# Tests: config integration — McpServerConfig in MercuryConfig
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