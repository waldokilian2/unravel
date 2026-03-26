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
│  │  • Loads skill content ONCE                         │   │
│  │  • Asks user for verification preference            │   │
│  │  • Counts files & splits into modules               │   │
│  │  • Spawns agents in batches of 2 (parallel)         │   │
│  │  • Embeds skill content in agent prompts            │   │
│  │  • 3-agent limit: main + 2 parallel agents max      │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                              │
                ┌─────────────┴─────────────┐
                │                           │
         Spawn Agent                    Spawn Agent
    unravel-extractor              unravel-extractor
      (Module 1)                     (Module 2)
         │                               │
         └─────────────┬─────────────────┘
                       │
                [Both run in parallel]
                       │
                       ▼
         [If verification enabled: Spawn verifiers in batches of 2]
         [If verification disabled: Skip to index creation]
                       │
                       ▼
         [If verifier finds issues: Spawn fixer → Re-verify]
         [If fix succeeds: Proceed to index creation]
         [If fix fails: Show manual recovery options]
                       │
                       ▼
                  All modules ready
                       │
                       ▼
              Orchestrator creates 00-INDEX.md
                       │
                       ▼
              unravel-summarizer (optional)
```

**Key:** Extractors run in batches of 2 (parallel within batch, sequential between batches). Verifiers run in batches of 2 if enabled by user. If verification fails with issues, fixer is spawned to surgically fix problems, then re-verified. Main orchestrator waits for each batch to complete before launching the next batch. This maximizes throughput while respecting the 3-agent limit.

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

**Step 2: Ask user for verification preference**

After artifact type selection, ask:
```
Would you like independent verification of extracted artifacts?

[✓] Yes - Run independent verifier after each extractor (most thorough, slower)
[ ] No - Skip independent verifier (extractor self-verifies, faster)
```

**Explanation:** Extractors always self-verify their outputs. Independent verification provides an additional layer of validation by having a separate agent review the work. For most cases, the extractor's self-verification is sufficient.

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
Claude: Would you like independent verification of extracted artifacts?
       [✓] Yes - Run independent verifier after each extractor (most thorough, slower)
       [ ] No - Skip independent verifier (extractor self-verifies, faster)
       [user selects "No"]
       Claude: Found 47 files across 3 modules.
               Processing with batched parallel execution (3-agent limit)...

               Batch 1/2: Extracting from auth and payment modules...
               Batch 2/2: Extracting from user module...
               Merging all outputs...

               [follows orchestrating-extraction skill for each type sequentially]
```

```
You: Extract business rules from auth.ts
Claude: [follows orchestrating-extraction skill for business-rules with batched parallel execution]
```

```
You: What are the validation rules in this code?
Claude: [follows orchestrating-extraction skill for business-rules with batched parallel execution]
```

```
You: Analyze business rules across the entire payment system
Claude: [follows orchestrating-extraction skill with batched parallel execution]
```

```
You: Analyze everything about the payment system
Claude: [presents category selection]
       [processes each type sequentially with batched parallel execution within each type]
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
1. Receive domain knowledge in prompt (embedded by orchestrator)
2. Extract + self-verify each artifact from **provided file list**
3. Output to docs/output/[type]/[module].md

**Note:** The orchestrator provides domain knowledge in the prompt. The extractor does NOT read skills. The orchestrator discovers files and passes specific paths to the extractor.

### orchestrating-extraction (skill)
**Purpose:** Coordinate extractors, verifiers (optional), and index creation for all extractions
**Use for:** All extraction tasks (small and large)
**Process:**
1. Ask user for verification preference
2. Load skill content ONCE using Skill tool
3. Embed skill content in extractor/verifier prompts
4. Create output folder: docs/output/[artifact-type]/
5. Use Glob/Grep to discover all relevant files
6. **Smart module detection:**
   - Strategy 1: User-defined modules (if specified in request)
   - Strategy 2: Directory-based (clean structure)
   - Strategy 3: Import/dependency clustering (flat structure)
   - Strategy 4: Single module fallback (unclear structure)
7. Spawn extractors in batches of 2 (parallel within batch, sequential between batches)
8. If user chose "Yes": spawn verifiers in batches of 2 (parallel within batch, sequential between batches)
9. When ready: create 00-INDEX.md with links to all module files

**IMPORTANT:** Handles ONE artifact type at a time. Multiple types = multiple complete workflows (processed sequentially).
**Execution:** Batched parallel (extractors/verifiers run in batches of 2, max 3 concurrent agents total).
**Verification:** Optional - user chooses whether to run independent verifiers (extractors always self-verify)
**Skill loading:** Orchestrator reads each skill ONCE and embeds content in agent prompts (eliminates redundant skill reads)
**Output:** Folder structure with module files and index (no single combined file)

### unravel-verifier
**Purpose:** Independently verify extraction outputs (optional)
**Use for:** After each extractor completes (main agent dispatches) - only if user chose "Yes" for verification
**Process:**
1. Receive domain knowledge in prompt (embedded by orchestrator)
2. Read extraction output
3. Cross-check against source code
4. Verify accuracy, completeness, boundaries
5. Report PASSED or FAILED with structured issues

**Note:** This agent is only spawned if the user chose "Yes" for independent verification. Extractors always self-verify their outputs. The orchestrator provides domain knowledge in the prompt - the verifier does NOT read skills.

### unravel-fixer
**Purpose:** Surgically fix specific issues in extraction output
**Use for:** After verifier fails with structured issues (automatic)
**Process:**
1. Receive output file path and issues list
2. Read source files for context
3. Apply surgical fixes (remove hallucinated, update locations, augment incomplete, correct misdescribed)
4. Save fixed output
5. Report fixes applied

**Note:** This agent is automatically spawned when verification fails with fixable issues. It makes minimal edits to fix only the problematic items.

**Issue types handled:**
- **hallucinated** - Remove (artifact doesn't exist)
- **wrong_location** - Update (correct file:line reference)
- **incomplete** - Augment (add missing details)
- **misdescribed** - Correct (fix description/semantics)

### unravel-summarizer
**Purpose:** Create executive summary from all outputs
**Use for:** Optional, after all extractions complete
**Process:**
1. Read all artifact index files (00-INDEX.md) and module files
2. Analyze and synthesize key findings
3. Create EXECUTIVE-SUMMARY.md with overview, insights, recommendations

## Output Location

All artifacts saved to: `docs/output/`

Each artifact type gets its own folder:
- business-rules/ (with 00-INDEX.md and module files)
- process-flows/ (with 00-INDEX.md and module files)
- data-specs/ (with 00-INDEX.md and module files)
- user-stories.md
- security-nfrs.md
- integrations.md
- EXECUTIVE-SUMMARY.md (optional)

## Key Principles

**User choice first:** Ask user to select artifact types and verification preference

**Hotspot-first:** Find relevant files before reading (don't read everything)

**Source locations:** Include file:line for every artifact

**No hallucinations:** Only extract what exists in the code

**Surgical fixes:** When verification fails, fix only the problematic items (don't re-extract entire module)

**Consistent workflow:** All extractions follow the same orchestration pattern

**One artifact per workflow:** Multiple types = multiple complete workflows (processed sequentially)

**Batched parallel:** Extractors run in batches of 2 for optimal throughput (verifiers optional)

**3-agent limit:** Main orchestrator + 2 parallel agents maximum at any time

**Optional verification:** User chooses whether to run independent verifiers (extractors always self-verify)

**Automatic fixing:** When verification fails with fixable issues, automatically apply surgical fixes and re-verify

**Optional summary:** Offer executive summary after completion
