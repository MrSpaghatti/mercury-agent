import unittest, asyncdispatch, options, strutils

when defined(warningOffGcUnsafe):
  import mercury_core/agent_dispatcher
  import mercury_core/discord_types
else:
  import mercury_core/agent_dispatcher
  import mercury_core/discord_types

suite "Agent Dispatcher":
  test "creates dispatcher with callback":
    when defined(warningOffGcUnsafe):
      var receivedResult: AgentResult  # used with GcUnsafe suppressed
      let cb = proc(result: AgentResult) {.gcsafe, closure, noSideEffect.} =
        receivedResult = result
      let dispatcher = newAgentDispatcher(cb)
      check dispatcher != nil
    else:
      let storage = new(AgentResult)
      let cb = proc(result: AgentResult) {.gcsafe, closure.} =
        storage[] = result
      let dispatcher = newAgentDispatcher(cb)
      check dispatcher != nil

  test "dispatchAgent returns result via callback":
    when defined(warningOffGcUnsafe):
      var receivedResult: AgentResult
      let cb = proc(result: AgentResult) {.gcsafe, closure, noSideEffect.} =
        receivedResult = result
      let dispatcher = newAgentDispatcher(cb)
      let request = AgentRequest(
        userInput: "hello",
        sessionId: "sess_1",
        channelId: "chan_1",
        threadId: "thread_1"
      )
      waitFor dispatchAgent(dispatcher, request)
      check receivedResult.responseText.contains("hello")
      check receivedResult.error.isNone
    else:
      let storage = new(AgentResult)
      let cb = proc(result: AgentResult) {.gcsafe, closure.} =
        storage[] = result
      let dispatcher = newAgentDispatcher(cb)
      let request = AgentRequest(
        userInput: "hello",
        sessionId: "sess_1",
        channelId: "chan_1",
        threadId: "thread_1"
      )
      waitFor dispatchAgent(dispatcher, request)
      check storage[].responseText.contains("hello")
      check storage[].error.isNone

  test "startDispatcher and stopDispatcher are no-ops":
    let dispatcher = newAgentDispatcher(nil)
    startDispatcher(dispatcher)
    stopDispatcher(dispatcher)
    check true  # Just verify no crash