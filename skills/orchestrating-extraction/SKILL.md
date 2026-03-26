---
name: orchestrating-extraction
description: Orchestrate parallel extractors and verifiers with 3-agent limit, then create index
---

# Orchestrating Extraction

You are orchestrating an Unravel extraction. Coordinate extractors, verifiers, and index creation.

**Execution model:** Run up to 2 extractors/verifiers in parallel (3-agent limit: main orchestrator + 2 parallel agents).
**Note:** Multiple artifact types are processed sequentially (one complete workflow per type).

## Your Task

Analyze the extraction request and coordinate extractors, verifiers, and index creation.

**IMPORTANT: You handle ONE artifact type at a time.** If asked for multiple artifact types, handle them one at a time with complete workflows per type.

**Artifact Type:** [business-rules | process-flows | data-specs | user-stories | security-nfrs | integrations]

**Scope:** [file paths, directories, or "codebase"]

## Coordination Process

### Step 0: Load Skill Content

Before starting extraction, load the relevant skill content ONCE using the Skill tool.

**Read the extraction skill for the artifact type you're handling:**

```
Skill("unravel:extract-[artifact-type]")
```

**Skill name mapping:**
| Artifact Type | Skill Name |
|---------------|------------|
| business-rules | unravel:extract-business-rules |
| process-flows | unravel:extract-process-flows |
| data-specs | unravel:extract-data-specs |
| user-stories | unravel:extract-user-stories |
| security-nfrs | unravel:extract-security-nfrs |
| integrations | unravel:extract-integrations |

**Store the skill content** - you'll need to embed it in the extractor and verifier prompts.

**Key sections to extract from the skill:**
1. **What to Extract** - Pattern definitions
2. **Hotspot Discovery** - File discovery patterns
3. **Output Format** - Expected output structure
4. **Core Principles** - Extraction guidelines

**IMPORTANT:** You will embed this skill content directly in agent prompts. Do NOT tell agents to use the Skill tool.

### Step 1: Ask User for Verification Preference

Before starting extraction, ask the user whether they want independent verification:

```
Would you like independent verification of extracted artifacts?

[✓] Yes - Run independent verifier after each extractor (most thorough, slower)
[ ] No - Skip independent verifier (extractor self-verifies, faster)
```

**Store the user's choice** and use it to determine whether to spawn verifiers in Step 4.

**Note:** Extractors always self-verify their outputs. Independent verification provides an additional layer of validation by having a separate agent review the work. For most cases, the extractor's self-verification is sufficient. Independent verification is useful for:
- Critical systems requiring maximum accuracy
- Complex or unfamiliar codebases
- Audit or documentation requiring thorough validation

### Step 2: Count Files, Discover, Create Output Folder, and Split into Modules

**File discovery is the orchestrator's responsibility:** You use Glob/Grep to find all relevant files, then pass specific file paths to each extractor.

1. Use the hotspot patterns from the skill content you loaded in Step 0

2. Use Glob/Grep with those patterns to find all relevant files in the codebase

3. **Create output folder using Bash:**
   ```
   mkdir -p "docs/output/[artifact-type]/"
   ```

4. Split discovered files into logical modules (by directory/feature)

**Note:** The folder is created once here. All subsequent agents are informed the folder exists.

**Module Naming Convention:**

| Source Structure | Module Name | Example |
|------------------|-------------|---------|
| Single directory | Directory name | `src/auth` → `auth` |
| Nested directories | Last directory name | `src/payment/processing` → `processing` |
| Files across features | Primary feature name | `auth.ts, user.ts` → `auth` |
| Mixed/unclear | Numbered | `module-1`, `module-2`, etc. |

**Output folder structure:**
```
docs/output/[artifact-type]/
├── 00-INDEX.md        ← Created in Step 5
├── [module-name].md   ← One file per module
└── [module-name].md
```

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
→ Output folder: docs/output/business-rules/
→ Module files: auth.md, payment.md

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
→ Output folder: docs/output/business-rules/
→ Module files: processing.md, methods.md
```

If only one module or few files, treat as a single module named after the primary directory or `main`.

### Step 3: Launch Extractors (Batched Parallel)

For each module, launch extractors in batches of 2 (max 2 concurrent agents):

**CRITICAL:** Embed the skill content directly in the agent prompt. Do NOT tell agents to use the Skill tool.

**Batching pattern:**
```
# Process modules in batches of 2
batch_size = 2
for i in range(0, len(modules), batch_size):
    batch = modules[i:i+batch_size]
    task_ids = []

    # Launch extractors for this batch in parallel
    for module in batch:
        task_id = Agent(unravel-extractor,
                       "Extract [artifact-type] from [module-name] module

                        **DOMAIN KNOWLEDGE:**
                        [Embed the skill content here - include:
                         - What to Extract section
                         - Hotspot Discovery patterns
                         - Output Format
                         - Core Principles]

                        Artifact Type: [artifact-type]
                        Module Name: [module-name]
                        Files: [specific file paths]
                        Output: docs/output/[artifact-type]/[module-name].md

                        **NOTE:** The output folder already exists. Just write your file to it.

                        **INSTRUCTIONS:**
                        Use the domain knowledge above to extract [artifact-type] patterns.
                        Follow the output format specified in the domain knowledge.
                        Self-verify each artifact as you extract it.",
                       run_in_background=true)
        task_ids.append(task_id)

    # Wait for all extractors in this batch to complete
    for task_id in task_ids:
        TaskOutput(task_id, block=true)
```

**IMPORTANT:** Launch extractors in batches of 2 (parallel within batch, sequential between batches).
**IMPORTANT:** Always embed the full skill content in the prompt.
**IMPORTANT:** Use `run_in_background=true` for parallel agent spawns.
**IMPORTANT:** Do NOT include Skill tool instructions - the skill content is already provided.

### Step 4: Verification Phase

The verification phase consists of three subprocesses. Execute them sequentially.

**Note:** This entire phase is conditional based on the user's verification preference from Step 1.

#### 4.1: Launch Verifiers (Batched)

**Check the user's verification preference from Step 1:**

**If user chose "No" (skip independent verification):**
- Skip this entire verification phase
- Proceed directly to Step 5 (Create Index)
- All module files are considered ready

**If user chose "Yes" (run independent verification):**

For each module file created, launch verifiers in batches of 2 (max 2 concurrent agents).

**CRITICAL:** Embed the skill content directly in the verifier prompt. Do NOT tell agents to use the Skill tool.

**Batching pattern:**
```
# Process module files in batches of 2
batch_size = 2
verification_results = []  # Store results for next step

for i in range(0, len(module_files), batch_size):
    batch = module_files[i:i+batch_size]
    task_ids = []

    # Launch verifiers for this batch in parallel
    for module_file in batch:
        task_id = Agent(unravel-verifier,
                       "Verify extraction output

                        **DOMAIN KNOWLEDGE:**
                        [Embed the skill content here - include:
                         - What to Extract section (for pattern definitions)
                         - Output Format (to understand expected structure)
                         - Core Principles]

                        Output File: [module_file]
                        Source Files: [files that module analyzed]
                        Artifact Type: [artifact-type]

                        **INSTRUCTIONS:**
                        Use the domain knowledge above to verify:
                        1. Accuracy - artifacts exist in source code
                        2. Completeness - all patterns captured
                        3. Boundaries - no artifacts outside scope

                        Report PASSED or FAILED with STRUCTURED ISSUES (include issue type, location, problem, expected, action).",
                       run_in_background=true)
        task_ids.append(task_id)

    # Wait for all verifiers in this batch to complete
    for task_id in task_ids:
        result = TaskOutput(task_id, block=true)

        # Parse and store verification result for subprocess 4.2
        verification_results.append({
            module_file: module_file,
            status: "PASSED" if result contains "PASSED" else "FAILED",
            issues: result.issues if result contains "FAILED" else []
        })
```

**Output of 4.1:** A list of verification results, one per module file, containing:
- `module_file`: Path to the module output file
- `status`: "PASSED" or "FAILED"
- `issues`: List of structured issues (if any)

**IMPORTANT:** Launch verifiers in batches of 2 (parallel within batch, sequential between batches).
**IMPORTANT:** Always embed the full skill content in the prompt.
**IMPORTANT:** Use `run_in_background=true` for parallel agent spawns.
**IMPORTANT:** Do NOT include Skill tool instructions - the skill content is already provided.

#### 4.2: Process Failed Verifications

For each failed verification result from subprocess 4.1, apply the surgical fix workflow.

**Recovery Workflow:**
```
failed_modules = []  # Track modules that ultimately failed

for result in verification_results:
    if result.status == "PASSED":
        continue  # No action needed

    # This result failed - always apply surgical fix workflow
    if result.issues is not empty:
        # Step 1: Launch fixer
        fix_task_id = Agent(unravel-fixer,
                           "Fix extraction output

                            **Output File:** [result.module_file]
                            **Issues:** [result.issues]
                            **Source Files:** [files that module analyzed]

                            **NOTE:** The output folder already exists. Just edit the file in place.

                            **INSTRUCTIONS:**
                            Apply surgical fixes to address each issue in the list.
                            Read source files to verify correct information.
                            Make minimal edits - only fix what's broken.",
                           run_in_background=true)
        TaskOutput(fix_task_id, block=true)

        # Step 2: Extract fixer results and re-verify
        # Parse the fixer output to extract the fixes applied
        fixer_output = TaskOutput(fix_task_id, block=true)
        fixes_applied = []

        # Extract fixes from fixer output format:
        # "Fixes:
        #  - Line 45: Removed hallucinated rule "User must be admin to delete"
        #  - Line 78: Updated location from src/auth/password.ts:45 to src/auth/validation.ts:23
        #  - Line 102: Augmented with regex pattern and error message details"
        for line in fixer_output.split('\n'):
            if line.strip().startswith('- Line'):
                # Parse: "- Line 45: Removed hallucinated rule..."
                parts = line.split(':', 2)
                if len(parts) >= 3:
                    line_num = parts[1].strip().split()[0]  # Extract line number
                    description = parts[2].strip()
                    # Extract action type from description (first word)
                    # Actions: Removed, Updated, Augmented, Corrected
                    action_word = description.split()[0].lower()
                    # Map to issue type
                    action_map = {
                        "removed": "remove",
                        "updated": "update",
                        "augmented": "augment",
                        "corrected": "correct"
                    }
                    action_type = action_map.get(action_word, "update")
                    fixes_applied.append({
                        line: line_num,
                        type: action_type,
                        description: description
                    })

        # Build re-verification context
        fixes_context = "\n".join([
            f"Issue {i+1}: [{fix.type}] - Line {fix.line}: {fix.description}\n  Action: {fix.type}"
            for i, fix in enumerate(fixes_applied)
        ])

        # Step 3: Re-verify after fix with context
        reverify_task_id = Agent(unravel-verifier,
                                "Verify extraction output

                                 **DOMAIN KNOWLEDGE:**
                                 [Embed the skill content here]

                                 Output File: [result.module_file]
                                 Source Files: [files that module analyzed]
                                 Artifact Type: [artifact-type]

                                 **RE-VERIFICATION MODE:**
                                 This output was just fixed. The following issues were addressed:

                                 ${fixes_context}

                                 **INSTRUCTIONS:**
                                 1. Focus verification on the fixed items above (specific line numbers)
                                 2. Confirm each fix was applied correctly
                                 3. Quick scan for any new issues introduced by the fixes
                                 4. Report PASSED if fixes are correct, or FAILED with remaining issues",
                                run_in_background=true)
        reverify_result = TaskOutput(reverify_task_id, block=true)

        # Step 4: Check re-verification result
        if reverify_result contains "FAILED":
            # Surgical fix failed - add to failed modules
            failed_modules.append({
                module_file: result.module_file,
                issues: reverify_result.issues
            })
        # If re-verification passed, module is ready for index creation (no action needed)

    else:
        # No issues parsed - add to failed modules
        failed_modules.append({
            module_file: result.module_file,
            issues: result.issues
        })
```

**Output of 4.2:** A list of modules that failed verification (or re-verification after fix attempt).

**IMPORTANT:** When verification fails with structured issues, automatically spawn fixer and re-verify (surgical fix workflow).
**IMPORTANT:** Each failed module triggers exactly one fix attempt. If re-verification fails, the module is marked for manual recovery.
**IMPORTANT:** The fixer output must include a "Fixes:" section listing each fix applied with line numbers, action type, and description. This is extracted and passed to the re-verifier as context.

#### 4.3: Determine Outcome

After processing all failed verifications in subprocess 4.2, determine the next step.

**Check the failed_modules list:**

**If failed_modules is empty (all modules passed):**
- Proceed to Step 5 (Create Index)
- All module files are verified and ready

**If failed_modules has items (some modules failed):**
- Do NOT proceed to Step 5
- Present manual recovery options to the user
- Wait for user decision before continuing

**Recovery options presentation:**
```
Verification completed with failures:

Failed Modules: [list from failed_modules]

For each failed module, present:
1. Re-run extraction for the failed module only
2. Manually review and fix issues in the output file
3. Skip the failed module and create index with the rest (user confirmation required)

Which option would you like for each failed module?
```

**After user recovery action:**
- If user chose to re-extract: Restart workflow for that module (return to Step 3 for specific module)
- If user chose manual fix: Wait for user to confirm fixes are complete, then re-run verifier (return to 4.1 for specific module)
- If user chose to skip: Remove module from index, proceed to Step 5 with remaining modules

**IMPORTANT:** Do not create the index until all modules to be included have passed verification (or user explicitly chose to skip failed modules).

### Step 5: Create Index

**Prerequisites for index creation:**

**If user chose "No" (skip independent verification):**
- Create index directly with all module files
- No verification step needed

**If user chose "Yes" (run independent verification):**
- Only create index after Step 4.3 confirms all modules passed (or user chose to skip failed modules)

**Index creation:**

Create `docs/output/[artifact-type]/00-INDEX.md` with the following format:

```markdown
# [Artifact Type]

Extraction: [YYYY-MM-DD]

## Extraction Summary
- **Total Artifacts:** [count from all modules]
- **Files Analyzed:** [unique file count]
- **Modules:** [count]
- **Verification:** Each module independently verified

## Modules

| Module | Artifacts | Link |
|--------|-----------|------|
| [module-name] | [count] | [[module-name].md](module-name.md) |
| [module-name] | [count] | [[module-name].md](module-name.md) |

---

*Generated by Unravel on [timestamp]*
```

**Process:**
1. Count total artifacts across all module files
2. Count unique source files analyzed
3. Create the index file using Write tool
4. Report completion with summary

**Report format:**
```
✅ Index created: docs/output/[artifact-type]/00-INDEX.md
Modules: [count]
Total artifacts: [count]
```

### Verification Recovery Examples

The following examples illustrate the verification and recovery workflow described in Step 4.

**Example 1: Surgical fix succeeded (automatic recovery)**
```
❌ Verification FAILED for module 'payment'
Issues found: 3

🔧 Applying surgical fixes...
   Removed 1 hallucinated rule
   Updated 1 wrong location
   Augmented 1 incomplete rule

✅ Re-verification PASSED for module 'payment'
Proceeding to create index...
```

**Example 2: Surgical fix failed, manual recovery needed**
```
❌ Verification FAILED for module 'payment'
Issues found: 5

🔧 Applying surgical fixes...
   Fixed 3 issues
   2 issues remain (complex structural problems)

Recovery options:
1. Re-extract payment module: Agent(unravel-extractor, "...payment...")
2. Manually review and fix the 2 remaining issues in docs/output/business-rules/payment.md
3. Skip payment module and create index with other modules

Which option would you like?
```

**Example 4: Re-verification prompt with fix context**
```
# After fixer completes, re-verification includes context:

Agent(unravel-verifier,
       "Verify extraction output

        **DOMAIN KNOWLEDGE:**
        [Business rules skill content embedded here]

        Output File: docs/output/business-rules/payment.md
        Source Files: src/payment/charge.ts, src/payment/refund.ts
        Artifact Type: business-rules

        **RE-VERIFICATION MODE:**
        This output was just fixed. The following issues were addressed:

        Issue 1: [remove] - Line 45: Hallucinated rule about admin requirements
          Action: remove
        Issue 2: [update] - Line 78: Incorrect file location reference
          Action: update
        Issue 3: [augment] - Line 102: Missing validation pattern details
          Action: augment

        **INSTRUCTIONS:**
        1. Focus verification on the fixed items above (specific line numbers)
        2. Confirm each fix was applied correctly
        3. Quick scan for any new issues introduced by the fixes
        4. Report PASSED if fixes are correct, or FAILED with remaining issues")

# The verifier now knows exactly what to check instead of re-reading the entire file
```

## Batching Strategy

The orchestration uses a **batched parallel approach** to maximize throughput while respecting the 3-agent limit (main orchestrator + 2 parallel agents).

### How Batching Works

1. **Extractors:** Process modules in batches of 2
   - Launch 2 extractors in parallel (run_in_background=true)
   - Wait for both to complete (TaskOutput with block=true)
   - Launch next batch of 2
   - Repeat until all modules processed

2. **Verifiers:** Process verified outputs in batches of 2 (if user chose "Yes")
   - After all extractors complete, launch 2 verifiers in parallel
   - Wait for both to complete
   - Launch next batch of 2
   - Repeat until all outputs verified
   - **Skipped entirely if user chose "No"**

3. **Index creation:** Done by orchestrator after extraction completes
   - If user chose "Yes": runs after all verifications pass
   - If user chose "No": runs immediately after extractors complete
   - Creates 00-INDEX.md with links to all module files

### Example Timeline (5 modules, with independent verification)

```
Time →
Extractors:    [E1+E2] → [E3+E4] → [E5]  → (all complete)
Verifiers:                              → [V1+V2] → [V3+V4] → [V5] → (all pass)
Index create:                                                          → [Orchestrator]
```

**Example Timeline (5 modules, without independent verification):**

```
Time →
Extractors:    [E1+E2] → [E3+E4] → [E5]  → (all complete)
Index create:                                    → [Orchestrator]
```

**Legend:**
- E1-E5: Extractors for modules 1-5
- V1-V5: Verifiers for modules 1-5
- `[E1+E2]`: Two agents running in parallel

**Note:** If a verifier fails with issues, a fixer agent is spawned before index creation. After fixing, the module is re-verified. If re-verification fails, manual recovery is required.

### Benefits of Batching

- **Faster than pure sequential:** 2 agents working simultaneously ≈ 2x speedup
- **Respects agent limits:** Never exceeds 3 concurrent agents (main + 2 workers)
- **Predictable resource usage:** Easy to track progress and errors
- **Graceful error handling:** Failed batches don't affect completed work

## Available Tools

- **Bash** - Create output folder (`mkdir -p`)
- **Grep** - Search for patterns to count files
- **Glob** - Find files matching patterns
- **Agent** - Dispatch extractors, verifiers, and fixer
- **Write** - Create the index file
- **Skill** - Read extraction skills ONCE at the beginning (Step 0) to embed in agent prompts

**Note:** The orchestrator creates the output folder in Step 2. Agents are informed the folder exists and should write directly to it without attempting to create it.

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

Index: Pending (awaiting all verifications)
```

## Error Handling

**If an extractor fails:**
- Report error details
- Don't launch verifier for that module
- Don't create index
- Ask user how to proceed

**If a verifier fails:**
- Report which module failed with specific errors
- Show verification failure details
- Don't create index
- Present recovery options (see Step 4.2 and 4.3 for automatic fix workflow and manual recovery)

**Note:** If user chose "No" for independent verification, this step is skipped entirely.

## Core Principles

**Skill content embedding:** Orchestrator reads each skill ONCE and embeds content in agent prompts (eliminates redundant skill reads)

**Batched parallel execution:** Extractors and verifiers (if enabled) run in batches of 2 for optimal throughput

**3-agent limit:** Main orchestrator + 2 parallel agents maximum at any time

**Optional independent verification:** User chooses whether to run independent verifiers (extractors always self-verify)

**Fail fast:** Stop on errors, don't create index with partial/bad results

**Verify before index:** If verification enabled, no index until all verifications pass

**One artifact type:** This orchestration handles ONE artifact type. Multiple types require multiple complete workflows (processed sequentially)

**Module-based organization:** Split by logical features/directories for clarity

**Folder-based output:** Each artifact type gets its own folder with module files and an index

**User control:** User chooses verification level based on their needs

## Multiple Artifact Types

If the user requests multiple artifact types (e.g., "extract everything"):

**DO NOT:** Try to handle all types in one pass

**INSTEAD:** Handle each type sequentially with complete workflow:

```
Processing [N] artifact types sequentially...

[Type 1 - complete workflow with batched parallel execution]
[Type 2 - complete workflow with batched parallel execution]
[Type 3 - complete workflow with batched parallel execution]
```

**Note:** Each artifact type gets its own complete workflow (extract → verify → create index) with batched parallel execution within that type.

**Note:** After all extractions complete, offer to create an executive summary using the unravel-summarizer agent.
