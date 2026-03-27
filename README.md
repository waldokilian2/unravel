# Unravel

Turn source code into business documentation. Unravel extracts structured artifacts from any codebase so you can understand what a system does without reading code.

## Quick Start

```bash
# Install the plugin
/plugin marketplace add waldokilian2/unravel-marketplace
/plugin install unravel@unravel-marketplace

# Run it
/unravel
```

Or just describe what you want in plain language:

```
Analyze the payment system
Extract business rules from auth.ts
What are the validation rules in this code?
```

## What It Extracts

| Artifact | What You Get |
|----------|-------------|
| **Business Rules** | Validation constraints, access controls, error conditions |
| **Process Flows** | Function call chains, state machines, decision paths |
| **Data Specs** | Schemas, ORM models, DTOs, relationships |
| **User Stories** | End-user actions from controllers, routes, CLI handlers |
| **Security / NFRs** | Auth patterns, rate limits, encryption, logging |
| **Integrations** | HTTP clients, database connections, external services |

## How It Works

```
You select what to extract
        │
        ▼
  Files discovered & grouped into modules
        │
        ▼
  Extractors run in parallel (2 at a time)
        │
        ▼
  Optional independent verification
        │
    ┌───┴───┐
  Pass      Fail
    │         │
    │      Surgical fix → Re-verify
    │         │
    └────┬────┘
         ▼
  Index created with links to all modules
         │
         ▼
  Optional executive summary
```

### Verification

Every extractor self-verifies its output. You can also enable **independent verification**, which spawns a separate agent to cross-check each extraction against the source code. If issues are found, Unravel automatically applies surgical fixes and re-verifies.

| Mode | Speed | Thoroughness |
|------|-------|-------------|
| Self-verify (default) | Fast | Good for most codebases |
| Independent verification | Slower | Catches more errors, recommended for critical systems |

## Output

All artifacts land in `docs/output/`, organized by type:

```
docs/output/
├── business-rules/
│   ├── 00-INDEX.md          ← Table of contents
│   ├── auth.md              ← One file per module
│   └── payment.md
├── process-flows/
│   ├── 00-INDEX.md
│   └── ...
├── data-specs/
├── user-stories/
├── security-nfrs/
├── integrations/
└── EXECUTIVE-SUMMARY.md      ← Optional, on request
```

## Under the Hood

### Agents

Four specialized agents handle the work:

| Agent | Role | Tools |
|-------|------|-------|
| **unravel-extractor** | Reads files, extracts patterns, writes output | Grep, Glob, Read, Write |
| **unravel-verifier** | Cross-checks extraction against source code | Read, Grep, Glob |
| **unravel-fixer** | Applies surgical fixes when verification fails | Read, Edit |
| **unravel-summarizer** | Creates executive summary from all outputs | Read, Glob, Write |

### Skills

Eight skills provide domain knowledge and orchestration:

| Skill | Purpose |
|-------|---------|
| **using-unravel** | Entry point — artifact selection, verification preference |
| **orchestrating-extraction** | Per-type workflow — discovery, batching, verification, index |
| **extract-business-rules** | Pattern definitions for business rules |
| **extract-process-flows** | Pattern definitions for process flows |
| **extract-data-specs** | Pattern definitions for data specifications |
| **extract-user-stories** | Pattern definitions for user stories |
| **extract-security-nfrs** | Pattern definitions for security and NFRs |
| **extract-integrations** | Pattern definitions for integrations |

### Execution Model

- **Batched parallel:** 2 agents at a time (main orchestrator + 2 workers = 3 max)
- **Skill embedding:** Each extraction skill is read once and embedded in agent prompts
- **Fail-fast:** No index created with partial or bad results
- **Sequential by type:** Multiple artifact types run as separate complete workflows
- **Multi-language:** TypeScript, JavaScript, Python, Go, Java patterns supported

## Example Session

```
You: /unravel

Claude: What would you like to extract?

       □ Business Logic - Rules, flows, user stories
       □ Data Specifications - Schemas, models, DTOs
       □ Technical Details - Security, integrations
       □ Everything - All 6 types

       [You select Business Logic → All types]

Claude: Would you like independent verification?

       [✓] Yes - Most thorough
       [ ] No  - Faster

       [You select Yes]

Claude: Found 47 files across 3 modules.

       Batch 1/2: Extracting business-rules from auth, payment... done
       Batch 2/2: Extracting business-rules from user... done

       Verifying auth... PASSED
       Verifying payment... FAILED (3 issues)
       Verifying user... PASSED

       Fixing payment... Removed 1 hallucinated rule,
                        Updated 1 wrong location,
                        Augmented 1 incomplete rule
       Re-verification PASSED

       Output: docs/output/business-rules/

       [Repeats for process-flows and user-stories]

       All extractions complete! Create an executive summary?
       [You select Yes]
```

## License

MIT
