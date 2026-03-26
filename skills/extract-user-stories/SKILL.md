---
name: extract-user-stories
description: Domain knowledge for extracting user stories - controllers, routes, endpoints, event handlers
---

# User Stories Extraction

Domain knowledge for extracting user stories from code.

## What to Extract

User stories describe what users can do with the system:

- **Controller definitions** - @Controller, @RestController classes
- **Route handlers** - @Get, @Post, @Put, @Delete decorators
- **Router definitions** - router.get(), app.post() patterns
- **Event handlers** - on(), addEventListener(), subscribe()
- **CLI commands** - command(), yargs, commander patterns
- **API endpoints** - REST, GraphQL endpoints

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

## Pattern Signals

| Code Pattern | User Story |
|--------------|------------|
| `@Post('register')` | As a user, I can register |
| `@Get('profile')` | As a user, I can view my profile |
| `@Delete('account/:id')` | As a user, I can delete my account |
| `on('click', submit)` | As a user, I can submit forms |
| `command('build')` | As a developer, I can build the project |
| `@SubscribeMessage('chat')` | As a user, I can send chat messages |

## Output Format

**Per-module extractor output:**
```markdown
# [Module Name] Module

Extraction: [YYYY-MM-DD]
Files Analyzed: [N] files

## Artifacts

- As a [role], I can [action]
  Source: [METHOD] [path] ([filename.ts:23](path/to/filename.ts#L23))
  Implementation: [function name]

- As a [role], I can [action]
  Source: [METHOD] [path] ([filename.ts:15](path/to/filename.ts#L15))
  Implementation: [function name]
```

Each module file is standalone. The orchestrator creates an 00-INDEX.md that links to all module files.

**Example:**
```markdown
## auth Module

- As a user, I can register with email/password
  Source: POST /api/auth/register ([src/controllers/auth.ts:23](src/controllers/auth.ts#L23))
  Implementation: register() function

- As an admin, I can view all users
  Source: GET /api/admin/users ([src/admin/users.ts:12](src/admin/users.ts#L12))
  Implementation: findAll() with @RolesAllowed('admin')
```

## Core Principles

**Intent-first:** Derive user goals from implementation endpoints

**Include roles:** Specify who can perform the action (user, admin, system, etc.)

**Read implementations:** Don't infer from route names alone - read the handler code

**Note permissions:** Include auth/role requirements if present
