## NOTE: This project has been renamed from Mercury Agent to Talos Agent. All package names (mercury_core, mercury_agent, mercury_code) are now (talos_core, talos_agent, talos_code).

# Task 6: Plan-Execute Mode

**Status**: 🔴 Not Started
**Dependencies**: Task 1 (Agent Loop relocation)
**Complexity**: Medium

---

## Target

- `mercury_core/src/mercury_core/agent_loop.nim` (new location after Task 1)
- `mercury_core/src/mercury_core/plan_executor.nim` (new)
- `mercury_agent/src/mercury_agent.nim`

## Current State

- `agent_loop.nim` runs a flat ReAct loop: LLM → tool calls → LLM → tool calls → … → final answer.
- Sub-agent delegation (`delegate.nim`) covers some multi-step work but doesn't do structured planning.
- The ROADMAP lists Plan-Execute as "Low (deferred)".

## Change

### Phase 6a — Plan data model
1. Create `plan_executor.nim`:
   ```nim
   type
     PlanStep* = object
       id*: string               # "1", "2a", etc.
       description*: string      # human-readable
       toolName*: string          # tool to use ("" for LLM reasoning)
       toolArgs*: string          # JSON args ("" for reasoning)
       dependsOn*: seq[string]    # step IDs this step waits for
       status*: StepStatus
       result*: string            # output after execution

     StepStatus* = enum
       ssPending, ssRunning, ssComplete, ssFailed, ssSkipped

     ExecutionPlan* = object
       goal*: string
       steps*: seq[PlanStep]
       currentStep*: int

     PlanResult* = object
       plan*: ExecutionPlan
       finalAnswer*: string
       stats*: AgentStats
       allStepsComplete*: bool
   ```

### Phase 6b — Plan generation
1. Add `generatePlan(llm, goal, tools): ExecutionPlan` — sends a specialized system prompt asking the LLM to output a JSON plan.
2. System prompt template:
   ```
   You are a planning agent. Given a goal and available tools, produce a step-by-step plan.
   Output ONLY valid JSON: {"goal": "...", "steps": [{"id": "1", "description": "...", "toolName": "shell", "toolArgs": "..."}, ...]}
   ```
3. Parse and validate the plan: all `id` fields unique, `dependsOn` references valid, tools exist in registry.

### Phase 6c — Plan executor
1. Add `executePlan(agentCfg, llm, registry, memory, plan): PlanResult`:
   - Topological sort steps by `dependsOn`.
   - Execute each step in order:
     - If `toolName` is non-empty: execute the tool, store result.
     - If `toolName` is empty: call LLM with the step description as a "reasoning step" — the LLM gets the plan context and previous results.
   - On step failure: mark failed, continue dependent steps as `ssSkipped`, attempt remaining independent steps.
   - After all steps complete, call LLM one final time to synthesize the final answer from all step results.

### Phase 6d — Integration into agent loop
1. Add `executionPlan*: Option[ExecutionPlan]` to `AgentConfig`.
2. In `runAgentLoop`, if a plan is provided, use `executePlan` instead of the ReAct loop.
3. Add `--plan` flag to CLI:
   ```bash
   ./mercury_agent ask "build a todo app" --plan
   ```
   This switches from ReAct to Plan-Execute mode.

### Phase 6e — Plan display
1. In CLI, display the plan before execution:
   ```
   Plan:
     1. [shell] nimble init todo_app
     2. [shell] cd todo_app && nimble build
     3. [reasoning] Review build output and suggest fixes
   Executing...
   ```
2. Show step status in real-time (✓ complete, ✗ failed, → skipped).

## Acceptance

- `generatePlan` produces valid JSON plan from LLM. Test with mock LLM.
- `executePlan` runs steps in correct dependency order. Test with a 3-step plan where step 3 depends on step 1.
- Step failure doesn't crash the executor; dependent steps are skipped.
- CLI `--plan` flag switches to Plan-Execute mode.
- Plan is displayed before execution, step status shown.
- Existing ReAct loop behavior unchanged when `--plan` is not used.
- All 460 existing tests pass.