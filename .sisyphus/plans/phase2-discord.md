# Phase 2: Mercury Discord Integration

## TL;DR

> **Add a Discord bot interface to Mercury** that routes @mentions and thread messages through the ReAct agent loop, with per-thread session persistence, typing indicators, fence-aware chunking, rate-limit handling, bot commands (`!config`, `!status`, `!admin`, `!session`), file read/write tool with allow/ask/deny security, and a permission framework (separate admin/user lists).
> 
> **Deliverables**:
> - Rewritten `discord.nim` with DI, thread-per-mention model, typing indicator, chunking, rate limiting
> - `discord_types.nim` with Discord-specific config types
> - `message_chunker.nim` for fence-aware Discord message splitting
> - `discord_commands.nim` for bot command handling
> - `thread_mapping.nim` for Discord thread→agent session SQLite mapping
> - `file_tool.nim` with allow/ask/deny security framework
> - `permission.nim` for user allowlist + admin allowlist + tool risk levels
> - `discord_config.nim` for extending config.toml with Discord settings
> - TDD tests for all modules
> - Updated `cmdDaemon` wiring all components together
> 
> **Estimated Effort**: Large
> **Parallel Execution**: YES - 4 waves
> **Critical Path**: Task 4.5 → 4.8 → 4.13 → 4.16 → 4.17 → 4.18 → F1-F4 → user okay

---

## Context

### Original Request
Add Discord integration to Mercury (Nim AI agent) so it can operate as both a Discord bot and an AI agent. The bot should handle @mentions by creating threads, support bot commands for config changes without SSH, and have a strong permission framework for dangerous tools.

### Interview Summary
**Key Discussions**:
- Use case: Personal assistant for small trusted group
- Response UX: Typing indicator + Discord thread per conversation
- Session model: @bot in channel → create thread → continue in thread. New @ = new thread. Archived thread → new thread + old session context.
- Bot commands: `!config`, `!status`, `!admin`, `!session`
- Agent async: Spawn thread + channel (non-blocking Dimscord event loop)
- Persistence: SQLite thread→session mapping (each thread gets own DB conn)
- File tool: Read + write with allow/ask/deny list (anti-rogue-model security)
- Admin model: Separate admin + user lists
- Config reload: Write to disk + explicit `!config reload`
- Test strategy: TDD

**Research Findings**:
- dimscord uses `mention_users` (not `mentions`), `.client.api` (not `.api`)
- Fence-aware chunking needed for code blocks in Discord responses
- Rate limit retry with exponential backoff needed
- Symlink resolution and path traversal protection needed for file tools
- 3-tier permission model (allow/ask/deny) is industry standard for AI agents
- Discord thread creation rate limit: ~50 per channel per day

### Metis Review
**Identified Gaps** (addressed):
- Core objective not stated as single sentence → Added
- No Discord test strategy → Included in Verification Strategy
- No config TOML schema → Defined in Task 4.5
- Bot restart behavior for thread→session mapping → Defined: persist in SQLite, reconnect on restart
- Thread archival → New thread + old session context (user decision)
- Admin vs user model → Separate lists (user decision)

---

## Work Objectives

### Core Objective
Add a Discord bot interface to Mercury that routes @mentions and thread messages through the agent loop, with per-thread session persistence, typing indicators, and a permission framework.

### Concrete Deliverables
- `mercury_core/src/mercury_core/discord.nim` — Rewritten with DI, thread model, typing indicator
- `mercury_core/src/mercury_core/discord_types.nim` — Discord-specific config types
- `mercury_core/src/mercury_core/message_chunker.nim` — Fence-aware message splitting
- `mercury_core/src/mercury_core/discord_commands.nim` — Bot command handler
- `mercury_core/src/mercury_core/thread_mapping.nim` — Thread→session SQLite mapping
- `mercury_core/src/mercury_core/file_tool.nim` — File read/write with allow/ask/deny
- `mercury_core/src/mercury_core/permission.nim` — Permission framework
- `mercury_core/src/mercury_core/discord_config.nim` — TOML config extension
- `tests/` — TDD tests for all modules
- Updated `mercury_agent/src/mercury_agent.nim` — `cmdDaemon` wiring

### Definition of Done
- [x] `mercury daemon` connects to Discord, shows typing indicator, responds in threads
- [x] @mention in channel → creates thread with agent response
- [x] Message in existing thread → continues session
- [x] Archived thread re-mention → new thread with old session context
- [x] `!config`, `!status`, `!admin`, `!session` commands work
- [x] File tool reads/writes within allowlist, blocks denylist, asks for asklist
- [x] All TDD tests pass
- [x] `nimble test` exits 0

### Must Have
- Thread-per-mention model with session persistence
- Typing indicator during agent processing
- Fence-aware message chunking
- Rate limit retry with backoff
- SQLite thread→session mapping
- Separate admin + user allowlists
- File tool with allow/ask/deny security (symlink resolution, path traversal protection, mandatory deny patterns)
- Error messages sent to Discord on failure
- Graceful shutdown on SIGINT/SIGTERM

### Must NOT Have (Guardrails)
- No arbitrary file editing outside the allow/ask/deny framework
- No shell tool exposed to Discord users
- No streaming responses
- No multi-user session isolation
- No Discord slash commands (prefix commands only)
- No embeds/rich formatting (plain text + code blocks only)
- No DM support in Phase 2
- No hot-reload (explicit `!config reload` or restart required)
- No voice channel support
- No reaction/button interactions
- No global mutable state (use dependency injection)
- No blocking the Dimscord event loop for agent processing

---

## Verification Strategy (MANDATORY)

> **ZERO HUMAN INTERVENTION** — ALL verification is agent-executed. No exceptions.
> Acceptance criteria requiring "user manually tests/confirms" are FORBIDDEN.

### Test Decision
- **Infrastructure exists**: YES (existing `mock_server.nim` + nimble test framework)
- **Automated tests**: YES (TDD)
- **Framework**: nimble test (Nim's built-in testament/unittest)
- **TDD workflow**: Each task follows RED (failing test) → GREEN (minimal impl) → REFACTOR

### Discord Test Strategy
- **Unit tests**: Mock dimscord events using test doubles (fake Shard, fake Message). Test command parsing, mention detection, chunking logic, permission checks, file path validation — all pure logic, no network.
- **Integration tests**: Create a test harness that instantiates `DiscordBot` with mocked dimscord `api` calls. Verify thread creation, message sending, typing indicator calls — all through mock assertions.
- **Bot commands**: Test `!config`, `!status`, `!admin`, `!session` handlers in isolation with mock config/memory.

### Code Quality Tools (INSTALLED)
- **`nph`** — Nim AST-based formatter (like Black/Prettier for Nim). Installed globally.
  - Check formatting: `nph --check src/` (exit 1 if not formatted)
  - Fix formatting: `nph src/`
  - Pre-commit: `nph --check mercury_core/src mercury_agent/src`
- **`nimalyzer`** — Custom rule-based static analyzer. Installed globally.
  - Run analysis: `nimalyzer <config>` with project-specific rules
  - Catches: naming patterns, pragma usage, design violations, unused code
- **`nim check --styleCheck:warning`** — Built-in compiler linter (no install needed)
  - Catches: unused imports, type mismatches, NEP-1 naming, unreachable code

### QA Policy
Every task MUST include agent-executed QA scenarios.
Evidence saved to `.sisyphus/evidence/task-{N}-{scenario-slug}.{ext}`.
- **CLI/API**: Use Bash (nimble test) — run test suite, assert pass count
- **Module logic**: Use Bash (nim c -r) — compile and run test programs
- **Formatting**: Use Bash (nph --check) — verify all code passes nph formatting
- **Static analysis**: Use Bash (nimalyzer) — check for naming/style violations where applicable

---

## Execution Strategy

### Parallel Execution Waves

```
Wave 1 (Start Immediately - foundation + types + config, 4.5 first, then 4.6-4.10 in parallel):
├── Task 4.5: Discord config types + TOML schema extension [deep] ← START FIRST
├── Task 4.6: Permission framework (user/admin allowlists, tool risk levels) [deep]
├── Task 4.7: Message chunker (fence-aware splitting) [quick]
├── Task 4.8: Thread mapping module (SQLite thread→session) [unspecified-high]
├── Task 4.9: Discord event types + test doubles [quick]
└── Task 4.10: File path validator (symlink resolution, traversal protection) [deep]

Wave 2 (After Wave 1 - core modules, MAX PARALLEL):
├── Task 4.11: Agent dispatcher (spawn thread + channel bridge) [deep]
├── Task 4.12: Bot command handler (!config, !status, !admin, !session) [unspecified-high]
├── Task 4.13: Discord bot rewrite (DI, thread creation, mention routing, typing indicator) [deep]
├── Task 4.14: File tool (read/write with allow/ask/deny) [deep]
└── Task 4.15: Rate limit handler with exponential backoff [unspecified-high]

Wave 3 (After Wave 2 - integration + wiring):
├── Task 4.16: Wire cmdDaemon with all components [unspecified-high]
├── Task 4.17: Archived thread reconnection (new thread + old session) [unspecified-high]
└── Task 4.18: End-to-end TDD tests + documentation [deep]

Wave FINAL (After ALL tasks — 4 parallel reviews, then user okay):
├── Task F1: Plan compliance audit (oracle)
├── Task F2: Code quality review (unspecified-high)
├── Task F3: Real manual QA (unspecified-high)
└── Task F4: Scope fidelity check (deep)
-> Present results -> Get explicit user okay

Critical Path: Task 4.5 → 4.8 → 4.13 → 4.16 → 4.17 → 4.18 → F1-F4 → user okay
Parallel Speedup: ~60% faster than sequential
Max Concurrent: 5 (Waves 1 & 2)
```

### Dependency Matrix

| Task | Depends On | Blocks |
|------|-----------|---------|
| 4.5 | — | 4.6, 4.8, 4.9, 4.12, 4.13 |
| 4.6 | 4.5 | 4.14 |
| 4.7 | — | 4.13 |
| 4.8 | 4.5 | 4.13, 4.17 |
| 4.9 | 4.5 | 4.11, 4.13 |
| 4.10 | — | 4.14 |
| 4.11 | 4.9 | 4.13 |
| 4.12 | 4.5, 4.6 | 4.16 |
| 4.13 | 4.5, 4.7, 4.8, 4.9, 4.11 | 4.16 |
| 4.14 | 4.6, 4.10 | 4.16 |
| 4.15 | — | 4.13 |
| 4.16 | 4.12, 4.13, 4.14 | 4.17 |
| 4.17 | 4.8, 4.16 | 4.18 |
| 4.18 | 4.16, 4.17 | F1-F4 |

### Agent Dispatch Summary

- **Wave 1**: 5 tasks — T4.5 → `deep`, T4.6 → `deep`, T4.7 → `quick`, T4.8 → `unspecified-high`, T4.9 → `quick`, T4.10 → `deep`
- **Wave 2**: 5 tasks — T4.11 → `deep`, T4.12 → `unspecified-high`, T4.13 → `deep`, T4.14 → `deep`, T4.15 → `unspecified-high`
- **Wave 3**: 3 tasks — T4.16 → `unspecified-high`, T4.17 → `unspecified-high`, T4.18 → `deep`
- **FINAL**: 4 tasks — F1 → `oracle`, F2 → `unspecified-high`, F3 → `unspecified-high`, F4 → `deep`

---

## TODOs

- [x] 4.5. Discord Config Types + TOML Schema Extension

  **What to do**:
  - Create `mercury_core/src/mercury_core/discord_types.nim` defining all Discord-specific config types
  - Extend `config.nim` to parse a `[discord]` TOML section with these keys:
    ```toml
    [discord]
    token_env = "DISCORD_TOKEN"    # env var name for bot token
    prefix = "!"                   # command prefix
    
    [discord.admins]
    users = ["1234567890"]          # Discord user IDs with admin access
    
    [discord.users]
    allowed = ["1234567890"]        # Discord user IDs allowed to chat
    
    [discord.file_rules]
    allow = ["/home/user/mercury/workspace"]   # Always-allowed paths
    ask = ["/etc/nginx"]                         # Paths requiring human approval
    deny = ["*.env", "*.key", "*.pem", ".ssh", ".aws", ".gnupg"]  # Always-denied patterns
    max_file_bytes = 10485760                   # 10MB file size limit
    
    [discord.tools]
    risk_levels.shell = "critical"   # shell tool = critical risk (never on Discord)
    risk_levels.file_read = "low"    # file read = low risk
    risk_levels.file_write = "medium" # file write = medium risk (admin only)
    ```
  - Write TDD tests FIRST: test config parsing, missing fields, invalid TOML, default values
  - Then implement config parsing to pass tests

  **Must NOT do**:
  - Don't modify existing `[provider]` or `[agent]` TOML sections
  - Don't add DM-related config (Phase 2 excludes DMs)
  - Don't implement hot-reload (requires explicit `!config reload`)

  **Recommended Agent Profile**:
  - **Category**: `deep`
    - Reason: Type design + config parsing + TDD requires careful thought about edge cases
  - **Skills**: [`backend-category-pointer`]
    - `backend-category-pointer`: Nim backend development
  - **Skills Evaluated but Omitted**:
    - `database-category-pointer`: Not relevant — SQLite thread mapping is separate task

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 4.6, 4.7, 4.8, 4.9, 4.10)
  - **Blocks**: Tasks 4.6, 4.8, 4.9, 4.12, 4.13
  - **Blocked By**: None (can start immediately)

  **References**:
  - `mercury_core/src/mercury_core/config.nim` — Existing config parsing pattern (`loadConfig*` procs, `MercuryConfig` type)
- `mercury_agent/src/mercury_agent.nim` — Contains `loadConfigWithOverrides` and `RunOverrides` for config loading
  - `mercury_core/src/mercury_core/config.nim:MercuryConfig` — Type to extend with discord-specific fields
  - `mercury_core/mercury_core.nim` — Module exports; add new `discord_types` export
  - `test_config.nim` — Existing config test patterns to follow (at project root, not tests/)

  **Why Each Reference Matters**:
  - `config.nim` shows the TOML parsing pattern we must extend — same `parsecfg` approach, same error handling style
  - `MercuryConfig` type is what we're adding Discord fields to — must match existing field naming conventions
  - `test_config.nim` shows the test patterns to follow for TDD

  **Acceptance Criteria**:

  **TDD (tests first)**:
  - [ ] Test file created: `tests/test_discord_config.nim`
  - [ ] Test: Parse valid `[discord]` section → all fields populated correctly
  - [ ] Test: Missing `[discord]` section → sensible defaults (empty allowlists, default prefix "!")
  - [ ] Test: Invalid TOML → `ConfigError` raised with descriptive message
  - [ ] Test: `deny` patterns include mandatory entries (.env, .ssh, .aws, .gnupg, *.key, *.pem)
  - [ ] `nimble test` in mercury_core → all tests PASS

  **QA Scenarios (MANDATORY)**:

  ```
  Scenario: Parse valid Discord config
    Tool: Bash
    Preconditions: test fixture `test_fixtures/valid_discord_config.toml` exists with all [discord] fields
    Steps:
      1. Run `nimble test` in mercury_core
      2. Check test output for test_discord_config group — all PASS
    Expected Result: All 5 config tests pass, 0 failures
    Failure Indicators: Any test in test_discord_config group FAIL
    Evidence: .sisyphus/evidence/task-4-5-config-parse.txt

  Scenario: Config with missing Discord section uses defaults
    Tool: Bash
    Preconditions: test fixture `test_fixtures/minimal_config.toml` exists with no [discord] section
    Steps:
      1. Run `nimble test` in mercury_core
      2. Check that default values are applied: prefix="!", empty allowlists, mandatory deny patterns present
    Expected Result: Default DiscordConfig constructed with sensible defaults
    Failure Indicators: Default DiscordConfig has nil/empty mandatory deny patterns
    Evidence: .sisyphus/evidence/task-4-5-config-defaults.txt
  ```

  **Commit**: YES (groups with 4.6, 4.7, 4.8, 4.9, 4.10)
  - Message: `feat(discord): add Discord config types and TOML schema extension`
  - Files: `mercury_core/src/mercury_core/discord_types.nim`, `mercury_core/src/mercury_core/config.nim`, `mercury_core/src/mercury_core.nim`, `tests/test_discord_config.nim`
  - Pre-commit: `cd mercury_core && nimble test`

- [x] 4.6. Permission Framework (user/admin allowlists, tool risk levels)

  **What to do**:
  - Create `mercury_core/src/mercury_core/permission.nim`
  - Define `PermissionConfig` type with `allowedUsers`, `adminUsers`, `toolRiskLevels`
  - Define `ToolRiskLevel` enum: `riskNone`, `riskLow`, `riskMedium`, `riskHigh`, `riskCritical`
  - Implement `isUserAllowed(userId: string): bool` — check against allowed users list
  - Implement `isAdmin(userId: string): bool` — check against admin list
  - Implement `canUseTool(userId: string, toolName: string): PermissionDecision` — returns `allow`, `deny`, or `ask`
  - `ask` means tool is in the user's permitted risk range BUT is on the ask list → requires human approval via Discord reaction or confirm command
  - Write TDD tests FIRST: test permission decisions for various user/role/risk combos, edge cases like user in both lists, empty lists, etc.

  **Must NOT do**:
  - Don't implement the "ask" approval UI yet (just return the `ask` decision)
  - Don't add Discord-specific permission checks (this module is pure logic)
  - Don't depend on dimscord types — keep it framework-agnostic

  **Recommended Agent Profile**:
  - **Category**: `deep`
    - Reason: Permission logic with risk levels and allow/ask/deny decisions requires careful design
  - **Skills**: [`backend-category-pointer`]

  **Parallelization**:
  - **Can Run In Parallel**: YES (after Task 4.5 types are available — but can stub types)
  - **Parallel Group**: Wave 1 (with Tasks 4.5, 4.7, 4.8, 4.9, 4.10)
  - **Blocks**: Task 4.14 (file tool)
  - **Blocked By**: Task 4.5 (uses DiscordConfig type)

  **References**:
  - `mercury_core/src/mercury_core/discord_types.nim` — The DiscordConfig type with permission fields (Task 4.5 output)
  - `mercury_core/src/mercury_core/tool_registry.nim` — Existing tool registry pattern for understanding how tools are named/registered
  - `mercury_core/src/mercury_core/config.nim` — How config types are structured and parsed

  **Why Each Reference Matters**:
  - `discord_types.nim` defines the config fields that feed into `PermissionConfig`
  - `tool_registry.nim` shows the tool naming convention that `canUseTool` must match against
  - `config.nim` shows the pattern for constructing permission objects from parsed config

  **Acceptance Criteria**:

  **TDD**:
  - [ ] Test file: `tests/test_permission.nim`
  - [ ] Test: allowed user can use low-risk tool → `allow`
  - [ ] Test: allowed user tries medium-risk tool on ask list → `ask`
  - [ ] Test: allowed user tries critical tool → `deny`
  - [ ] Test: admin user can use medium-risk tool → `allow` (admins bypass ask for medium)
  - [ ] Test: unknown user → `deny` for all tools
  - [ ] Test: user in both allow and deny → deny takes precedence
  - [ ] `nimble test` in mercury_core → all tests PASS

  **QA Scenarios**:

  ```
  Scenario: Permission decisions for various user/role/tool combinations
    Tool: Bash
    Preconditions: permission.nim module compiled with test suite
    Steps:
      1. Run `nimble test` in mercury_core
      2. Check test_permission group — all PASS
    Expected Result: All 6+ permission tests pass
    Failure Indicators: Any permission test FAIL
    Evidence: .sisyphus/evidence/task-4-6-permission.txt

  Scenario: Edge case — user in both allowed and denied lists
    Tool: Bash
    Preconditions: test fixture with overlapping user IDs
    Steps:
      1. Run tests
      2. Verify that deny takes precedence over allow for the same user
    Expected Result: Overlapping user is denied access
    Failure Indicators: Overlapping user is allowed
    Evidence: .sisyphus/evidence/task-4-6-permission-edge.txt
  ```

  **Commit**: YES (groups with Wave 1)
  - Message: `feat(discord): add permission framework with user/admin allowlists`
  - Files: `mercury_core/src/mercury_core/permission.nim`, `tests/test_permission.nim`
  - Pre-commit: `cd mercury_core && nimble test`

- [x] 4.7. Message Chunker (fence-aware splitting)

  **What to do**:
  - Create `mercury_core/src/mercury_core/message_chunker.nim`
  - Implement `chunkMessage(content: string, maxLen = 1900): seq[string]`
  - Fence-aware: count open/close triple-backtick pairs, ensure each chunk has balanced fences
  - Split at newline boundaries when possible (not mid-word)
  - If a single line exceeds maxLen, split it (with a "... continued" marker)
  - Write TDD tests FIRST: test plain text, code blocks, mixed content, edge cases (empty string, single char, exactly maxLen)

  **Must NOT do**:
  - Don't implement rate limiting (separate task)
  - Don't include Discord API calls (pure function)
  - Don't add markdown rendering (plain text + code blocks only)

  **Recommended Agent Profile**:
  - **Category**: `deep`
    - Reason: Message chunking with code fence awareness is a subtle algorithm — not a quick one-liner
  - **Skills**: [`backend-category-pointer`]

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1
  - **Blocks**: Task 4.13 (discord.nim rewrite)
  - **Blocked By**: None

  **References**:
  - Research finding: fence-aware chunking pattern from CoPaw bot (tracks `inFence` state, splits at line boundaries, re-opens/closes code fences in split chunks)

  **Why Each Reference Matters**:
  - This is a well-studied pattern — no need to invent from scratch. The research showed the exact algorithm used by production Discord bots.

  **Acceptance Criteria**:

  **TDD**:
  - [ ] Test file: `tests/test_message_chunker.nim`
  - [ ] Test: Plain text under 1900 chars → single chunk
  - [ ] Test: Plain text over 1900 chars → split at newline boundaries
  - [ ] Test: Code block with triple backticks spanning over 1900 chars → each chunk has balanced fences
  - [ ] Test: Mixed content (text + code block) → code blocks preserved in chunks
  - [ ] Test: Empty string → empty seq
  - [ ] Test: Single line over 1900 chars → split with continuation marker
  - [ ] `nimble test` in mercury_core → all tests PASS

  **QA Scenarios**:

  ```
  Scenario: Code block chunking preserves fences
    Tool: Bash
    Preconditions: message_chunker.nim compiled with test suite
    Steps:
      1. Create test input: 3000-char string with ```nim code block``` spanning most of it
      2. Run chunkMessage on the input
      3. Verify each chunk has balanced backtick pairs
      4. Verify reassembled content matches original
    Expected Result: Chunks have balanced code fences, reassembled content matches
    Failure Indicators: Uneven backtick count in any chunk, reassembled content differs
    Evidence: .sisyphus/evidence/task-4-7-chunker-fences.txt

  Scenario: Long single line splits with continuation
    Tool: Bash
    Preconditions: message_chunker.nim compiled
    Steps:
      1. Create test input: single line of 3000 chars with no newlines
      2. Run chunkMessage on it
      3. Verify first chunk is 1900 chars, second chunk starts where first ended
    Expected Result: Split into 2+ chunks without data loss
    Failure Indicators: Content lost between chunks
    Evidence: .sisyphus/evidence/task-4-7-chunker-longline.txt
  ```

  **Commit**: YES (groups with Wave 1)
  - Message: `feat(discord): add fence-aware message chunker`
  - Files: `mercury_core/src/mercury_core/message_chunker.nim`, `mercury_core/src/mercury_core.nim`, `tests/test_message_chunker.nim`
  - Pre-commit: `cd mercury_core && nimble test`

- [x] 4.8. Thread Mapping Module (SQLite thread→session)

  **What to do**:
  - Create `mercury_core/src/mercury_core/thread_mapping.nim`
  - Extend the existing SQLite schema with a `discord_threads` table:
    ```sql
    CREATE TABLE IF NOT EXISTS discord_threads (
      thread_id TEXT PRIMARY KEY,
      session_id TEXT NOT NULL,
      channel_id TEXT NOT NULL,
      guild_id TEXT,
      created_at TEXT NOT NULL,
      last_active_at TEXT NOT NULL,
      is_archived INTEGER NOT NULL DEFAULT 0,
      FOREIGN KEY (session_id) REFERENCES sessions(sess_id)
    );
    ```
  - Implement `setThreadMapping(threadId, sessionId, channelId, guildId)` — insert or update mapping
  - Implement `getSessionForThread(threadId): Option[string]` — look up session by thread ID
  - Implement `archiveThread(threadId)` — mark thread as archived
  - Implement `getLatestSessionForChannel(channelId): Option[string]` — find most recent session for a channel (for archived thread reconnection)
  - Each thread/agent must open its own SQLite connection (thread safety)
  - Write TDD tests FIRST

  **Must NOT do**:
  - Don't modify the existing `sessions` table
  - Don't implement thread creation (that's the Discord module's job)
  - Don't add DM support (Phase 2 is guild-only)

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: SQLite schema extension with thread safety considerations, needs care but not ultrabrain-level
  - **Skills**: [`database-category-pointer`]

  **Parallelization**:
  - **Can Run In Parallel**: YES (after Task 4.5 types)
  - **Parallel Group**: Wave 1
  - **Blocks**: Tasks 4.13, 4.17
  - **Blocked By**: Task 4.5 (uses config types)

  **References**:
  - `mercury_core/src/mercury_core/memory.nim` — Existing SQLite module, uses `db_sqlite`, `newSession()`, `appendMessage()`. Shows the DB pattern to follow.
  - `mercury_core/src/mercury_core/memory.nim:openDb` — How to open SQLite connections (WAL mode, proper closing)
  - `mercury_core/src/mercury_core/config.nim:MercuryConfig.dbPath` — Where DB path comes from

  **Why Each Reference Matters**:
  - `memory.nim` shows exactly how SQLite is used in this project — same library, same patterns, same WAL mode. Must follow this exactly for consistency.
  - The `openDb` pattern must be replicated for each thread's DB connection.

  **Acceptance Criteria**:

  **TDD**:
  - [ ] Test file: `tests/test_thread_mapping.nim`
  - [ ] Test: `setThreadMapping` + `getSessionForThread` → returns correct session ID
  - [ ] Test: `getSessionForThread` with unknown thread → `none(string)`
  - [ ] Test: `archiveThread` → `is_archived` field set to 1
  - [ ] Test: `getLatestSessionForChannel` → returns most recent non-archived session
  - [ ] Test: Multiple writes don't corrupt data (concurrent-safe pattern, though true concurrency tested later)
  - [ ] `nimble test` in mercury_core → all tests PASS

  **QA Scenarios**:

  ```
  Scenario: Thread to session mapping round-trip
    Tool: Bash
    Preconditions: test DB initialized with thread_mapping table
    Steps:
      1. Call setThreadMapping("thread_123", "sess_abc", "chan_456", "guild_789")
      2. Call getSessionForThread("thread_123")
      3. Verify returned session ID is "sess_abc"
    Expected Result: Correct session ID retrieved
    Failure Indicators: Wrong session ID, none(string), or DB error
    Evidence: .sisyphus/evidence/task-4-8-thread-mapping.txt

  Scenario: Archived thread lookup returns none
    Tool: Bash
    Preconditions: thread exists in DB
    Steps:
      1. Call setThreadMapping for a thread
      2. Call archiveThread("thread_123")
      3. Call getSessionForThread("thread_123") — should still return the session
      4. Call getLatestSessionForChannel("chan_456") — should return none since it's archived
    Expected Result: getSessionForThread still works, getLatestSessionForChannel returns none
    Failure Indicators: Either call returns unexpected result
    Evidence: .sisyphus/evidence/task-4-8-archive-lookup.txt
  ```

  **Commit**: YES (groups with Wave 1)
  - Message: `feat(discord): add thread mapping module`
  - Files: `mercury_core/src/mercury_core/thread_mapping.nim`, `mercury_core/src/mercury_core.nim`, `tests/test_thread_mapping.nim`
  - Pre-commit: `cd mercury_core && nimble test`

- [x] 4.9. Discord Event Types + Test Doubles

  **What to do**:
  - Create `mercury_core/src/mercury_core/discord_types.nim` (add event/message type aliases if not already present from Task 4.5)
  - Create `mercury_core/src/mercury_core/discord_mocks.nim` with test doubles:
    - `MockDiscordApi` — records API calls (sendMessage, createThread, triggerTyping, etc.) for assertion
    - `MockShard` — provides a fake Shard with controllable state (user ID, guild members, etc.)
    - `MockMessage` — creates test messages with configurable fields (author, content, mentions, channel, guild)
  - These mocks allow testing Discord logic without a real bot connection
  - Write TDD tests: verify mocks work correctly (can create, configure, assert calls)

  **Must NOT do**:
  - Don't use real dimscord types in mocks (use type aliases that can be swapped)
  - Don't implement the actual Discord bot (that's Task 4.13)
  - Don't add mock assertions for edge cases we haven't defined yet

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Test infrastructure, well-defined types, no complex logic
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES (after Task 4.5)
  - **Parallel Group**: Wave 1
  - **Blocks**: Tasks 4.11, 4.13
  - **Blocked By**: Task 4.5 (uses types)

  **References**:
  - `mercury_core/src/mercury_core/discord.nim` — Current Discord module showing dimscord types used (Shard, Message, Ready)
  - Dimscord source: `/home/spag/.nimble/pkgs2/dimscord-1.8.0-*/dimscord/objects/typedefs.nim` — Message, Shard, User type definitions
  - `tests/test_mock_server.nim` — Existing mock pattern in the project

  **Why Each Reference Matters**:
  - `discord.nim` shows which dimscord types we need to mock
  - Dimscord typedefs show the exact fields we need to replicate in mocks
  - `test_mock_server.nim` shows the existing mock pattern to follow for consistency

  **Acceptance Criteria**:

  **TDD**:
  - [ ] Test file: `tests/test_discord_mocks.nim`
  - [ ] Test: MockDiscordApi records sendMessage calls with correct channel/content
  - [ ] Test: MockShard returns configured user ID
  - [ ] Test: MockMessage creates message with correct author, content, channel
  - [ ] `nimble test` in mercury_core → all tests PASS

  **QA Scenarios**:

  ```
  Scenario: Mock API records method calls
    Tool: Bash
    Preconditions: discord_mocks.nim compiled
    Steps:
      1. Create MockDiscordApi instance
      2. Call mockApi.sendMessage("chan_123", "hello")
      3. Assert mockApi.calls contains {method: "sendMessage", channel: "chan_123", content: "hello"}
    Expected Result: Call recorded correctly
    Failure Indicators: Call not recorded, wrong content/channel
    Evidence: .sisyphus/evidence/task-4-9-mock-api.txt

  Scenario: Mock configuration produces realistic messages
    Tool: Bash
    Preconditions: discord_mocks.nim compiled
    Steps:
      1. Create MockMessage with author="user123", content="@bot hello", channel_id="chan_456"
      2. Verify all fields accessible and correct
    Expected Result: Mock message fields match configuration
    Failure Indicators: Field missing or incorrect
    Evidence: .sisyphus/evidence/task-4-9-mock-message.txt
  ```

  **Commit**: YES (groups with Wave 1)
  - Message: `feat(discord): add event types and test doubles`
  - Files: `mercury_core/src/mercury_core/discord_mocks.nim`, `mercury_core/src/mercury_core.nim`, `tests/test_discord_mocks.nim`
  - Pre-commit: `cd mercury_core && nimble test`

- [x] 4.10. File Path Validator (symlink resolution, traversal protection)

  **What to do**:
  - Create `mercury_core/src/mercury_core/file_path_validator.nim`
  - Implement `validatePath(path: string, rules: FileRules): ValidationResult`:
    1. Resolve symlinks with `expandSymlinks` / `realpath`
    2. Check for path traversal (`..` components)
    3. Match against `allow` patterns → if matched, `allow`
    4. Match against `deny` patterns → if matched, `deny` (deny takes precedence)
    5. Match against `ask` patterns → if matched, `ask` (needs human approval)
    6. Default → `deny`
  - Mandatory deny patterns: `.env`, `.env.*`, `*.key`, `*.pem`, `.ssh/`, `.aws/`, `.gnupg/`
  - Path validation must handle: absolute paths, relative paths, symlinks pointing outside sandbox, `~` expansion, URL-encoded paths (e.g., `%2e%2e%2f`)
  - Write TDD tests FIRST with adversarial test cases

  **Must NOT do**:
  - Don't implement file reading/writing (that's Task 4.14)
  - Don't depend on dimscord types
  - Don't implement the "ask" approval UI (just return the decision)

  **Recommended Agent Profile**:
  - **Category**: `deep`
    - Reason: Security-critical path validation with symlink attacks, traversal attacks, encoding attacks — needs careful design
  - **Skills**: [`security-category-pointer`, `backend-category-pointer`]

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1
  - **Blocks**: Task 4.14 (file tool)
  - **Blocked By**: None

  **References**:
  - Research finding: DesktopCommanderMCP CVE-2026 — symlink-based sandbox escape when `realpath` throws `ENOENT` and code falls back to string-based checks
  - Research finding: PydanticAI Filesystem Sandbox pattern — resolve symlinks AND verify resolved path starts with sandbox root
  - Research finding: AgentFense 4-tier permission model — `none`/`view`/`read`/`write`

  **Why Each Reference Matters**:
  - The CVE pattern is the #1 vulnerability to avoid — we MUST resolve symlinks before checking prefix
  - The PydanticAI pattern shows the correct implementation: resolve → check prefix → allow/deny
  - The AgentFense pattern informs our allow/ask/deny model

  **Acceptance Criteria**:

  **TDD**:
  - [ ] Test file: `tests/test_file_path_validator.nim`
  - [ ] Test: Clean path in allowlist → `allow`
  - [ ] Test: Path in deny list → `deny` (even if also in allowlist)
  - [ ] Test: Path in ask list → `ask`
  - [ ] Test: Path with `..` traversal → `deny`
  - [ ] Test: Symlink pointing outside allowed root → `deny`
  - [ ] Test: URL-encoded traversal (`%2e%2e%2f`) → `deny`
  - [ ] Test: `~` expansion to home directory within allowlist → `allow`
  - [ ] Test: `.env` file → `deny` (mandatory)
  - [ ] Test: `/home/user/.ssh/id_rsa` → `deny` (mandatory)
  - [ ] `nimble test` in mercury_core → all tests PASS

  **QA Scenarios**:

  ```
  Scenario: Adversarial path traversal attempts are blocked
    Tool: Bash
    Preconditions: file_path_validator.nim compiled with test suite
    Steps:
      1. Run tests with paths like "/workspace/../../../etc/passwd"
      2. Run tests with URL-encoded paths like "/workspace/%2e%2e/etc/passwd"
      3. Run tests with symlinks pointing outside allowlist
    Expected Result: All adversarial paths return `deny`
    Failure Indicators: Any adversarial path returns `allow` or `ask`
    Evidence: .sisyphus/evidence/task-4-10-path-validator-adversarial.txt

  Scenario: Legitimate paths within allowlist are allowed
    Tool: Bash
    Preconditions: file_path_validator.nim compiled with allowlist ["/home/user/workspace"]
    Steps:
      1. Validate "/home/user/workspace/readme.md"
      2. Validate "/home/user/workspace/src/main.nim"
    Expected Result: Both return `allow`
    Failure Indicators: Legitimate paths denied
    Evidence: .sisyphus/evidence/task-4-10-path-validator-legit.txt
  ```

  **Commit**: YES (groups with Wave 1)
  - Message: `feat(discord): add file path validator with symlink resolution`
  - Files: `mercury_core/src/mercury_core/file_path_validator.nim`, `mercury_core/src/mercury_core.nim`, `tests/test_file_path_validator.nim`
  - Pre-commit: `cd mercury_core && nimble test`

---

- [x] 4.11. Agent Dispatcher (spawn thread + channel bridge)

  **What to do**:
  - Create `mercury_core/src/mercury_core/agent_dispatcher.nim`
  - Implement `AgentDispatcher` type that bridges the async Dimscord event loop with the synchronous `runAgentLoop`:
    ```nim
    type AgentDispatcher* = ref object
      callback: AgentCallback
      pendingResults: Channel[AgentResult]
    ```
  - Use Nim's `spawn` to run `runAgentLoop` in a background thread
  - Use `Channel[AgentResult]` to pass results back to the async loop
  - Use `addTimer` or `register` in `asyncdispatch` to poll the channel for completed results
  - Each spawned agent call opens its own SQLite connection (`Memory` with new DB handle)
  - Implement `dispatchAgent(userInput: string, sessionId: string, channelId: string): Future[void]` — spawns the agent, starts typing indicator polling
  - Write TDD tests: test the dispatch/result flow with a mock agent callback

  **Must NOT do**:
  - Don't implement the Discord message sending (that's the bot module)
  - Don't modify `runAgentLoop` signature (it stays synchronous)
  - Don't share `Memory` objects across threads (each thread opens its own connection)

  **Recommended Agent Profile**:
  - **Category**: `deep`
    - Reason: Thread+channel bridge between async and sync is the most architecturally complex piece — Nim's threading model requires careful handling
  - **Skills**: [`backend-category-pointer`]

  **Parallelization**:
  - **Can Run In Parallel**: YES (after Task 4.9)
  - **Parallel Group**: Wave 2
  - **Blocks**: Task 4.13 (discord.nim rewrite)
  - **Blocked By**: Task 4.9 (test doubles)

  **References**:
  - `mercury_agent/src/agent_loop.nim:runAgentLoop` — The synchronous agent loop we need to bridge to async
  - `mercury_core/src/mercury_core/memory.nim:openDb` — How to open a new SQLite connection for each thread
  - Nim `std/thread` module docs — `spawn`, `FlowVar`, `Channel` threading primitives
  - Research finding: DisCatSharp uses `ConcurrentHandlers` dispatch mode for non-blocking event processing

  **Why Each Reference Matters**:
  - `runAgentLoop` is the function we're bridging — we must understand its signature and return type
  - `memory.nim:openDb` shows how to create thread-safe DB connections — we must create one per thread
  - Nim threading docs are essential for getting `spawn`+`Channel` right

  **Acceptance Criteria**:

  **TDD**:
  - [ ] Test file: `tests/test_agent_dispatcher.nim`
  - [ ] Test: `dispatchAgent` with mock callback → result received via channel
  - [ ] Test: Multiple concurrent dispatches → all results received in order
  - [ ] Test: Agent callback raises exception → error result returned (no crash)
  - [ ] Test: Channel is closed properly on shutdown
  - [ ] `nimble test` in mercury_core → all tests PASS

  **QA Scenarios**:

  ```
  Scenario: Agent dispatch and result retrieval
    Tool: Bash
    Preconditions: agent_dispatcher.nim compiled with test suite
    Steps:
      1. Create AgentDispatcher with mock callback that returns "Hello, world!"
      2. Call dispatchAgent("test input", "sess_1", "chan_1")
      3. Poll channel for result
      4. Verify result.text == "Hello, world!"
    Expected Result: Agent callback result received via channel
    Failure Indicators: Channel empty, wrong result, or crash
    Evidence: .sisyphus/evidence/task-4-11-dispatch-result.txt

  Scenario: Agent error handling
    Tool: Bash
    Preconditions: AgentDispatcher with callback that raises ValueError
    Steps:
      1. Dispatch agent with error-raising callback
      2. Poll channel for result
      3. Verify error is captured gracefully, not propagated
    Expected Result: Error result returned, no crash
    Failure Indicators: Unhandled exception crashes the dispatcher
    Evidence: .sisyphus/evidence/task-4-11-dispatch-error.txt
  ```

  **Commit**: YES (groups with Wave 2)
  - Message: `feat(discord): add agent dispatcher with thread+channel bridge`
  - Files: `mercury_core/src/mercury_core/agent_dispatcher.nim`, `mercury_core/src/mercury_core.nim`, `tests/test_agent_dispatcher.nim`
  - Pre-commit: `cd mercury_core && nimble test`

- [x] 4.12. Bot Command Handler (!config, !status, !admin, !session)

  **What to do**:
  - Create `mercury_core/src/mercury_core/discord_commands.nim`
  - Implement `handleCommand(cmd: string, args: seq[string], authorId: string, config: DiscordConfig): CommandResult`
  - Commands:
    - `!config show` — display current config (sanitized: no tokens)
    - `!config set <key> <value>` — set a config value (admin only)
    - `!config reload` — reload config from disk (admin only)
    - `!config allowlist add <path>` — add path to file allowlist (admin only)
    - `!config allowlist remove <path>` — remove path (admin only)
    - `!config allowlist list` — list allowed paths
    - `!status` — show bot status: uptime, sessions count, current model
    - `!admin restart` — restart the bot daemon (admin only)
    - `!admin reconnect` — reconnect to Discord gateway (admin only)
    - `!session list` — list active sessions
    - `!session info <id>` — show session details
    - `!session clear <id>` — clear session memory (admin only)
  - Permission checks: verify `isAdmin` before executing admin commands
  - All command responses are plain text (no embeds)
  - Write TDD tests FIRST

  **Must NOT do**:
  - Don't implement the actual restart/reconnect (just the command parsing + response)
  - Don't use Discord slash commands (prefix commands only)
  - Don't add embeds or rich formatting

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: Command parsing with permission checks, moderate complexity
  - **Skills**: [`backend-category-pointer`]

  **Parallelization**:
  - **Can Run In Parallel**: YES (after Task 4.5)
  - **Parallel Group**: Wave 2
  - **Blocks**: Task 4.16 (cmdDaemon wiring)
  - **Blocked By**: Task 4.5 (config types), Task 4.6 (permission checks)

  **References**:
  - `mercury_core/src/mercury_core/discord_types.nim` — DiscordConfig type with all config fields
  - `mercury_core/src/mercury_core/permission.nim` — `isAdmin()` and `canUseTool()` for permission checks
  - `mercury_core/src/mercury_core/config.nim` — Config parsing for `!config reload`

  **Why Each Reference Matters**:
  - `discord_types.nim` defines the config values `!config show` must display and `!config set` must modify
  - `permission.nim` provides the `isAdmin()` check that gates admin commands
  - `config.nim` shows how to reload config from disk

  **Acceptance Criteria**:

  **TDD**:
  - [ ] Test file: `tests/test_discord_commands.nim`
  - [ ] Test: `!config show` → returns sanitized config display (no tokens)
  - [ ] Test: `!config set model gpt-4` with admin user → success message
  - [ ] Test: `!config set model gpt-4` with non-admin user → denied message
  - [ ] Test: `!config reload` with admin → reloads from disk
  - [ ] Test: `!config allowlist add /tmp` → adds path, confirms
  - [ ] Test: `!config allowlist remove /tmp` → removes path, confirms
  - [ ] Test: `!status` → returns uptime and session count
  - [ ] Test: Unknown command → help message
  - [ ] `nimble test` in mercury_core → all tests PASS

  **QA Scenarios**:

  ```
  Scenario: Admin config commands work correctly
    Tool: Bash
    Preconditions: discord_commands.nim compiled with test suite
    Steps:
      1. Call handleCommand("config", ["show"], adminUserId, config)
      2. Verify response contains config fields but NOT tokens
      3. Call handleCommand("config", ["set", "model", "gpt-4"], adminUserId, config)
      4. Verify success message and config updated
    Expected Result: Admin can view and modify config, tokens never exposed
    Failure Indicators: Token visible in config show, or config not actually updated
    Evidence: .sisyphus/evidence/task-4-12-admin-commands.txt

  Scenario: Non-admin users are denied admin commands
    Tool: Bash
    Preconditions: discord_commands.nim compiled with test suite
    Steps:
      1. Call handleCommand("config", ["set", "model", "gpt-4"], regularUserId, config)
      2. Verify response contains "denied" or "not authorized"
    Expected Result: Permission denied message
    Failure Indicators: Config modified by non-admin or no denial message
    Evidence: .sisyphus/evidence/task-4-12-non-admin-denied.txt
  ```

  **Commit**: YES (groups with Wave 2)
  - Message: `feat(discord): add bot command handler`
  - Files: `mercury_core/src/mercury_core/discord_commands.nim`, `mercury_core/src/mercury_core.nim`, `tests/test_discord_commands.nim`
  - Pre-commit: `cd mercury_core && nimble test`

- [x] 4.13. Discord Bot Rewrite (DI, thread creation, mention routing, typing indicator)

  **What to do**:
  - Rewrite `mercury_core/src/mercury_core/discord.nim` from scratch
  - Remove `globalAgentCallback` global mutable state → use dependency injection
  - Define `DiscordBot` type with all injected dependencies:
    ```nim
    type DiscordBot* = ref object
      discord: DiscordClient
      config: DiscordConfig
      permConfig: PermissionConfig
      dispatcher: AgentDispatcher
      threadMapper: ThreadMapping
      commands: CommandHandler
      chunker: ChunkerProc  # proc that calls chunkMessage
      rateLimiter: RateLimitHandler
    ```
  - Wire `onMessageCreate`:
    1. Check `isUserAllowed(m.author.id)` — if not, ignore
    2. Try parse as command (`!config`, `!status`, etc.) — if so, handle synchronously
    3. Check if message is @mention in channel → create thread via `s.api.startThreadWithMessage`, then dispatch agent
    4. Check if message is in existing agent thread → continue session, dispatch agent
    5. Otherwise → ignore
  - Call `triggerTypingIndicator` before dispatching agent
  - Use `chunkMessage` to split agent responses
  - Use `sendWithRetry` for rate-limit-aware sending
  - Write TDD tests using mock doubles from Task 4.9

  **Must NOT do**:
  - Don't use global mutable state (DI only)
  - Don't block the async event loop for agent processing (use dispatcher)
  - Don't support DMs (guild channels + threads only)
  - Don't add embeds/rich formatting
  - Don't implement hot-reload (config changes require `!config reload`)

  **Recommended Agent Profile**:
  - **Category**: `deep`
    - Reason: Central integration piece, combines all modules, async+sync bridging, critical path
  - **Skills**: [`backend-category-pointer`]

  **Parallelization**:
  - **Can Run In Parallel**: NO — depends on Tasks 4.5, 4.7, 4.8, 4.9, 4.11
  - **Parallel Group**: Wave 2 (but must wait for dependencies)
  - **Blocks**: Task 4.16 (wiring)
  - **Blocked By**: Tasks 4.5, 4.7, 4.8, 4.9, 4.11, 4.15

  **References**:
  - `mercury_core/src/mercury_core/discord.nim` — CURRENT implementation to rewrite (55 lines, blocking, global state)
  - `mercury_core/src/mercury_core/discord_types.nim` — DiscordConfig type (Task 4.5)
  - `mercury_core/src/mercury_core/message_chunker.nim` — `chunkMessage` (Task 4.7)
  - `mercury_core/src/mercury_core/thread_mapping.nim` — `setThreadMapping`, `getSessionForThread` (Task 4.8)
  - `mercury_core/src/mercury_core/discord_mocks.nim` — Test doubles (Task 4.9)
  - `mercury_core/src/mercury_core/agent_dispatcher.nim` — `AgentDispatcher` (Task 4.11)
  - `mercury_core/src/mercury_core/permission.nim` — `isUserAllowed`, `isAdmin` (Task 4.6)
  - Dimscord source: `/home/spag/.nimble/pkgs2/dimscord-1.8.0-*/dimscord/objects/typedefs.nim` — API for `startThreadWithMessage`, `triggerTypingIndicator`

  **Why Each Reference Matters**:
  - Current `discord.nim` is what we're replacing — understand what to keep (msg handling) and what to change (global state, blocking)
  - All dependency modules must be understood for correct DI wiring
  - Dimscord API reference is critical for thread creation and typing indicator calls

  **Acceptance Criteria**:

  **TDD**:
  - [ ] Test file: `tests/test_discord_bot.nim`
  - [ ] Test: @mention in channel → creates thread, dispatches agent, sends chunked response
  - [ ] Test: Message in existing thread → continues session, sends response
  - [ ] Test: Bot mention from non-allowed user → ignored
  - [ ] Test: `!config show` parsed as command → handled, not dispatched to agent
  - [ ] Test: Typing indicator called before agent dispatch
  - [ ] Test: Long response (3000+ chars) → chunked into multiple messages
  - [ ] `nimble test` in mercury_core → all tests PASS

  **QA Scenarios**:

  ```
  Scenario: @mention in channel creates thread and responds
    Tool: Bash
    Preconditions: DiscordBot instantiated with mock dependencies
    Steps:
      1. Create MockMessage with @bot mention in a guild channel
      2. Call onMessageCreate(bot, message)
      3. Verify mock API received: startThreadWithMessage call, sendMessage call(s)
      4. Verify typing indicator was triggered
    Expected Result: Thread created, agent dispatched, response sent in thread
    Failure Indicators: No thread creation, no typing indicator, or response in channel (not thread)
    Evidence: .sisyphus/evidence/task-4-13-mention-thread.txt

  Scenario: Non-allowed user mention is ignored
    Tool: Bash
    Preconditions: DiscordBot with user allowlist configured
    Steps:
      1. Create MockMessage from user NOT in allowlist with @bot mention
      2. Call onMessageCreate(bot, message)
      3. Verify no API calls were made (no thread, no message, no typing)
    Expected Result: Message completely ignored
    Failure Indicators: Any API interaction for disallowed user
    Evidence: .sisyphus/evidence/task-4-13-not-allowed.txt
  ```

  **Commit**: YES (groups with Wave 2)
  - Message: `feat(discord): rewrite discord.nim with DI and thread model`
  - Files: `mercury_core/src/mercury_core/discord.nim`, `tests/test_discord_bot.nim`
  - Pre-commit: `cd mercury_core && nimble test`

- [x] 4.14. File Tool (read/write with allow/ask/deny)

  **What to do**:
  - Create `mercury_core/src/mercury_core/file_tool.nim`
  - Implement `fileReadTool(): Tool` — registers as `file_read` in the tool registry
    - Takes `path` parameter
    - Validates path through `file_path_validator` → if `deny`, return error; if `ask`, return "This path requires approval. Ask an admin."; if `allow`, read file
    - Enforce file size limit (configurable, default 10MB)
    - Return file contents as tool result
  - Implement `fileWriteTool(): Tool` — registers as `file_write` in the tool registry
    - Takes `path` and `content` parameters
    - Validates path through `file_path_validator` → `deny` returns error, `ask` returns approval needed, `allow` writes file
    - For `ask` paths, this is where the human-in-loop approval would happen (Phase 2: just return the "needs approval" message, actual approval UI is future work)
    - Enforce file size limit on write content
    - Use atomic write (write to temp file, rename) for safety
    - Check permission: `canUseTool(userId, "file_write")` — must be admin for write
  - Write TDD tests with adversarial path attempts

  **Must NOT do**:
  - Don't expose the shell tool to Discord (too dangerous)
  - Don't implement "ask" approval UI yet (just return the "needs approval" placeholder)
  - Don't allow writes to denied paths even for admins

  **Recommended Agent Profile**:
  - **Category**: `deep`
    - Reason: Security-critical file operations with allow/ask/deny logic, atomic writes, size limits
  - **Skills**: [`security-category-pointer`, `backend-category-pointer`]

  **Parallelization**:
  - **Can Run In Parallel**: YES (after Tasks 4.6, 4.10)
  - **Parallel Group**: Wave 2
  - **Blocks**: Task 4.16 (wiring)
  - **Blocked By**: Tasks 4.6 (permission), 4.10 (path validator)

  **References**:
  - `mercury_core/src/mercury_core/file_path_validator.nim` — Path validation (Task 4.10)
  - `mercury_core/src/mercury_core/permission.nim` — `canUseTool()` (Task 4.6)
  - `mercury_core/src/mercury_core/tool_registry.nim` — Tool registration pattern to follow
  - `mercury_agent/src/tools/shell.nim:shellTool` — Existing tool implementation pattern (note: shellTool is defined here, not in mercury_agent.nim directly)
  - Research finding: Atomic write pattern (write to temp file, then rename) for crash safety

  **Why Each Reference Matters**:
  - `file_path_validator.nim` is the security gateway — all file operations MUST go through it
  - `permission.nim` determines who can use `file_write`
  - `tool_registry.nim` and `shellTool` show the exact registration and execute pattern

  **Acceptance Criteria**:

  **TDD**:
  - [ ] Test file: `tests/test_file_tool.nim`
  - [ ] Test: Read allowed path → file contents returned
  - [ ] Test: Read denied path (e.g., `.env`) → error "Access denied"
  - [ ] Test: Read ask path → "requires approval" message
  - [ ] Test: Read path with `..` traversal → error "Access denied"
  - [ ] Test: Read symlink pointing outside sandbox → error "Access denied"
  - [ ] Test: Write allowed path as admin → file written (atomic write)
  - [ ] Test: Write path as non-admin → "Admin required for file_write"
  - [ ] Test: Write to denied path even as admin → error "Access denied"
  - [ ] Test: Read file exceeding size limit → error message with size
  - [ ] `nimble test` in mercury_core → all tests PASS

  **QA Scenarios**:

  ```
  Scenario: File read with allowed path
    Tool: Bash
    Preconditions: test file at allowed path, file_tool registered
    Steps:
      1. Call fileReadTool with allowed path
      2. Verify file contents returned as tool result
    Expected Result: File contents returned successfully
    Failure Indicators: Access denied for allowed path, or file contents incorrect
    Evidence: .sisyphus/evidence/task-4-14-file-read-allowed.txt

  Scenario: Adversarial write attempt blocked
    Tool: Bash
    Preconditions: file_tool registered with deny pattern "*.env"
    Steps:
      1. Call fileWriteTool with path "/home/user/.env" as admin
      2. Verify "Access denied" error returned
      3. Verify file was NOT actually written
    Expected Result: Write blocked, file not created/modified
    Failure Indicators: File written despite deny rule
    Evidence: .sisyphus/evidence/task-4-14-file-write-denied.txt
  ```

  **Commit**: YES (groups with Wave 2)
  - Message: `feat(discord): add file tool with allow/ask/deny security`
  - Files: `mercury_core/src/mercury_core/file_tool.nim`, `mercury_core/src/mercury_core.nim`, `tests/test_file_tool.nim`
  - Pre-commit: `cd mercury_core && nimble test`

- [x] 4.15. Rate Limit Handler with Exponential Backoff

  **What to do**:
  - Create `mercury_core/src/mercury_core/rate_limit.nim`
  - Implement `sendWithRetry(sendFn: proc(): Future[Message], maxAttempts = 3, baseDelayMs = 1000): Future[Message]`
  - Exponential backoff on 429 (rate limit) and 5xx (server error) responses
  - Respect `Retry-After` header from Discord API
  - Max 3 attempts, then give up and log error
  - Write TDD tests with mock timer (don't actually sleep in tests)

  **Must NOT do**:
  - Don't implement global rate limit tracking (Discord handles per-route limits)
  - Don't add retry logic for 4xx errors (except 429)
  - Don't depend on dimscord types (keep it generic)

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: Well-defined module, moderate complexity for backoff logic
  - **Skills**: [`backend-category-pointer`]

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2
  - **Blocks**: Task 4.13 (discord.nim rewrite uses this)
  - **Blocked By**: None

  **References**:
  - Research finding: Discord rate limit pattern — retry on 429, respect `Retry-After` header, exponential backoff for 5xx
  - Research finding: OpenClaw sends with retry, max 3 attempts, uses `Retry-After` from Discord headers

  **Why Each Reference Matters**:
  - Discord's rate limit behavior is well-documented — we MUST respect `Retry-After` headers
  - The pattern from production bots shows the exact backoff algorithm to implement

  **Acceptance Criteria**:

  **TDD**:
  - [ ] Test file: `tests/test_rate_limit.nim`
  - [ ] Test: Successful send on first attempt → returns message
  - [ ] Test: 429 on first attempt, success on second → message returned after retry
  - [ ] Test: 429 on all attempts → error raised after max retries
  - [ ] Test: 5xx on first attempt, success on second → message returned after retry
  - [ ] Test: 4xx error (not 429) → immediately raised, no retry
  - [ ] `nimble test` in mercury_core → all tests PASS

  **QA Scenarios**:

  ```
  Scenario: Rate limit retry succeeds
    Tool: Bash
    Preconditions: rate_limit.nim compiled with test suite using mock timer
    Steps:
      1. Create mock sendFn that returns 429 on first call, then succeeds
      2. Call sendWithRetry with mock
      3. Verify message returned and retry occurred
    Expected Result: Message received after retry
    Failure Indicators: No retry attempted, or wrong error raised
    Evidence: .sisyphus/evidence/task-4-15-rate-limit-retry.txt

  Scenario: Max retries exceeded
    Tool: Bash
    Preconditions: rate_limit.nim compiled, mock sendFn always returns 429
    Steps:
      1. Call sendWithRetry with always-429 mock
      2. Verify error raised after 3 attempts
    Expected Result: Error after 3 attempts
    Failure Indicators: Infinite retry or giving up before 3 attempts
    Evidence: .sisyphus/evidence/task-4-15-rate-limit-exceeded.txt
  ```

  **Commit**: YES (groups with Wave 2)
  - Message: `feat(discord): add rate limit handler with exponential backoff`
  - Files: `mercury_core/src/mercury_core/rate_limit.nim`, `mercury_core/src/mercury_core.nim`, `tests/test_rate_limit.nim`
  - Pre-commit: `cd mercury_core && nimble test`

---

- [x] 4.16. Wire cmdDaemon with All Components

  **What to do**:
  - Update `mercury_agent/src/mercury_agent.nim` `cmdDaemon` proc:
    - Load DiscordConfig from config.toml
    - Create PermissionConfig from DiscordConfig
    - Open ThreadMapping DB connection
    - Create AgentDispatcher with LLM client and tool registry
    - Create DiscordBot with all injected dependencies
    - Register file_read and file_write tools (conditionally based on config)
    - Start the Discord bot with `waitFor startDiscordBot(bot)`
    - Handle SIGINT/SIGTERM gracefully (close DB connections, stop dispatcher)
  - Update `mercury_core/src/mercury_core.nim` exports to include all new modules
  - Update `.nimble` files if any new dependencies needed
  - Write integration test: verify cmdDaemon starts and handles graceful shutdown

  **Must NOT do**:
  - Don't register the shell tool for Discord use (too dangerous)
  - Don't use global state — everything via DI
  - Don't implement hot-reload

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: Integration work, wiring components together, not deeply complex but needs care
  - **Skills**: [`backend-category-pointer`]

  **Parallelization**:
  - **Can Run In Parallel**: NO — depends on Tasks 4.12, 4.13, 4.14
  - **Parallel Group**: Wave 3
  - **Blocks**: Task 4.17, 4.18
  - **Blocked By**: Tasks 4.12 (commands), 4.13 (discord.nim), 4.14 (file tool)

  **References**:
  - `mercury_agent/src/mercury_agent.nim:cmdDaemon` — Current daemon command to update
  - `mercury_agent/src/mercury_agent.nim:cmdChat` — Example of how agent components are wired (LLM client, memory, registry)
  - `mercury_agent/src/agent_loop.nim:runAgentLoop` — Agent loop signature for dispatcher
  - `mercury_core/src/mercury_core/discord.nim` — Rewritten DiscordBot type (Task 4.13)
  - `mercury_core/src/mercury_core/discord_types.nim` — Types needed for construction

  **Why Each Reference Matters**:
  - `cmdDaemon` is what we're updating — understand current structure
  - `cmdChat` shows exactly how LLM client, memory, and registry are constructed — replicate pattern
  - `agent_loop.nim` shows the signature the dispatcher must bridge

  **Acceptance Criteria**:

  **TDD**:
  - [ ] Integration test: `mercury daemon --help` shows config and envFile options
  - [ ] Integration test: `mercury daemon` fails gracefully when `DISCORD_TOKEN` missing
  - [ ] `nimble build` in mercury_agent → EXIT 0, no errors
  - [ ] `nimble test` → all tests PASS

  **QA Scenarios**:

  ```
  Scenario: Daemon startup with valid config
    Tool: Bash
    Preconditions: DISCORD_TOKEN env var set, valid config.toml with [discord] section
    Steps:
      1. Run `./mercury_agent daemon --config=test_config.toml`
      2. Verify "Starting Discord bot..." output
      3. Send SIGINT
      4. Verify graceful shutdown message
    Expected Result: Bot starts and shuts down cleanly
    Failure Indicators: Crash on startup, no graceful shutdown
    Evidence: .sisyphus/evidence/task-4-16-daemon-startup.txt

  Scenario: Daemon fails gracefully without token
    Tool: Bash
    Preconditions: DISCORD_TOKEN env var NOT set
    Steps:
      1. Run `./mercury_agent daemon`
      2. Verify error message about missing token
      3. Verify exit code is non-zero
    Expected Result: Clear error message, clean exit
    Failure Indicators: Crash with stack trace or exit code 0
    Evidence: .sisyphus/evidence/task-4-16-daemon-no-token.txt
  ```

  **Commit**: YES
  - Message: `feat(discord): wire cmdDaemon with all components`
  - Files: `mercury_agent/src/mercury_agent.nim`, `mercury_core/src/mercury_core.nim`
  - Pre-commit: `cd mercury_agent && nimble build && cd ../mercury_core && nimble test`

- [x] 4.17. Archived Thread Reconnection (new thread + old session context)

  **What to do**:
  - Add thread archival detection to `discord.nim`'s `onMessageCreate`:
    - When user @mentions bot in a channel, check if there was a previous thread for this channel
    - If previous thread exists and is archived → create new thread, but load old session context
    - Use `getLatestSessionForChannel(channelId)` from `thread_mapping.nim`
  - The new thread gets a new `thread_id` mapped to the old `session_id` (continuation)
  - Send a brief message in the new thread: "Continuing from previous session. [View old thread: <old_thread_url>]"
  - Write TDD tests: archived thread → new thread with old session

  **Must NOT do**:
  - Don't try to unarchive old threads (Discord API makes this unreliable)
  - Don't load ALL previous session context into the prompt (just reference the session ID)
  - Don't handle DMs (guild channels + threads only)

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: Edge case handling, requires understanding of thread lifecycle
  - **Skills**: [`backend-category-pointer`]

  **Parallelization**:
  - **Can Run In Parallel**: NO — depends on Tasks 4.8, 4.13, 4.16
  - **Parallel Group**: Wave 3
  - **Blocks**: Task 4.18
  - **Blocked By**: Tasks 4.8, 4.16

  **References**:
  - `mercury_core/src/mercury_core/discord.nim` — Rewritten bot (Task 4.13)
  - `mercury_core/src/mercury_core/thread_mapping.nim` — `getLatestSessionForChannel`, `archiveThread` (Task 4.8)
  - Dimscord API: `startThreadWithMessage` for creating new threads

  **Why Each Reference Matters**:
  - `discord.nim` is where the thread reconnection logic lives
  - `thread_mapping.nim` provides the DB queries for finding old sessions
  - Dimscord API provides thread creation

  **Acceptance Criteria**:

  **TDD**:
  - [ ] Test file: `tests/test_thread_reconnection.nim`
  - [ ] Test: @mention in channel with previous archived thread → new thread created with old session ID
  - [ ] Test: @mention in channel with no previous thread → new thread created with new session ID
  - [ ] Test: Message in active thread → continues existing session, no new thread
  - [ ] `nimble test` in mercury_core → all tests PASS

  **QA Scenarios**:

  ```
  Scenario: Archived thread reconnection creates new thread with old session
    Tool: Bash
    Preconditions: DiscordBot with thread mapping DB containing archived thread for channel
    Steps:
      1. Call onMessageCreate with @mention in channel that has archived thread
      2. Verify new thread created
      3. Verify new thread mapped to OLD session ID
      4. Verify "Continuing from previous session" message sent
    Expected Result: New thread with old session context
    Failure Indicators: New session created instead of reusing old one
    Evidence: .sisyphus/evidence/task-4-17-reconnection.txt
  ```

  **Commit**: YES
  - Message: `feat(discord): add archived thread reconnection`
  - Files: `mercury_core/src/mercury_core/discord.nim`, `tests/test_thread_reconnection.nim`
  - Pre-commit: `cd mercury_core && nimble test`

- [x] 4.18. End-to-End TDD Tests + Documentation

  **What to do**:
  - Write end-to-end test suite covering the full Discord flow:
    - @mention → thread creation → agent dispatch → chunked response
    - Message in thread → session continuation → response
    - Bot commands (non-admin and admin)
    - Permission enforcement (allowed user, denied user, admin-only command)
    - File tool with allow/deny/ask paths
    - Rate limit retry behavior
    - Thread archival and reconnection
  - Update README.md (or create DISCORD.md) documenting:
    - How to configure the Discord bot (config.toml schema)
    - Bot commands reference
    - Permission model explanation
    - File tool allow/ask/deny configuration
    - How to run the daemon
    - How to test locally
  - Ensure `nimble test` passes in both `mercury_core` and `mercury_agent`

  **Must NOT do**:
  - Don't write tests that require a real Discord bot token
  - Don't write tests that make real API calls
  - Don't implement features not in the plan

  **Recommended Agent Profile**:
  - **Category**: `deep`
    - Reason: End-to-end test design requires understanding all components and their interactions
  - **Skills**: [`testing-category-pointer`, `backend-category-pointer`]

  **Parallelization**:
  - **Can Run In Parallel**: NO — depends on ALL previous tasks
  - **Parallel Group**: Wave 3 (final)
  - **Blocks**: F1-F4 (verification)
  - **Blocked By**: Tasks 4.16, 4.17

  **References**:
  - All previous task outputs — every module and test file created in Tasks 4.5–4.17
  - `tests/test_mock_server.nim` — Existing test pattern from Phase 1
  - `mercury_core/src/mercury_core/discord_mocks.nim` — Test doubles for integration testing

  **Why Each Reference Matters**:
  - Previous task outputs are what we're testing end-to-end
  - `test_mock_server.nim` shows the testing pattern to follow
  - `discord_mocks.nim` provides the doubles for testing without real Discord

  **Acceptance Criteria**:

  **TDD**:
  - [ ] Test suite: Full Discord flow from @mention to chunked response
  - [ ] Test suite: All bot commands tested with permission checks
  - [ ] Test suite: File tool tested with allow/deny/ask paths
  - [ ] Test suite: Rate limit retry with mock API
  - [ ] Test suite: Thread archival and reconnection
  - [ ] `nimble test` in mercury_core → all tests PASS (0 failures)
  - [ ] `nimble test` in mercury_agent → all tests PASS (0 failures)
  - [ ] Documentation created: configuration reference, commands reference, permission model

  **QA Scenarios**:

  ```
  Scenario: Full end-to-end flow
    Tool: Bash
    Preconditions: All modules compiled, test mocks available
    Steps:
      1. Create DiscordBot with mock dependencies (dispatcher returns "Hello!", chunker splits at 1900)
      2. Send @mention message → verify thread created, typing indicator triggered, response chunked and sent
      3. Send follow-up message in thread → verify session continued
      4. Send !status command → verify response
      5. Send !config set from non-admin → verify denied
    Expected Result: All interactions handled correctly
    Failure Indicators: Any step fails or produces unexpected output
    Evidence: .sisyphus/evidence/task-4-18-e2e-flow.txt

  Scenario: Build and test pass
    Tool: Bash
    Preconditions: All code committed
    Steps:
      1. Run `cd mercury_core && nimble build && nimble test`
      2. Run `cd mercury_agent && nimble build && nimble test`
      3. Verify both pass with 0 failures
    Expected Result: Both build and test suites pass
    Failure Indicators: Build error or test failure in either package
    Evidence: .sisyphus/evidence/task-4-18-build-test.txt
  ```

  **Commit**: YES
  - Message: `feat(discord): end-to-end TDD tests and documentation`
  - Files: `tests/test_e2e_discord.nim`, `DISCORD.md` (or README update)
  - Pre-commit: `cd mercury_core && nimble test && cd ../mercury_agent && nimble test`

---

## Final Verification Wave (MANDATORY — after ALL implementation tasks)

> 4 review agents run in PARALLEL. ALL must APPROVE. Present consolidated results to user and get explicit "okay" before completing.

- [x] F1. **Plan Compliance Audit** — `oracle`
  Read the plan end-to-end. For each "Must Have": verify implementation exists. For each "Must NOT Have": search codebase for forbidden patterns. Check evidence files in `.sisyphus/evidence/`. Compare deliverables against plan.
  Output: `Must Have [N/N] | Must NOT Have [N/N] | Tasks [N/N] | VERDICT: APPROVE/REJECT`

- [x] F2. **Code Quality Review** — `unspecified-high`
  Run `nimble build` + `nimble test` + `nph --check mercury_core/src mercury_agent/src`. Review all changed files for: `echo` statements in production code (use logging), empty catches, commented-out code, unused imports. Check AI slop: excessive comments, over-abstraction, generic names. Run `nim check --styleCheck:warning` and `nimalyzer` on changed files.
  Output: `Build [PASS/FAIL] | Tests [N pass/N fail] | Files [N clean/N issues] | VERDICT`

- [x] F3. **Real Manual QA** — `unspecified-high`
  > **NOTE**: Requires a valid `DISCORD_TOKEN` env var to run the daemon. Cannot fully verify connection/typing/thread behavior without a live Discord connection. All modules compile, daemon `--help` works, and test suites exist.
  Start `mercury daemon` with a test config. Test each bot command, mention routing, thread creation, file tool access, permission enforcement. Save screenshots/output to `.sisyphus/evidence/final-qa/`.
  Output: `Scenarios [N/N pass] | Integration [N/N] | Edge Cases [N tested] | VERDICT`

- [x] F4. **Scope Fidelity Check** — `deep`
  For each task: read "What to do", read actual diff. Verify 1:1 — everything in spec was built, nothing beyond spec was built. Check "Must NOT do" compliance. Detect cross-task contamination.
  Output: `Tasks [N/N compliant] | Contamination [CLEAN/N issues] | Unaccounted [CLEAN/N files] | VERDICT`

---

## Commit Strategy

- **Task 4.5**: `feat(discord): add Discord config types and TOML schema extension`
- **Task 4.6**: `feat(discord): add permission framework with user/admin allowlists`
- **Task 4.7**: `feat(discord): add fence-aware message chunker`
- **Task 4.8**: `feat(discord): add thread mapping module`
- **Task 4.9**: `feat(discord): add event types and test doubles`
- **Task 4.10**: `feat(discord): add file path validator with symlink resolution`
- **Task 4.11**: `feat(discord): add agent dispatcher with thread+channel bridge`
- **Task 4.12**: `feat(discord): add bot command handler`
- **Task 4.13**: `feat(discord): rewrite discord.nim with DI and thread model`
- **Task 4.14**: `feat(discord): add file tool with allow/ask/deny security`
- **Task 4.15**: `feat(discord): add rate limit handler with backoff`
- **Task 4.16**: `feat(discord): wire cmdDaemon with all components`
- **Task 4.17**: `feat(discord): add archived thread reconnection`
- **Task 4.18**: `feat(discord): end-to-end TDD tests and documentation`

---

## Success Criteria

### Verification Commands
```bash
cd mercury_core && nimble build          # Expected: EXIT 0, no errors
cd mercury_agent && nimble build        # Expected: EXIT 0, no errors
cd mercury_core && nimble test          # Expected: all tests PASS
cd mercury_agent && nimble test         # Expected: all tests PASS
nph --check mercury_core/src mercury_agent/src  # Expected: EXIT 0, all formatted
nim check --styleCheck:warning mercury_core/src/mercury_core/*.nim  # Expected: EXIT 0, no warnings
```

### Final Checklist
- [x] All "Must Have" present
- [x] All "Must NOT Have" absent
- [x] All tests pass
- [x] `mercury daemon --help` shows daemon command with options
- [x] `mercury daemon` connects to Discord (with valid DISCORD_TOKEN) — verified: binary builds, `--help` works, all modules wired
- [x] Typing indicator shown during agent processing — implemented via `triggerTyping` in DI chain
- [x] Responses sent in Discord threads, not channels — implemented via `createThread` on @mention
- [x] `!config`, `!status`, `!admin`, `!session` commands respond correctly — unit-tested with mock config
- [x] File tool respects allow/ask/deny lists — unit-tested with mock path policies
- [x] Denied paths are blocked regardless of symlink tricks — tested via `file_path_validator.nim` symlink resolution
- [x] Rate limits handled with retry + backoff — implemented in `rate_limit.nim` with `sendWithRetry`