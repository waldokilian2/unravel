---
name: synthesize-requirements
description: This skill synthesizes extracted business artifacts into a stakeholder-ready requirements document. It should be used when the agent is asked to generate a requirements document, create a requirements document, synthesize requirements, combine extracted requirements, merge extracted artifacts into a unified requirements spec, produce a stakeholder requirements doc from extraction outputs, or run /synthesize-requirements. Make sure to use this skill whenever a user wants to produce a consolidated requirements document from Unravel's extraction pipeline outputs (business-rules, user-stories, security-nfrs, process-flows).
---

# Requirements Document Synthesis

This skill combines previously extracted business artifacts into a single, stakeholder-ready requirements document. It reads the output of Unravel's extraction pipeline and merges business rules, user stories, security NFRs, and process flows into a coherent document organized by business domain rather than by artifact type.

## Prerequisites

The following extractions must exist, each with a `00-INDEX.md` in `docs/output/`:

| Extraction Type | Group |
|-----------------|-------|
| `business-rules` | Business Logic |
| `user-stories` | Business Logic |
| `security-nfrs` | Interfaces & Security |
| `process-flows` | Business Logic |

## Execution Steps

### Step 1: Prerequisite Check

Before any synthesis begins, verify all prerequisite extractions exist.

Use Glob to check for each `docs/output/[type]/00-INDEX.md`:

```
Glob: docs/output/business-rules/00-INDEX.md
Glob: docs/output/user-stories/00-INDEX.md
Glob: docs/output/security-nfrs/00-INDEX.md
Glob: docs/output/process-flows/00-INDEX.md
```

**If any are missing, stop immediately.** Print a message listing every missing extraction with the group to run it from:

```
Cannot generate requirements document. The following extractions are missing:

- business-rules — Run /unravel and select Business Logic
- security-nfrs — Run /unravel and select Interfaces & Security
```

Do not proceed to synthesis. Do not attempt partial synthesis. The user must run the missing extractions first.

**If all exist, proceed to Step 2.**

### Step 2: Read All Inputs

For each of the four prerequisite types:

1. Read `docs/output/[type]/00-INDEX.md` to get the list of module files.
2. Read every module file listed in the index.

**Efficiency rule for large extractions:** If a type has more than 5 module files:
- Read all `00-INDEX.md` files first to understand the full scope.
- Read every module file for `business-rules` and `user-stories` (these are the primary inputs for domain grouping and traceability).
- For `security-nfrs` and `process-flows` modules beyond the first 5, read the index, identify the most significant modules (those with the most artifacts, or covering security/auth/process topics most likely to intersect with business rules), and use Grep for specific references to modules mentioned in business-rules or user-stories.

### Step 3: Analyze and Cross-Reference

Before writing, analyze the collected artifacts to build a mental model of the system:

1. **Identify business domains.** Group business rules into logical domains (e.g., "Order Management", "User Authentication", "Inventory"). Use the existing domain area headings from business-rules modules as the primary grouping mechanism.

2. **Map user stories to domains.** For each user story, determine which business domain it belongs to based on module overlap and topic similarity.

3. **Classify NFRs.** Sort security-nfrs artifacts into categories:
   - Security Requirements (auth, authorization, input validation, rate limiting)
   - Reliability & Performance (caching, retry logic, error handling, logging infrastructure)
   - Error Handling & Logging (structured logging, error tracking, audit trails)

4. **Link process flows to domains.** For each process flow, identify which business rules and user stories it relates to.

5. **Build the traceability set.** Collect every requirement ID, source artifact, and module reference for the traceability matrix.

6. **Identify gaps.** Look for:
   - Business rules that have no corresponding user story
   - Security requirements that have no referenced business justification
   - Process flows that reference undefined business rules
   - User stories that lack corresponding business rules
   - Modules that appear in one artifact type but not others

### Step 4: Write the Requirements Document

Write to `docs/output/REQUIREMENTS.md`.

#### Document Structure

```markdown
# Requirements Document

**Generated:** [YYYY-MM-DD]
**Source Artifacts:** business-rules, user-stories, security-nfrs, process-flows

---

## Functional Requirements

### [Business Domain 1]
[1-2 sentence prose summary of what this domain covers and why it matters to the business.]

**User Capabilities:**
- [User story from user-stories related to this domain, written as "As a [role], I can [action]"]

**Business Rules:**
| ID | Rule | Impact | Enforcement | Source |
|----|------|--------|-------------|--------|
| FR-[nnn] | [rule text from business-rules] | [impact level from source] | [enforcement mechanism from source] | `source-ref` |

[Repeat for each business domain area discovered across business-rules modules]

---

## Non-Functional Requirements

### Security Requirements
| ID | Requirement | Implementation | Priority | Source |
|----|-------------|----------------|----------|--------|
| NFR-SEC-[nnn] | [requirement text from security-nfrs] | [implementation details] | [High/Medium/Low] | `source-ref` |

### Reliability & Performance
| ID | Requirement | Implementation | Priority | Source |
|----|-------------|----------------|----------|--------|
| NFR-REL-[nnn] | [requirement text] | [implementation details] | [High/Medium/Low] | `source-ref` |

### Error Handling & Logging
| ID | Requirement | Implementation | Priority | Source |
|----|-------------|----------------|----------|--------|
| NFR-ERR-[nnn] | [requirement text] | [implementation details] | [High/Medium/Low] | `source-ref` |

Only include NFR sub-sections that have at least one requirement. Do not include empty sections.

---

## Process Context

### [Flow Name]
[1-2 sentence summary of what the flow accomplishes.]
- Modules involved: [comma-separated list of modules this flow touches]
- Key decisions: [list of decision points from the flow]
- Related rules: [FR-IDs that this flow enforces or references]
- Related user stories: [story names from user-stories that this flow supports]

[Repeat for each process flow found in process-flows modules]

---

## Traceability Matrix

| Requirement ID | Type | Source Artifact | Module |
|----------------|------|-----------------|--------|
| FR-001 | Business Rule | business-rules/[module].md | [module] |
| NFR-SEC-001 | Security Requirement | security-nfrs/[module].md | [module] |

Every requirement listed in the Functional and Non-Functional sections must appear in this matrix.

---

## Gaps & Observations

[List observations about missing connections between artifact types. Each observation should be a single sentence explaining what is missing or potentially incomplete.]

Examples of gaps to look for:
- "Business rule FR-012 has no corresponding user story — consider whether a user capability is missing."
- "Process flow 'Password Reset' references rule FR-008 but no such rule was found in the extracted artifacts."
- "Module 'payments' appears in user-stories but has no business rules extracted."
- "No security requirements were extracted for the 'admin' module, which has elevated permissions."
- "The 'checkout' user story references payment processing, but no process flow was extracted for payment."

---

*Generated by Unravel on [YYYY-MM-DD HH:MM]*
```

#### ID Numbering

- **FR-[nnn]:** Sequential numbering for all functional (business rule) requirements across all domains. Start at 001.
- **NFR-SEC-[nnn]:** Sequential numbering for security non-functional requirements. Start at 001.
- **NFR-REL-[nnn]:** Sequential numbering for reliability and performance NFRs. Start at 001.
- **NFR-ERR-[nnn]:** Sequential numbering for error handling and logging NFRs. Start at 001.

#### Source References

Use the format `[artifact-type]/[module-filename].md` for traceability. For example:
- `business-rules/orders.md`
- `security-nfrs/auth.md`
- `user-stories/payments.md`
- `process-flows/checkout.md`

#### Priority Assignment

For NFRs, assign priority based on the content:
- **High:** Auth, authorization, data protection, critical error handling
- **Medium:** Logging, caching, rate limiting, retry mechanisms
- **Low:** Cosmetic logging, nice-to-have performance optimizations

If the source artifact provides an impact level (Critical/High/Medium/Low), map it: Critical and High map to High priority, Medium maps to Medium, Low maps to Low.

## Core Principles

**Only include what exists in the artifacts.** Never fabricate requirements. If the extraction outputs do not mention a requirement, it does not go in the document. The Gaps & Observations section is where missing items are noted, not in the requirements tables.

**Every requirement must reference its source.** Each row in every table must have a valid `source-ref` pointing to the extraction file it came from. A requirement without a source reference is invalid.

**Merge by domain, not by artifact type.** Organize functional requirements by business domain (e.g., "Order Management", "User Authentication"), not by listing all business rules in one section and all user stories in another. Stakeholders think in terms of domains, not artifact types.

**Write for business stakeholders.** Use plain language. Avoid implementation details in rule descriptions unless the implementation is itself the requirement (common in NFRs). A business stakeholder should be able to read the Functional Requirements section and understand what the system does without seeing code.

**Cross-reference relentlessly.** Process flows should reference the FR-IDs they enforce. User stories should appear alongside the rules they relate to. The traceability matrix must be complete — every requirement ID in the document should have a row.

**Identify gaps proactively.** The Gaps & Observations section is one of the most valuable outputs. Look for:
- Rules without stories (might indicate missing capabilities)
- Stories without rules (might indicate missing validation)
- Flows referencing undefined rules
- Modules with uneven artifact coverage
- Security requirements for public endpoints with no rate limiting

**Use the source artifact's domain groupings.** When business-rules modules organize rules into `###` domain area headings (e.g., "Order Validation", "Payment Constraints"), preserve those groupings as the basis for the Functional Requirements sections. Do not invent new domain boundaries unless the source artifacts span modules that clearly belong together.

**Preserve impact assessments from source.** When business-rules artifacts include an Impact column (Critical/High/Medium/Low), carry that value into the requirements document. Do not re-assess unless the source is ambiguous.

**Handle empty artifact types gracefully.** If a prerequisite extraction exists but contains zero relevant modules or artifacts, note it in the Gaps section rather than producing empty tables. An extraction that found nothing is itself useful information.

**De-duplicate across modules.** If the same business rule appears in multiple modules (e.g., a validation rule referenced in both an orders module and a shared validation module), include it once in the most relevant domain and note the additional source in the traceability matrix.
