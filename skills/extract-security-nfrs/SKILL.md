---
name: extract-security-nfrs
description: This skill provides domain knowledge for extracting security measures and non-functional requirements from code. It should be used when the agent is tasked with documenting authentication, authorization, middleware, rate limiting, logging infrastructure, caching, error handling, or performance-related code patterns. Make sure to use this skill whenever protective measures, infrastructure concerns, or reliability patterns need to be audited or documented.
---

# Security & NFRs Extraction

Security measures and non-functional requirements capture how the system protects data and ensures reliability — the "how does the system stay secure and performant?" They document safeguards that stakeholders and auditors need to verify.

## What to Extract

Security measures and NFRs protect data and ensure reliability:

- **Authentication and authorization** — JWT, OAuth, session management, RBAC, ABAC
- **Middleware layers** — Express middleware, interceptors, guards, filters
- **Rate limiting** — Throttle decorators, rate-limiter middleware, API quotas
- **Logging infrastructure** — Winston, Bunyan, Pino, structured logging, audit logs
- **Error handling** — Global exception handlers, error filters, circuit breakers
- **Performance and caching** — Redis, `@Cacheable`, CDN, APM, metrics collection
- **Input sanitization** — XSS prevention, CSRF tokens, SQL injection prevention
- **Retry mechanisms** — Exponential backoff, circuit breakers, dead letter queues

## Where Security/NFRs Live (vs. Other Types)

- **Security/NFR vs. business rule:** `if (!user.isActive) throw new ForbiddenError()` is a *security measure* (authorization check). `if (order.total < 50) throw new MinOrderError()` is a *business rule* (business constraint). The difference is *why* the check exists — to protect access or to enforce a business constraint.
- **Security/NFR vs. integration:** `axios.post('https://api.stripe.com')` is an *integration*. The `try-catch` wrapping that call, and any retry logic, are *NFRs* (error handling and reliability).
- **Security/NFR vs. user story:** `@UseGuards(JwtGuard)` on a route is a *security measure*. The route itself is a *user story* (what the user can do). Document auth requirements in both places — as a detail of the story and as a security artifact.

## Hotspot Discovery

Use the Glob and Grep tools to find files with security and NFR measures:

```
Glob:  **/middleware/**/*.{ts,js,py,go,java}
Glob:  **/guards/**/*.{ts,js,py}
Glob:  **/interceptors/**/*.{ts,js}
Glob:  **/filters/**/*.{ts,js,py,java}
Grep:  pattern="middleware|@UseGuards|@RolesAllowed|authorize" type=ts,js,py,java output_mode=files_with_matches
Grep:  pattern="logger|console\.|winston|pino|bunyan" type=ts,js,py output_mode=files_with_matches
Grep:  pattern="rate.*limit|throttle|limiter|quota" type=ts,js,py,go output_mode=files_with_matches
Grep:  pattern="catch|error.*handler|exception|@Catch" type=ts,js,py,java output_mode=files_with_matches
Grep:  pattern="cache|redis|@Cacheable|ttl" type=ts,js,py,go output_mode=files_with_matches
```

**Prioritize:** Start with middleware, guard, and interceptor directories. Then check configuration files for security settings.

## Pattern Signals

| Code Pattern | Security/NFR |
|--------------|--------------|
| `@UseGuards(JwtGuard)` | JWT authentication required |
| `@RolesAllowed('admin')` | Role-based access control |
| `@Throttle(10, 60)` | Max 10 requests per minute |
| `logger.info(request)` | Request/activity logging |
| `bcrypt.hash(password, 10)` | Password hashing (salt rounds: 10) |
| `helmet()` or `csurf()` | Security headers / CSRF protection |
| `app.use(rateLimit(...))` | Global rate limiting middleware |
| `try { ... } catch (e) { logger.error(e) }` | Error handling with logging |

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
| [What's required] | [How it's implemented] | [filename.ts:42](path/to/filename.ts#L42) |
```

**Example:**
```markdown
## auth Module

### Authentication
| Requirement | Implementation | Source |
|-------------|----------------|--------|
| JWT required | @UseGuards(JwtGuard) | [src/auth/auth.controller.ts:5](src/auth/auth.controller.ts#L5) |
| Role-based access | @RolesAllowed('admin') | [src/admin/controller.ts:8](src/admin/controller.ts#L8) |
| Password hashing | bcrypt, salt rounds: 10 | [src/auth/service.ts:23](src/auth/service.ts#L23) |

### Logging
| Requirement | Implementation | Source |
|-----------|----------------|--------|
| Request logging | Winston logger | [src/middleware/logger.ts:12](src/middleware/logger.ts#L12) |
| Error tracking | Sentry integration | [src/errors/handler.ts:45](src/errors/handler.ts#L45) |
```

## Core Principles

**Document what exists and flag what doesn't.** If the code has rate limiting, document it. If public endpoints lack rate limiting, note it as `MISSING: No rate limiting on public endpoints`. This evaluative approach is unique to this skill — stakeholders need to know gaps.

**Capture implementation details.** For security measures, the implementation matters as much as the requirement. "Password hashing" is vague; "bcrypt with 10 salt rounds" is actionable. Include library names, configuration values, and algorithm details.

**Group by concern.** Organize findings into logical categories: Authentication, Authorization, Logging, Error Handling, Performance. This makes the output scannable for auditors.
