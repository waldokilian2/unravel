---
name: extract-integrations
description: This skill provides domain knowledge for extracting external service integrations from code. It should be used when the agent is tasked with identifying HTTP calls, API client usage, environment variables for external services, webhook receivers, message queues, or any external system dependencies. Make sure to use this skill whenever a system's external dependencies, API surface area consumed, or third-party service connections need to be documented, including database connections and cloud services.
---

# Integrations Extraction

Integrations capture the external services and systems that the codebase depends on — the "what does this system talk to outside itself?" They document the dependency graph that operations teams need to manage.

## What to Extract

Integrations are external services and APIs the system depends on:

- **HTTP requests** — `fetch()`, `axios`, `http`, `requests`, `urllib`, `HttpClient`
- **API client libraries** — AWS SDK, Stripe SDK, SendGrid, Twilio, Firebase
- **Environment variables for external services** — API keys, endpoints, connection strings
- **Webhook receivers** — POST routes that accept callbacks from external services
- **Message queues** — SQS, Kafka, RabbitMQ, Redis pub/sub, SNS
- **Database connections** — PostgreSQL, MongoDB, MySQL, Redis (external, not embedded)
- **Cloud services** — S3, CloudFront, Lambda invocations, storage buckets

## Where Integrations Live (vs. Other Types)

- **Integration vs. user story:** `POST /webhook/stripe` is a *user story* (the system accepts webhooks). The *fact that it connects to Stripe* is an *integration*. Document the endpoint in user-stories; document the Stripe dependency here.
- **Integration vs. security/NFR:** `axios.post('https://api.stripe.com')` is an *integration*. The `try-catch` wrapping that call is an *NFR* (error handling). The `process.env.STRIPE_API_KEY` is an *integration* (credential).
- **Integration vs. data spec:** A Prisma schema defining a `User` model is a *data spec*. The `DATABASE_URL` connecting to PostgreSQL is an *integration*.

## Hotspot Discovery

Use the Glob and Grep tools to find files with external integrations:

```
Grep:  pattern="fetch\(|axios|http\.\w+|requests\." type=ts,js,py,go output_mode=files_with_matches
Grep:  pattern="process\.env|import\.meta\.env|os\.getenv" type=ts,js,py,go output_mode=files_with_matches
Grep:  pattern="client|Client|sdk|SDK" type=ts,js,py,go output_mode=files_with_matches
Grep:  pattern="webhook|queue|pubsub|kafka|sqs|sns" type=ts,js,py,go output_mode=files_with_matches
Grep:  pattern="mongoose\.connect|createPool|\.connect\(|sql\.open" type=ts,js,py,go output_mode=files_with_matches
Grep:  pattern="s3\.|cloudfront|@aws-sdk|boto3" type=ts,js,py output_mode=files_with_matches
```

**Prioritize:** Start with configuration files (`.env`, `config.*`), service/client modules, and webhook handlers. These contain the most concentrated integration information.

## Pattern Signals

| Code Pattern | Integration |
|--------------|-------------|
| `axios.post('https://api.stripe.com')` | Stripe API (HTTP) |
| `process.env.SENDGRID_API_KEY` | SendGrid (API key) |
| `import { S3Client } from '@aws-sdk'` | AWS S3 (SDK client) |
| `app.post('/webhook/stripe')` | Stripe webhook receiver |
| `channel.basic_publish(exchange='orders')` | RabbitMQ (message queue) |
| `process.env.DATABASE_URL` | Database connection string |
| `requests.post(url, json=data)` (Python) | HTTP API call |
| `boto3.client('s3')` (Python) | AWS S3 (SDK client) |

## Output Format

**Per-module extractor output:**
```markdown
# [Module Name] Module

Extraction: [YYYY-MM-DD]
Files Analyzed: [N] files

## Artifacts

### [Service Name]
| Detail | Value | Source |
|--------|-------|--------|
| Provider | [Service name] | [filename.ts:42](path/to/filename.ts#L42) |
| Purpose | [What it's used for] | [context] |
| Endpoint | [URL or identifier] | env: VAR_NAME |
| Auth Method | [API Key/OAuth/etc] | env: VAR_NAME |
```

**Example:**
```markdown
## payment Module

### Stripe
| Detail | Value | Source |
|--------|-------|--------|
| Provider | Stripe | [src/payment/stripe.ts:1](src/payment/stripe.ts#L1) |
| Purpose | Payment processing | — |
| Endpoint | https://api.stripe.com | env: STRIPE_API_URL |
| Auth Method | API Key | env: STRIPE_API_KEY |
| SDK | stripe@14.0.0 | [package.json](package.json) |
| Webhook | POST /webhook/stripe | [src/webhooks/stripe.ts:12](src/webhooks/stripe.ts#L12) |

### Database
| Detail | Value | Source |
|--------|-------|--------|
| Provider | PostgreSQL | — |
| Purpose | Primary data store | — |
| Connection | env: DATABASE_URL | env: DATABASE_URL |
| ORM | Prisma | [prisma/schema.prisma](prisma/schema.prisma) |
```

## Core Principles

**Document the dependency, not the implementation.** The purpose is to answer "what external systems does this project depend on?" — not to document every function that makes an API call. Group by service provider, not by file.

**Capture all required env vars.** Every environment variable that points to an external service (API keys, URLs, connection strings) should be listed. Operations teams need this to configure deployments.

**Note the auth method.** How the system authenticates with the external service (API key, OAuth, mutual TLS, IAM role) is critical for security audits and rotation planning.

**Distinguish providers from consumers.** A `POST /webhook/stripe` route is a *consumer* (receives from Stripe). `axios.post('https://api.stripe.com/charges')` is a *provider call* (sends to Stripe). Both are integrations, but the relationship direction matters.
