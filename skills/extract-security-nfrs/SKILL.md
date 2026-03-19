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

## Always Use Orchestration

This skill **always** orchestrates subagent execution. Even for single-file extractions, a fresh subagent is dispatched.

**Why?**
- Fresh context per extraction (no pollution)
- Consistent review process (two-stage: spec → quality)
- Parallelizable by design
- Matches Superpowers' subagent-driven-development pattern

**How it works:**
1. You (orchestrator) analyze scope and identify files
2. Dispatch one or more security-nfrs-extractor-subagent tasks
3. For each completed task: run spec compliance review → quality review
4. Aggregate results into docs/output/security-nfrs.md

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

## Task Dispatching

**Single file:**
```
Task("Extract security/NFRs from auth.middleware.ts")

Subagent receives:
- File: auth.middleware.ts
- Artifact type: security-nfrs
- Output: docs/output/security-nfrs.md
```

**Multiple files (parallel):**
```
Task("Extract security/NFRs from auth middleware")
Task("Extract security/NFRs from logging infrastructure")
Task("Extract security/NFRs from rate limiting")

All three run concurrently
```

## Two-Stage Review (Required)

After each subagent completes:

**Stage 1: Spec Compliance Review**
```
Task("Review spec compliance for security/NFRs extraction")
- All measures in scope extracted?
- No artifacts outside scope?
- Output format followed?
```

**Stage 2: Quality Review** (only after Stage 1 passes)
```
Task("Review quality for security/NFRs extraction")
- Each measure matches actual code?
- No hallucinations?
- Clear, well-documented?
```

## Integration

**Required subagents:**
- unravel:security-nfrs-extractor-subagent - Focused extraction
- unravel:spec-compliance-reviewer - Stage 1 review
- unravel:quality-reviewer - Stage 2 review

**For large tasks (10+ measures, 5+ files):**
- Use unravel:orchestrating-extractions for full orchestration
- Use unravel:dispatching-parallel-extractors for parallel execution
- Use unravel:planning-extractions to create task plans
