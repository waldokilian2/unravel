---
name: planning-extractions
description: Use when planning complex extractions - breaks analysis into bite-sized tasks for parallel execution
---

# Planning Extractions

## Overview

Create detailed extraction plans with bite-sized tasks for delegation to subagents. Each task should take 2-5 minutes to complete.

**Core principle:** Decompose complex extractions into independent, focused tasks that can be executed by fresh subagents.

**Announce at start:** "I'm using the planning-extractions skill to create a task plan for this extraction."

## When to Use

Use when:
- Extracting from 5+ files
- Single file has 10+ patterns
- Multiple artifact types needed
- Unknown scope (need to discover first)
- Full codebase analysis requested

Don't use for:
- Single file with < 10 patterns (use extraction skill directly)
- Specific, scoped request (use extraction skill directly)

## The Process

### Step 1: Scope Discovery

First, understand what needs to be extracted:

1. **Identify artifact type(s)** - business-rules, process-flows, data-specs, user-stories, security-nfrs, integrations
2. **Count files** - How many files need analysis?
3. **Estimate patterns** - Rough count of patterns per file
4. **Check dependencies** - Are there shared contexts or sequential dependencies?

### Step 2: Task Decomposition Strategy

Break work into 2-5 minute tasks using one of these strategies:

**By File (most common):**
- Each task = 1-3 files
- Group related files (same module/feature)
- 10-15 patterns per task max

**By Pattern Group (for complex files):**
- Single file with 20+ patterns
- Split by pattern type or location
- Tasks: lines 1-100, 101-200, etc.

**By Module (for large codebases):**
- Each task = one module/feature
- Independent modules can run in parallel
- Shared modules go sequentially

**By Artifact Type (for mixed extractions):**
- Different artifact types = independent tasks
- Business rules, process flows, data specs can run in parallel

### Step 3: Create Task Plan

**Save plan to:** `docs/plans/YYYY-MM-DD-[artifact-type]-extraction.md`

**Plan template:**

```markdown
# [Artifact Type] Extraction Plan

> **For Claude:** REQUIRED SUB-SKILL: Use unravel:orchestrating-extractions to execute this plan.

**Created:** [YYYY-MM-DD]

## Scope

**Artifact Type:** [business-rules/process-flows/etc]
**Files:** [N] files
**Estimated Patterns:** [M] patterns
**Estimated Time:** [X] minutes

## Files to Analyze

- [file1.ts]
- [file2.ts]
- ...

## Tasks

### Task 1: [Module/Group Name]
**Files:** [specific files]
**Estimated Patterns:** [count]

**Subagent:** unravel:[artifact-type]-extractor-subagent

**Output:** Append to docs/output/[artifact-type].md

---

### Task 2: [Module/Group Name]
**Files:** [specific files]
**Estimated Patterns:** [count]

**Subagent:** unravel:[artifact-type]-extractor-subagent

**Output:** Append to docs/output/[artifact-type].md

---

## Dependencies

- Task 3 depends on Task 1 (shared context)
- All other tasks are independent (parallel-safe)

## Execution Order

**Parallel:** Tasks 1, 2 (independent)
**Sequential:** Task 3 (after Task 1 completes)

## Aggregation

Merge all task outputs into: docs/output/[artifact-type].md

## Verification

After all tasks complete:
- Use unravel:orchestrating-verification
- Stage 1: Spec compliance (all patterns extracted?)
- Stage 2: Quality review (accurate, no hallucinations?)
```

### Step 4: Present Plan

Show the plan and ask if the user wants to:
1. Proceed with orchestrated execution
2. Adjust the plan
3. Use simple workflow instead

## Example Task Plan

```markdown
# Business Rules Extraction Plan

**Created:** 2025-03-19

## Scope

**Artifact Type:** business-rules
**Files:** 15 files
**Estimated Patterns:** ~75 rules
**Estimated Time:** 30 minutes

## Files to Analyze

- src/auth/*.ts (5 files)
- src/payment/*.ts (4 files)
- src/user/*.ts (6 files)

## Tasks

### Task 1: Auth Module Business Rules
**Files:**
- src/auth/login.ts
- src/auth/register.ts
- src/auth/middleware.ts

**Estimated Patterns:** 20 rules

**Subagent:** unravel:business-rules-extractor-subagent

---

### Task 2: Payment Module Business Rules
**Files:**
- src/payment/process.ts
- src/payment/validate.ts
- src/payment/refund.ts

**Estimated Patterns:** 25 rules

**Subagent:** unravel:business-rules-extractor-subagent

---

### Task 3: User Module Business Rules
**Files:**
- src/user/profile.ts
- src/user/settings.ts
- src/user/permissions.ts

**Estimated Patterns:** 30 rules

**Subagent:** unravel:business-rules-extractor-subagent

---

## Dependencies

All tasks are independent (parallel-safe)

## Execution Order

**Parallel:** Tasks 1, 2, 3 can run concurrently

## Aggregation

Merge all task outputs into: docs/output/business-rules.md

## Verification

After all tasks complete:
- Use unravel:orchestrating-verification
```

## Red Flags

**Never:**
- Create tasks > 10 minutes (too large)
- Mix unrelated files in same task
- Skip dependency analysis
- Create tasks without clear boundaries
- Make subagents read plan files (provide full task text instead)

**Always:**
- Keep tasks 2-5 minutes each
- Group related files together
- Document dependencies clearly
- Specify exact file paths
- Indicate which subagent type to use

## Integration

**Required workflow skills:**
- **unravel:orchestrating-extractions** - Executes the plan with subagents
- **unravel:orchestrating-verification** - Two-stage verification after execution

**Alternative workflow:**
- **Direct extraction skill** - Use for small tasks (< 10 patterns, < 5 files)
