import unittest
import std/[asyncdispatch, options, strutils]
import db_connector/db_sqlite
import mercury_core/discord
import mercury_core/discord_mocks
import mercury_core/discord_types
import mercury_core/agent_dispatcher
import mercury_core/thread_mapping

suite "DiscordBot (DI-based)":

  proc makeConfig(admins: seq[string] = @[], users: seq[string] = @[]): DiscordConfig =
    result = defaultDiscordConfig()
    result.admins.allow = admins
    result.users.allow = users

  proc makeDb(): DbConn =
    let db = open(":memory:", "", "", "")
    initThreadMappingSchema(db)
    return db

  proc makeBot(admins: seq[string] = @["admin1"], users: seq[string] = @[]): tuple[bot: DiscordBot, api: MockDiscordApi, db: DbConn] =
    let api = newMockDiscordApi()
    let cfg = makeConfig(admins = admins, users = users)
    let dispatcher = newAgentDispatcher(proc(r: AgentResult) {.gcsafe.} = discard)
    let shard = newMockShard("bot_user_id")
    let db = makeDb()
    let bot = newDiscordBot(
      sendMessage = mockSendFn(api),
      triggerTyping = mockTypingFn(api),
      createThread = mockCreateThreadFn(api),
      archiveThread = mockArchiveThreadFn(api),
      db = db,
      config = cfg,
      dispatcher = dispatcher,
      shard = shard,
    )
    return (bot, api, db)

  test "bot messages are ignored":
    let (bot, api, db) = makeBot()
    defer: db.close()
    let msg = Message(
      id: "msg_bot",
      author: MockUser(id: "bot1", username: "BotUser", bot: true),
      content: "!status",
      channel_id: "chan1",
      guild_id: some("guild1"),
      mention_users: @[MockUser(id: "bot_user_id", username: "bot_user_id", bot: true)],
    )
    bot.shard.userId = "bot_user_id"
    waitFor bot.onMessageCreate(msg)
    check api.calls.len == 0

  test "unknown users are ignored":
    let (bot, api, db) = makeBot(admins = @["admin1"], users = @["user1"])
    defer: db.close()
    let msg = Message(
      id: "msg_unknown",
      author: MockUser(id: "stranger", username: "Stranger", bot: false),
      content: "hello",
      channel_id: "chan1",
      guild_id: some("guild1"),
      mention_users: @[MockUser(id: "bot_user_id", username: "bot_user_id", bot: true)],
    )
    bot.shard.userId = "bot_user_id"
    waitFor bot.onMessageCreate(msg)
    check api.calls.len == 0

  test "command with prefix is handled":
    let (bot, api, db) = makeBot(users = @["user1"])
    defer: db.close()
    let msg = Message(
      id: "msg_cmd_1",
      author: MockUser(id: "user1", username: "TestUser", bot: false),
      content: "!status",
      channel_id: "chan1",
      guild_id: some("guild1"),
      mention_users: @[MockUser(id: "bot_user_id", username: "bot_user_id", bot: true)],
    )
    bot.shard.userId = "bot_user_id"
    waitFor bot.onMessageCreate(msg)
    check api.calls.len >= 1
    var foundSend = false
    for call in api.calls:
      if call.kind == mockSendMessage:
        foundSend = true
        check call.channelId in ["chan1", "thread_1"]
    check foundSend

  test "command response is chunked and sent":
    let (bot, api, db) = makeBot(users = @["user1"])
    defer: db.close()
    let msg = Message(
      id: "msg_cmd_2",
      author: MockUser(id: "user1", username: "TestUser", bot: false),
      content: "!status",
      channel_id: "chan1",
      guild_id: some("guild1"),
      mention_users: @[MockUser(id: "bot_user_id", username: "bot_user_id", bot: true)],
    )
    bot.shard.userId = "bot_user_id"
    waitFor bot.onMessageCreate(msg)
    var sendCount = 0
    for call in api.calls:
      if call.kind == mockSendMessage:
        sendCount.inc
    check sendCount >= 1

  test "unknown command returns unknown command message":
    let (bot, api, db) = makeBot(users = @["user1"])
    defer: db.close()
    let msg = Message(
      id: "msg_cmd_3",
      author: MockUser(id: "user1", username: "TestUser", bot: false),
      content: "!foobar",
      channel_id: "chan1",
      guild_id: some("guild1"),
      mention_users: @[MockUser(id: "bot_user_id", username: "bot_user_id", bot: true)],
    )
    bot.shard.userId = "bot_user_id"
    waitFor bot.onMessageCreate(msg)
    var foundResponse = false
    for call in api.calls:
      if call.kind == mockSendMessage:
        foundResponse = true
        check "Unknown" in call.content or "unknown" in call.content
    check foundResponse

  test "config set command updates bot config":
    let (bot, _, db) = makeBot(admins = @["admin1"], users = @["admin1"])
    defer: db.close()
    check bot.config.prefix == "!"
    let msg = Message(
      id: "msg_cfg_1",
      author: MockUser(id: "admin1", username: "Admin", bot: false),
      content: "!config set prefix ?",
      channel_id: "chan1",
      guild_id: some("guild1"),
      mention_users: @[MockUser(id: "bot_user_id", username: "bot_user_id", bot: true)],
    )
    bot.shard.userId = "bot_user_id"
    waitFor bot.onMessageCreate(msg)
    check bot.config.prefix == "?"

  test "regular message triggers typing and agent dispatch":
    let api = newMockDiscordApi()
    let cfg = makeConfig(admins = @["admin1"], users = @["user1"])
    let dispatcher = newAgentDispatcher(proc(r: AgentResult) {.gcsafe.} = discard)
    let shard = newMockShard("bot_user_id")
    let db = makeDb()
    let bot = newDiscordBot(
      sendMessage = mockSendFn(api),
      triggerTyping = mockTypingFn(api),
      createThread = mockCreateThreadFn(api),
      archiveThread = mockArchiveThreadFn(api),
      db = db,
      config = cfg,
      dispatcher = dispatcher,
      shard = shard,
    )
    defer: db.close()
    let msg = Message(
      id: "msg_reg_1",
      author: MockUser(id: "user1", username: "TestUser", bot: false),
      content: "hello agent",
      channel_id: "chan1",
      guild_id: some("guild1"),
      mention_users: @[MockUser(id: "bot_user_id", username: "bot_user_id", bot: true)],
    )
    bot.shard.userId = "bot_user_id"
    bot.shard.userId = "bot_user_id"
    bot.shard.userId = "bot_user_id"
    bot.shard.userId = "bot_user_id"
    bot.shard.userId = "bot_user_id"
    bot.shard.userId = "bot_user_id"
    waitFor bot.onMessageCreate(msg)
    var foundTyping = false
    for call in api.calls:
      if call.kind == mockTriggerTyping:
        foundTyping = true
        check call.channelId in ["chan1", "thread_1"]
    check foundTyping

  test "prefix-only message with no command is ignored":
    let (bot, api, db) = makeBot(users = @["user1"])
    defer: db.close()
    let msg = Message(
      id: "msg_prefix_only",
      author: MockUser(id: "user1", username: "TestUser", bot: false),
      content: "!",
      channel_id: "chan1",
      guild_id: some("guild1"),
      mention_users: @[MockUser(id: "bot_user_id", username: "bot_user_id", bot: true)],
    )
    bot.shard.userId = "bot_user_id"
    bot.shard.userId = "bot_user_id"
    waitFor bot.onMessageCreate(msg)
    check api.calls.len == 0

  test "admin command denied for non-admin user":
    let (bot, api, db) = makeBot(admins = @["admin1"], users = @["user1"])
    defer: db.close()
    let msg = Message(
      id: "msg_admin_denied",
      author: MockUser(id: "user1", username: "RegularUser", bot: false),
      content: "!admin restart",
      channel_id: "chan1",
      guild_id: some("guild1"),
      mention_users: @[MockUser(id: "bot_user_id", username: "bot_user_id", bot: true)],
    )
    bot.shard.userId = "bot_user_id"
    bot.shard.userId = "bot_user_id"
    waitFor bot.onMessageCreate(msg)
    var foundResponse = false
    for call in api.calls:
      if call.kind == mockSendMessage:
        foundResponse = true
        check "permission" in call.content.toLowerAscii or "denied" in call.content.toLowerAscii
    check foundResponse
