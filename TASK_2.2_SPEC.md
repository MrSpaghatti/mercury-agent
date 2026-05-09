# Task 2.2: ReAct Agent Loop Specification
## For Delegation to Jules Agent

**Project**: Mercury Agent (Nim-based AI agent harness)
**Repo**: MrSpaghatti/mercury-agent
**Location**: `/home/spag/mercury`
**Task**: 2.2 from mercury-agent plan
**Depends on**: Task 2.1 (Tool registry + shell tool)

## REQUIREMENTS

### 1. Create Agent Loop Module
**File**: `mercury_core/src/mercury_core/agent_loop.nim`

**Core Types**:
```nim
type
  AgentLoop* = object
    llm: LLMClient
    tools: ToolRegistry
    memory: Memory
    config: MercuryConfig
    maxIterations: int
    currentIteration: int
    
  AgentResponse* = object
    content: string
    toolCalls: seq[ToolCall]
    tokenUsage: TokenUsage
    iterations: int
    sessionId: string
```

### 2. Implement ReAct Loop Algorithm
**Steps**:
1. **Initialize**: Load config, create LLM client, tool registry, memory session
2. **Build Messages**: System prompt + history + user input
3. **Call LLM**: With messages + tool definitions
4. **Parse Response**:
   - Text response → return final answer
   - Tool calls → execute tools, append results, loop
5. **Loop Control**: Max iterations (default 10), loop detection
6. **Logging**: Every turn logged to SQLite memory

**System Prompt** (~200 tokens, PI Agent philosophy):
```
You are Mercury, a helpful AI assistant. You can use tools to help answer questions.

When you need to use a tool, respond with tool_calls. Otherwise, respond with text.

Think step by step. If a tool fails, try a different approach. If you get stuck, ask for clarification.
```

### 3. Key Features to Implement
- **Text Response Handling**: Return text when no tools needed
- **Tool Execution**: Call tools via ToolRegistry, handle results
- **Loop Detection**: Repeated same tool call 3× triggers loop detection
- **Error Handling**: Tool errors reported back to LLM gracefully
- **Token Tracking**: Track usage per iteration, total
- **Memory Integration**: Log every turn to SQLite (session, messages, tokens)
- **Context Management**: Handle context limits (truncate history if needed)

### 4. Memory Integration
- Create new session for each agent run
- Append each message (user, assistant, tool) to memory
- Store token counts for cost tracking
- Enable searchable history via FTS5

### 5. Tests
**File**: `tests/tagent_loop.nim`
**Test Cases**:
1. Simple text response (no tools)
2. Tool-using response (calls shell tool)
3. Loop detection (repeated tool calls)
4. Tool error handling
5. Max iteration limit
6. Memory logging verification
7. Token usage tracking

## CONTEXT

### Dependencies
- **Task 1.2**: LLM client (`llm_client.nim`) - provides `LLMClient`, `ChatMessage`, `ToolCall`, `TokenUsage`
- **Task 2.1**: Tool registry (`tool_registry.nim`) - provides `ToolRegistry`, `Tool` concept
- **Task 1.4**: Memory module (`memory.nim`) - provides `Memory`, `newSession`, `appendMessage`
- **Task 1.1**: Config module (`config.nim`) - provides `MercuryConfig`

### Existing Code Patterns
- Use existing error handling patterns (custom exception types)
- Follow module structure from other core modules
- Use JSON serialization for tool calls/results (as in memory module)
- Integrate with existing test patterns

### Constraints
- **DO NOT** add Plan-Execute mode (defer to v2)
- **DO NOT** add sub-agent delegation (defer to v2)
- **DO NOT** add reflection/self-critique (defer to v2)
- Keep system prompt minimal (~200 tokens)
- Focus on reliability over features

## VERIFICATION CRITERIA

### Acceptance Tests
- [ ] Agent responds with text when no tools needed
- [ ] Agent calls tool when appropriate, uses result, continues
- [ ] Agent stops after max iterations with message
- [ ] Repeated same tool call 3× triggers loop detection
- [ ] Tool errors reported back to LLM
- [ ] Every turn logged to SQLite
- [ ] Token usage tracked correctly
- [ ] All tests pass with mock server

### Quality Gates
- `nimble test tagent_loop` passes
- Project still builds: `nimble build`
- No memory leaks (clean session management)
- Thread-safe for concurrent use
- Follows existing code quality standards

## INTEGRATION POINTS

### With Task 2.1 (Tool Registry)
```nim
# Expected interface from task 2.1
proc executeTool*(registry: ToolRegistry, name: string, arguments: string): string
proc getToolSchema*(registry: ToolRegistry): JsonNode  # OpenAI-compatible
```

### With Task 1.4 (Memory)
```nim
# Expected interface from task 1.4
proc newSession*(memory: Memory, metadata: string = ""): string
proc appendMessage*(memory: Memory, sessionId: string, message: ChatMessage, 
                    tokensIn: int, tokensOut: int)
```

### Mock Testing
- Use mock LLM server (from task 2.3 when available)
- Mock tool registry for unit tests
- In-memory SQLite for testing

## READY FOR DELEGATION

This specification is complete and ready for delegation to Jules agent once task 2.1 (Tool registry) is complete. The task is well-scoped with clear dependencies, requirements, and verification criteria.