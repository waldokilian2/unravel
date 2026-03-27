---
name: extract-process-flows
description: This skill provides domain knowledge for extracting process flows from code. It should be used when the agent is tasked with tracing function call chains, mapping state machines, documenting async/await sequences, identifying workflows, or rendering Mermaid diagrams of execution paths. Make sure to use this skill whenever execution order, data flow, or state transitions need to be documented, even in non-TypeScript codebases.
---

# Process Flows Extraction

Process flows capture how data and control move through the system — the "what happens, in what order." They answer questions like "what happens when a user registers?" or "what are the valid states of an order?"

## What to Extract

Process flows show how data and control move through the system:

- **Function call chains** — Sequential operations, especially with `await` or blocking calls
- **State machine implementations** — State transitions, state changes, lifecycle management
- **Workflow orchestrators** — Step-by-step processes, pipeline stages, saga patterns
- **Async/await sequences** — Promise chains, callback flows, async pipelines
- **Event-driven flows** — Event handlers, pub/sub, message consumers, listeners

## Where Process Flows Live (vs. Other Types)

- **Process flow vs. user story:** A route handler definition is a *user story* (what the user can do). The internal call chain *within* that handler (validate → create → notify) is a *process flow*.
- **Process flow vs. business rule:** A condition check is a *business rule*. The sequence of steps that includes that check is a *process flow*. Capture the flow here; the constraint in the if-statement belongs in business-rules.

## Hotspot Discovery

Use the Glob and Grep tools to find files with process flows:

```
Grep:  pattern="await\s+\w+\.\w+" type=ts,js,py output_mode=files_with_matches
Grep:  pattern="state|transition|StateMachine" type=ts,js,py,go,java output_mode=files_with_matches
Grep:  pattern="workflow|orchestrat|pipeline|saga" type=ts,js,py,go,java output_mode=files_with_matches
Grep:  pattern="\.then\(|callback|next\(" type=ts,js output_mode=files_with_matches
Grep:  pattern="on\(|subscribe\(|@SubscribeMessage" type=ts,js,py output_mode=files_with_matches
```

**Prioritize:** Start with service files, workflow modules, and state management code. Skip test files and configuration.

## Pattern Signals

| Code Pattern | Process Flow | Mermaid Example |
|--------------|--------------|-----------------|
| `await validate(); await create()` | Registration: validate → create | `validate --> create` |
| `state = 'processing'` | State transition: pending → processing | `Pending --> Processing` |
| `step1(); step2(); step3()` | Sequential workflow | `step1 --> step2 --> step3` |
| `fetch().then().then()` | Async pipeline | `fetch --> then1 --> then2` |
| `on('order:created', handler)` | Event-driven flow | `Event --> Handler` |
| `def process_order(order): ...` (calls 3+ functions) | Order processing flow | `validate --> charge --> ship` |

## Output Format

**Per-module extractor output:**
```markdown
# [Module Name] Module

Extraction: [YYYY-MM-DD]
Files Analyzed: [N] files

## Artifacts

### Flow: [Descriptive Name]
**Source:** [filename.ts:15-30](path/to/filename.ts#L15-L30)

​```mermaid
flowchart TD
    A[Start] --> B[step1]
    B --> C[step2]
    C --> D[End]
​```

**Description:** [Brief explanation of the flow]
```

**Example output:**
```markdown
## auth Module

### Flow: User Registration
**Source:** [src/auth/register.ts:15-30](src/auth/register.ts#L15-L30)

​```mermaid
flowchart TD
    A[Request] --> B[validateUser]
    B --> C[createUser]
    C --> D[sendEmail]
    D --> E[Response]
​```

**Description:** New user registration with validation and email notification

### Flow: Password Reset
**Source:** [src/auth/password.ts:40-65](src/auth/password.ts#L40-L65)

​```mermaid
flowchart TD
    A[Request] --> B[validateToken]
    B -->|Valid| C[updatePassword]
    B -->|Invalid| D[Error]
    C --> E[notifyUser]
​```

**Description:** Password reset with token validation
```

## Mermaid Diagram Types

| Flow Type | Mermaid Type | When to Use |
|-----------|--------------|-------------|
| Sequential workflow | `flowchart TD` | Steps that execute one after another |
| Conditional flow | `flowchart TD` | Steps with yes/no branches (`\|Yes\|`, `\|No\|`) |
| State machine | `stateDiagram-v2` | Named states with transition events |
| Time-sequenced | `flowchart LR` | Left-to-right when time/order matters visually |
| Parallel steps | `flowchart TD` | `A --> B` & `A --> C` for concurrent operations |

## Core Principles

**Trace the path, not just the function.** A process flow is more than a function name — it's the sequence of operations. Follow at least one function call deep. If `register()` calls `validate()` then `create()`, trace into both and show what each does.

**Include error paths.** A flow that only shows the happy path is misleading. If there's a try-catch or conditional error return, include it as a branch.

**Keep diagrams focused.** One flow per diagram. If a function has 8+ steps, consider splitting into sub-flows or summarizing groups of steps.

**Use descriptive node names.** Node labels like `validateUser` or `checkStock` are far more useful than `B`, `C`, `D`. Name nodes after the function or operation they represent.
