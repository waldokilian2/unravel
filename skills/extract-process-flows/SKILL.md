---
name: extract-process-flows
description: Domain knowledge for extracting process flows - function call sequences, state machines, workflows
---

# Process Flows Extraction

Domain knowledge for extracting process flows from code.

## What to Extract

Process flows show how data and control move through the system:

- **Function call chains** - Especially with await, sequential calls
- **State machine implementations** - State transitions, state changes
- **Workflow orchestrators** - Step-by-step processes
- **Async/await sequences** - Promise chains, async flows
- **Event-driven flows** - Event handlers, subscribers, listeners

## Hotspot Discovery

```bash
# Find function call chains
grep -r "await.*\." --include="*.ts" --include="*.js" -l | head -20

# Find state machines
grep -r "state\|transition\|StateMachine" --include="*.ts" -l | head -20

# Find workflow definitions
grep -r "workflow\|orchestrat\|step\|pipeline" --include="*.ts" -l | head -20

# Find promise chains
grep -r "\.then(" --include="*.ts" --include="*.js" -l | head -20
```

## Pattern Signals

| Code Pattern | Process Flow |
|--------------|--------------|
| `await validateUser(); await createUser();` | Registration: validateUser() → createUser() |
| `transitionTo('processing')` | State transition: pending → processing |
| `step1(); step2(); step3();` | Sequential workflow: step1 → step2 → step3 |
| `fetch().then().then()` | Async pipeline: fetch → then → then |
| `on('click', handleClick)` | Event-driven flow: click → handleClick |
| `states: ['pending', 'processing', 'done']` | State machine with 3 states |

## Output Format

**Note:** This format is what the extractor outputs per module. The merger will combine all module outputs and add `# Process Flows` as the top-level title.

**Per-module extractor output:**
```markdown
## [Module Name] Module

Extraction: [YYYY-MM-DD]
Files Analyzed: [N] files

1. [step1]() → [step2]() → [step3]()
   Source: [file:line-range]

2. [step1]() → [step2]()
   Source: [file:line-range]
```

**Final merged output (after merger combines all modules):**
```markdown
# Process Flows

Extraction: [YYYY-MM-DD]

## Extraction Summary
- **Total Artifacts:** [count]
- **Files Analyzed:** [unique file count]
- **Modules:** [list]
- **Verification:** Each module independently verified

---

## auth Module
1. [step1]() → [step2]() → [step3]()
   Source: [file:line-range]

## payment Module
States: `[state1]` → `[state2]` → `[state3]`
Transitions: [file:line-range]
```

## Core Principles

**Trace-first:** Follow the execution path from entry point to completion

**One level deep:** Trace at least one function call deep

**Include errors:** Don't skip error/exception paths

**Source locations:** Include file:line-range for each flow step
