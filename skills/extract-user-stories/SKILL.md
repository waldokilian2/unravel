---
name: extract-user-stories
description: Use when analyzing code for user-facing features or requirements. Automatically triggers on: controller definitions, route handlers, event handlers, CLI commands.
---

# Extracting User Stories

## Overview
Derive user stories from controllers, routes, and event handlers by understanding what user actions the system enables and what outcomes it delivers.

## When to Use
Use when analyzing code for user-facing features or requirements. Triggers on:
- Controller definitions
- Route handlers (@Get, @Post, router.get, etc.)
- Event handlers
- CLI commands
- API endpoints
- UI event handlers

## Always Use Orchestration

This skill **always** orchestrates subagent execution. Even for single-file extractions, a fresh subagent is dispatched.

**Why?**
- Fresh context per extraction (no pollution)
- Consistent review process (two-stage: spec → quality)
- Parallelizable by design
- Matches Superpowers' subagent-driven-development pattern

**How it works:**
1. You (orchestrator) analyze scope and identify files
2. Dispatch one or more user-stories-extractor-subagent tasks
3. For each completed task: run spec compliance review → quality review
4. Aggregate results into docs/output/user-stories.md

## Core Principle
**Intent-first: Derive user goals from implementation endpoints**

## Checklist

1. **Hotspot Discovery** - Find route/controller files
2. **Derive** - Extract user intent from endpoints
3. **Document** - Write to docs/output/user-stories.md
4. **Verify** - Confirm stories make sense

## Hotspot Discovery

```bash
# Find route definitions
grep -r "@Get\|@Post\|@Put\|@Delete\|router\." --include="*.ts" --include="*.js" -l | head -20

# Find controllers
grep -r "Controller" --include="*.ts" -l | head -20

# Find event handlers
grep -r "on\|addEventListener\|handle" --include="*.ts" --include="*.js" -l | head -20

# Find CLI commands
grep -r "command\|cli\|yargs\|commander" --include="*.ts" -l | head -20
```

Exclude generated code:
```bash
--exclude-dir=node_modules --exclude-dir=dist --exclude-dir=build --exclude-dir=.next
```

## Pattern Signals

| Pattern | Example | User Story |
|---------|---------|------------|
| POST endpoint | `@Post('register')` | As a user, I can register |
| GET endpoint | `@Get('profile')` | As a user, I can view my profile |
| Event handler | `on('click', submit)` | As a user, I can submit forms |
| CLI command | `command('build')` | As a developer, I can build the project |
| WebSocket | `@SubscribeMessage('chat')` | As a user, I can send chat messages |

## Output Format

```markdown
## User Stories

Extraction: 2025-03-17

### Authentication
- As a user, I can register with email/password
  Source: POST /api/auth/register (src/controllers/auth.ts:23)
  Implementation: register() function

- As a user, I can log in and receive a JWT
  Source: POST /api/auth/login (src/controllers/auth.ts:45)
  Implementation: login() function

### User Management
- As an admin, I can view all users
  Source: GET /api/admin/users (src/admin/users.ts:12)
  Implementation: findAll() function with @RolesAllowed('admin')
```

## Token Efficiency
- Only read files that match hotspot patterns
- Derive user intent from route names and parameters
- Group related stories by feature/module
- If 50+ stories found, suggest analyzing by module
- Use standard "As a [role], I can [action]" format

## Edge Cases
- **No patterns found**: "No user stories detected. Check: are you in the right directory?"
- **Too many patterns**: "Large codebase detected. Analyzing module-by-module..."
- **Internal endpoints**: Mark as "[INTERNAL: Not user-facing]"
- **Ambiguous intent**: Extract with note "[CONFIRM: Does this mean...?]"
- **Multiple roles**: Document all applicable roles
- **Admin-only features**: Clearly mark role requirements
- **Batch operations**: Note "[BATCH: Processes multiple items]"

## Red Flags

**Never:**
- Infer user stories without reading route implementations
- Assume user roles from route names alone
- Document features that don't have user-facing endpoints
- Skip authentication/authorization requirements
- Create stories without source verification

**Always:**
- Read route/controller implementations to understand behavior
- Include the user role (user, admin, system, etc.)
- Document what the user achieves (outcome, not just action)
- Include source locations (file:line)
- Note permission/role requirements
- Verify the endpoint is actually user-facing

## Task Dispatching

**Single file:**
```
Task("Extract user stories from auth.controller.ts")

Subagent receives:
- File: auth.controller.ts
- Artifact type: user-stories
- Output: docs/output/user-stories.md
```

**Multiple files (parallel):**
```
Task("Extract user stories from auth controllers")
Task("Extract user stories from payment controllers")
Task("Extract user stories from user controllers")

All three run concurrently
```

## Two-Stage Review (Required)

After each subagent completes:

**Stage 1: Spec Compliance Review**
```
Task("Review spec compliance for user stories extraction")
- All stories in scope extracted?
- No artifacts outside scope?
- Output format followed?
```

**Stage 2: Quality Review** (only after Stage 1 passes)
```
Task("Review quality for user stories extraction")
- Each story matches actual code?
- No hallucinations?
- Clear, well-documented?
```

## Integration

**Required subagents:**
- unravel:user-stories-extractor-subagent - Focused extraction
- unravel:spec-compliance-reviewer - Stage 1 review
- unravel:quality-reviewer - Stage 2 review

**For large tasks (10+ stories, 5+ files):**
- Use unravel:orchestrating-extractions for full orchestration
- Use unravel:dispatching-parallel-extractors for parallel execution
- Use unravel:planning-extractions to create task plans
