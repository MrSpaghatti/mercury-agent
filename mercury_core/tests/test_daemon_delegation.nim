import unittest, asyncdispatch, options, strutils
import mercury_core/agent_dispatcher
import mercury_core/discord_types
import mercury_core/config
import mercury_core/tool_registry
import mock_llm_server

suite "daemon delegation config":
  test "daemonDelegation defaults to false":
    let cfg = defaultDiscordConfig()
    check cfg.daemonDelegation == false

  test "daemonDelegation can be set to true":
    var cfg = defaultDiscordConfig()
    cfg.daemonDelegation = true
    check cfg.daemonDelegation == true

const SuccessBody = """
{
  "id": "chatcmpl-1",
  "object": "chat.completion",
  "model": "test-model",
  "choices": [{
    "index": 0,
    "message": {"role": "assistant", "content": "hello from agent"},
    "finish_reason": "stop"
  }],
  "usage": {"prompt_tokens": 5, "completion_tokens": 3, "total_tokens": 8}
}
"""

suite "agent dispatcher — production path (real runAgentLoop)":
  setup:
    var server {.inject.} = startMockServer()

  teardown:
    stopMockServer(server)

  test "dispatcher runs a real agent loop and produces a result via callback":
    server.enqueue("200 OK", SuccessBody)
    var received: agent_dispatcher.AgentResult
    let cb = proc(r: agent_dispatcher.AgentResult) {.gcsafe, closure, raises: [].} =
      {.cast(gcsafe), cast(raises: []).}:
        received = r

    let dispatcher = newAgentDispatcher(
      cb, defaultConfig(), makeClient(server), newToolRegistry(), ":memory:")
    let request = AgentRequest(
      userInput: "hello",
      sessionId: "sess_1",
      channelId: "chan_1",
      threadId: "thread_1"
    )
    waitFor dispatchAgent(dispatcher, request)
    check received.responseText == "hello from agent"
    check received.error.isNone
    check received.channelId == "chan_1"

  test "dispatcher propagates LLM errors as AgentResult.error":
    server.enqueue("500 Internal Server Error",
      """{"error": {"message": "upstream exploded"}}""")
    var received: agent_dispatcher.AgentResult
    let cb = proc(r: agent_dispatcher.AgentResult) {.gcsafe, closure, raises: [].} =
      {.cast(gcsafe), cast(raises: []).}:
        received = r

    let dispatcher = newAgentDispatcher(
      cb, defaultConfig(), makeClient(server, maxRetries = 1),
      newToolRegistry(), ":memory:")
    let request = AgentRequest(
      userInput: "test",
      sessionId: "sess_2",
      channelId: "chan_2",
      threadId: "thread_2"
    )
    waitFor dispatchAgent(dispatcher, request)
    check received.error.isSome
    check received.channelId == "chan_2"

  test "dispatcher sends the real user input to the LLM":
    server.enqueue("200 OK", SuccessBody)
    let cb = proc(r: agent_dispatcher.AgentResult) {.gcsafe, closure, raises: [].} = discard

    let dispatcher = newAgentDispatcher(
      cb, defaultConfig(), makeClient(server), newToolRegistry(), ":memory:")
    let request = AgentRequest(
      userInput: "custom input",
      sessionId: "sess_3",
      channelId: "chan_3",
      threadId: "thread_3"
    )
    waitFor dispatchAgent(dispatcher, request)
    check server.requestCount == 1
    check "custom input" in server.requestBodies[0]

  test "callback receives result synchronously":
    server.enqueue("200 OK", SuccessBody)
    var resultReceived = false
    let cb = proc(r: agent_dispatcher.AgentResult) {.gcsafe, closure, raises: [].} =
      {.cast(gcsafe), cast(raises: []).}:
        resultReceived = true

    let dispatcher = newAgentDispatcher(
      cb, defaultConfig(), makeClient(server), newToolRegistry(), ":memory:")
    let request = AgentRequest(
      userInput: "sync test",
      sessionId: "sess_4",
      channelId: "chan_4",
      threadId: "thread_4"
    )
    waitFor dispatchAgent(dispatcher, request)
    check resultReceived == true

  test "turnCallback fires once per ReAct turn with the request's channelId":
    server.enqueue("200 OK", SuccessBody)
    var turnCalls: seq[string] = @[]
    let cb = proc(r: agent_dispatcher.AgentResult) {.gcsafe, closure, raises: [].} = discard
    let turnCb = proc(channelId: string) {.gcsafe, closure, raises: [].} =
      {.cast(gcsafe), cast(raises: []).}:
        turnCalls.add(channelId)

    let dispatcher = newAgentDispatcher(
      cb, defaultConfig(), makeClient(server), newToolRegistry(), ":memory:",
      turnCallback = turnCb)
    let request = AgentRequest(
      userInput: "hello",
      sessionId: "sess_5",
      channelId: "chan_typing",
      threadId: "thread_5"
    )
    waitFor dispatchAgent(dispatcher, request)
    check turnCalls == @["chan_typing"]

suite "agent dispatcher — placeholder path (no cfg/llm)":
  test "echoes input back when constructed without production args":
    var received: agent_dispatcher.AgentResult
    let cb = proc(r: agent_dispatcher.AgentResult) {.gcsafe, closure, raises: [].} =
      {.cast(gcsafe), cast(raises: []).}:
        received = r
    let dispatcher = newAgentDispatcher(cb)
    let request = AgentRequest(userInput: "echo me", channelId: "chan_5")
    waitFor dispatchAgent(dispatcher, request)
    check received.responseText == "Agent response for: echo me"
    check received.error.isNone
