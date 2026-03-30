---
name: extract-process-flows
description: This skill provides domain knowledge for extracting process flows, data flows, and domain events from code. It should be used when the agent is tasked with tracing function call chains, mapping state machines, documenting async/await sequences, identifying workflows, rendering Mermaid diagrams of execution paths, tracing data through pipelines, documenting data lineage, cataloging domain events published/consumed, or understanding how data enters, transforms, is stored, and exits the system. Make sure to use this skill whenever execution order, data flow, state transitions, data transformations, ETL processes, or domain event models need to be documented, even in non-TypeScript codebases.
user-invocable: false
---

# Process & Data Flows Extraction

Process, data flows, and domain events capture how control, data, and events move through the system — the "what happens, in what order, and what data changes along the way." They answer questions like "what happens when a user registers?", "what are the valid states of an order?", "where does order data come from?", and "what events does the system publish?"

Each flow includes both a Mermaid diagram showing the sequence of operations and an optional data trace table showing how data transforms at each stage. Domain events document the internal event-driven communication patterns.

## What to Extract

### Control Flows (Execution Order)
- **Function call chains** — Sequential operations, especially with `await` or blocking calls
- **State machine implementations** — State transitions, state changes, lifecycle management
- **Workflow orchestrators** — Step-by-step processes, pipeline stages, saga patterns
- **Async/await sequences** — Promise chains, callback flows, async pipelines
- **Event-driven flows** — Event handlers, pub/sub, message consumers, listeners

### Data Flows (Data Movement)
- **Data entry points** — API endpoints, file uploads, webhooks, message queue consumers, CLI inputs
- **Data transformations** — Mapping, enrichment, validation, normalization, aggregation
- **Data storage points** — Database writes/reads, cache sets/gets, file system writes
- **Data exit points** — API responses, outgoing webhooks, email/SMS content, file exports, third-party API calls
- **Data pipelines** — ETL processes, batch jobs, data migration scripts
- **Data lineage** — Where a piece of data originates and all the places it flows to

### Domain Events (Internal Communication)
- **Domain events published** — `EventBus.publish()`, `emitter.emit()`, `dispatch()`, event constructor calls
- **Domain events consumed** — `EventBus.on()`, `@EventHandler()`, `@Subscribe()`, message queue consumers
- **Event payload schemas** — The shape of data carried with each event
- **Event names and types** — Naming conventions, event categorization (domain vs. infrastructure)
- **Event sourcing** — Event store writes, aggregate event sequences, snapshot events

## Where Process & Data Flows Live (vs. Other Types)

- **Process flow vs. user story:** A route handler definition is a *user story* (what the user can do). The internal call chain *within* that handler (validate → create → notify) is a *process flow*.
- **Process flow vs. business rule:** A condition check is a *business rule*. The sequence of steps that includes that check is a *process flow*. Capture the flow here; the constraint in the if-statement belongs in business-rules.
- **Data flow vs. data spec:** A *data spec* defines the shape of data (field names, types, constraints). A *data flow* defines where that data goes and how it transforms. The spec says "Order has items: OrderItem[]"; the flow says "Order items are validated, totaled, stored, and included in the confirmation email."
- **Data flow vs. integration:** An *integration* documents the external service connection (Stripe, S3). A *data flow* shows what data goes to/from that service and what happens to it.
- **Event vs. integration:** An outbound webhook call to Stripe is an *integration* (external service dependency). The *fact that the system fires an `OrderCompleted` event* is a *domain event*. The event handler that then calls Stripe is the bridge. Document the service dependency in integrations; document the event model here.
- **Event vs. process flow:** A sequence of function calls is a *process flow*. The *events that trigger or are emitted during that flow* are *domain events*. Document the execution path in the flow diagram; document the event model in the Events section.

## Hotspot Discovery

Use the Glob and Grep tools to find process and data flow patterns:

```
Grep:  pattern="await\s+\w+\.\w+" type=ts,js,py output_mode=files_with_matches
Grep:  pattern="state|transition|StateMachine" type=ts,js,py,go,java output_mode=files_with_matches
Grep:  pattern="workflow|orchestrat|pipeline|saga" type=ts,js,py,go,java output_mode=files_with_matches
Grep:  pattern="\.then\(|callback|next\(" type=ts,js output_mode=files_with_matches
Grep:  pattern="on\(|subscribe\(|@SubscribeMessage" type=ts,js,py output_mode=files_with_matches
Glob:  **/pipelines/**/*.{ts,js,py,go,java}
Glob:  **/jobs/**/*.{ts,js,py}
Grep:  pattern="\.create\(|\.save\(|\.insert\(|\.update\(" type=ts,js,py,go output_mode=files_with_matches
Grep:  pattern="\.findOne\(|\.findMany\(|\.query\(" type=ts,js,py,go output_mode=files_with_matches
Grep:  pattern="stream|pipe|ETL" type=ts,js,py output_mode=files_with_matches
Glob:  **/events/**/*.{ts,js,py,go,java}
Grep:  pattern="emit|publish|EventBus|EventEmitter|eventBus" type=ts,js,py,go,java output_mode=files_with_matches
Grep:  pattern="@EventHandler|@Subscribe|@OnEvent|@EventListener" type=ts,java,py output_mode=files_with_matches
Grep:  pattern="EventStore|appendEvent|aggregate|DomainEvent" type=ts,js,py,go,java output_mode=files_with_matches
```

**Prioritize:** Start with service files, workflow modules, and state management code. Then check pipeline/job files for batch processing. Skip test files and configuration.

## Pattern Signals

| Code Pattern | Flow | Mermaid Example |
|--------------|------|-----------------|
| `await validate(); await create()` | Registration: validate → create | `validate --> create` |
| `state = 'processing'` | State transition: pending → processing | `Pending --> Processing` |
| `step1(); step2(); step3()` | Sequential workflow | `step1 --> step2 --> step3` |
| `fetch().then().then()` | Async pipeline | `fetch --> then1 --> then2` |
| `on('order:created', handler)` | Event-driven flow | `Event --> Handler` |
| `eventBus.publish(new OrderCreated(order))` | Domain event: OrderCreated published | `Event --> Handler` |
| `@Subscribe('user.created')` | Event consumer: listens for user.created | `Event --> Handler` |
| `const user = await User.create({ ... })` | Data storage: new user written to DB | `Request --> Validate --> Store` |
| `s3.upload(bucket, key, fileData)` | Data exit: data uploaded to S3 | `Transform --> S3 Upload` |
| `await sendEmail({ to, body })` | Data exit: order data in email | `Store --> Email` |

## Output Format

**Per-module extractor output:**
```markdown
# [Module Name] Module

Extraction: [YYYY-MM-DD]
Files Analyzed: [N] files

## Artifacts

### Flow: [Descriptive Name]
**Source:** `filename.ts:15-30`
**Type:** [real-time / batch / event-driven / state-machine]

​```mermaid
flowchart TD
    A[Start] --> B[step1]
    B --> C[step2]
    C --> D[End]
​```

**Description:** [Brief explanation of the flow]

**Data Trace:**
| Stage | Action | Data Shape | Source |
|-------|--------|------------|--------|
| [Entry/Transform/Storage/Exit] | [what happens] | [key fields] | `filename.ts:20` |
```

The **Data Trace** table is optional. Include it when the flow involves notable data transformations, storage, or exit to external systems. For simple control flows where data shape doesn't change meaningfully, omit it.

### Events Published
| Event Name | Trigger | Payload Fields | Source |
|------------|---------|----------------|--------|
| [event name] | [when it fires] | [key fields in payload] | `filename.ts:42` |

### Events Consumed
| Event Name | Handler | Side Effects | Source |
|------------|---------|--------------|--------|
| [event name] | [handler function] | [what the handler does] | `filename.ts:20` |

## Sources
| Ref | Full Path |
|-----|-----------|
| `src/auth/password.ts:40-65` | [src/auth/password.ts:40-65](src/auth/password.ts#L40-L65) |
| `src/orders/orders.service.ts:15` | [src/orders/orders.service.ts:15](src/orders/orders.service.ts#L15) |

**Example: Control Flow (no data trace needed)**
```markdown
### Flow: Password Reset
**Source:** `src/auth/password.ts:40-65`
**Type:** real-time

​```mermaid
flowchart TD
    A[Request] --> B[validateToken]
    B -->|Valid| C[updatePassword]
    B -->|Invalid| D[Error]
    C --> E[notifyUser]
​```

**Description:** Password reset with token validation
```

**Example: Full Flow with Data Trace**
```markdown
### Flow: Order Placement
**Source:** `src/orders/orders.service.ts:15-45`
**Type:** real-time

​```mermaid
flowchart TD
    A[POST /orders\nRequest body] --> B[Validate items\nCheck stock]
    B --> C[Calculate total\nApply discounts]
    C --> D[Store order\nPostgreSQL]
    D --> E[Publish event\nOrderCreated]
    E --> F[API response\n201 + order JSON]
​```

**Description:** New order placement with validation, persistence, and event publishing

**Data Trace:**
| Stage | Action | Data Shape | Source |
|-------|--------|------------|--------|
| Entry | Receive order request | `{ items: OrderItem[], shippingAddress: string }` | `src/orders/dto/create-order.dto.ts:3` |
| Transform | Validate items, check stock | Validated items + available quantities | `src/orders/orders.service.ts:20` |
| Transform | Calculate total, apply coupon | `{ subtotal, discount, total }` | `src/orders/orders.service.ts:30` |
| Storage | Persist order to database | `Order entity { id, status: PENDING, total, userId }` | `src/orders/orders.service.ts:38` |
| Exit | Publish domain event | `OrderCreated { orderId, userId, total }` | `src/orders/orders.service.ts:42` |
| Exit | Return API response | `{ id, status, total, createdAt }` | `src/orders/orders.service.ts:45` |
```

**Example: Batch Flow**
```markdown
### Flow: Order Export (Batch)
**Source:** `src/jobs/order-export.job.ts:1-25`
**Type:** batch

​```mermaid
flowchart LR
    A[Cron trigger\ndaily at 2am] --> B[Query completed\norders from last day]
    B --> C[Map to CSV rows\nformat dates/amounts]
    C --> D[Upload to S3\norders-YYYY-MM-DD.csv]
    D --> E[Notify ops team\nvia Slack]
​```

**Description:** Nightly export of completed orders to S3 as CSV

**Data Trace:**
| Stage | Action | Data Shape | Source |
|-------|--------|------------|--------|
| Entry | Cron schedule triggers job | Date range: yesterday | `src/jobs/order-export.job.ts:5` |
| Storage | Query completed orders | `Order[]` with items | `src/jobs/order-export.job.ts:10` |
| Transform | Serialize to CSV | CSV rows: id, date, customer, items, total | `src/jobs/order-export.job.ts:15` |
| Exit | Upload CSV to S3 | File: `exports/orders-2026-03-26.csv` | `src/jobs/order-export.job.ts:20` |
```

## Mermaid Diagram Types

| Flow Type | Mermaid Type | When to Use |
|-----------|--------------|-------------|
| Sequential workflow | `flowchart TD` | Steps that execute one after another |
| Conditional flow | `flowchart TD` | Steps with yes/no branches (`\|Yes\|`, `\|No\|`) |
| State machine | `stateDiagram-v2` | Named states with transition events |
| Data pipeline / batch | `flowchart LR` | Left-to-right for temporal data movement |
| Parallel steps | `flowchart TD` | `A --> B` & `A --> C` for concurrent operations |

## Core Principles

**Trace the path, not just the function.** A flow is more than a function name — it's the sequence of operations. Follow at least one function call deep. If `register()` calls `validate()` then `create()`, trace into both and show what each does.

**Include error paths.** A flow that only shows the happy path is misleading. If there's a try-catch or conditional error return, include it as a branch.

**Keep diagrams focused.** One flow per diagram. If a function has 8+ steps, consider splitting into sub-flows or summarizing groups of steps.

**Use descriptive node names.** Node labels like `validateUser` or `checkStock` are far more useful than `B`, `C`, `D`. Name nodes after the function or operation they represent.

**Include data traces when data transforms meaningfully.** Not every flow needs a data trace table. Add one when the flow involves data entering the system, being transformed, stored, or exiting to external systems. For pure control flows (auth checks, validation gates), the diagram alone is sufficient.

**Note the flow type.** Tag each flow as real-time (API request → response), batch (cron job, scheduled task), event-driven (triggered by an event), or state-machine (entity lifecycle). This tells analysts the execution context.

**Capture all exit points.** Data that enters the system can exit through API responses, webhooks, emails, file exports, third-party API calls, or message queues. Document every exit.

**Distinguish domain events from infrastructure events.** `OrderCreated` is a domain event (business stakeholders care about it). `CacheInvalidated` is an infrastructure event (only engineers care about it). Group or tag them differently when possible.

**Map the full event lifecycle.** An event is only half-documented if you list only the publisher. Identify who publishes it, what the payload contains, and who consumes it. The consumer list is often as important as the event definition.

**Identify event ordering dependencies.** If `OrderShipped` always fires after `OrderCompleted`, note that. If `PaymentFailed` triggers `OrderCancelled`, document the causal chain. Event sequences are critical for understanding system behavior.

**Flag gaps.** If a multi-step handler has no try-catch or error branch, note: `MISSING: No error handling path documented for [flow]`. If an async operation has no timeout or cancellation handling, note: `MISSING: No timeout/cancellation handling for [operation]`. If a state machine has states with no outgoing transitions, note: `MISSING: No transition defined from [state]`.
