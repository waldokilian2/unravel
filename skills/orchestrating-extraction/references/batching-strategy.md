# Batching Strategy Details

The orchestration uses a **batched parallel approach** to maximize throughput while respecting the 3-agent limit (main orchestrator + 2 parallel agents).

## How Batching Works

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

## Example Timeline (5 modules, with independent verification)

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

## Benefits of Batching

- **Faster than pure sequential:** 2 agents working simultaneously ≈ 2x speedup
- **Respects agent limits:** Never exceeds 3 concurrent agents (main + 2 workers)
- **Predictable resource usage:** Easy to track progress and errors
- **Graceful error handling:** Failed batches don't affect completed work

## Batching Pseudocode

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

                        **DOMAIN KNOWLEDGE (complete extraction skill):**
                        [Paste the FULL SKILL.md file content here verbatim.
                        Do NOT summarize or excerpt. The extractor needs every
                        section: What to Extract, Where [Type] Lives,
                        Hotspot Discovery, Pattern Signals, Output Format,
                        and Core Principles. Copy it all.]

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
**IMPORTANT:** Do NOT include Skill tool instructions — the skill content is already provided.

### Verifier Batching Pseudocode

```
# Process module files in batches of 2
batch_size = 2
verification_results = []

for i in range(0, len(module_files), batch_size):
    batch = module_files[i:i+batch_size]
    task_ids = []

    for module_file in batch:
        task_id = Agent(unravel-verifier,
                       "Verify extraction output

                        **DOMAIN KNOWLEDGE (complete extraction skill):**
                        [Paste the FULL SKILL.md file content here verbatim.
                        The verifier needs the complete skill to understand
                        pattern definitions, boundary rules, and output format.]

                        Output File: [module_file]
                        Source Files: [files that module analyzed]
                        Artifact Type: [artifact-type]

                        **INSTRUCTIONS:**
                        Use the domain knowledge above to verify:
                        1. Accuracy - artifacts exist in source code
                        2. Completeness - all patterns captured
                        3. Boundaries - no artifacts outside scope

                        Report PASSED or FAILED with STRUCTURED ISSUES.",
                       run_in_background=true)
        task_ids.append(task_id)

    for task_id in task_ids:
        result = TaskOutput(task_id, block=true)
        verification_results.append({
            module_file: module_file,
            status: "PASSED" if result contains "PASSED" else "FAILED",
            issues: result.issues if result contains "FAILED" else []
        })
```
