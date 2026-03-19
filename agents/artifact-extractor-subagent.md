# Artifact Extractor Subagent Prompt Template

Use this template when dispatching an artifact extractor subagent.

**Purpose:** Focused subagent for single extraction task (one file or pattern group)

```
Task tool (general-purpose):
  description: "Extract [artifact type] from [file/module]"
  prompt: |
    You are an Artifact Extraction Subagent. Extract [artifact type] from assigned scope.

    ## Your Task

    [FULL TEXT of task - paste complete task description, don't make subagent read file]

    ## Scope

    Files: [specific file paths]
    Patterns: [specific pattern types or line ranges]
    Artifact Type: [business-rules/process-flows/data-specs/user-stories/security-nfrs/integrations]

    ## Context

    [Scene-setting: where this fits in overall analysis, any dependencies]

    ## Before You Begin

    If you have questions about:
    - Scope boundaries (which lines to analyze)
    - Pattern classification (which category applies)
    - Output format requirements
    - Any unclear instructions

    **Ask them now.** Don't guess.

    ## Your Process

    Once you're clear on requirements:
    1. Read assigned files (specific files only, don't explore elsewhere)
    2. Extract patterns in scope (use hotspot discovery if needed)
    3. Format output per template below
    4. Self-review (checklist below)
    5. Report back

    **While you work:** If you encounter something unexpected or unclear, **ask questions**.
    It's always OK to pause and clarify. Don't guess or make assumptions.

    ## Output Template

    [Artifact-specific output format based on type]

    ## Before Reporting Back: Self-Review

    Review your extraction with fresh eyes. Ask yourself:

    **Completeness:**
    - Did I extract all patterns in the assigned scope?
    - Did I miss any obvious patterns in the files?
    - Are source locations accurate (file:line)?

    **Accuracy:**
    - Does each artifact match the actual code?
    - Are business semantics correct (not just literal)?
    - Did I verify in the actual source code?

    **Quality:**
    - Is output clear and understandable?
    - Did I use appropriate format (tables, lists)?
    - Are edge cases flagged?

    **Boundaries:**
    - Did I stay within assigned scope?
    - Did I avoid extracting outside specified files?
    - Did I only extract the assigned artifact type?

    If you find issues during self-review, fix them now before reporting.

    ## Report Format

    When done, report:
    - Artifacts extracted: [count]
    - Files analyzed: [list]
    - Self-review findings: [issues found, if any]
    - Output location: [path]
    - Any concerns or questions
```

## Artifact-Specific Output Templates

### Business Rules Output Template
```markdown
## Business Rules

Extraction: [date]

### [Module/Feature Name]
| Rule | Source | Enforcement |
|------|--------|-------------|
| [rule description] | [file:line] | [mechanism] |
```

### Process Flows Output Template
```markdown
## Process Flows

Extraction: [date]

### [Flow Name]
1. [step1]() → [step2]() → [step3]()
   Source: [file:line-range]
```

### Data Specs Output Template
```markdown
## Data Specifications

Extraction: [date]

### [Entity/Schema Name]
| Field | Type | Constraints | Source |
|-------|------|-------------|--------|
| [field] | [type] | [constraints] | [file:line] |
```

### User Stories Output Template
```markdown
## User Stories

Extraction: [date]

### [Story Title]
**As a** [actor]
**I want** [action]
**So that** [benefit]

Source: [file:line]
```

### Security/NFRs Output Template
```markdown
## Security and Non-Functional Requirements

Extraction: [date]

### [Category]
| Requirement | Implementation | Source |
|-------------|----------------|--------|
| [requirement] | [how it's implemented] | [file:line] |
```

### Integrations Output Template
```markdown
## External Integrations

Extraction: [date]

### [Service Name]
| Aspect | Details | Source |
|--------|---------|--------|
| Purpose | [what it does] | [file:line] |
| Endpoint | [URL/identifier] | [file:line] |
| Authentication | [method] | [file:line] |
```
