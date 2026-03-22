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
│                     Main Agent (You)                        │
│                                                             │
│  Follows orchestrating-extraction skill                     │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  • Counts files & splits into modules               │   │
│  │  • Spawns agents SEQUENTIALLY (one at a time)       │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                              │
                ┌─────────────┴─────────────┐
                │                           │
         Spawn Agent                    Spawn Agent
    unravel-extractor              unravel-verifier
      (Module 1)          ←────────→    (Module 1)
                │                           │
                │                           │
         Spawn Agent                    Spawn Agent
    unravel-extractor              unravel-verifier
      (Module 2)          ←────────→    (Module 2)
                │                           │
                │                           │
         Spawn Agent                    Spawn Agent
    unravel-extractor              unravel-verifier
      (Module 3)          ←────────→    (Module 3)
                │                           │
                └─────────────┬─────────────┘
                              │
                       Spawn Agent
                  unravel-merger
                              │
                       Spawn Agent
              unravel-summarizer (optional)
```

**Key:** The horizontal arrows (←────────→) indicate workflow sequence, not automatic spawning. The Main Agent explicitly spawns each agent: extractor completes → Main Agent spawns corresponding verifier → after all verifiers pass → Main Agent spawns merger.

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

**Option 1: Use /unravel command**
```
You: /unravel
```

**Option 2: Direct request**
```
You: Extract business rules from auth.ts
You: Analyze the payment system
You: What are the validation rules in this code?
```

**Step 1: Ask user to select artifact type(s)**

When the user asks to analyze or extract from code, present this selection:

```
What would you like to extract?

□ Business Logic - Business rules, process flows, user stories
□ Data Specifications - Schemas, ORM classes, DTOs, validation
□ Technical Details - Security/NFRs, integrations
□ Everything - Extract all 6 artifact types
```

**Follow-up refinement (if user selects a category):**

If user selects a category (not "Everything"), ask:
```
You selected [Category Name]. Which types?

□ All [category] types
□ [Type 1] only
□ [Type 2] only
□ [Type 3] only
```

**Category mappings:**
- Business Logic → business-rules, process-flows, user-stories
- Data Specifications → data-specs
- Technical Details → security-nfrs, integrations

**Step 2: For multiple artifact types, ask execution preference**

If user selected more than one artifact type:
```
You selected [N] artifact types to extract. How should they be processed?

□ Parallel - Faster, but check your model's concurrency limit (usually 3)
□ Sequential - Slower, but no concurrency concerns
```

**Invocation examples:**

```
You: /unravel
Claude: What would you like to extract?
       □ Business Logic - Business rules, process flows, user stories
       □ Data Specifications - Schemas, ORM classes, DTOs, validation
       □ Technical Details - Security/NFRs, integrations
       □ Everything - Extract all 6 artifact types
       [user selects Business Logic]
Claude: You selected Business Logic. Which types?
       □ All business logic types
       □ Business Rules only
       □ Process Flows only
       □ User Stories only
       [user selects "All business logic types"]
       Claude: [follows orchestrating-extraction skill for each type sequentially]
```

```
You: Extract business rules from auth.ts
Claude: [follows orchestrating-extraction skill for business-rules]
```

```
You: What are the validation rules in this code?
Claude: [follows orchestrating-extraction skill for business-rules]
```

```
You: Analyze business rules across the entire payment system
Claude: [follows orchestrating-extraction skill with sequential execution]
```

```
You: Analyze everything about the payment system
Claude: [presents category selection, then asks about execution if multiple types]
□ Parallel - Faster, but check your model's concurrency limit (usually 3)
□ Sequential - Slower, but no concurrency concerns

[Then processes each type with complete extraction workflow]
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
**Purpose:** Extract artifacts from assigned files
**Use for:** Per-module extraction (spawned by orchestrating-extraction skill)
**Process:**
1. Read skill for domain knowledge (pattern definitions, output format)
2. Extract + self-verify each artifact from **provided file list**
3. Output to docs/output/[type].[module].tmp.md

**Note:** The orchestrator discovers files and passes specific paths to the extractor. The extractor does NOT do file discovery.

### orchestrating-extraction (skill)
**Purpose:** Coordinate extractors, verifiers, and merger for all extractions
**Use for:** All extraction tasks (small and large)
**Process:**
1. Read skill for hotspot patterns
2. Use Glob/Grep to discover all relevant files
3. Split into modules (by directory/feature)
4. Spawn extractors SEQUENTIALLY (each gets specific file list)
5. Spawn verifiers SEQUENTIALLY as extractors complete
6. When all verifiers pass: spawn unravel-merger agent

**IMPORTANT:** Handles ONE artifact type at a time. Multiple types = multiple complete workflows.
**Execution:** Always sequential (extractors → verifiers → merger, one at a time).

### unravel-verifier
**Purpose:** Independently verify extraction outputs
**Use for:** After each extractor completes (main agent dispatches)
**Process:**
1. Read extraction output
2. Cross-check against source code
3. Verify accuracy, completeness, boundaries
4. Report PASSED or FAILED

### unravel-merger
**Purpose:** Combine verified outputs into final file
**Use for:** After main agent dispatches extractors
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

**Consistent workflow:** All extractions follow the same orchestration pattern

**One artifact per workflow:** Multiple types = multiple complete workflows

**Optional summary:** Offer executive summary after completion

**Sequential execution:** All agents spawn sequentially, no nesting
