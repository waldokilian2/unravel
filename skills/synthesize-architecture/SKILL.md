---
name: synthesize-architecture
description: >-
  This skill synthesizes extracted architecture artifacts into a stakeholder-ready
  architecture document. Use this agent when the user asks to generate an architecture
  document, create an architecture overview, synthesize architecture, map system architecture,
  produce an architecture summary, or mentions /synthesize-architecture. This is a
  post-extraction command — it reads files already created by Unravel's extraction pipeline
  and combines them into a single coherent document. Do NOT use this skill for extracting
  new artifacts; it only synthesizes existing ones.
user-invocable: true
---

# Architecture Document Synthesis

This skill takes the four extraction artifact groups that Unravel produces and weaves them into a single, stakeholder-readable architecture document. It does not perform any new code analysis — it reads, cross-references, and synthesizes what the extraction pipeline already produced.

## Prerequisite Artifacts

All four extraction groups must be complete before synthesis can begin. Each group must have a `00-INDEX.md` in `docs/output/`.

| Extraction Type | Output Directory | Extraction Group |
|----------------|-----------------|------------------|
| `dependency-map` | `docs/output/dependency-map/` | Architecture |
| `integrations` | `docs/output/integrations/` | Interfaces & Security |
| `process-flows` | `docs/output/process-flows/` | Business Logic |
| `data-specs` | `docs/output/data-specs/` | Data & Domain |

## Execution Flow

### Step 1: Prerequisite Check

Use Glob to verify that each prerequisite index file exists:

```
Glob: docs/output/dependency-map/00-INDEX.md
Glob: docs/output/integrations/00-INDEX.md
Glob: docs/output/process-flows/00-INDEX.md
Glob: docs/output/data-specs/00-INDEX.md
```

If **any** index file is missing, stop immediately and print a message listing all missing extractions:

```
Cannot generate architecture document. The following extractions are missing:

- [type] — Run /unravel and select [group name]
```

Show the message exactly once with all missing types listed, then **STOP**. Do not proceed to synthesis.

### Step 2: Read Input Artifacts

For each extraction type that passed the prerequisite check:

1. **Read the `00-INDEX.md`** to get the list of module files produced by that extraction.
2. **Read each module file** listed in the index.

**Large extraction handling:** If an extraction type has more than 5 module files:
- Read the `00-INDEX.md` first.
- Read all module files for `dependency-map` (this is the structural backbone).
- For the other types (`integrations`, `process-flows`, `data-specs`), read the index, identify the most significant modules (those with the most artifacts, referenced by dependency-map, or containing external service integrations), and read those in full. For the remaining modules, use Grep to find specific cross-references (module names, entity names, service names) as needed rather than reading every file.

### Step 3: Cross-Reference and Synthesize

While reading the artifacts, actively cross-reference between them:

- When a `dependency-map` module lists dependencies on other modules, note those modules for cross-referencing with `integrations` and `data-specs`.
- When `integrations` mentions an external service used by a module, link that back to the module's entry in `dependency-map`.
- When `data-specs` defines entities, check `process-flows` for flows that read or write those entities.
- When `process-flows` describes a data transformation, verify against `data-specs` that the source and target entities exist.

### Step 4: Generate the Architecture Document

Write the output to `docs/output/ARCHITECTURE.md` using the following structure exactly.

## Output Format

```markdown
# Architecture Document

**Generated:** [YYYY-MM-DD]
**Source Artifacts:** dependency-map, integrations, process-flows, data-specs

---

## System Overview

[2-3 paragraph prose overview of the system's architecture, synthesized from dependency-map and integrations. Describe the high-level structure, technology stack, and architectural patterns observed.]

---

## Component Map

[For each module from dependency-map:]

### [Module Name]
- **Role:** [What this module does, synthesized from its dependency-map description and any process-flows or integrations that reference it]
- **Dependencies:** [Internal module dependencies from dependency-map, listed as module names]
- **External Services:** [From integrations, if applicable — list the external services this module connects to]
- **Data Entities:** [From data-specs, if applicable — list the entities this module owns or primarily operates on]

---

## Integration Points

### External Services
| Service | Purpose | Protocol | Module(s) | Source |
|---------|---------|----------|-----------|--------|
| [service name] | [what the service is used for] | [HTTP/gRPC/queue/event] | [which modules use it] | `extraction-file:line` |

### Internal Communication
[Prose description (1-3 paragraphs) of how modules communicate internally. Derive this from process-flows (event-driven patterns, direct function calls, shared state) and dependency-map (import graph). Describe the dominant communication patterns — is it event-driven, synchronous RPC, shared database, message queue, or a mix? Highlight any notable patterns such as event buses, shared kernel modules, or anti-corruption layers.]

---

## Data Architecture

### Entity Relationships
[Prose description (1-3 paragraphs) synthesizing the overall data model from data-specs. Describe the core entities, their relationships (one-to-many, many-to-many), and any notable patterns such as aggregate roots, value objects, or polymorphic associations. Do not repeat every field — focus on the shape and relationships of the data model at a stakeholder level.]

### Data Flow
[For each significant data flow from process-flows that involves data creation, transformation, or storage:]

- **[Flow name]:** [source entity or entry point] → [transformation description] → [destination entity or exit point]
  - Source: process-flows/[module].md

[List only the significant data flows — those that represent core business processes or involve multiple entities. Omit simple CRUD flows unless they are architecturally notable.]

---

## Dependency Analysis

### Module Coupling
| Module | Depends On | Coupling Level |
|--------|-----------|----------------|
| [module name] | [list of modules it depends on] | [High/Medium/Low] |

**Coupling Level Criteria:**
- **High:** Depends on 4+ internal modules, or has circular dependencies, or depends on shared infrastructure modules used by many others.
- **Medium:** Depends on 2-3 internal modules with no circular dependencies.
- **Low:** Depends on 0-1 internal modules, or only depends on leaf/utility modules.

### Architectural Risks
[Flag specific risks observed in the dependency graph:]
- **Circular dependencies:** List any module pairs or chains where A → B → A exists.
- **Tight coupling:** Modules that depend on many others or are depended on by many others (identify hub modules).
- **Shared dependency risk:** Modules that share a common dependency where changes to the shared module would have high blast radius.
- **Missing abstractions:** If two unrelated modules both depend on the same implementation detail rather than an abstraction, note it.

---

## Gaps & Observations

[Prose section listing architectural concerns discovered across all artifacts. Draw from the following sources:]

- **Dependency gaps:** Circular dependencies, unpinned versions, missing shared libraries for duplicated patterns, modules with too many responsibilities (god modules).
- **Integration gaps:** External services without error handling, missing retry logic, no circuit breakers, missing health checks, unconfigured timeouts.
- **Data gaps:** Entities without relationships defined, missing constraints, orphan entities not referenced by any flow.
- **Flow gaps:** Multi-step handlers without error paths, async operations without timeout or cancellation handling, event handlers that could silently fail.
- **General observations:** Architectural patterns observed (or missing), technology choices, areas where the system is well-structured, areas that may need refactoring.

[Only describe what exists in the extracted artifacts. Do not fabricate concerns or patterns that are not supported by the data. If a section has no observations, say so explicitly rather than leaving it empty or guessing.]

---

*Generated by Unravel on [timestamp]*
```

## Core Principles

**Write prose, not just tables.** The System Overview, Internal Communication, Entity Relationships, and Gaps & Observations sections must be prose. Stakeholders need narrative explanation to understand the big picture. Tables are for structured reference; prose is for comprehension.

**Cross-reference relentlessly.** Every claim in the architecture document should be traceable to at least one extraction artifact. When describing a module's role, check dependency-map, process-flows, and integrations for corroborating evidence. When describing data flow, verify against both process-flows and data-specs.

**Flag risks, do not hide them.** Circular dependencies, god modules, missing error handling, tight coupling — these are the most valuable insights for stakeholders. Surface them prominently in the Dependency Analysis and Gaps & Observations sections.

**Only describe what exists.** Never fabricate architectural patterns, data flows, or integration points that are not present in the extraction artifacts. If the artifacts are thin in a certain area, note that coverage is limited rather than guessing.

**Use source references.** Include compact source references in the format `file:line` to allow stakeholders to trace claims back to the extraction modules. References point to extraction output files (e.g., `dependency-map/orders.md`), not to source code directly — the extraction files themselves contain source code references.

**Scale prose to available data.** If an extraction type has rich, detailed output, write correspondingly detailed prose. If an extraction type has sparse output, keep the prose proportionally brief. Do not inflate thin data with filler.

**Stop on missing prerequisites.** The prerequisite check is non-negotiable. If any extraction is missing, print the missing types with instructions on how to produce them, then stop. Do not attempt partial synthesis.

## Edge Cases

- **Empty extraction directories:** If a `00-INDEX.md` exists but lists zero module files, treat that extraction as present but empty. Note in the Gaps & Observations section that the extraction produced no artifacts for that type.
- **Single-module projects:** If dependency-map shows only one module, the Component Map will have one entry. Internal Communication should note that the system is monolithic with no inter-module communication. Dependency Analysis will show no coupling.
- **No external services:** If integrations found no external services, the External Services table should state "No external service integrations detected." Do not omit the section.
- **No process flows:** If process-flows found no flows, the Data Flow section should state "No process flows were extracted." Do not omit the section.
- **Conflicting information:** If two extraction types describe the same module differently, report both perspectives and note the discrepancy in Gaps & Observations rather than choosing one.
