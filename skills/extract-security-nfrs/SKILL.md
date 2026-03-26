---
name: extract-security-nfrs
description: Domain knowledge for extracting security measures and non-functional requirements
---

# Security & NFRs Extraction

Domain knowledge for extracting security and non-functional requirements from code.

## What to Extract

Security measures and NFRs protect data and ensure reliability:

- **Middleware layers** - Express middleware, interceptors, guards
- **Authentication/authorization** - @UseGuards, @RolesAllowed, JWT decorators
- **Rate limiting** - @Throttle, rate-limiter, throttle middleware
- **Logging infrastructure** - Winston, Bunyan, console.log patterns
- **Error handling** - try-catch, error handlers, exception filters
- **Performance monitoring** - APM, metrics, timers
- **Caching layers** - Redis, @Cacheable, cache decorators
- **Retry mechanisms** - Retry logic, circuit breakers

## Hotspot Discovery

```bash
# Find middleware
grep -r "middleware\|@UseGuards\|@RolesAllowed" --include="*.ts" -l | head -20

# Find logging
grep -r "logger\|console\.\|log\|winston" --include="*.ts" --include="*.js" -l | head -20

# Find rate limiting
grep -r "rate.*limit\|throttle\|limiter" --include="*.ts" --include="*.js" -l | head -20

# Find error handling
grep -r "catch\|error.*handler\|exception" --include="*.ts" --include="*.js" -l | head -20

# Find caching
grep -r "cache\|redis\|@Cacheable" --include="*.ts" --include="*.js" -l | head -20
```

## Pattern Signals

| Code Pattern | Security/NFR |
|--------------|--------------|
| `@UseGuards(JwtGuard)` | JWT authentication required |
| `@RolesAllowed('admin')` | Role-based access control |
| `@Throttle(10, 60)` | Max 10 requests per minute |
| `logger.info()` | Request/activity logging |
| `try { ... } catch (e)` | Error handling |
| `@Cacheable('users')` | Performance caching |
| `bcrypt.hash(password, 10)` | Password hashing (salt rounds: 10) |

## Output Format

**Per-module extractor output:**
```markdown
# [Module Name] Module

Extraction: [YYYY-MM-DD]
Files Analyzed: [N] files

## Artifacts

| Requirement | Implementation | Source |
|-------------|----------------|--------|
| [What's required] | [How it's implemented] | [filename.ts:42](path/to/filename.ts#L42) |
```

Each module file is standalone. The orchestrator creates an 00-INDEX.md that links to all module files.

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
| Component | Implementation | Source |
|-----------|----------------|--------|
| Request logging | Winston logger | [src/middleware/logger.ts:12](src/middleware/logger.ts#L12) |
| Error tracking | Sentry integration | [src/errors/handler.ts:45](src/errors/handler.ts#L45) |
```

## Core Principles

**Protection-first:** Identify safeguards and operational requirements

**Document what exists:** Only extract what's actually implemented

**Note environment differences:** Flag if dev/prod differ

**Flag missing measures:** Note "MISSING: No rate limiting on public endpoints"
