# Unravel

Unravel the mysteries in your code. Automatic business artifact extraction from source code - understand what any system does by reading what it's built from.

## Installation

```bash
/plugin marketplace add waldokilian2/unravel-marketplace
/plugin install unravel@unravel-marketplace
```

## Usage

### Step 1: Select What to Extract

When you ask Unravel to analyze code, it will first ask you to select artifact types:

```
Which artifact types would you like to extract?

□ Business Rules - Conditional logic, validation, exceptions
□ Process Flows - Function call chains, state machines, workflows
□ Data Specs - Schemas, ORMs, DTOs, validation
□ User Stories - Controllers, routes, endpoints
□ Security/NFRs - Middleware, auth, logging, performance
□ Integrations - HTTP calls, APIs, env vars, external services
```

### Step 2: Unravel Extracts

Unravel automatically chooses the best path:

**Simple Path (< 10 files):** Fast, single-pass extraction
```
User → Select type(s) → unravel-extractor → Output
```

**Complex Path (10+ files):** Sequential extraction with independent verification
```
User → Select type(s) → unravel-orchestrator → workers (sequential) → verifiers (sequential) → unravel-merger → Output
```

### Example Workflow

```
You: Analyze the payment system

Claude: Which artifact types would you like to extract?
       [✓] Business Rules
       [✓] Process Flows
       [ ] Data Specs
       [ ] User Stories
       [ ] Security/NFRs
       [ ] Integrations

Claude: Found 47 files across 3 modules.
       Using complex path with sequential execution.

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
```

### Step 3: Executive Summary (Optional)

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

### Agents

| Agent | Purpose |
|-------|---------|
| **unravel-extractor** | Extract patterns from files (< 10 files) |
| **unravel-orchestrator** | Coordinate workers, verifiers, and merger (10+ files) |
| **unravel-verifier** | Independently verify extraction outputs |
| **unravel-merger** | Combine verified outputs into final file |
| **unravel-summarizer** | Create executive summary from all outputs |

### Execution Model

- **Orchestrators always run sequential internally:** Workers and verifiers run one at a time
- **Multiple orchestrators:** When extracting multiple artifact types, user chooses parallel or sequential
- **One artifact type per orchestrator:** Multiple types = multiple orchestrators
- **Independent verification:** Each module's output is verified before merging
- **Fail-fast:** Stops on errors, doesn't merge partial/bad results
