# Task 2.2: ReAct Agent Loop - Verification Test Plan

## Overview
This document outlines the verification tests for the ReAct agent loop implementation (task 2.2). These tests will be used to verify Jules' implementation once it's complete.

## Test Categories

### 1. Basic Functionality Tests
**Objective**: Verify core agent loop functionality

**Test Cases**:
1. **Simple text response**
   - Input: "Say hello"
   - Mock LLM response: Text only ("Hello!")
   - Expected: Agent returns "Hello!" without tool calls
   - Verification: No tool calls executed, memory logged

2. **Tool-using response**
   - Input: "What's 2+2?"
   - Mock LLM response: Tool call to calculator
   - Mock tool response: "4"
   - Mock LLM follow-up: "The answer is 4"
   - Expected: Agent calls tool, uses result, returns final answer
   - Verification: Tool called once, memory has all messages

3. **Multiple tool calls**
   - Input: Complex query requiring multiple tools
   - Mock: Series of tool calls and responses
   - Expected: Agent handles sequential tool usage
   - Verification: Correct tool execution order

### 2. Error Handling Tests
**Objective**: Verify robust error handling

**Test Cases**:
4. **Tool error recovery**
   - Input: Query requiring tool
   - Mock tool: Returns error
   - Mock LLM: Adapts strategy, tries different approach
   - Expected: Agent handles tool error gracefully
   - Verification: Error logged, agent continues

5. **LLM error recovery**
   - Input: Any query
   - Mock LLM: Returns 500 error, then succeeds on retry
   - Expected: Agent retries and succeeds
   - Verification: Retry logic works

6. **Invalid tool call**
   - Input: Query
   - Mock LLM: Returns invalid tool call (non-existent tool)
   - Expected: Agent reports tool not found, continues
   - Verification: Error handling works

### 3. Loop Control Tests
**Objective**: Verify loop management

**Test Cases**:
7. **Max iterations**
   - Input: Query that causes infinite loop
   - Mock LLM: Always returns tool call
   - Expected: Agent stops after max iterations (default 10)
   - Verification: Loop detection works

8. **Loop detection**
   - Input: Query
   - Mock LLM: Returns same tool call 3 times in a row
   - Expected: Agent detects loop, stops with message
   - Verification: Loop detection triggers at 3 repeats

9. **Context window management**
   - Input: Long conversation history
   - Expected: Agent truncates history to fit context
   - Verification: Context management works

### 4. Memory Integration Tests
**Objective**: Verify SQLite memory integration

**Test Cases**:
10. **Session creation**
    - Input: Any query
    - Expected: New session created in SQLite
    - Verification: Session record exists

11. **Message logging**
    - Input: Query with tool usage
    - Expected: All messages logged (user, assistant, tool)
    - Verification: All messages in database with correct metadata

12. **Token tracking**
    - Input: Query
    - Expected: Token counts logged for each message
    - Verification: Token usage tracked accurately

13. **Session retrieval**
    - Input: Query about previous session
    - Expected: Agent can retrieve session history
    - Verification: History retrieval works

### 5. Integration Tests
**Objective**: Verify integration with other components

**Test Cases**:
14. **Config integration**
    - Input: Query with custom config (different model, temperature)
    - Expected: Agent uses config values
    - Verification: Config properly integrated

15. **Tool registry integration**
    - Input: Query requiring shell tool
    - Expected: Agent uses registered shell tool
    - Verification: Tool registry integration works

16. **LLM client integration**
    - Input: Query
    - Expected: Agent uses LLM client correctly
    - Verification: Proper HTTP requests, headers, etc.

## Test Implementation Strategy

### Mock Components
1. **Mock LLM Server**: Use existing mock from tests (or task 2.3 when available)
2. **Mock Tool Registry**: Test implementation with stub tools
3. **In-memory SQLite**: For testing memory integration

### Test Files
- `tests/tagent_loop.nim`: Main test file
- `tests/mock_components.nim`: Shared mock components
- `tests/test_helpers.nim`: Test utilities

### Verification Steps
For each test:
1. **Setup**: Initialize mocks, create agent
2. **Execution**: Run agent with test input
3. **Assertion**: Verify expected behavior
4. **Cleanup**: Reset state

## Acceptance Criteria Verification

From the plan, verify each acceptance criterion:

1. [ ] **Agent responds with text when no tools needed** → Test 1
2. [ ] **Agent calls tool when appropriate, uses result, continues** → Test 2
3. [ ] **Agent stops after max iterations with message** → Test 7
4. [ ] **Repeated same tool call 3× triggers loop detection** → Test 8
5. [ ] **Tool errors reported back to LLM** → Test 4
6. [ ] **Every turn logged to SQLite** → Test 11
7. [ ] **Tests pass with mock server** → All tests

## Quality Gates

1. **Code Quality**: `make desloppify` score ≥ 90
2. **Test Coverage**: All critical paths covered
3. **Integration**: Works with existing components
4. **Performance**: No memory leaks, reasonable performance
5. **Documentation**: Code is well-documented

## Ready for Verification

Once Jules completes task 2.2 implementation, run these verification tests to ensure quality and correctness.