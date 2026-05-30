## Mercury agent dispatcher.
##
## Bridges the async Dimscord event loop with synchronous agent processing.
## Uses a simple callback-based approach: the Discord bot calls dispatchAgent
## which runs the agent in a background thread and returns the result via
## a callback when complete.

import std/[asyncdispatch, options]

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

  AgentDispatcher* = ref object
    callback*: AgentCallback

proc newAgentDispatcher*(callback: AgentCallback): AgentDispatcher =
  ## Creates a new agent dispatcher with the given callback.
  ## The callback is invoked when agent processing completes.
  ## Requires gcsafe callback for Nim 2.2.x async GC-safety.
  AgentDispatcher(callback: callback)

proc dispatchAgent*(dispatcher: AgentDispatcher, request: AgentRequest) {.async, gcsafe.} =
  ## Dispatches an agent request. Currently a placeholder that simulates
  ## async processing. The actual agent integration will be wired in Task 4.16.
  ##
  ## In the full implementation, this would:
  ## 1. Spawn a thread with a new DB connection
  ## 2. Run the agent loop in that thread
  ## 3. Send result back via Channel
  ## 4. Invoke the callback with the result
  ##
  ## For now, we simulate a brief delay and return a placeholder response
  ## to allow the Discord bot to be tested end-to-end.
  await sleepAsync(100)  # Simulate processing delay

  let result = AgentResult(
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