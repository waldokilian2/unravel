---
name: extract-integrations
description: Use when analyzing code for external service integrations or API calls. Automatically triggers on: HTTP requests, fetch/axios calls, environment variables for endpoints, API key usage.
---

# Extracting Integrations

## Overview
Document external service integrations and API dependencies to understand what third-party services the system relies on, how it communicates with them, and what credentials are required.

## When to Use
Use when analyzing code for external service integrations or API calls. Triggers on:
- HTTP requests (fetch, axios, http module)
- API client libraries
- Environment variables for endpoints
- API key usage
- Webhook endpoints
- Message queue connections
- Database connections (external databases)

## Always Use Orchestration

This skill **always** orchestrates subagent execution. Even for single-file extractions, a fresh subagent is dispatched.

**Why?**
- Fresh context per extraction (no pollution)
- Consistent review process (two-stage: spec → quality)
- Parallelizable by design
- Matches Superpowers' subagent-driven-development pattern

**How it works:**
1. You (orchestrator) analyze scope and identify files
2. Dispatch one or more integrations-extractor-subagent tasks
3. For each completed task: run spec compliance review → quality review
4. Aggregate results into docs/output/integrations.md

## Core Principle
**Dependency-first: Identify external system dependencies**

## Checklist

1. **Hotspot Discovery** - Find HTTP calls and env vars
2. **Extract** - Document external services
3. **Document** - Write to docs/output/integrations.md
4. **Verify** - Confirm all integrations captured

## Hotspot Discovery

```bash
# Find HTTP calls
grep -r "fetch\|axios\|http\.\|request" --include="*.ts" --include="*.js" -l | head -20

# Find env usage
grep -r "process\.env\|import\.meta\.env" --include="*.ts" --include="*.js" -l | head -20

# Find API clients
grep -r "client\|Client\|sdk\|SDK" --include="*.ts" --include="*.js" -l | head -20

# Find webhook/message queue
grep -r "webhook\|queue\|pubsub\|kafka\|sqs" --include="*.ts" --include="*.js" -l | head -20
```

Exclude generated code:
```bash
--exclude-dir=node_modules --exclude-dir=dist --exclude-dir=build --exclude-dir=.next
```

## Pattern Signals

| Pattern | Example | Integration |
|---------|---------|-------------|
| HTTP call | `axios.post('https://api.stripe.com')` | Stripe API |
| Env var | `process.env.SENDGRID_API_KEY` | SendGrid (API key) |
| SDK import | `import { S3Client } from '@aws-sdk'` | AWS S3 |
| Webhook handler | `app.post('/webhook/stripe')` | Stripe webhook receiver |
| Queue publish | `await queue.publish('order-created')` | Message queue |

## Output Format

```markdown
## Integrations

Extraction: 2025-03-17

### Payment Gateway
| Detail | Value | Source |
|--------|-------|--------|
| Provider | Stripe | src/payment/stripe.ts:1 |
| Endpoint | https://api.stripe.com | env: STRIPE_API_URL |
| Auth Method | API Key | env: STRIPE_API_KEY |
| SDK | stripe@14.0.0 | package.json |
| Webhook | POST /webhook/stripe | src/webhooks/stripe.ts:12 |

### Email Service
| Detail | Value | Source |
|--------|-------|--------|
| Provider | SendGrid | src/email/sendgrid.ts:1 |
| Endpoint | https://api.sendgrid.com | env: SENDGRID_URL |
| Auth Method | API Key | env: SENDGRID_API_KEY |

### Cloud Storage
| Detail | Value | Source |
|--------|-------|--------|
| Provider | AWS S3 | src/storage/s3.ts:1 |
| Region | us-east-1 | env: AWS_REGION |
| Auth Method | IAM credentials | env: AWS_ACCESS_KEY_ID |
```

## Token Efficiency
- Only read files that match hotspot patterns
- Extract integration summaries, not full implementations
- Group related endpoints together
- If 50+ integrations found, suggest analyzing by module
- Document environment variable dependencies

## Edge Cases
- **No patterns found**: "No integrations detected. Check: are you in the right directory?"
- **Too many patterns**: "Large codebase detected. Analyzing module-by-module..."
- **Dynamic endpoints**: Extract with note "[DYNAMIC: Endpoint determined at runtime]"
- **Multiple environments**: Document all environment variables used
- **Conditional integrations**: Note "[CONDITIONAL: Used only when...]"
- **Internal APIs**: Mark as "[INTERNAL: Calls internal microservice]"
- **Deprecated integrations**: Flag as "DEPRECATED: Still using X, should migrate to Y"

## Red Flags

**Never:**
- Infer API endpoints without reading actual calls
- Assume authentication methods without verification
- Document integrations without source locations
- Skip environment variable documentation
- Ignore error handling for external calls

**Always:**
- Read actual HTTP/client implementation code
- Document all required environment variables
- Include source locations
- Note authentication methods explicitly
- Document webhook receivers if present
- Include error handling patterns for each integration
- Flag missing error handling if absent

## Task Dispatching

**Single file:**
```
Task("Extract integrations from stripe.ts")

Subagent receives:
- File: stripe.ts
- Artifact type: integrations
- Output: docs/output/integrations.md
```

**Multiple files (parallel):**
```
Task("Extract integrations from payment services")
Task("Extract integrations from email services")
Task("Extract integrations from storage services")

All three run concurrently
```

## Two-Stage Review (Required)

After each subagent completes:

**Stage 1: Spec Compliance Review**
```
Task("Review spec compliance for integrations extraction")
- All integrations in scope extracted?
- No artifacts outside scope?
- Output format followed?
```

**Stage 2: Quality Review** (only after Stage 1 passes)
```
Task("Review quality for integrations extraction")
- Each integration matches actual code?
- No hallucinations?
- Clear, well-documented?
```

## Integration

**Required subagents:**
- unravel:integrations-extractor-subagent - Focused extraction
- unravel:spec-compliance-reviewer - Stage 1 review
- unravel:quality-reviewer - Stage 2 review

**For large tasks (10+ integrations, 5+ files):**
- Use unravel:orchestrating-extractions for full orchestration
- Use unravel:dispatching-parallel-extractors for parallel execution
- Use unravel:planning-extractions to create task plans
