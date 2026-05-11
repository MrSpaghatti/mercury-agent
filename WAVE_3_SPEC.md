# Wave 3: CLI + Integration Specification
## For Delegation to Jules Agent (After Wave 2 Completion)

**Project**: Mercury Agent (Nim-based AI agent harness)
**Repo**: MrSpaghatti/mercury-agent
**Location**: `/home/spag/mercury`
**Wave**: 3 (CLI + Integration)
**Tasks**: 3.1, 3.2, 3.3 (sequential)
**Depends on**: Wave 2 completion (especially task 2.2)

---

## TASK 3.1: CLI Interface (cligen)

### Requirements
**File**: `mercury_agent/src/main.nim`

**CLI Features**:
- Use `cligen` library for command-line parsing
- Main command: `mercury [options] "prompt"`
- Options:
  - `--provider`: string (openrouter|vllm)
  - `--model`: string (model name)
  - `--config`: string (config file path)
  - `--verbose`: bool (verbose output)
  - `--version`: bool (print version)
- Subcommands:
  - `mercury "prompt"`: Run agent with prompt
  - `mercury --version`: Print version
  - `mercury init`: Create default config file
  - `mercury history`: Show recent sessions
  - `mercury session <id>`: Show specific session
- Stdin support: `echo "hello" | mercury`
- Colorized output with `std/terminal`
- Token usage summary after each response

**Implementation Details**:
- Version from `mercury_agent.nimble` or constant
- Config loading via existing `config.nim` module
- Integration with agent loop (task 2.2)
- Error handling with clear messages
- Graceful Ctrl+C handling

**Tests**: `tests/tcli.nim`
- Test argument parsing
- Test subcommands
- Test stdin handling
- Test error cases

### Acceptance Criteria
- [ ] `mercury --version` prints "mercury X.Y.Z"
- [ ] `mercury "hello"` runs agent and prints response
- [ ] `mercury --provider vllm "hello"` uses vLLM provider
- [ ] `mercury init` creates default config file
- [ ] `mercury history` shows recent sessions
- [ ] `echo "hello" | mercury` reads from stdin
- [ ] Token usage printed after response
- [ ] All tests pass

---

## TASK 3.2: Integration - Wire Everything Together

### Requirements
**File**: `mercury_agent/src/mercury_agent.nim`

**Integration Pipeline**:
1. Load config (from CLI args or file)
2. Initialize LLM client (with config)
3. Initialize tool registry (register shell tool)
4. Initialize memory (SQLite database)
5. Create new session
6. Run agent loop with prompt
7. Print response with formatting
8. Print token usage summary
9. Save session to memory

**Component Wiring**:
- Config → LLMClient → ToolRegistry → AgentLoop → Memory
- Error handling at each stage
- Clean shutdown on Ctrl+C
- Session persistence

**Key Integration Points**:
- Use existing modules: config, llm_client, tool_registry, agent_loop, memory
- Ensure all components work together
- Handle initialization order dependencies
- Manage resource cleanup

**Tests**: Integration tests with mock server
- End-to-end happy path
- Error path testing
- Network failure handling
- Session persistence verification

### Acceptance Criteria
- [ ] Full pipeline runs end-to-end with mock server
- [ ] Each component initializes in correct order
- [ ] Errors at each stage produce clear messages
- [ ] Ctrl+C during agent loop exits cleanly
- [ ] Session saved to SQLite after completion
- [ ] Integration test passes

---

## TASK 3.3: End-to-End Tests + Documentation

### Requirements
**Documentation**:
- `README.md`: Overview, quick start, config reference, tool docs, dev guide
- `docs/architecture.md`: Component diagram, data flow, design decisions
- `CONTRIBUTING.md`: Development setup, testing, contribution guidelines

**End-to-End Tests**:
- Comprehensive test suite covering all paths:
  - Happy path (text response)
  - Tool path (tool usage)
  - Error path (tool errors, network errors)
  - Network path (timeouts, retries)
  - Loop path (max iterations, loop detection)
- All tests pass without network (use mock server)
- Test coverage for critical paths

**Code Quality**:
- Run `desloppify` scan
- Fix any issues found
- Target score ≥ 90

### Acceptance Criteria
- [ ] All end-to-end tests pass
- [ ] `nimble test` passes with no network
- [ ] README.md covers quick start, config, tools, development
- [ ] `docs/architecture.md` has component diagram
- [ ] `CONTRIBUTING.md` has dev setup instructions
- [ ] `make desloppify` passes with score ≥ 90

---

## DEPENDENCIES

### Required from Wave 2
- **Task 2.2**: Agent loop (core ReAct implementation)
- **Task 2.1**: Tool registry (for shell tool integration)
- **Task 2.3**: Mock server (optional, for testing)

### Existing Components (Wave 1)
- **Task 1.1**: Config module
- **Task 1.2**: LLM client
- **Task 1.3**: Token counter
- **Task 1.4**: Memory module

### External Dependencies
- `cligen` library (for CLI)
- `db_connector` (already in use)
- `std/terminal` (for colorized output)

## VERIFICATION STRATEGY

### For Each Task
1. **Code Review**: Read implementation, check against requirements
2. **Build Test**: `nimble build` must succeed
3. **Unit Tests**: Task-specific tests must pass
4. **Integration Tests**: End-to-end tests must pass
5. **Manual Testing**: Run CLI commands, verify behavior

### Quality Gates
- No compilation warnings/errors
- All tests pass
- Code follows existing patterns
- Error handling is robust
- Documentation is clear and complete

## READY FOR DELEGATION

Wave 3 tasks are sequential and depend on Wave 2 completion. Once task 2.2 (agent loop) is complete, these tasks can be delegated to Jules in sequence:
1. Task 3.1 (CLI interface)
2. Task 3.2 (Integration)
3. Task 3.3 (Documentation + tests)

Each task has clear requirements, acceptance criteria, and verification steps.