---
name: extract-user-stories
description: This skill provides domain knowledge for extracting user stories from code. It should be used when the agent is tasked with mapping API endpoints to user actions, documenting controller capabilities, deriving "As a [role], I can [action]" stories from route handlers, or cataloging CLI commands. Make sure to use this skill whenever user-facing capabilities, API surface area, or system entry points need to be documented, regardless of framework.
---

# User Stories Extraction

User stories capture what users can do with the system — the "what capabilities does this system expose?" They bridge code and business language by translating route handlers and event listeners into actionable stories.

## What to Extract

User stories describe what users can do with the system:

- **Route handlers** — `@Get`, `@Post`, `@Put`, `@Delete`, `router.get()`, `app.route()`
- **Controller classes** — `@Controller`, `@RestController`, Flask blueprints, Spring controllers
- **Event handlers** — `on()`, `addEventListener()`, `subscribe()`, message queue consumers
- **CLI commands** — `command()`, yargs, commander, argparse, cobra
- **API endpoints** — REST, GraphQL resolvers, gRPC service methods
- **WebSocket handlers** — Socket.io, WS handlers, `@SubscribeMessage`

## Where User Stories Live (vs. Other Types)

- **User story vs. process flow:** A route definition (`POST /register`) is a *user story* — it describes what the user can do. The internal call chain *within* the handler is a *process flow*.
- **User story vs. security/NFR:** `@UseGuards(JwtGuard)` on a route is a *security measure*. The route itself (`POST /orders`) is a *user story*. Include the auth requirement as a detail of the story, not as a separate artifact here.

## Hotspot Discovery

Use the Glob and Grep tools to find files with user-facing endpoints:

```
Glob:  **/controllers/**/*.{ts,js,py,go,java}
Glob:  **/routes/**/*.{ts,js,py,go,java}
Glob:  **/handlers/**/*.{ts,js,py}
Grep:  pattern="@Get|@Post|@Put|@Delete|@Patch|router\.\w+\(" type=ts,js output_mode=files_with_matches
Grep:  pattern="app\.(get|post|put|delete)|@app\.route|@blueprint" type=ts,js,py output_mode=files_with_matches
Grep:  pattern="@Controller|@RestController|@RequestMapping" type=ts,java output_mode=files_with_matches
Grep:  pattern="addEventListener|\.on\(|\.subscribe\(" type=ts,js,py output_mode=files_with_matches
Grep:  pattern="command\(|\.command\(|cobra\.AddCommand" type=ts,js,py,go output_mode=files_with_matches
```

**Prioritize:** Start with controller/route/handler directories. These are the primary entry points for user actions.

## Pattern Signals

| Code Pattern | User Story |
|--------------|------------|
| `@Post('register')` | As a user, I can register |
| `app.get('/profile')` (Express) | As a user, I can view my profile |
| `@Delete('account/:id')` | As a user, I can delete my account |
| `@app.route('/search', methods=['GET'])` (Flask) | As a user, I can search |
| `@SubscribeMessage('chat')` (WS) | As a user, I can send chat messages |
| `cobra.Command{Use: "build"}` (Go) | As a developer, I can build the project |

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
  Auth: [authentication/authorization requirements, if any]
```

**Example:**
```markdown
## auth Module

- As a user, I can register with email/password
  Source: POST /api/auth/register ([src/controllers/auth.ts:23](src/controllers/auth.ts#L23))
  Implementation: register() function
  Auth: None (public endpoint)

- As a user, I can view my profile
  Source: GET /api/auth/profile ([src/controllers/auth.ts:45](src/controllers/auth.ts#L45))
  Implementation: getProfile() function
  Auth: JWT required

- As an admin, I can view all users
  Source: GET /api/admin/users ([src/admin/users.ts:12](src/admin/users.ts#L12))
  Implementation: findAll() function
  Auth: JWT + Admin role required
```

## Core Principles

**Read the handler, not just the route.** A route path like `POST /users` tells you very little. Read the handler function body to understand what the endpoint actually does — that's where the real user story lives. `POST /users` could mean "create a user" or "invite a user" or "import users."

**Derive the role from code, not guesses.** If the handler checks `req.user.role === 'admin'`, the role is "admin." If there's no role check, the role is "user" (or "authenticated user" if auth is required). Don't invent roles.

**Include auth requirements.** Whether an endpoint requires authentication, and what role/permission it needs, is essential context for the story. A user story without auth context is incomplete.

**Group by role when possible.** If most endpoints require one role and a few require another, consider grouping stories by role in the output for readability.
