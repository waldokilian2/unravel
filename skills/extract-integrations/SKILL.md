---
name: extract-integrations
description: This skill provides domain knowledge for extracting external service integrations, configuration, and notifications from code. It should be used when the agent is tasked with identifying HTTP calls, API client usage, environment variables, configuration files, feature flags, webhook receivers, message queues, notification dispatchers (email/SMS/push), outgoing webhooks, or any external system dependencies and operational settings. Make sure to use this skill whenever a system's external dependencies, configuration requirements, notification systems, or third-party service connections need to be documented, including database connections, cloud services, and deployment settings.
user-invocable: false
---

# Integrations, Configuration & Notifications Extraction

This skill captures external services, operational configuration, and notification systems — the "what does this system talk to, what does it need to run, and who does it notify?" It documents the dependency graph and deployment requirements that operations teams need to manage.

## What to Extract

### External Integrations
- **HTTP requests** — `fetch()`, `axios`, `http`, `requests`, `urllib`, `HttpClient`
- **API client libraries** — AWS SDK, Stripe SDK, SendGrid, Twilio, Firebase
- **Environment variables for external services** — API keys, endpoints, connection strings
- **Webhook receivers** — POST routes that accept callbacks from external services
- **Message queues** — SQS, Kafka, RabbitMQ, Redis pub/sub, SNS
- **Database connections** — PostgreSQL, MongoDB, MySQL, Redis (external, not embedded)
- **Cloud services** — S3, CloudFront, Lambda invocations, storage buckets

### Configuration & Environment
- **Environment variables** — All `process.env`, `os.getenv`, `import.meta.env`, `System.getenv` references
- **Configuration files** — `.env`, `.env.example`, `config.yaml`, `config.json`, `appsettings.json`
- **Default values** — Fallback values when env vars are unset (`process.env.PORT || 3000`)
- **Required vs. optional** — Which variables have defaults (optional) and which don't (required)
- **Feature flags** — LaunchDarkly, Unleash, custom flag systems, conditional behavior based on config
- **Multi-environment configuration** — Environment-specific settings (dev/staging/prod), config overlays
- **Secrets existence** — API keys, database URLs, JWT secrets (note that they exist, not their values)

### Notifications & Outgoing Webhooks
- **Notification dispatchers** — Email sending, SMS dispatch, push notification triggers
- **Notification templates** — Email templates, SMS templates, push message formats
- **Outgoing webhooks** — Webhook dispatching to notify external systems

## Where Integrations Live (vs. Other Types)

- **Integration vs. user story:** `POST /webhook/stripe` is a *user story* (the system accepts webhooks). The *fact that it connects to Stripe* is an *integration*. Document the endpoint in user-stories; document the Stripe dependency here.
- **Integration vs. security/NFR:** `axios.post('https://api.stripe.com')` is an *integration*. The `try-catch` wrapping that call is an *NFR* (error handling). The `process.env.STRIPE_API_KEY` is an *integration* (credential).
- **Integration vs. data spec:** A Prisma schema defining a `User` model is a *data spec*. The `DATABASE_URL` connecting to PostgreSQL is an *integration*.
- **Integration vs. domain vocabulary:** Error code definitions (`ErrorCode.INVALID_EMAIL`) belong in the *domain-vocabulary* skill. External service error handling goes here.
- **Config vs. security/NFR:** JWT secret configuration (`JWT_SECRET`) is a *config* item (required to run). The *use of that secret for token signing* is a *security/NFR*.
- **Notification vs. process flow:** An event handler that reacts to `UserCreated` and sends a welcome email — the *email sending* is a *notification*. The *event that triggers it* is a *domain event* (documented in process-flows).

## Hotspot Discovery

Use the Glob and Grep tools to find files with external integrations, configuration, and notifications:

```
Grep:  pattern="fetch\(|axios|http\.\w+|requests\." type=ts,js,py,go output_mode=files_with_matches
Grep:  pattern="process\.env|import\.meta\.env|os\.getenv" type=ts,js,py,go output_mode=files_with_matches
Grep:  pattern="client|Client|sdk|SDK" type=ts,js,py,go output_mode=files_with_matches
Grep:  pattern="webhook|queue|pubsub|kafka|sqs|sns" type=ts,js,py,go output_mode=files_with_matches
Grep:  pattern="mongoose\.connect|createPool|\.connect\(|sql\.open" type=ts,js,py,go output_mode=files_with_matches
Grep:  pattern="s3\.|cloudfront|@aws-sdk|boto3" type=ts,js,py output_mode=files_with_matches
Glob:  **/.env*
Glob:  **/config*.{ts,js,py,json,yaml,yml,toml}
Glob:  **/appsettings*.{json,yaml,yml}
Glob:  **/application*.{yml,yaml,properties}
Grep:  pattern="\|\||\?\?|defaultValue|getOrDefault|default:" type=ts,js,py,java output_mode=files_with_matches
Grep:  pattern="feature.*flag|featureFlag|isEnabled|launchdarkly|unleash|getConfig" type=ts,js,py,go output_mode=files_with_matches
Glob:  **/notifications/**/*.{ts,js,py}
Glob:  **/emails/**/*.{ts,js,py,hbs,html}
Glob:  **/templates/**/*.{ts,js,hbs,html}
Grep:  pattern="sendEmail|sendSMS|sendPush|notify|mail\.send|twilio" type=ts,js,py,go output_mode=files_with_matches
Grep:  pattern="webhook\.send|webhook\.dispatch|postMessage" type=ts,js,py output_mode=files_with_matches
```

**Prioritize:** Start with `.env`, `.env.example`, and config files at the project root. Then search source code for env var references, service/client modules, notification/email templates, and webhook handlers.

## Pattern Signals

| Code Pattern | What to Extract |
|--------------|-----------------|
| `axios.post('https://api.stripe.com')` | Stripe API (HTTP integration) |
| `process.env.SENDGRID_API_KEY` | SendGrid (API key integration) |
| `import { S3Client } from '@aws-sdk'` | AWS S3 (SDK client integration) |
| `app.post('/webhook/stripe')` | Stripe webhook receiver |
| `channel.basic_publish(exchange='orders')` | RabbitMQ (message queue) |
| `process.env.DATABASE_URL` | Database connection string |
| `process.env.PORT \|\| 3000` | Optional env var: PORT (default: 3000) |
| `featureFlags.newCheckout.isEnabled()` | Feature flag: newCheckout |
| `sendEmail({ to: user.email, template: 'welcome' })` | Email notification: welcome template |
| `webhookService.dispatch('order.updated', payload)` | Outgoing webhook: order.updated |

## Output Format

**Per-module extractor output:**
```markdown
# [Module Name] Module

Extraction: [YYYY-MM-DD]
Files Analyzed: [N] files

## Artifacts

### Integrations

#### [Service Name]
| Detail | Value | Source |
|--------|-------|--------|
| Provider | [Service name] | `filename.ts:42` |
| Purpose | [What it's used for] | context |
| Endpoint | [URL or identifier] | env: VAR_NAME |
| Auth Method | [API Key/OAuth/etc] | env: VAR_NAME |

### Configuration

#### Environment Variables
| Variable | Required | Default | Description | Source |
|----------|----------|---------|-------------|--------|
| [VAR_NAME] | [yes/no] | [default or "none"] | [what it configures] | `filename.ts:42` |

#### Feature Flags
| Flag | Purpose | Source |
|------|---------|--------|
| [flag name] | [what it controls] | `filename.ts:20` |

### Notifications & Webhooks

#### Notifications
| Type | Trigger | Template/Content | Recipients | Source |
|------|---------|------------------|------------|--------|
| [email/SMS/push] | [when sent] | [template name or content] | [who receives] | `filename.ts:30` |

#### Outgoing Webhooks
| Webhook | Trigger | Payload | Destination | Source |
|---------|---------|---------|-------------|--------|
| [name] | [when dispatched] | [what's sent] | [URL or config] | `filename.ts:50` |

## Sources
| Ref | Full Path |
|-----|-----------|
| `src/payment/stripe.ts:1` | [src/payment/stripe.ts:1](src/payment/stripe.ts#L1) |
| `src/config/database.ts:5` | [src/config/database.ts:5](src/config/database.ts#L5) |
```

**Example:**
```markdown
## payment Module

### Integrations

#### Stripe
| Detail | Value | Source |
|--------|-------|--------|
| Provider | Stripe | `src/payment/stripe.ts:1` |
| Purpose | Payment processing | — |
| Endpoint | https://api.stripe.com | env: STRIPE_API_URL |
| Auth Method | API Key | env: STRIPE_API_KEY |
| SDK | stripe@14.0.0 | `package.json` |
| Webhook | POST /webhook/stripe | `src/webhooks/stripe.ts:12` |

#### Database
| Detail | Value | Source |
|--------|-------|--------|
| Provider | PostgreSQL | — |
| Purpose | Primary data store | — |
| Connection | env: DATABASE_URL | env: DATABASE_URL |
| ORM | Prisma | `prisma/schema.prisma` |

### Configuration

#### Environment Variables
| Variable | Required | Default | Description | Source |
|----------|----------|---------|-------------|--------|
| DATABASE_URL | yes | none | PostgreSQL connection string | `src/config/database.ts:5` |
| STRIPE_API_KEY | yes | none | Stripe API secret key | `src/config/payments.ts:2` |
| PORT | no | 3000 | HTTP server port | `src/index.ts:10` |
| NODE_ENV | no | development | Application environment | `src/config/index.ts:1` |

### Notifications & Webhooks

#### Notifications
| Type | Trigger | Template/Content | Recipients | Source |
|------|---------|------------------|------------|--------|
| Email | Payment failed | payment-failed.html | Order user email | `src/notifications/payment-email.ts:15` |
| Email | Refund processed | refund-confirmation.html | Order user email | `src/notifications/payment-email.ts:30` |

#### Outgoing Webhooks
| Webhook | Trigger | Payload | Destination | Source |
|---------|---------|---------|-------------|--------|
| payment.completed | Payment confirmed | Payment JSON | env: WEBHOOK_PAYMENTS_URL | `src/webhooks/dispatch.ts:20` |

## Sources
| Ref | Full Path |
|-----|-----------|
| `src/payment/stripe.ts:1` | [src/payment/stripe.ts:1](src/payment/stripe.ts#L1) |
| `src/webhooks/stripe.ts:12` | [src/webhooks/stripe.ts:12](src/webhooks/stripe.ts#L12) |
| `prisma/schema.prisma` | [prisma/schema.prisma](prisma/schema.prisma) |
| `src/config/database.ts:5` | [src/config/database.ts:5](src/config/database.ts#L5) |
| `src/config/payments.ts:2` | [src/config/payments.ts:2](src/config/payments.ts#L2) |
| `src/index.ts:10` | [src/index.ts:10](src/index.ts#L10) |
| `src/config/index.ts:1` | [src/config/index.ts:1](src/config/index.ts#L1) |
| `src/notifications/payment-email.ts:15` | [src/notifications/payment-email.ts:15](src/notifications/payment-email.ts#L15) |
| `src/notifications/payment-email.ts:30` | [src/notifications/payment-email.ts:30](src/notifications/payment-email.ts#L30) |
| `src/webhooks/dispatch.ts:20` | [src/webhooks/dispatch.ts:20](src/webhooks/dispatch.ts#L20) |
```

## Core Principles

**Document the dependency, not the implementation.** The purpose is to answer "what external systems does this project depend on?" — not to document every function that makes an API call. Group by service provider, not by file.

**Distinguish required from optional config.** An env var with a default value (e.g., `process.env.PORT || 3000`) is optional — the system will work without it. An env var with no default (e.g., `process.env.DATABASE_URL`) is required — the system will fail without it. This distinction is critical for deployment teams.

**Note the auth method.** How the system authenticates with the external service (API key, OAuth, mutual TLS, IAM role) is critical for security audits and rotation planning.

**Distinguish providers from consumers.** A `POST /webhook/stripe` route is a *consumer* (receives from Stripe). `axios.post('https://api.stripe.com/charges')` is a *provider call* (sends to Stripe). Both are integrations, but the relationship direction matters.

**Document config purpose, not just name.** `DATABASE_URL` tells an engineer what it is. But "PostgreSQL connection string for primary data store" tells an operator why it matters and what happens if it's wrong.

**Capture notification triggers precisely.** "Welcome email sent" is vague. "Welcome email sent when UserCreated event fires, to user.email, using welcome.html template" is precise. Include the trigger condition, recipient logic, and template reference.

**Note the existence of secrets without exposing values.** Document that `JWT_SECRET` is required, but never extract or record its actual value from `.env` files.

**Flag gaps.** If an external API call has no error handling, note: `MISSING: No error handling for [service] API calls`. If no `.env.example` or documentation exists for required env vars, note: `MISSING: No env var documentation or .env.example found`. If a service integration has no timeout configured, note: `MISSING: No timeout configured for [service] calls`.
