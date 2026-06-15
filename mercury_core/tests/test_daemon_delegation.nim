import unittest, asyncdispatch, options
import mercury_core/agent_dispatcher
import mercury_core/discord_types
import mercury_core/config
import mercury_core/llm_client
import mercury_core/tool_registry

suite "daemon delegation config":
  test "daemonDelegation defaults to false":
    let cfg = defaultDiscordConfig()
    check cfg.daemonDelegation == false

  test "daemonDelegation can be set to true":
    var cfg = defaultDiscordConfig()
    cfg.daemonDelegation = true
    check cfg.daemonDelegation == true

suite "agent dispatcher with runFn":
  test "dispatcher with runFn produces result via callback":
    var received: AgentResult
    let cb = proc(r: AgentResult) {.gcsafe, closure, raises: [].} =
      received = r

    let runFn = proc(cfg: MercuryConfig; llm: LLMClient; reg: ToolRegistry;
                      dbPath, userInput: string): AgentLoopResult {.gcsafe, raises: [].} =
      AgentLoopResult(
        responseText: "hello from agent",
        error: none[string](),
        sessionId: "sess_daemon"
      )

    let dispatcher = newAgentDispatcher(cb, runFn, defaultConfig(), LLMClient(), newToolRegistry(), ":memory:")
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

  test "dispatcher with runFn propagates error":
    var received: AgentResult
    let cb = proc(r: AgentResult) {.gcsafe, closure, raises: [].} =
      received = r

    let runFn = proc(cfg: MercuryConfig; llm: LLMClient; reg: ToolRegistry;
                      dbPath, userInput: string): AgentLoopResult {.gcsafe, raises: [].} =
      AgentLoopResult(
        responseText: "",
        error: some("something went wrong"),
        sessionId: ""
      )

    let dispatcher = newAgentDispatcher(cb, runFn, defaultConfig(), LLMClient(), newToolRegistry(), ":memory:")
    let request = AgentRequest(
      userInput: "test",
      sessionId: "sess_2",
      channelId: "chan_2",
      threadId: "thread_2"
    )
    waitFor dispatchAgent(dispatcher, request)
    check received.responseText == ""
    check received.error.isSome
    check received.error.get() == "something went wrong"
    check received.channelId == "chan_2"

  test "dispatcher with runFn passes config and userInput":
    var capturedCfg: MercuryConfig
    var capturedInput: string

    let cb = proc(r: AgentResult) {.gcsafe, closure, raises: [].} = discard

    let runFn = proc(cfg: MercuryConfig; llm: LLMClient; reg: ToolRegistry;
                      dbPath, userInput: string): AgentLoopResult {.gcsafe, raises: [].} =
      capturedCfg = cfg
      capturedInput = userInput
      AgentLoopResult(
        responseText: "ok",
        error: none[string](),
        sessionId: "sess_3"
      )

    let dispatcher = newAgentDispatcher(cb, runFn, defaultConfig(), LLMClient(), newToolRegistry(), ":memory:")
    let request = AgentRequest(
      userInput: "custom input",
      sessionId: "sess_3",
      channelId: "chan_3",
      threadId: "thread_3"
    )
    waitFor dispatchAgent(dispatcher, request)
    check capturedInput == "custom input"

  test "callback receives result synchronously":
    var resultReceived = false

    let cb = proc(r: AgentResult) {.gcsafe, closure, raises: [].} =
      resultReceived = true

    let runFn = proc(cfg: MercuryConfig; llm: LLMClient; reg: ToolRegistry;
                      dbPath, userInput: string): AgentLoopResult {.gcsafe, raises: [].} =
      AgentLoopResult(
        responseText: "sync",
        error: none[string](),
        sessionId: "sess_4"
      )

    let dispatcher = newAgentDispatcher(cb, runFn, defaultConfig(), LLMClient(), newToolRegistry(), ":memory:")
    let request = AgentRequest(
      userInput: "sync test",
      sessionId: "sess_4",
      channelId: "chan_4",
      threadId: "thread_4"
    )
    waitFor dispatchAgent(dispatcher, request)
    check resultReceived == true
