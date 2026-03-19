---
name: using-unravel
description: Use when starting any code analysis task - establishes how to find and use Unravel skills
---

# Using Unravel Skills

You have Unravel superpowers. These skills automatically extract business artifacts from code, helping you understand what a system does by reading what it's built from.

## What Unravel Does

Automatically extracts and documents:
- **Business Rules** - Conditional logic, validation, exceptions
- **Process Flows** - Function stacks, state machines, workflows
- **Data Specs** - Schemas, ORMs, DTOs, validation annotations
- **User Stories** - Controller/route definitions imply user intent
- **Security/NFRs** - Middleware, auth, logging
- **Integrations** - HTTP calls, env vars, API keys

## How It Works

## Rule
**Before any code analysis task, check if an Unravel skill applies.**

If there's even a 1% chance a skill might apply, you MUST use it.

## When Skills Trigger

| Pattern | Triggers Skill |
|---------|----------------|
| If/else, guard clauses, validation | extract-business-rules |
| Function call chains, state machines | extract-process-flows |
| Schemas, ORM classes, DTOs | extract-data-specs |
| Controllers, routes, event handlers | extract-user-stories |
| Middleware, auth decorators, logging | extract-security-nfrs |
| HTTP requests, fetch/axios, env vars | extract-integrations |

## Workflow

Unravel **always** uses orchestration with subagent execution.

**How it works:**
1. **Identify** - Recognize code pattern matches a category
2. **Invoke** - Use matching extraction skill
3. **Orchestrate** - Skill dispatches subagent(s) for extraction
4. **Review** - Two-stage review (spec compliance → quality)
5. **Output** - Artifacts saved to `docs/output/`

**Example:**
```
You: What are the business rules in payment.ts?
Claude: [invokes extract-business-rules skill]
       [dispatches business-rules-extractor-subagent for payment.ts]
       [runs spec compliance review]
       [runs quality review]
       [aggregates results into docs/output/business-rules.md]
```

**Key principle:** Every extraction uses fresh subagent(s) with two-stage review, ensuring consistency and quality.

## Key Principles

- **Hotspot-first** - Find relevant files before reading
- **Token-efficient** - Only read files with patterns
- **Accurate** - Source locations with every artifact
- **No hallucinations** - Only extract what exists

## Available Skills

### Extraction Skills (Always Orchestrate)
Each skill dispatches subagent(s) and runs two-stage review:

- **unravel:extract-business-rules** - Conditional logic, validation, exceptions
- **unravel:extract-process-flows** - Function call chains, state machines, workflows
- **unravel:extract-data-specs** - Schemas, ORM classes, DTOs
- **unravel:extract-user-stories** - Controllers, routes, event handlers
- **unravel:extract-security-nfrs** - Middleware, auth, logging, performance
- **unravel:extract-integrations** - HTTP calls, APIs, env vars

### Orchestration Support Skills
Used by extraction skills for complex scenarios:

- **unravel:orchestrating-extractions** - Master orchestration for complex multi-file extractions
- **unravel:dispatching-parallel-extractors** - Parallel dispatch for independent files
- **unravel:planning-extractions** - Task planning for large/unknown scopes
- **unravel:orchestrating-verification** - Two-stage verification coordination

## Available Agents

### Reviewer Agents
- **unravel:spec-compliance-reviewer**
  - Verifies extraction task completed as specified
  - Checks: all patterns extracted, nothing extra, boundaries respected
  - Stage 1 of two-stage verification

- **unravel:quality-reviewer**
  - Verifies extraction accuracy and quality
  - Checks: correct, no hallucinations, well-documented
  - Stage 2 of two-stage verification

- **unravel:verification-agent** (existing)
  - Reviews extracted artifacts for accuracy and completeness
  - Cross-checks that all patterns were captured
  - Validates source locations and documentation

### Extraction Subagents
Focused subagents for single extraction tasks (one file or pattern group):

- **unravel:business-rules-extractor-subagent** - Conditional logic, validation
- **unravel:process-flows-extractor-subagent** - Function call chains, state machines
- **unravel:data-specs-extractor-subagent** - Schemas, ORM classes, DTOs
- **unravel:user-stories-extractor-subagent** - Controllers, routes, event handlers
- **unravel:security-nfrs-extractor-subagent** - Middleware, auth, logging
- **unravel:integrations-extractor-subagent** - HTTP calls, APIs, env vars

- **unravel:artifact-extractor** (existing, via agents/artifact-extractor.md)
  - Deep extraction for complex files with 10+ patterns
  - Handles large-scale analysis tasks
  - Produces comprehensive output documentation

### When Agents Are Used

**Extraction Subagents:**
- Always dispatched by extraction skills
- Even single-file = single subagent
- Multiple files = parallel subagent dispatch
- Fresh context per extraction (no pollution)

**Reviewer Agents:**
- Always dispatched after extraction (two-stage review)
- Stage 1: spec-compliance-reviewer (completeness check)
- Stage 2: quality-reviewer (accuracy check)
- Required for every extraction
