## Mercury agent dispatcher.
##
## Bridges the async Dimscord event loop with synchronous agent processing.
## The dispatcher receives an AgentRunFn from mercury_agent (cmdDaemon) and
## calls it synchronously inside dispatchAgent. This blocks the Discord
## event loop during agent execution — acceptable for a single-user bot.
##
## TODO: Use a dedicated worker thread once dimscord's GC-safety issues
## with --threads:on are resolved. The thread-spawn infrastructure is
## designed but not wired because dimscord cannot currently be compiled
## with --threads:on (see config.nims).

import std/[asyncdispatch, options]
import config, llm_client, tool_registry

type
  AgentRequest* = object
    userInput*: string
    sessionId*: string
    channelId*: string
    threadId*: string

  AgentResult* = object
    responseText*: string
    error*: Option[string]
    channelId*: string

  AgentCallback* = proc(result: AgentResult) {.gcsafe, raises: [].}

  AgentRunFn* = proc(cfg: MercuryConfig; llm: LLMClient; reg: ToolRegistry;
                      dbPath, userInput: string): AgentLoopResult {.gcsafe, raises: [].}

  AgentLoopResult* = object  ## Matches agent_loop.nim's AgentResult shape
    responseText*: string
    error*: Option[string]
    sessionId*: string

  AgentDispatcher* = ref object
    callback*: AgentCallback
    runFn*: AgentRunFn
    cfg*: MercuryConfig
    llm*: LLMClient
    reg*: ToolRegistry
    dbPath*: string

proc newAgentDispatcher*(callback: AgentCallback): AgentDispatcher =
  ## Simplified constructor for tests. The dispatcher will echo back the
  ## request (placeholder behaviour) if no runFn is provided.
  AgentDispatcher(callback: callback)

proc newAgentDispatcher*(callback: AgentCallback; runFn: AgentRunFn;
                          cfg: MercuryConfig; llm: LLMClient;
                          reg: ToolRegistry; dbPath: string): AgentDispatcher =
  ## Full constructor for production use (mercury daemon).
  ## The callback is invoked on the event-loop thread when processing completes.
  ## The runFn must wrap runAgentLoop (injected from mercury_agent).
  AgentDispatcher(
    callback: callback, runFn: runFn, cfg: cfg, llm: llm, reg: reg, dbPath: dbPath
  )

proc dispatchAgent*(dispatcher: AgentDispatcher; request: AgentRequest): Future[void] {.async, gcsafe.} =
  ## Dispatches an agent request. If a runFn is configured (production daemon),
  ## calls it synchronously. Otherwise echoes the input back (placeholder
  ## behaviour used in unit tests).
  ##
  ## FUTURE: This should spawn a worker thread. Blocked on dimscord's
  ## GC-safety with --threads:on.
  let result =
    if dispatcher.runFn != nil:
      let agentResult = dispatcher.runFn(dispatcher.cfg, dispatcher.llm, dispatcher.reg,
                                          dispatcher.dbPath, request.userInput)
      AgentResult(
        responseText: agentResult.responseText,
        error: agentResult.error,
        channelId: request.channelId
      )
    else:
      # Placeholder: used by tests that construct via newAgentDispatcher(callback)
      AgentResult(
        responseText: "Agent response for: " & request.userInput,
        error: none[string](),
        channelId: request.channelId
      )

  if dispatcher.callback != nil:
    dispatcher.callback(result)

proc startDispatcher*(dispatcher: AgentDispatcher) =
  ## Starts the dispatcher. Currently a no-op.
  discard

proc stopDispatcher*(dispatcher: AgentDispatcher) =
  ## Stops the dispatcher. Currently a no-op.
  discard
