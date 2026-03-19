---
name: extract-process-flows
description: Use when analyzing code for function call sequences, state machine transitions, or workflow orchestrators. Automatically triggers on: function call chains, state transitions, workflow definitions, async/await sequences, promise chains.
---

# Extracting Process Flows

## Overview
Map process flows by identifying function call stacks, state machine transitions, and workflow orchestrators to understand how data and control flow through the system.

## When to Use
Use when analyzing code for function call sequences, state machine transitions, or workflow orchestrators. Triggers on:
- Function call chains (especially with await)
- State machine implementations
- Workflow orchestrators
- Async/await sequences
- Promise chains

## Always Use Orchestration

This skill **always** orchestrates subagent execution. Even for single-file extractions, a fresh subagent is dispatched.

**Why?**
- Fresh context per extraction (no pollution)
- Consistent review process (two-stage: spec → quality)
- Parallelizable by design
- Matches Superpowers' subagent-driven-development pattern

**How it works:**
1. You (orchestrator) analyze scope and identify files
2. Dispatch one or more process-flows-extractor-subagent tasks
3. For each completed task: run spec compliance review → quality review
4. Aggregate results into docs/output/process-flows.md

## Core Principle
**Trace-first: Follow the execution path from entry point to completion**

## Checklist

1. **Hotspot Discovery** - Find files with flow patterns
2. **Trace** - Follow function call chains
3. **Document** - Write to docs/output/process-flows.md
4. **Verify** - Confirm flows are complete

## Hotspot Discovery

```bash
# Find function call chains
grep -r "await.*\." --include="*.ts" --include="*.js" -l | head -20

# Find state machines
grep -r "state\|transition\|StateMachine" --include="*.ts" -l | head -20

# Find workflow definitions
grep -r "workflow\|orchestrat\|step\|pipeline" --include="*.ts" -l | head -20
```

Exclude generated code:
```bash
--exclude-dir=node_modules --exclude-dir=dist --exclude-dir=build --exclude-dir=.next
```

## Pattern Signals

| Pattern | Example | Process Flow |
|---------|---------|---------------|
| Async chain | `await validateUser(); await createUser();` | Registration flow |
| State machine | `transitionTo('processing')` | State transition |
| Orchestrator | `step1(); step2(); step3();` | Sequential workflow |
| Promise chain | `fetch().then().then()` | Async pipeline |
| Event handler | `on('click', handleClick)` | Event-driven flow |

## Output Format

```markdown
## Process Flows

Extraction: 2025-03-17

### User Registration
1. validateInput() → createUser() → sendWelcomeEmail()
   Source: src/auth/registration.ts:45-67

### Payment Processing
1. validatePayment() → chargeCard() → updateOrder() → sendReceipt()
   Source: src/payment/process.ts:12-45

### Order State Machine
States: `pending` → `processing` → `shipped` → `delivered`
Source: src/orders/StateMachine.ts:10-25
```

## Token Efficiency
- Trace one level deep unless complex workflow
- Use numbered lists for sequences
- Only read files that match hotspot patterns
- Extract flow summaries, not full implementations
- If 50+ flows found, suggest analyzing by module

## Edge Cases
- **No patterns found**: "No process flows detected. Check: are you in the right directory?"
- **Too many patterns**: "Large codebase detected. Analyzing module-by-module..."
- **Circular dependencies**: Flag as "CIRCULAR: X calls Y which calls X"
- **Complex branching**: Extract with note "[COMPLEX: Multiple paths, verify coverage]"
- **Dynamic dispatch**: Extract with note "[DYNAMIC: Runtime-determined call path]"

## Red Flags

**Never:**
- Assume execution order without tracing
- Extract flow without reading actual implementation
- Skip error handling paths
- Ignore state machine transitions
- Document inferred flows without source verification

**Always:**
- Follow actual execution paths (read the code)
- Include error/exception paths in flows
- Document state transitions explicitly
- Trace at least one level deep
- Include source locations for each flow step

## Task Dispatching

**Single file:**
```
Task("Extract process flows from payment.ts")

Subagent receives:
- File: payment.ts
- Artifact type: process-flows
- Output: docs/output/process-flows.md
```

**Multiple files (parallel):**
```
Task("Extract process flows from auth module")
Task("Extract process flows from payment module")
Task("Extract process flows from user module")

All three run concurrently
```

## Two-Stage Review (Required)

After each subagent completes:

**Stage 1: Spec Compliance Review**
```
Task("Review spec compliance for process flows extraction")
- All flows in scope extracted?
- No artifacts outside scope?
- Output format followed?
```

**Stage 2: Quality Review** (only after Stage 1 passes)
```
Task("Review quality for process flows extraction")
- Each flow matches actual code?
- No hallucinations?
- Clear, well-documented?
```

## Integration

**Required subagents:**
- unravel:process-flows-extractor-subagent - Focused extraction
- unravel:spec-compliance-reviewer - Stage 1 review
- unravel:quality-reviewer - Stage 2 review

**For large tasks (10+ flows, 5+ files):**
- Use unravel:orchestrating-extractions for full orchestration
- Use unravel:dispatching-parallel-extractors for parallel execution
- Use unravel:planning-extractions to create task plans
