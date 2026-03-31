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
| **API Contracts** | Request/response schemas, endpoints, status codes |
| **Domain Vocabulary** | Enums, constants, business terminology, error catalogs |
| **Dependency Map** | Module coupling, package dependencies, architecture |
| **Test Coverage** | Test suites, coverage gaps, mocked dependencies |
| **Evolution History** | Deprecated code, tech debt, migration history |

## How It Works

```
You select what to extract (4 groups, 11 types)
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
         │
         ▼
  Optional synthesis documents
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
│   ├── 00-INDEX.md          ← Table of contents with key findings
│   ├── auth.md              ← One file per module
│   └── payment.md
├── process-flows/
├── data-specs/
├── user-stories/
├── security-nfrs/
├── integrations/
├── api-contracts/
├── domain-vocabulary/
├── dependency-map/
├── test-coverage/
├── evolution-history/
├── EXECUTIVE-SUMMARY.md      ← Optional, on request
├── REQUIREMENTS.md           ← Synthesis: /synthesize-requirements
├── ARCHITECTURE.md           ← Synthesis: /synthesize-architecture
├── DATA-DICTIONARY.md        ← Synthesis: /synthesize-data-dictionary
├── SECURITY-AUDIT.md         ← Synthesis: /synthesize-security-audit
└── TEST-PLAN.md              ← Synthesis: /synthesize-test-plan
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

11 extraction skills provide domain knowledge, 2 orchestration skills coordinate workflows, and 5 synthesis skills combine extracted artifacts into stakeholder-ready documents:

| Skill | Purpose |
|-------|---------|
| **using-unravel** | Entry point — artifact selection, verification preference |
| **orchestrating-extraction** | Per-type workflow — discovery, batching, verification, index |
| **extract-business-rules** | Pattern definitions for business rules |
| **extract-process-flows** | Pattern definitions for process and data flows |
| **extract-data-specs** | Pattern definitions for data specifications |
| **extract-user-stories** | Pattern definitions for user stories |
| **extract-security-nfrs** | Pattern definitions for security and NFRs |
| **extract-integrations** | Pattern definitions for integrations |
| **extract-api-contracts** | Pattern definitions for API contracts |
| **extract-domain-vocabulary** | Pattern definitions for domain vocabulary and error catalogs |
| **extract-dependency-map** | Pattern definitions for dependency maps |
| **extract-test-coverage** | Pattern definitions for test coverage analysis |
| **extract-evolution-history** | Pattern definitions for evolution history |
| **synthesize-requirements** | Combines rules, stories, security, and flows into requirements document |
| **synthesize-architecture** | Combines dependencies, integrations, flows, and data specs into architecture overview |
| **synthesize-data-dictionary** | Combines data specs and domain vocabulary into unified data dictionary |
| **synthesize-security-audit** | Combines security, integrations, and API contracts into security audit |
| **synthesize-test-plan** | Combines test coverage, rules, and stories into prioritized test plan |

### Execution Model

- **Batched parallel:** 2 agents at a time (main orchestrator + 2 workers = 3 max)
- **Skill embedding:** Each extraction skill is read once and embedded in agent prompts
- **Fail-fast:** No index created with partial or bad results
- **Sequential by type:** Multiple artifact types run as separate complete workflows
- **Multi-language:** TypeScript, JavaScript, Python, Go, Java patterns supported

## Example Session

```
You: /unravel

Claude: Unravel can extract these artifact types:

       1. Business Rules
       2. Process & Data Flows
       3. User Stories
       4. Data Specs
       5. Security & NFRs
       6. API Contracts
       7. Integrations & Config
       8. Domain Vocabulary
       9. Dependency Map
       10. Test Coverage
       11. Evolution History

       Which areas would you like to extract?

       [✓] Business Logic — Business rules, process & data flows, user stories
       [ ] Data & Domain — Data specs, domain vocabulary
       [ ] Interfaces & Security — API contracts, integrations, security & NFRs
       [ ] Architecture — Dependency map, test coverage, evolution history

       [You select Business Logic]

Claude: Which Business Logic types?

       [✓] Business Rules — Validation constraints, access controls, error conditions
       [✓] Process & Data Flows — Function call chains, state machines, decision paths
       [✓] User Stories — End-user actions from controllers, routes, CLI handlers

       [You select all three]

Claude: Would you like independent verification?

       [ ] Yes - Most thorough, slower
       [✓] No  - Extractor self-verifies, faster

       [You select No]

Claude: Found 47 files across 3 modules.

       Batch 1/2: Extracting business-rules from auth, payment... done
       Batch 2/2: Extracting business-rules from user... done

       Output: docs/output/business-rules/

       [Repeats for process-flows and user-stories]

       All extractions complete! Create an executive summary?
       [You select Yes]
```

### After Extraction: Synthesis Commands

Once you've extracted the relevant artifact types, generate stakeholder-ready documents:

```
You: /synthesize-requirements
You: /synthesize-architecture
You: /synthesize-data-dictionary
You: /synthesize-security-audit
You: /synthesize-test-plan
```

Each command checks that its prerequisite extractions exist and combines them into a single document. For example, `/synthesize-requirements` requires business-rules, user-stories, security-nfrs, and process-flows extractions.

## License

MIT
