---
name: orchestrating-extractions
description: Use when orchestrating complex extraction tasks - decomposes requests, dispatches subagents, coordinates two-stage review, aggregates results
---

# Orchestrating Extractions

## Overview

Orchestrate complex extraction tasks by decomposing them into independent subtasks, dispatching fresh subagents for each, coordinating two-stage review, and aggregating results.

**Core principle:** Decompose → Dispatch → Review → Aggregate. Let specialized subagents handle bite-sized tasks while you coordinate.

**Announce at start:** "I'm using the orchestrating-extractions skill to coordinate this extraction."

## When to Use

All extraction skills use this orchestration pattern. Use this skill directly when:

- Multiple files/modules need coordination
- Parallel execution would be beneficial
- Unknown scope needs planning first
- Complex aggregation required

**Simple case (1 file):** The extraction skill handles subagent dispatch directly.

**Complex case (multiple files):** Use this skill for full orchestration.

## The Process

### Step 1: Scope Analysis

Analyze the extraction request:

1. **Identify artifact type** - What are we extracting?
2. **Count files** - How many files need analysis?
3. **Estimate patterns** - Rough count of patterns per file
4. **Check parallelization** - Can files be processed independently?

```
Example analysis:
- Artifact type: business-rules
- Files: 15 files across 3 modules
- Estimated patterns: ~75 rules
- Parallelization: Yes (modules are independent)
```

### Step 2: Task Planning (if needed)

If scope is large or unknown, use planning-extractions first:

**Invoke:** `unravel:planning-extractions`

This creates a detailed plan with:
- Task breakdown (2-5 min each)
- File assignments per task
- Dependencies between tasks
- Execution order (parallel vs sequential)

**If scope is known and straightforward**, skip to Step 3.

### Step 3: Subagent Dispatch

For each task, dispatch a focused subagent:

**Example parallel dispatch:**
```
Task("Extract business rules from auth module (5 files)")
Task("Extract business rules from payment module (4 files)")
Task("Extract business rules from user module (6 files)")
// All three run concurrently
```

**Subagent prompt template:**
```markdown
Extract [artifact type] from [module/files]:

**Files:** [specific file paths]
**Artifact Type:** [business-rules/process-flows/etc]
**Output:** Save to docs/output/[type].md

**Process:**
1. Read assigned files
2. Extract patterns
3. Format output per template
4. Self-review and report back
```

### Step 4: Two-Stage Review Per Task

For each completed task, run two-stage review:

**Stage 1: Spec Compliance Review**
```
Task("Review spec compliance for [task]")

Check:
- All patterns in scope extracted?
- No artifacts outside scope?
- Output format followed?
- Source locations accurate?
```

**If issues found:** Dispatch subagent to fix, then re-review.

**Stage 2: Quality Review** (only after Stage 1 passes)
```
Task("Review quality for [task]")

Check:
- Each artifact matches actual code?
- No hallucinations?
- Clear, well-documented?
```

**If issues found:** Dispatch subagent to fix, then re-review.

### Step 5: Aggregation

After all tasks complete and pass review:

1. **Read all outputs** - Collect from each subagent
2. **Merge into single file** - docs/output/[artifact-type].md
3. **Verify completeness** - All tasks represented
4. **Format consistently** - Uniform structure

### Step 6: Final Verification

Optionally run orchestrating-verification for end-to-end verification:

**Invoke:** `unravel:orchestrating-verification`

## Example Workflow

**User Request:** "Extract all business rules from the codebase"

**Step 1: Scope Analysis**
- Artifact type: business-rules
- Files: 15 files (grep found if/else patterns)
- Estimated patterns: ~75 rules
- Parallelization: Yes (3 independent modules)

**Step 2: Task Planning**
```
Auth module: 5 files, ~20 rules
Payment module: 4 files, ~25 rules
User module: 6 files, ~30 rules
```

**Step 3: Parallel Dispatch**
```
Agent 1 → Extract business rules from auth module
Agent 2 → Extract business rules from payment module
Agent 3 → Extract business rules from user module
```

**Step 4: Two-Stage Review (per task)**
```
Task 1: Spec review → Quality review → Pass
Task 2: Spec review → Quality review → Pass
Task 3: Spec review → Quality review → Pass
```

**Step 5: Aggregation**
```
Merge all outputs into docs/output/business-rules.md
```

**Result:** 75 rules extracted, verified, and documented in ~10 minutes

## Red Flags

**Never:**
- Make subagents read plan files (provide full task text)
- Skip review stages (both spec compliance and quality required)
- Proceed with unfixed issues (must re-review after fixes)
- Start quality review before spec compliance passes
- Aggregate without verifying all tasks complete
- Use single agent for entire orchestration (you coordinate, subagents execute)

**Always:**
- Provide complete task context in subagent prompts
- Run both review stages in order (spec → quality)
- Re-review after any fixes are made
- Verify spec compliance before quality review
- Aggregate only after all tasks pass review
- Use fresh subagent per task (no context pollution)

## Subagent Types

**Extraction Subagents:**
- unravel:business-rules-extractor-subagent
- unravel:process-flows-extractor-subagent
- unravel:data-specs-extractor-subagent
- unravel:user-stories-extractor-subagent
- unravel:security-nfrs-extractor-subagent
- unravel:integrations-extractor-subagent

**Reviewer Subagents:**
- unravel:spec-compliance-reviewer (Stage 1)
- unravel:quality-reviewer (Stage 2)

## Integration

**Required workflow skills:**
- **unravel:planning-extractions** - Create task plan for large/unknown scopes
- **unravel:orchestrating-verification** - Final two-stage verification after aggregation

**Related skills:**
- **Direct extraction skills** - Handle single-file orchestration automatically
- **unravel:dispatching-parallel-extractors** - Use for parallel-only execution

## Commands

- `/extract` - Trigger this orchestration skill
- `/parallel-extract` - Trigger parallel extraction without planning
- `/verify` - Trigger two-stage verification
