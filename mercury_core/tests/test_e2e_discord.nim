import unittest
import std/[asyncdispatch, options, os, strutils, json]
import db_connector/db_sqlite

import mercury_core/[discord, discord_mocks, discord_types, discord_commands,
  permission, agent_dispatcher, file_tool, file_path_validator, thread_mapping, tool_registry]

suite "End-to-end Discord Integration":
  var
    db: DbConn
    api: MockDiscordApi
    bot: DiscordBot
    shard: MockShard
    dispatcher: AgentDispatcher
    config: DiscordConfig

  setup:
    db = open(":memory:", "", "", "")
    initThreadMappingSchema(db)

    api = newMockDiscordApi()
    shard = newMockShard("bot_user_id")

    config = defaultDiscordConfig()
    config.admins.allow.add("admin_user")
    config.users.allow.add("regular_user")

    dispatcher = newAgentDispatcher(proc(res: AgentResult) =
      discard waitFor api.sendMessage(res.channelId, res.responseText)
    )

    bot = newDiscordBot(
      sendMessage = mockSendFn(api),
      triggerTyping = mockTypingFn(api),
      createThread = mockCreateThreadFn(api),
      archiveThread = mockArchiveThreadFn(api),
      db = db,
      config = config,
      dispatcher = dispatcher,
      shard = shard
    )

  teardown:
    db.close()

  test "Mention creates thread and dispatches agent":
    let msg = makeMessage("regular_user", "Hello bot!", "channel_1", "guild_1", @["bot_user_id"])
    waitFor onMessageCreate(bot, msg)
    waitFor sleepAsync(150) # wait for dispatcher callback

    var typingCount = 0
    var threadCreated = false
    var responseSent = false

    for call in api.calls:
      if call.kind == mockTriggerTyping:
        typingCount.inc
      if call.kind == mockCreateThread:
        threadCreated = true
        check call.channelId == "channel_1"
      if call.kind == mockSendMessage:
        responseSent = true
        check "Agent response for: Hello bot!" in call.content

    check threadCreated
    check responseSent

  test "Message in existing thread continues session":
    # First, setup an existing thread
    let sessionId = "test_session_1"
    setThreadMapping(db, "thread_1", sessionId, "channel_1", "guild_1")

    let msg = makeMessage("regular_user", "Next message", "thread_1", "guild_1", @[])
    waitFor onMessageCreate(bot, msg)
    waitFor sleepAsync(150)

    # Should NOT create a new thread. Should trigger typing in thread_1 and send response there.
    var newThreadCount = 0
    var typingInThread = false
    var responseSent = false

    for call in api.calls:
      if call.kind == mockCreateThread:
        newThreadCount.inc
      if call.kind == mockTriggerTyping and call.channelId == "thread_1":
        typingInThread = true
      if call.kind == mockSendMessage and call.channelId == "thread_1":
        responseSent = true

    check newThreadCount == 0
    check typingInThread
    check responseSent

  test "Bot commands: !status, !admin restart, !config set":
    let statusMsg = makeMessage("regular_user", "!status", "channel_1", "guild_1", @[])
    waitFor onMessageCreate(bot, statusMsg)

    var statusFound = false
    for call in api.calls:
      if call.kind == mockSendMessage and "status" in call.content.toLowerAscii:
        statusFound = true
    check statusFound

    api.calls = @[]
    
    let adminRestart = makeMessage("regular_user", "!admin restart", "channel_1", "guild_1", @[])
    waitFor onMessageCreate(bot, adminRestart)
    
    var deniedFound = false
    for call in api.calls:
      if call.kind == mockSendMessage and "permission denied" in call.content.toLowerAscii:
        deniedFound = true
    check deniedFound

    api.calls = @[]

    let configSet = makeMessage("admin_user", "!config set prefix ?", "channel_1", "guild_1", @[])
    waitFor onMessageCreate(bot, configSet)
    
    check bot.config.prefix == "?"
    
  test "File tool configuration":
    # Let's write dummy files
    writeFile("test_allowed.txt", "allowed")
    writeFile(".env_test", "secret")
    
    let rules = FileRules(
      sandboxDir: getCurrentDir(),
      allowPatterns: @["*"],
      askPatterns: @[],
      denyPatterns: @[".env*"]
    )

    let readTool = fileReadTool(rules)

    let allowedArgs = %*{"path": "test_allowed.txt"}
    let allowedResult = readTool.execute(allowedArgs)
    check "allowed" in allowedResult.output

    let deniedArgs = %*{"path": ".env_test"}
    let deniedResult = readTool.execute(deniedArgs)
    check "Access denied" in deniedResult.output
    
    removeFile("test_allowed.txt")
    removeFile(".env_test")

  test "Thread archival behavior":
    let msg1 = makeMessage("regular_user", "Hello first", "channel_1", "guild_1", @["bot_user_id"])
    waitFor onMessageCreate(bot, msg1)
    waitFor sleepAsync(150)
    
    var firstThreadId = ""
    for call in api.calls:
      if call.kind == mockCreateThread:
        firstThreadId = call.threadId
        
    check firstThreadId != ""
    
    # Archive the thread via thread_mapping directly
    archiveThread(db, firstThreadId)
    
    api.calls = @[]
    
    # Now user mentions bot again in channel_1
    let msg2 = makeMessage("regular_user", "Hello again", "channel_1", "guild_1", @["bot_user_id"])
    waitFor onMessageCreate(bot, msg2)
    waitFor sleepAsync(150)
    
    # It should create a NEW thread but reuse the same session
    var secondThreadId = ""
    var continueFound = false
    for call in api.calls:
      if call.kind == mockCreateThread:
        secondThreadId = call.threadId
      if call.kind == mockSendMessage and "Continuing from previous session" in call.content:
        continueFound = true
        
    check secondThreadId != ""
    check secondThreadId != firstThreadId
    check continueFound
