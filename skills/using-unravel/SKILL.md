---
name: using-unravel
description: This skill should be used when the user asks to "analyze code", "extract business rules", "extract business artifacts", "document the codebase", "understand what this system does", "reverse engineer code", "find business logic", "extract process flows", "extract data specs", "extract user stories", "analyze security measures", "find integrations", or mentions "/unravel". Activates when the user wants to understand code by extracting structured business documentation from it.
---

# Using Unravel

Unravel extracts structured business artifacts from source code, transforming raw code into documentation that business stakeholders can understand.

## What Unravel Extracts

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

## Extraction Workflow

### Step 1: Present Artifact Selection

Present this selection to the user:

```
What would you like to extract?

□ Business Logic - Business rules, process flows, user stories
□ Data Specifications - Schemas, ORM classes, DTOs, validation
□ Technical Details - Security/NFRs, integrations
□ Everything - Extract all 6 artifact types
```

If the user selects a category (not "Everything"), ask for refinement:

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

### Step 2: Ask Verification Preference (Once)

After artifact type selection, ask the user **once** for all types:

```
Would you like independent verification of extracted artifacts?

[✓] Yes - Run independent verifier after each extractor (most thorough, slower)
[ ] No - Skip independent verifier (extractor self-verifies, faster)
```

Store the user's choice and pass it to each orchestrating-extraction workflow. Do not ask again for subsequent artifact types.

**Rationale:** Extractors always self-verify their outputs. Independent verification provides an additional layer of validation by having a separate agent review the work. For most cases, the extractor's self-verification is sufficient. Independent verification is useful for critical systems, complex or unfamiliar codebases, and audit or documentation requiring thorough validation.

### Step 3: Execute Extractions

For each selected artifact type, invoke the orchestrating-extraction skill:

```
Skill("unravel:orchestrating-extraction")
```

The orchestrating-extraction skill handles the complete workflow for one artifact type:
- File discovery and module splitting
- Batched parallel extraction (2 agents at a time, 3-agent limit)
- Optional independent verification (based on user's choice from Step 2)
- Automatic surgical fixes when verification fails
- Index creation

**Pass the user's verification preference to the orchestrator** so it skips the verification question. When multiple artifact types are selected, run each type's complete workflow sequentially.

### Step 4: Offer Executive Summary

After all extractions complete, offer:

```
All extractions complete! Would you like me to create an executive summary?

□ Yes - Create EXECUTIVE-SUMMARY.md with overview and insights
□ No - I'm done
```

To create the summary, spawn the `unravel-summarizer` agent.

## Output Location

All artifacts are saved to `docs/output/`:

```
docs/output/
├── business-rules/
│   ├── 00-INDEX.md       ← Table of contents with links
│   └── [module].md       ← One file per module
├── process-flows/
│   ├── 00-INDEX.md
│   └── [module].md
├── data-specs/
│   ├── 00-INDEX.md
│   └── [module].md
├── user-stories/
│   ├── 00-INDEX.md
│   └── [module].md
├── security-nfrs/
│   ├── 00-INDEX.md
│   └── [module].md
├── integrations/
│   ├── 00-INDEX.md
│   └── [module].md
└── EXECUTIVE-SUMMARY.md   ← Optional, generated on request
```

Each artifact type gets its own folder with module files and an index. This is consistent across all 6 types.

## How It Works

The `orchestrating-extraction` skill handles the complete extraction pipeline per artifact type: file discovery, batched parallel extraction (2 agents at a time, 3-agent limit), optional independent verification, automatic surgical fixes, and index creation. It spawns four specialized agents (extractor, verifier, fixer, summarizer) as needed. For orchestration details, consult the **orchestrating-extraction** skill directly.
