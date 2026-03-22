---
name: using-unravel
description: Use when starting any code analysis task - establishes how to find and use Unravel
---

# Using Unravel

You have Unravel superpowers. Unravel automatically extracts business artifacts from code.

## What Unravel Does

Extracts and documents:
- **Business Rules** - Conditional logic, validation, exceptions
- **Process Flows** - Function call chains, state machines, workflows
- **Data Specs** - Schemas, ORMs, DTOs, validation
- **User Stories** - Controllers, routes, endpoints
- **Security/NFRs** - Middleware, auth, logging, performance
- **Integrations** - HTTP calls, APIs, env vars, external services

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Unravel Core                            │
└─────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┴───────────────┐
              │                               │
         ┌────▼─────┐                   ┌────▼─────┐
         │  Simple  │                   │  Complex │
         │  Path    │                   │  Path    │
         │ (<10)    │                   │ (10+)    │
         └────┬─────┘                   └────┬─────┘
              │                               │
    ┌─────────▼─────────┐           ┌─────────▼─────────┐
    │  unravel-extractor│           │ unravel-orchestrator│
    │  (single-pass)    │           │  (always sequential │
    │                   │           │   internally)       │
    │  • Extract        │           └─────────┬─────────┘
    │  • Self-verify    │                     │
    │  • Output         │         ┌───────────┼───────────┐
    └───────────────────┘         │           │           │
                            ┌────▼───┐  ┌───▼───┐  ┌───▼───┐
                            |Worker 1|  |Worker 2|  |Worker 3|
                            |Extract │  |Extract │  |Extract │
                            └────┬───┘  └───┬───┘  └───┬───┘
                                 │         │         │
                              Sequential (one at a time)
                                 │         │         │
                            ┌────▼───┐  ┌───▼───┐  ┌───▼───┐
                            |Verif.1 │  |Verif.2 │  |Verif.3 │
                            └────┬───┘  └───┬───┘  └───┬───┘
                                 │         │         │
                                 └─────────┼─────────┘
                                           │
                            ┌──────────────▼──────────────┐
                            │  unravel-merger              │
                            │  • Combine outputs           │
                            │  • Cleanup temp files        │
                            └──────────────┬───────────────┘
                                           │
                            ┌──────────────▼──────────────┐
                            │  unravel-summarizer (optional)│
                            │  • Executive summary         │
                            └───────────────────────────────┘

Multiple orchestrators can run in parallel (user choice),
but each orchestrator is always sequential internally.
```

## When to Use Unravel

| Trigger | Artifact Type |
|---------|---------------|
| If/else, validation, exceptions | Business Rules |
| Function call chains, state machines | Process Flows |
| Schemas, ORM classes, DTOs | Data Specs |
| Controllers, routes, event handlers | User Stories |
| Middleware, auth, logging | Security/NFRs |
| HTTP calls, fetch/axios, env vars | Integrations |

## How to Invoke

**Step 1: Ask user to select artifact type(s)**

When the user asks to analyze or extract from code, present this selection:

```
Which artifact types would you like to extract?

Select one or more:
□ Business Rules - Conditional logic, validation, exceptions
□ Process Flows - Function call chains, state machines, workflows
□ Data Specs - Schemas, ORMs, DTOs, validation
□ User Stories - Controllers, routes, endpoints
□ Security/NFRs - Middleware, auth, logging, performance
□ Integrations - HTTP calls, APIs, env vars, external services
```

**Step 2: For multiple artifact types, ask execution preference**

If user selected more than one artifact type:
```
You selected [N] artifact types to extract. How should the orchestrators run?

□ Parallel - Faster, but check your model's concurrency limit (usually 3)
□ Sequential - Slower, but no concurrency concerns
```

**Direct invocation:**
```
You: Extract business rules from auth.ts
Claude: [uses unravel-extractor directly]
```

**Implicit invocation (pattern detection):**
```
You: What are the validation rules in this code?
Claude: [detects pattern → uses unravel-extractor for business-rules]
```

**Large codebase (single artifact type):**
```
You: Analyze business rules across the entire payment system
Claude: [uses unravel-orchestrator with sequential internal execution]
```

**Large codebase (multiple artifact types):**
```
You: Analyze everything about the payment system
Claude: [presents selection, then asks about orchestrator execution]

You selected [N] artifact types. How should the orchestrators run?
□ Parallel - Faster, but check your model's concurrency limit (usually 3)
□ Sequential - Slower, but no concurrency concerns

[Then launches SEPARATE orchestrators per user's choice]
  → orchestrator for business-rules
  → orchestrator for process-flows
  → orchestrator for data-specs
  → orchestrator for user-stories
  → orchestrator for security-nfrs
  → orchestrator for integrations

Each orchestrator runs independently with sequential internal execution.
```

**Step 3: Offer executive summary**

After all extractions complete:
```
All extractions complete! Would you like me to create an executive summary?

□ Yes - Create EXECUTIVE-SUMMARY.md with overview and insights
□ No - I'm done
```

## Agents

### unravel-extractor
**Purpose:** Extract and verify in one pass
**Use for:** < 10 files, targeted extractions
**Process:**
1. Read skill for domain knowledge
2. Discover hotspots (grep/glob)
3. Extract + self-verify each artifact
4. Output to docs/output/[type].md

### unravel-orchestrator
**Purpose:** Coordinate workers, verifiers, and merger for large tasks
**Use for:** 10+ files, codebase-wide analysis
**Process:**
1. Count files with patterns
2. Ask user: parallel or sequential execution
3. If < 10: use unravel-extractor
4. If >= 10: split into modules, launch workers per user's choice
5. Launch verifiers for each temp file
6. When all verifiers pass: launch unravel-merger

**IMPORTANT:** Handles ONE artifact type at a time. Multiple types = multiple orchestrators.

### unravel-verifier
**Purpose:** Independently verify extraction outputs
**Use for:** After each worker completes (orchestrator dispatches)
**Process:**
1. Read extraction output
2. Cross-check against source code
3. Verify accuracy, completeness, boundaries
4. Report PASSED or FAILED

### unravel-merger
**Purpose:** Combine verified outputs into final file
**Use for:** After orchestrator dispatches workers
**Process:**
1. Read all temp files
2. Merge into single output
3. Cleanup temp files
4. Output final: docs/output/[type].md

### unravel-summarizer
**Purpose:** Create executive summary from all outputs
**Use for:** Optional, after all extractions complete
**Process:**
1. Read all artifact files
2. Analyze and synthesize key findings
3. Create EXECUTIVE-SUMMARY.md with overview, insights, recommendations

## Output Location

All artifacts saved to: `docs/output/`

- business-rules.md
- process-flows.md
- data-specs.md
- user-stories.md
- security-nfrs.md
- integrations.md
- EXECUTIVE-SUMMARY.md (optional)

## Key Principles

**User choice first:** Ask user to select artifact types and execution preference

**Hotspot-first:** Find relevant files before reading (don't read everything)

**Source locations:** Include file:line for every artifact

**No hallucinations:** Only extract what exists in the code

**Choose the right path:** Simple for small tasks, complex for large

**One artifact per orchestrator:** Multiple types = multiple orchestrators

**Optional summary:** Offer executive summary after completion
