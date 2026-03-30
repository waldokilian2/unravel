---
name: extract-user-stories
description: This skill provides domain knowledge for extracting user stories from code. It should be used when the agent is tasked with mapping API endpoints to user actions, documenting controller capabilities, deriving "As a [role], I can [action]" stories from route handlers, or cataloging CLI commands. Make sure to use this skill whenever user-facing capabilities, API surface area, or system entry points need to be documented, regardless of framework.
user-invocable: false
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

### [Role Group]
[1-2 sentence summary of what this role can do in this module.]

| Story | Endpoint | Implementation | Auth | Source |
|-------|----------|----------------|------|--------|
| As a [role], I can [action] | [METHOD] [path] | [function name] | [auth requirements] | `filename.ts:23` |
| As a [role], I can [action] | [METHOD] [path] | [function name] | [auth requirements] | `filename.ts:45` |

### [Another Role Group]
[1-2 sentence context.]

| Story | Endpoint | Implementation | Auth | Source |
|-------|----------|----------------|------|--------|
| ... | ... | ... | ... | ... |

## Sources
| Ref | Full Path |
|-----|-----------|
| `src/controllers/auth.ts:23` | [src/controllers/auth.ts:23](src/controllers/auth.ts#L23) |
| `src/controllers/auth.ts:45` | [src/controllers/auth.ts:45](src/controllers/auth.ts#L45) |
```

When a module has only one role, a single table without sub-headings is acceptable. Include a brief prose intro before the table.

**Example (single role):**
```markdown
# auth Module

Extraction: [YYYY-MM-DD]
Files Analyzed: [N] files

## Artifacts

Authentication endpoints for user identity management.

| Story | Endpoint | Implementation | Auth | Source |
|-------|----------|----------------|------|--------|
| As a user, I can register with email/password | POST /api/auth/register | register() | None (public) | `src/controllers/auth.ts:23` |
| As a user, I can view my profile | GET /api/auth/profile | getProfile() | JWT required | `src/controllers/auth.ts:45` |
| As a user, I can update my profile | PUT /api/auth/profile | updateProfile() | JWT required | `src/controllers/auth.ts:60` |

## Sources
| Ref | Full Path |
|-----|-----------|
| `src/controllers/auth.ts:23` | [src/controllers/auth.ts:23](src/controllers/auth.ts#L23) |
| `src/controllers/auth.ts:45` | [src/controllers/auth.ts:45](src/controllers/auth.ts#L45) |
| `src/controllers/auth.ts:60` | [src/controllers/auth.ts:60](src/controllers/auth.ts#L60) |
```

**Example (multiple roles):**
```markdown
# admin Module

Extraction: [YYYY-MM-DD]
Files Analyzed: [N] files

## Artifacts

### User
Standard users can manage their own resources within the admin area.

| Story | Endpoint | Implementation | Auth | Source |
|-------|----------|----------------|------|--------|
| As a user, I can view my profile | GET /api/admin/me | getMyProfile() | JWT required | `src/admin/users.ts:12` |
| As a user, I can update my settings | PUT /api/admin/me | updateMySettings() | JWT required | `src/admin/users.ts:25` |

### Admin
Admins have elevated access to manage all users and system configuration.

| Story | Endpoint | Implementation | Auth | Source |
|-------|----------|----------------|------|--------|
| As an admin, I can view all users | GET /api/admin/users | findAll() | JWT + Admin role required | `src/admin/users.ts:40` |
| As an admin, I can delete a user | DELETE /api/admin/users/:id | remove() | JWT + Admin role required | `src/admin/users.ts:55` |
| As an admin, I can update system settings | PUT /api/admin/settings | updateSettings() | JWT + Admin role required | `src/admin/settings.ts:10` |

## Sources
| Ref | Full Path |
|-----|-----------|
| `src/admin/users.ts:12` | [src/admin/users.ts:12](src/admin/users.ts#L12) |
| `src/admin/users.ts:25` | [src/admin/users.ts:25](src/admin/users.ts#L25) |
| `src/admin/users.ts:40` | [src/admin/users.ts:40](src/admin/users.ts#L40) |
| `src/admin/users.ts:55` | [src/admin/users.ts:55](src/admin/users.ts#L55) |
| `src/admin/settings.ts:10` | [src/admin/settings.ts:10](src/admin/settings.ts#L10) |
```

## Core Principles

**Read the handler, not just the route.** A route path like `POST /users` tells you very little. Read the handler function body to understand what the endpoint actually does — that's where the real user story lives. `POST /users` could mean "create a user" or "invite a user" or "import users."

**Derive the role from code, not guesses.** If the handler checks `req.user.role === 'admin'`, the role is "admin." If there's no role check, the role is "user" (or "authenticated user" if auth is required). Don't invent roles.

**Include auth requirements.** Whether an endpoint requires authentication, and what role/permission it needs, is essential context for the story. A user story without auth context is incomplete.

**Group by role.** Organize stories into `###` headings by role when a module has multiple roles. Use "User", "Admin", "System", or whatever roles the code defines. If a module has only one role, a single table is fine.

**Use brief prose for context.** A 1-2 sentence summary before each role group or table helps stakeholders quickly understand what capabilities that role has in this module.

**Flag gaps.** If a controller has routes but some handlers appear to be stubs or have minimal implementation, note: `MISSING: [handler] appears to be unimplemented or a stub`. If there's a clear user action that has no corresponding endpoint (e.g., no password change endpoint despite a password field), note: `MISSING: No endpoint for [expected action]`.
