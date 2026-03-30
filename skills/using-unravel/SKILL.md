---
name: using-unravel
description: This skill should be used when the user asks to "analyze code", "extract business rules", "extract business artifacts", "document the codebase", "understand what this system does", "reverse engineer code", "find business logic", "extract process flows", "extract data specs", "extract user stories", "analyze security measures", "find integrations", "document API contracts", "extract configuration", "map access control", "build a glossary", "catalog events", "document error types", "map dependencies", "trace data flows", "analyze test coverage", "assess codebase maturity", or mentions "/unravel". Activates when the user wants to understand code by extracting structured business documentation from it.
user-invocable: true
---

# Using Unravel

Unravel extracts structured business artifacts from source code, transforming raw code into documentation that business stakeholders can understand.

## What Unravel Extracts

### Core Artifacts
| Trigger | Artifact Type |
|---------|---------------|
| If/else, validation, exceptions | Business Rules |
| Function call chains, state machines, data movement, domain events | Process & Data Flows |
| Schemas, ORM classes, DTOs | Data Specs |
| Controllers, routes, event handlers | User Stories |
| Middleware, auth, logging, access control model | Security/NFRs & Access Control |
| HTTP calls, fetch/axios, external services, config, notifications, webhooks | Integrations & Config |

### Interface Artifacts
| Trigger | Artifact Type |
|---------|---------------|
| Request/response schemas, endpoints, status codes | API Contracts |

### Domain Knowledge Artifacts
| Trigger | Artifact Type |
|---------|---------------|
| Enums, domain constants, terminology, error classes, error codes | Domain Vocabulary & Error Catalog |

### Architecture Artifacts
| Trigger | Artifact Type |
|---------|---------------|
| Package deps, module imports, coupling | Dependency Map |
| Test suites, coverage gaps, mocks | Test Coverage |
| Deprecated code, migrations, tech debt | Evolution History |

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

First, present the full numbered list as reference text (not a question — just informational output):

```
Unravel can extract these artifact types:

1. Business Rules
2. Process & Data Flows
3. User Stories
4. Data Specs
5. Security & NFRs
6. API Contracts
7. Integrations & Config
8. Domain Vocabulary
9. Dependency Map
10. Test Coverage
11. Evolution History
```

Then ask the user to pick groups using AskUserQuestion (multiSelect: true, 3 options + reserve for "Other"):

```
Question: "Which areas would you like to extract?"
Options (multiSelect: true):
  - Business Logic — Business rules, process & data flows, user stories
  - Data & Domain — Data specs, domain vocabulary & error catalog
  - Interfaces & Security — API contracts, integrations & config, security & NFRs
  - Architecture — Dependency map, test coverage, evolution history
```

**Group mappings:**
- Business Logic → business-rules, process-flows, user-stories
- Data & Domain → data-specs, domain-vocabulary
- Interfaces & Security → api-contracts, integrations, security-nfrs
- Architecture → dependency-map, test-coverage, evolution-history

**Refinement (Step 1b):** If the user selects exactly **one** group, skip refinement and extract all types within that group. If the user selects **two or more** groups, ask a follow-up for each multi-type group to let them narrow down:

```
Question: "Which [Group Name] types?" (multiSelect: true)
  - [Type 1] — [one-line description]
  - [Type 2] — [one-line description]
  - [Type 3] — [one-line description]  (if applicable)
```

If the user selects all sub-types in a group, extract the whole group. This step gives power users fine-grained control without bothering single-group selections.

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

**Pass the user's verification preference to the orchestrator** so it skips the verification question. When multiple artifact types are selected, run each type's complete workflow sequentially. All 11 types are accessible through the 4 groups.

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
├── api-contracts/
│   ├── 00-INDEX.md
│   └── [module].md
├── domain-vocabulary/
│   ├── 00-INDEX.md
│   └── [module].md
├── dependency-map/
│   ├── 00-INDEX.md
│   └── [module].md
├── test-coverage/
│   ├── 00-INDEX.md
│   └── [module].md
├── evolution-history/
│   ├── 00-INDEX.md
│   └── [module].md
└── EXECUTIVE-SUMMARY.md   ← Optional, generated on request
```

Each artifact type gets its own folder with module files and an index. This is consistent across all 11 types.

## How It Works

The `orchestrating-extraction` skill handles the complete extraction pipeline per artifact type: file discovery, batched parallel extraction (2 agents at a time, 3-agent limit), optional independent verification, automatic surgical fixes, and index creation. It spawns four specialized agents (extractor, verifier, fixer, summarizer) as needed. For orchestration details, consult the **orchestrating-extraction** skill directly.
