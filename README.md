# Unravel

Unravel the mysteries in your code. Automatic business artifact extraction from source code - understand what any system does by reading what it's built from.

## Installation

```bash
/plugin marketplace add waldokilian2/unravel-marketplace
/plugin install unravel@unravel-marketplace
```

## Usage

### Step 1: Select What to Extract

When you ask Unravel to analyze code, it will first ask you to select artifact categories:

```
What would you like to extract?

□ Business Logic - Business rules, process flows, user stories
□ Data Specifications - Schemas, ORM classes, DTOs, validation
□ Technical Details - Security/NFRs, integrations
□ Everything - Extract all 6 artifact types
```

**Follow-up refinement** (if you select a category):

```
You selected Business Logic. Which types?

□ All business logic types (rules, processes, user stories)
□ Business Rules only
□ Process Flows only
□ User Stories only
```

**Step 2: Choose Verification Level**

After selecting artifact types, Unravel will ask about verification:

```
Would you like independent verification of extracted artifacts?

[✓] Yes - Run independent verifier after each extractor (most thorough, slower)
[ ] No - Skip independent verifier (extractor self-verifies, faster)
```

**Trade-offs:**
- **Yes** (Independent verification): Most thorough, catches more errors, but takes longer
- **No** (Extractor self-verification): Faster, still reliable for most cases

**Note:** Extractors always self-verify their outputs. Independent verification provides an additional layer of validation by having a separate agent review the work.

### Step 3: Unravel Extracts

Unravel follows a consistent extraction workflow with **batched parallel execution**:

```
User → Select type(s) → Choose verification → Main Agent follows orchestrating-extraction skill
  → Spawns extractors in batches of 2 (parallel within batch)
  → [If verification enabled] Spawns verifiers in batches of 2 (parallel within batch)
  → Spawns merger → Output
```

**Key:** Max 3 concurrent agents (main orchestrator + 2 parallel workers)

### Example Workflow

```
You: /unravel
    or
You: Analyze the payment system

Claude: What would you like to extract?

       □ Business Logic - Business rules, process flows, user stories
       □ Data Specifications - Schemas, ORM classes, DTOs, validation
       □ Technical Details - Security/NFRs, integrations
       □ Everything - Extract all 6 artifact types

       [User selects Business Logic]

Claude: You selected Business Logic. Which types?

       □ All business logic types (rules, processes, user stories)
       □ Business Rules only
       □ Process Flows only
       □ User Stories only

       [User selects "All business logic types"]

Claude: Would you like independent verification of extracted artifacts?

       [✓] Yes - Run independent verifier after each extractor (most thorough, slower)
       [ ] No - Skip independent verifier (extractor self-verifies, faster)

       [User selects "Yes" for thorough verification]

Claude: Found 47 files across 3 modules.
       Processing with batched parallel execution (3-agent limit)...

       Batch 1/2: Extracting business-rules from auth and payment modules... ✓
       Batch 2/2: Extracting business-rules from user module... ✓

       Batch 1/2: Verifying auth and payment modules...
          ✓ auth module - PASSED
          ❌ payment module - FAILED (3 issues found)

       🔧 Applying surgical fixes to payment module...
          Removed 1 hallucinated rule
          Updated 1 wrong location
          Augmented 1 incomplete rule
       ✓ Re-verification PASSED

       Batch 2/2: Verifying user module... ✓
       Merging outputs... ✓

       Output: docs/output/business-rules.md

       Now extracting process-flows...
       [same batched parallel process for process-flows]

       Now extracting user-stories...
       [same batched parallel process for user-stories]
```

### Step 4: Executive Summary (Optional)

After all extractions complete, Unravel offers to create an executive summary:

```
All extractions complete! Would you like me to create an executive summary?

[✓] Yes - Create EXECUTIVE-SUMMARY.md
[ ] No - I'm done
```

The executive summary includes:
- Overview of what the codebase does
- Key findings from each artifact type
- Top insights and recommendations
- Links to all generated artifacts

### Output

All extracted artifacts are saved to `docs/output/`:

- business-rules.md
- process-flows.md
- data-specs.md
- user-stories.md
- security-nfrs.md
- integrations.md
- **EXECUTIVE-SUMMARY.md** (optional, generated on request)

## How It Works

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Main Agent (You)                        │
│                                                             │
│  Follows orchestrating-extraction skill                     │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  • Loads skill content ONCE (reads each skill file)  │   │
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
    [Skill embedded in prompt]    [Skill embedded in prompt]
         │                               │
         └─────────────┬─────────────────┘
                       │
                [Both run in parallel]
                       │
                       ▼
         [If verification enabled: Spawn verifiers in batches of 2]
         [If verification disabled: Skip to merger]
                       │
                       ▼
         [If verifier finds issues: Spawn fixer → Re-verify]
         [If fix succeeds: Proceed to merge]
         [If fix fails: Show manual recovery options]
                       │
                       ▼
                  All modules ready
                       │
                       ▼
                  unravel-merger
                       │
                       ▼
              unravel-summarizer (optional)
```

**Key:** Extractors run in batches of 2 (parallel within batch, sequential between batches). Verifiers run in batches of 2 if enabled by user. If verification fails with fixable issues, fixer is spawned to surgically fix problems, then re-verified. Main orchestrator reads each skill ONCE and embeds the content in agent prompts - eliminating redundant skill file reads. Main orchestrator waits for each batch to complete before launching the next batch. This maximizes throughput while respecting the 3-agent limit.

### Agents

| Agent | Purpose |
|-------|---------|
| **unravel-extractor** | Extract patterns from files (per module) with self-verification |
| **unravel-verifier** | Optionally verify extraction outputs (independent agent) |
| **unravel-fixer** | Surgically fix specific issues in extraction output (automatic) |
| **unravel-merger** | Combine extraction outputs into final file |
| **unravel-summarizer** | Create executive summary from all outputs |

### Skills

| Skill | Purpose |
|-------|---------|
| **orchestrating-extraction** | Coordinate extractors, optional verifiers, and merger for all extractions |
| **using-unravel** | Main guide for using Unravel |
| **extract-business-rules** | Domain knowledge for business rules |
| **extract-process-flows** | Domain knowledge for process flows |
| **extract-data-specs** | Domain knowledge for data specs |
| **extract-user-stories** | Domain knowledge for user stories |
| **extract-security-nfrs** | Domain knowledge for security/NFRs |
| **extract-integrations** | Domain knowledge for integrations |

### Execution Model

- **All agents spawned by main agent:** No nested agent spawning
- **Skill loading optimization:** Orchestrator reads each skill ONCE and embeds content in agent prompts (eliminates redundant skill reads)
- **Batched parallel execution:** Extractors run in batches of 2 for optimal throughput (verifiers optional)
- **3-agent limit:** Main orchestrator + 2 parallel agents maximum at any time
- **Optional independent verification:** User chooses whether to run independent verifiers (extractors always self-verify)
- **Automatic surgical fixes:** When verification fails with fixable issues, automatically apply surgical fixes and re-verify
- **Fail-fast:** Stops on errors, doesn't merge partial/bad results
- **One artifact type per workflow:** Multiple types = multiple complete workflows (processed sequentially)

### Commands

| Command | Purpose |
|---------|---------|
| **/unravel** | Start Unravel extraction |
