---
name: extract-integrations
description: Domain knowledge for extracting external service integrations - HTTP calls, APIs, env vars
---

# Integrations Extraction

Domain knowledge for extracting external service dependencies from code.

## What to Extract

Integrations are external services and APIs the system depends on:

- **HTTP requests** - fetch(), axios, http module, request libraries
- **API client libraries** - SDK clients (AWS SDK, Stripe SDK, etc.)
- **Environment variables** - process.env, import.meta.env for endpoints/keys
- **API key usage** - API keys, tokens, credentials
- **Webhook endpoints** - POST routes receiving webhooks
- **Message queues** - SQS, Kafka, RabbitMQ, pub/sub
- **Database connections** - External databases (not local SQLite)

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

## Pattern Signals

| Code Pattern | Integration |
|--------------|-------------|
| `axios.post('https://api.stripe.com')` | Stripe API |
| `process.env.SENDGRID_API_KEY` | SendGrid (API key) |
| `import { S3Client } from '@aws-sdk'` | AWS S3 |
| `app.post('/webhook/stripe')` | Stripe webhook receiver |
| `await queue.publish('order-created')` | Message queue |
| `process.env.DATABASE_URL` | Database connection |

## Output Format

**Per-module extractor output:**
```markdown
# [Module Name] Module

Extraction: [YYYY-MM-DD]
Files Analyzed: [N] files

## Artifacts

| Detail | Value | Source |
|--------|-------|--------|
| Provider | [Service name] | [filename.ts:42](path/to/filename.ts#L42) |
| Endpoint | [URL/identifier] | [env: VAR_NAME] |
| Auth Method | [API Key/OAuth/etc] | [env: VAR_NAME] |
```

Each module file is standalone. The orchestrator creates an 00-INDEX.md that links to all module files.

**Example:**
```markdown
## payment Module

### Payment Gateway
| Detail | Value | Source |
|--------|-------|--------|
| Provider | Stripe | [src/payment/stripe.ts:1](src/payment/stripe.ts#L1) |
| Endpoint | https://api.stripe.com | env: STRIPE_API_URL |
| Auth Method | API Key | env: STRIPE_API_KEY |
| SDK | stripe@14.0.0 | [package.json](package.json) |
| Webhook | POST /webhook/stripe | [src/webhooks/stripe.ts:12](src/webhooks/stripe.ts#L12) |
```

## Core Principles

**Dependency-first:** Identify external system dependencies

**Document env vars:** List all required environment variables

**Note auth methods:** Explicitly document authentication

**Include webhooks:** Document webhook receivers if present

**Flag missing error handling:** Note if external calls lack try-catch
