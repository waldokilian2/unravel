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

### Step 2: Choose Execution Style (Multiple Types Only)

If you selected multiple artifact types, you'll be asked:

```
You selected [N] artifact types. How should they be processed?

□ Sequential - Complete one type before starting the next
□ Parallel - Process multiple types concurrently (subject to API limits)
```

### Step 3: Unravel Extracts

Unravel follows a consistent extraction workflow:

```
User → Select type(s) → Main Agent follows orchestrating-extraction skill
  → Spawns extractors (sequential)
  → Spawns verifiers (sequential)
  → Spawns merger → Output
```

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

Claude: Found 47 files across 3 modules.
       Processing business-rules with sequential execution.

       Module 1/3: Extracting business-rules... ✓
       Module 1/3: Verifying business-rules... ✓
       Module 2/3: Extracting business-rules... ✓
       Module 2/3: Verifying business-rules... ✓
       Module 3/3: Extracting business-rules... ✓
       Module 3/3: Verifying business-rules... ✓
       Merging outputs... ✓

       Output: docs/output/business-rules.md

       Now extracting process-flows...
       [same process for process-flows]

       Now extracting user-stories...
       [same process for user-stories]
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
│  │  • Counts files & splits into modules               │   │
│  │  • Spawns agents SEQUENTIALLY (one at a time)       │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                              │
                ┌─────────────┴─────────────┐
                │                           │
         Spawn Agent                    Spawn Agent
    unravel-extractor              unravel-verifier
      (Module 1)          ←────────→    (Module 1)
                │                           │
                │                           │
         Spawn Agent                    Spawn Agent
    unravel-extractor              unravel-verifier
      (Module 2)          ←────────→    (Module 2)
                │                           │
                │                           │
         Spawn Agent                    Spawn Agent
    unravel-extractor              unravel-verifier
      (Module 3)          ←────────→    (Module 3)
                │                           │
                └─────────────┬─────────────┘
                              │
                       Spawn Agent
                  unravel-merger
                              │
                       Spawn Agent
              unravel-summarizer (optional)
```

**Key:** The horizontal arrows (←────────→) indicate workflow sequence, not automatic spawning. The Main Agent explicitly spawns each agent: extractor completes → Main Agent spawns corresponding verifier → after all verifiers pass → Main Agent spawns merger.

### Agents

| Agent | Purpose |
|-------|---------|
| **unravel-extractor** | Extract patterns from files (per module) |
| **unravel-verifier** | Independently verify extraction outputs |
| **unravel-merger** | Combine verified outputs into final file |
| **unravel-summarizer** | Create executive summary from all outputs |

### Skills

| Skill | Purpose |
|-------|---------|
| **orchestrating-extraction** | Coordinate extractors, verifiers, and merger for all extractions |
| **using-unravel** | Main guide for using Unravel |
| **extract-business-rules** | Domain knowledge for business rules |
| **extract-process-flows** | Domain knowledge for process flows |
| **extract-data-specs** | Domain knowledge for data specs |
| **extract-user-stories** | Domain knowledge for user stories |
| **extract-security-nfrs** | Domain knowledge for security/NFRs |
| **extract-integrations** | Domain knowledge for integrations |

### Execution Model

- **All agents spawned by main agent:** No nested agent spawning
- **Sequential execution:** Extractors run one at a time, verifiers run one at a time
- **Independent verification:** Each module's output is verified before merging
- **Fail-fast:** Stops on errors, doesn't merge partial/bad results
- **One artifact type per workflow:** Multiple types = multiple complete workflows

### Commands

| Command | Purpose |
|---------|---------|
| **/unravel** | Start Unravel extraction |
| **/verify** | Verify extracted artifacts |
