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

1. **Identify** - Recognize code pattern matches a category
2. **Invoke** - Use matching skill
3. **Extract** - Skill guides discovery and extraction
4. **Output** - Artifacts saved to `docs/output/`
5. **Verify** - Optional verification agent review

## Key Principles

- **Hotspot-first** - Find relevant files before reading
- **Token-efficient** - Only read files with patterns
- **Accurate** - Source locations with every artifact
- **No hallucinations** - Only extract what exists

## Available Skills

- unravel:extract-business-rules
- unravel:extract-process-flows
- unravel:extract-data-specs
- unravel:extract-user-stories
- unravel:extract-security-nfrs
- unravel:extract-integrations

## Available Agents

Agents are autonomous specialists that perform complex multi-step tasks:

- **unravel:verification-agent**
  - Reviews extracted artifacts for accuracy and completeness
  - Cross-checks that all patterns were captured
  - Validates source locations and documentation

- **unravel:artifact-extractor** (via agents/artifact-extractor.md)
  - Deep extraction for complex files with 10+ patterns
  - Handles large-scale analysis tasks
  - Produces comprehensive output documentation

Dispatch agents when:
- Files contain 10+ patterns of the same type
- Analysis requires multi-step coordination
- Verification of extracted artifacts is needed
