---
name: extract-security-nfrs
description: Use when analyzing code for security measures or non-functional requirements. Automatically triggers on: middleware layers, auth decorators, rate limiting, logging, error handling.
---

# Extracting Security & NFRs

## Overview
Document security measures, logging, monitoring, and non-functional requirements to understand how the system protects data, handles failures, and meets operational requirements.

## When to Use
Use when analyzing code for security measures or non-functional requirements. Triggers on:
- Middleware layers
- Authentication/authorization decorators
- Rate limiting implementations
- Logging infrastructure
- Error handling
- Performance monitoring
- Caching layers
- Retry mechanisms

## Core Principle
**Protection-first: Identify safeguards and operational requirements**

## Checklist

1. **Hotspot Discovery** - Find middleware/auth files
2. **Extract** - Document security measures and NFRs
3. **Document** - Write to docs/output/security-nfrs.md
4. **Verify** - Confirm all measures captured

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

Exclude generated code:
```bash
--exclude-dir=node_modules --exclude-dir=dist --exclude-dir=build --exclude-dir=.next
```

## Pattern Signals

| Pattern | Example | Security/NFR |
|---------|---------|--------------|
| Auth guard | `@UseGuards(JwtGuard)` | JWT authentication required |
| Role check | `@RolesAllowed('admin')` | Role-based access control |
| Rate limiter | `@Throttle(10, 60)` | Max 10 requests per minute |
| Logger | `logger.info()` | Request/activity logging |
| Try-catch | `try { ... } catch (e)` | Error handling |
| Cache decorator | `@Cacheable('users')` | Performance caching |

## Output Format

```markdown
## Security & Non-Functional Requirements

Extraction: 2025-03-17

### Authentication
| Requirement | Implementation | Source |
|-------------|----------------|--------|
| JWT required | @UseGuards(JwtGuard) | src/auth/auth.controller.ts:5 |
| Role-based access | @RolesAllowed('admin') | src/admin/controller.ts:8 |
| Password hashing | bcrypt, salt rounds: 10 | src/auth/service.ts:23 |

### Logging
| Component | Implementation | Source |
|-----------|----------------|--------|
| Request logging | Winston logger | src/middleware/logger.ts:12 |
| Error tracking | Sentry integration | src/errors/handler.ts:45 |

### Performance
| Requirement | Implementation | Source |
|-------------|----------------|--------|
| Rate limiting | 10 req/min per IP | src/middleware/rate-limit.ts:8 |
| Response caching | Redis, TTL 300s | src/cache/cache.ts:15 |
```

## Token Efficiency
- Only read files that match hotspot patterns
- Document implementations concisely
- Group related measures together
- If 50+ measures found, suggest analyzing by module
- Focus on observable requirements, not implementation details

## Edge Cases
- **No patterns found**: "No security/NFRs detected. Check: are you in the right directory?"
- **Too many patterns**: "Large codebase detected. Analyzing module-by-module..."
- **Conditional measures**: Note "[CONDITIONAL: Applied only when...]"
- **Third-party security**: Document provider and configuration
- **Environment-specific**: Note "[DEV/PROD: Different in each environment]"
- **Deprecated measures**: Flag as "DEPRECATED: Still using X, should migrate to Y"
- **Missing measures**: Flag as "MISSING: No rate limiting on public endpoints"

## Red Flags

**Never:**
- Infer security measures without reading implementations
- Assume authentication exists without verification
- Document "should have" requirements (only extract what exists)
- Skip error handling mechanisms
- Ignore environment-specific configurations

**Always:**
- Read actual security implementation code
- Document what's actually implemented (not what should be)
- Include source locations
- Note environment differences if present
- Flag missing security measures explicitly
- Document both positive (what exists) and negative (what's missing)

## Integration
- For complex files (10+ measures), dispatch agents/artifact-extractor.md
- Use business-analyst:verification-agent to verify output
