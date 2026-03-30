---
name: orchestrating-extraction
description: This skill should be used when coordinating an Unravel extraction workflow. Handles file discovery, module splitting, batched parallel extraction, optional independent verification, and index creation for a single artifact type. The using-unravel skill invokes this skill for each selected artifact type.
user-invocable: false
---

# Orchestrating Extraction

Coordinate extractors, verifiers, and index creation for a single artifact type.

**Execution model:** Run up to 2 extractors/verifiers in parallel (3-agent limit: main orchestrator + 2 parallel agents).
**Scope:** Handle ONE artifact type at a time. Multiple types are processed sequentially by the using-unravel skill.

## Your Task

Analyze the extraction request and coordinate the full extraction pipeline for one artifact type.

**Artifact Type:** [business-rules | process-flows | data-specs | user-stories | security-nfrs | integrations | api-contracts | dependency-map | test-coverage | evolution-history | domain-vocabulary]
**Scope:** [file paths, directories, or "codebase"]
**Verification Preference:** [Yes | No — provided by using-unravel, do not ask the user]

## Coordination Process

### Step 0: Load Skill Content

Load the relevant extraction skill ONCE using the Skill tool:

```
Skill("unravel:extract-[artifact-type]")
```

The Skill tool returns the **complete SKILL.md content** into your context. Store this entire content — every line from `---` to the end — for embedding in agent prompts.

| Artifact Type | Skill Name |
|---------------|------------|
| business-rules | unravel:extract-business-rules |
| process-flows | unravel:extract-process-flows |
| data-specs | unravel:extract-data-specs |
| user-stories | unravel:extract-user-stories |
| security-nfrs | unravel:extract-security-nfrs |
| integrations | unravel:extract-integrations |
| api-contracts | unravel:extract-api-contracts |
| dependency-map | unravel:extract-dependency-map |
| test-coverage | unravel:extract-test-coverage |
| evolution-history | unravel:extract-evolution-history |
| domain-vocabulary | unravel:extract-domain-vocabulary |

**CRITICAL:** Embed the **complete, verbatim skill content** in every agent prompt. Do NOT summarize, condense, or selectively quote sections. Pass the entire SKILL.md content. The agents have no way to load skills themselves — they depend entirely on what you provide.

**WRONG:**
```
Key patterns from the skill: "Extract if/else chains, validation decorators..."
```

**RIGHT:**
```
--- Paste the full SKILL.md content here, starting from the frontmatter ---
```

**IMPORTANT:** Do NOT tell agents to use the Skill tool. They cannot access it.

### Step 1: Discover Files, Create Output Folder, Split into Modules

1. Use the hotspot patterns from the loaded skill content
2. Use **Glob/Grep tools** (not bash grep) to find all relevant files
3. Create the output folder using Bash: `mkdir -p "docs/output/[artifact-type]/"`
4. Split discovered files into logical modules

**Module Naming Convention:**

| Source Structure | Module Name | Example |
|------------------|-------------|---------|
| Single directory | Directory name | `src/auth` → `auth` |
| Nested directories | Last directory name | `src/payment/processing` → `processing` |
| Files across features | Primary feature name | `auth.ts, user.ts` → `auth` |
| Mixed/unclear | Numbered | `module-1`, `module-2`, etc. |

If only one module or few files, treat as a single module named after the primary directory or `main`.

**Output folder structure:**
```
docs/output/[artifact-type]/
├── 00-INDEX.md        ← Created in Step 5
├── [module-name].md   ← One file per module
└── [module-name].md
```

### Step 2: Launch Extractors (Batched Parallel)

For each module, launch extractors in batches of 2 (max 2 concurrent agents). Embed the skill content directly in the agent prompt. Use `run_in_background=true` for parallel spawns.

For detailed prompt templates, timeline diagrams, and batching pseudocode, read [references/batching-strategy.md](references/batching-strategy.md).

### Step 3: Verification Phase

This entire phase is conditional based on the **verification preference** provided by using-unravel. Do NOT ask the user for this preference.

**If verification is "No":** Skip directly to Step 4 (Create Index).

**If verification is "Yes":** Execute the following three subprocesses sequentially.

#### 3.1: Launch Verifiers (Batched)

For each module file created, launch verifiers in batches of 2. Embed the skill content in the prompt. Store results as:
```
verification_results = [{
    module_file: path,
    status: "PASSED" | "FAILED",
    issues: [structured issues if failed]
}]
```

#### 3.2: Process Failed Verifications

For each failed result with issues:

1. **Spawn fixer** — Launch `unravel-fixer` with the output file path, issues list, and source files
2. **Parse fixer output** — Extract the "Fixes:" section to build re-verification context
3. **Re-verify** — Launch `unravel-verifier` in RE-VERIFICATION MODE with the fix context
4. **Check result** — If re-verification passes, module is ready. If it fails, add to `failed_modules` list

Each failed module gets exactly one fix attempt. If re-verification fails, the module is marked for manual recovery.

For re-verification prompt templates and fixer output parsing, read [references/verification-recovery.md](references/verification-recovery.md).

#### 3.3: Determine Outcome

**If all modules passed:** Proceed to Step 4.

**If some modules failed:** Do NOT create the index. Present recovery options:

```
Verification completed with failures:

Failed Modules: [list]

For each failed module:
1. Re-run extraction for the failed module only
2. Manually review and fix issues in the output file
3. Skip the failed module and create index with the rest

Which option would you like for each failed module?
```

### Step 4: Create Index

Only create the index when all modules to be included have passed verification (or the user explicitly chose to skip failed modules).

**Read each module file** before creating the index. For each module, extract a 3-5 word highlight summarizing the most notable findings (e.g., "12 rules, 2 critical gaps", "3 flows, 1 batch job", "5 entities, 2 orphan tables"). This gives readers immediate value without opening every file.

Create `docs/output/[artifact-type]/00-INDEX.md`:

```markdown
# [Artifact Type]

Extraction: [YYYY-MM-DD]

## Extraction Summary
- **Total Artifacts:** [count from all modules]
- **Files Analyzed:** [unique file count]
- **Modules:** [count]
- **Verification:** [Each module independently verified | Extractor self-verified]

## Modules

| Module | Artifacts | Key Findings | Link |
|--------|-----------|--------------|------|
| [module-name] | [count] | [3-5 word highlight] | [[module-name].md](module-name.md) |

---

*Generated by Unravel on [timestamp]*
```

## Error Handling

**If an extractor fails:** Report error, do not launch verifier for that module, do not create index, ask user how to proceed.

**If a verifier fails:** Report which module failed with specific errors, show failure details, present recovery options per Step 3.3.

## Multiple Artifact Types

If handling multiple types (delegated from using-unravel), process each type sequentially with a complete workflow. Do not combine types into one pass.

```
Processing [N] artifact types sequentially...

[Type 1 - complete workflow]
[Type 2 - complete workflow]
[Type 3 - complete workflow]
```

After all extractions complete, using-unravel will offer to create an executive summary.

## Available Tools

- **Bash** — Create output folder (`mkdir -p`)
- **Grep** — Search for patterns to discover files (prefer over bash grep)
- **Glob** — Find files matching patterns (prefer over bash find)
- **Agent** — Dispatch extractors, verifiers, and fixer
- **Write** — Create the index file
- **Skill** — Read extraction skills ONCE at the beginning to embed in agent prompts

## Core Principles

- **Skill content embedding:** Load each skill ONCE via the Skill tool, embed the **full verbatim content** in every agent prompt. Never summarize or excerpt — agents cannot load skills themselves.
- **Batched parallel execution:** 2 agents at a time, max 3 concurrent
- **Optional independent verification:** User preference passed from using-unravel
- **Fail fast:** Do not create index with partial/bad results
- **One artifact type per workflow:** Multiple types = sequential complete workflows
- **Module-based organization:** Split by logical features/directories

## Additional Resources

- For batching prompt templates, timeline diagrams, and pseudocode, see [references/batching-strategy.md](references/batching-strategy.md)
- For verification recovery examples, re-verification templates, and fixer output parsing, see [references/verification-recovery.md](references/verification-recovery.md)
