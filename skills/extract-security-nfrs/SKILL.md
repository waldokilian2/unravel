---
name: extract-security-nfrs
description: This skill provides domain knowledge for extracting security measures, non-functional requirements, and access control models from code. It should be used when the agent is tasked with documenting authentication, authorization, role-permission mappings, middleware, rate limiting, logging infrastructure, caching, error handling, access control matrices, public vs. protected endpoints, or performance-related code patterns. Make sure to use this skill whenever protective measures, authorization models, infrastructure concerns, or reliability patterns need to be audited or documented.
user-invocable: false
---

# Security, NFRs & Access Control Extraction

Security measures, non-functional requirements, and access control capture how the system protects data, ensures reliability, and controls who can do what — the "how does the system stay secure, performant, and properly gated?" They document safeguards and authorization models that stakeholders and auditors need to verify.

## What to Extract

### Security Measures & NFRs
- **Authentication** — JWT, OAuth, session management, password hashing
- **Middleware layers** — Express middleware, interceptors, guards, filters
- **Rate limiting** — Throttle decorators, rate-limiter middleware, API quotas
- **Logging infrastructure** — Winston, Bunyan, Pino, structured logging, audit logs
- **Error handling** — Global exception handlers, error filters, circuit breakers
- **Performance and caching** — Redis, `@Cacheable`, CDN, APM, metrics collection
- **Input sanitization** — XSS prevention, CSRF tokens, SQL injection prevention
- **Retry mechanisms** — Exponential backoff, circuit breakers, dead letter queues

### Access Control Model
- **Route-level guards** — `@UseGuards()`, `@RolesAllowed()`, `@PreAuthorize()`, middleware that checks roles/permissions
- **Role definitions** — Enum or constant definitions of roles (`ADMIN`, `USER`, `MODERATOR`)
- **Permission definitions** — Named permissions (`canEdit`, `canDelete`, `canManageUsers`) and their assignment to roles
- **Resource-level checks** — Ownership verification (`if (user.id !== resource.userId)`), field-level access control
- **Public vs. protected endpoints** — Which endpoints require authentication and which are open
- **Permission hierarchies** — Role inheritance (ADMIN inherits all USER permissions), permission composition

## Where Security/NFRs & Access Control Live (vs. Other Types)

- **Security/NFR vs. business rule:** `if (!user.isActive) throw new ForbiddenError()` is a *security measure* (authorization check). `if (order.total < 50) throw new MinOrderError()` is a *business rule* (business constraint). The difference is *why* the check exists — to protect access or to enforce a business constraint.
- **Security/NFR vs. integration:** `axios.post('https://api.stripe.com')` is an *integration*. The `try-catch` wrapping that call, and any retry logic, are *NFRs* (error handling and reliability).
- **Security/NFR vs. user story:** `@UseGuards(JwtGuard)` on a route is a *security measure*. The route itself is a *user story* (what the user can do). Document auth requirements in both places — as a detail of the story and here as a security artifact.
- **Access control vs. user story:** A route definition (`DELETE /users/:id`) is a *user story*. The fact that only admins can access it is *access control* — documented here as part of the authorization model.

## Hotspot Discovery

Use the Glob and Grep tools to find security, NFR, and access control definitions:

```
Glob:  **/middleware/**/*.{ts,js,py,go,java}
Glob:  **/guards/**/*.{ts,js,py}
Glob:  **/interceptors/**/*.{ts,js}
Glob:  **/filters/**/*.{ts,js,py,java}
Glob:  **/policies/**/*.{ts,js,py}
Glob:  **/permissions/**/*.{ts,js,py}
Grep:  pattern="middleware|@UseGuards|@RolesAllowed|@PreAuthorize|@Secured|@RequirePermissions" type=ts,js,py,java output_mode=files_with_matches
Grep:  pattern="logger|console\.|winston|pino|bunyan" type=ts,js,py output_mode=files_with_matches
Grep:  pattern="rate.*limit|throttle|limiter|quota" type=ts,js,py,go output_mode=files_with_matches
Grep:  pattern="catch|error.*handler|exception|@Catch" type=ts,js,py,java output_mode=files_with_matches
Grep:  pattern="cache|redis|@Cacheable|ttl" type=ts,js,py,go output_mode=files_with_matches
Grep:  pattern="enum.*Role|ADMIN|USER|MODERATOR|SUPER_ADMIN" type=ts,js,py,go,java output_mode=files_with_matches
Grep:  pattern="isPublic|@Public|permitAll|allowAnonymous|isAuthenticated" type=ts,js,java,py output_mode=files_with_matches
Grep:  pattern="user\.id.*===|owner|isOwner|belongsTo" type=ts,js,py output_mode=files_with_matches
```

**Prioritize:** Start with middleware, guard, interceptor, and policy directories. Then check role/permission definitions and route handler decorators.

## Pattern Signals

| Code Pattern | Security/NFR | Category |
|--------------|-------------|----------|
| `@UseGuards(JwtGuard)` | JWT authentication required | Authentication |
| `@RolesAllowed('admin')` | Role-based access control | Access Control |
| `@Throttle(10, 60)` | Max 10 requests per minute | Rate Limiting |
| `logger.info(request)` | Request/activity logging | Logging |
| `bcrypt.hash(password, 10)` | Password hashing (salt rounds: 10) | Authentication |
| `helmet()` or `csurf()` | Security headers / CSRF protection | Input Sanitization |
| `if (user.id !== resource.ownerId) throw 403` | Resource-level ownership check | Access Control |
| `enum Role { ADMIN, USER, MODERATOR }` | Role definitions | Access Control |
| `@Public()` or `isPublic: true` | No authentication required | Access Control |
| `try { ... } catch (e) { logger.error(e) }` | Error handling with logging | Error Handling |

## Output Format

**Per-module extractor output:**
```markdown
# [Module Name] Module

Extraction: [YYYY-MM-DD]
Files Analyzed: [N] files

## Artifacts

### [Category]
| Requirement | Implementation | Source |
|-------------|----------------|--------|
| [What's required] | [How it's implemented] | `filename.ts:42` |
```

**Required categories:** Include Authentication, Rate Limiting, Logging, Error Handling, and Access Control for every module. Include additional categories (Performance, Input Sanitization, Retry) only when the module has relevant findings.

**The Access Control section uses a specialized format:**
```markdown
### Access Control

#### Role Definitions
| Role | Description | Source |
|------|-------------|--------|
| [role name] | [what this role represents] | `filename.ts:5` |

#### Access Matrix
| Endpoint | Method | Roles | Auth | Source |
|----------|--------|-------|------|--------|
| [path] | [GET/POST/etc] | [allowed roles or "public"] | [required/none] | `filename.ts:42` |

#### Resource-Level Controls
| Resource | Check | Logic | Source |
|----------|-------|-------|--------|
| [resource type] | [what's verified] | [how it's checked] | `filename.ts:20` |
```

**Example:**
```markdown
## auth Module

### Authentication
| Requirement | Implementation | Source |
|-------------|----------------|--------|
| JWT required | @UseGuards(JwtGuard) | `src/auth/auth.controller.ts:5` |
| Password hashing | bcrypt, salt rounds: 10 | `src/auth/service.ts:23` |

### Access Control

#### Role Definitions
| Role | Description | Source |
|------|-------------|--------|
| SUPER_ADMIN | Full system access, manages other admins | `src/auth/roles.enum.ts:2` |
| ADMIN | Manages users and content | `src/auth/roles.enum.ts:3` |
| USER | Standard user access | `src/auth/roles.enum.ts:5` |

#### Access Matrix
| Endpoint | Method | Roles | Auth | Source |
|----------|--------|-------|------|--------|
| /api/auth/login | POST | public | none | `src/auth/auth.controller.ts:10` |
| /api/users | GET | ADMIN, SUPER_ADMIN | JWT | `src/admin/users.controller.ts:15` |
| /api/users/:id | DELETE | SUPER_ADMIN | JWT | `src/admin/users.controller.ts:30` |
| /api/posts | GET | public | none | `src/posts/posts.controller.ts:8` |
| /api/posts | POST | USER, ADMIN | JWT | `src/posts/posts.controller.ts:20` |

#### Resource-Level Controls
| Resource | Check | Logic | Source |
|----------|-------|-------|--------|
| Post | Ownership | User can only edit their own posts (unless ADMIN) | `src/posts/posts.controller.ts:36` |

### Logging
| Requirement | Implementation | Source |
|-----------|----------------|--------|
| Request logging | Winston logger | `src/middleware/logger.ts:12` |
| Error tracking | Sentry integration | `src/errors/handler.ts:45` |

## Sources
| Ref | Full Path |
|-----|-----------|
| `src/auth/auth.controller.ts:5` | [src/auth/auth.controller.ts:5](src/auth/auth.controller.ts#L5) |
| `src/auth/service.ts:23` | [src/auth/service.ts:23](src/auth/service.ts#L23) |
| `src/auth/roles.enum.ts:2` | [src/auth/roles.enum.ts:2](src/auth/roles.enum.ts#L2) |
| `src/auth/roles.enum.ts:3` | [src/auth/roles.enum.ts:3](src/auth/roles.enum.ts#L3) |
| `src/auth/roles.enum.ts:5` | [src/auth/roles.enum.ts:5](src/auth/roles.enum.ts#L5) |
| `src/admin/users.controller.ts:15` | [src/admin/users.controller.ts:15](src/admin/users.controller.ts#L15) |
| `src/posts/posts.controller.ts:8` | [src/posts/posts.controller.ts:8](src/posts/posts.controller.ts#L8) |
| `src/posts/posts.controller.ts:20` | [src/posts/posts.controller.ts:20](src/posts/posts.controller.ts#L20) |
| `src/posts/posts.controller.ts:36` | [src/posts/posts.controller.ts:36](src/posts/posts.controller.ts#L36) |
| `src/middleware/logger.ts:12` | [src/middleware/logger.ts:12](src/middleware/logger.ts#L12) |
| `src/errors/handler.ts:45` | [src/errors/handler.ts:45](src/errors/handler.ts#L45) |
```

## Core Principles

**Document what exists and flag what doesn't.** If the code has rate limiting, document it. If public endpoints lack rate limiting, note it as `MISSING: No rate limiting on public endpoints`. This evaluative approach is unique to this skill — stakeholders need to know gaps.

**Capture implementation details.** For security measures, the implementation matters as much as the requirement. "Password hashing" is vague; "bcrypt with 10 salt rounds" is actionable. Include library names, configuration values, and algorithm details.

**Group by concern.** Organize findings into logical categories: Authentication, Access Control, Rate Limiting, Logging, Error Handling, Performance. This makes the output scannable for auditors.

**Build a complete access matrix.** The most valuable access control output is a table showing every endpoint and who can access it. This is what security auditors need and what analysts reference when designing new features.

**Note public endpoints explicitly.** Endpoints with no auth are not "missing access control" — they're intentionally public (login, registration, health checks). Document them as "public" rather than flagging them as missing.

**Distinguish role-based from resource-based access.** RBAC ("only admins can access this route") is different from ownership checks ("users can edit their own posts"). Keep these separate — route-level in the matrix, imperative in resource-level controls.

**Document role inheritance.** If the code uses role hierarchies (e.g., ADMIN inherits all USER permissions), document that explicitly. A matrix that lists every role for every endpoint is less useful than one that shows the hierarchy.
