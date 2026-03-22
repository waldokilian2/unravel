---
name: orchestrating-extraction
description: Orchestrate sequential extractors, verifiers, and merger for all extractions
---

# Orchestrating Extraction

You are orchestrating an Unravel extraction. Coordinate extractors, verifiers, and merger.

**Execution model:** Always run extractors, verifiers, and merger sequentially (one at a time).
**Note:** When multiple artifact types are selected, the user chooses parallel vs sequential processing across types.

## Your Task

Analyze the extraction request and coordinate extractors, verifiers, and merger.

**IMPORTANT: You handle ONE artifact type at a time.** If asked for multiple artifact types, handle them one at a time with complete workflows per type.

**Artifact Type:** [business-rules | process-flows | data-specs | user-stories | security-nfrs | integrations]

**Scope:** [file paths, directories, or "codebase"]

## Coordination Process

### Step 1: Count Files, Discover, and Split into Modules

**File discovery is the orchestrator's responsibility:** You use Glob/Grep to find all relevant files, then pass specific file paths to each extractor.

1. Read the corresponding extraction skill for hotspot patterns:
   - `unravel/skills/extract-business-rules/SKILL.md`
   - `unravel/skills/extract-process-flows/SKILL.md`
   - etc.

2. Use Glob/Grep with those patterns to find all relevant files in the codebase

3. Split discovered files into logical modules (by directory/feature)

**Module Naming Convention:**

| Source Structure | Module Name | Example |
|------------------|-------------|---------|
| Single directory | Directory name | `src/auth` → `auth` |
| Nested directories | Last directory name | `src/payment/processing` → `processing` |
| Files across features | Primary feature name | `auth.ts, user.ts` → `auth` |
| Mixed/unclear | Numbered | `module-1`, `module-2`, etc. |

**Examples:**
```
Example 1: Single-level directories
src/
  auth/
    login.ts
    register.ts
  payment/
    stripe.ts
    paypal.ts

→ Modules: auth, payment
→ Outputs: business-rules.auth.tmp.md, business-rules.payment.tmp.md

Example 2: Nested directories
src/
  payment/
    processing/
      charge.ts
      refund.ts
    methods/
      card.ts
      bank.ts

→ Modules: processing, methods
→ Outputs: business-rules.processing.tmp.md, business-rules.methods.tmp.md
```

If only one module or few files, treat as a single module named after the primary directory or `main`.

### Step 2: Launch Extractors (Sequential)

For each module, launch an Agent SEQUENTIALLY - wait for each to complete before launching the next:

```
Agent(unravel-extractor,
     "Extract [artifact-type] from [module-name] module
      Artifact Type: [artifact-type]
      Module Name: [module-name]
      Files: [specific file paths]
      Output: docs/output/[artifact-type].[module-name].tmp.md")
```

**IMPORTANT:** Launch extractors SEQUENTIALLY - one at a time.

### Step 3: Verify Each Output (Sequential)

For each temp file created, launch a verifier SEQUENTIALLY - wait for each to complete:

```
Agent(unravel-verifier,
     "Verify extraction output
      Output File: docs/output/[artifact-type].[module-name].tmp.md
      Source Files: [files that module analyzed]
      Artifact Type: [artifact-type]")
```

**IMPORTANT:** Launch verifiers SEQUENTIALLY as extractors complete.

### Step 4: Merge (After All Verifications Pass)

When all verifiers report PASSED:

```
Agent(unravel-merger,
     "Merge [artifact-type] extraction
      Temp files: docs/output/[artifact-type].*.tmp.md
      Output: docs/output/[artifact-type].md")
```

#### If Verification Fails (Recovery Process)

**If a verifier FAILS:**
1. Stop the merge process
2. Report which module failed and the specific errors
3. Explain recovery options:
   - **Option A:** Re-run extraction for the failed module only:
     ```
     Agent(unravel-extractor, "Extract [artifact-type] from [failed-module]...")
     Agent(unravel-verifier, "Verify docs/output/[artifact-type].[failed-module].tmp.md...")
     ```
   - **Option B:** Delete the failed temp file and manually fix issues in the source
   - **Option C:** Skip the failed module and merge the rest (user confirmation required)

4. After recovery, re-launch the merger with the updated temp files

**Recovery Example:**
```
❌ Verification FAILED for module 'payment'
Issues: 3 hallucinated rules found

Recovery options:
1. Re-extract payment module: Agent(unravel-extractor, "...payment...")
2. Manually review and fix the output file
3. Skip payment module and merge other modules

Which option would you like?
```

## Parallel vs Sequential (Multiple Artifact Types)

These settings control how **different artifact types** are processed, not the internal workflow.

| Setting | Behavior | When to Use |
|---------|----------|-------------|
| **Sequential** | Complete one artifact type fully before starting the next | Limited API quota, uncertain about patterns |
| **Parallel** | Start multiple artifact type workflows simultaneously | Time-sensitive, sufficient API quota |

**Important:** Each artifact type's internal workflow (extractors → verifiers → merger) is ALWAYS sequential.

**Example - Sequential Across Types:**
```
1. Business Rules (complete workflow)
   - Extractor 1 → Verifier 1
   - Extractor 2 → Verifier 2
   - Merger ✓
2. Process Flows (complete workflow) - starts AFTER business-rules completes
   - Extractor 1 → Verifier 1
   - Merger ✓
```

**Example - Parallel Across Types:**
```
1. Business Rules workflow  ┐
   - Extractor 1 → Verifier  ├─ All run concurrently
   - Merger ✓              │
2. Process Flows workflow  │
   - Extractor 1 → Verifier │ (each workflow internally sequential)
   - Merger ✓              │
3. Data Specs workflow     ┘
   - Extractor 1 → Verifier
   - Merger ✓
```

## Available Tools

- **Grep** - Search for patterns to count files
- **Glob** - Find files matching patterns
- **Agent** - Dispatch extractors, verifiers, and merger
- **Skill** - Read extraction skills for hotspot patterns

## Report Format

```
Extraction: [N] files across [M] modules
Artifact Type: [artifact-type]

Modules: [list]

Extractor Status:
  ✓ [Module A] - Complete
  ✓ [Module B] - Complete
  ⏳ [Module C] - In progress

Verification:
  ✓ [Module A] - Passed
  ⏳ [Module B] - Verifying...
  ⏳ [Module C] - Waiting

Merger: Pending (awaiting all verifications)
```

## Error Handling

**If an extractor fails:**
- Report error details
- Don't launch verifier for that module
- Don't launch merger
- Ask user how to proceed

**If a verifier fails:**
- Report which module failed with specific errors
- Show verification failure details
- Don't launch merger
- Present recovery options (see Verification Failure Recovery above)

## Core Principles

**Sequential execution:** Extractors run one at a time, verifiers run one at a time

**Independent verification:** Each temp file is verified before merge

**Fail fast:** Stop on errors, don't merge partial/bad results

**Verify before merge:** No merger until all verifications pass

**One artifact type:** This orchestration handles ONE artifact type. Multiple types require multiple complete workflows

**Module-based organization:** Split by logical features/directories for clarity

## Multiple Artifact Types

If the user requests multiple artifact types (e.g., "extract everything"):

**DO NOT:** Try to handle all types in one pass

**INSTEAD:** Ask user about parallel vs sequential processing, then handle each type with complete workflow:

```
You selected [N] artifact types. How should they be processed?

□ Sequential - Complete one type before starting the next
□ Parallel - Process multiple types concurrently (subject to API limits)

[Then process each type with full extract → verify → merge workflow]
```

**Note:** After all extractions complete, offer to create an executive summary using the unravel-summarizer agent.
