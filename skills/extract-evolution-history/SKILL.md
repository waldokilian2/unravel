---
name: extract-evolution-history
description: This skill provides domain knowledge for extracting evolution history and change analysis from code. It should be used when the agent is tasked with documenting deprecated features, dead code, recent development velocity, migration history, or identifying what parts of the codebase are stable vs. actively changing. Make sure to use this skill whenever the maturity and evolution of the codebase needs to be assessed, including deprecated APIs, unused modules, schema migration history, and areas of active development.
user-invocable: false
---

# Evolution History Extraction

Evolution history captures how the codebase has changed over time — the "what's old, what's new, and what's dying?" It documents the maturity landscape that analysts need to assess risk when planning modifications or extensions.

## What to Extract

Evolution history assesses the codebase's maturity and change patterns:
- **Deprecated features** — `@Deprecated` annotations, TODO/FIXME/HACK comments, code marked for removal
- **Dead code indicators** — Unused exports, unreachable code paths, files with zero imports, commented-out blocks
- **Migration history** — Database schema migrations (ordered by timestamp), API version changes
- **Development velocity** — Recent commit frequency by module/area, last-modified dates
- **API versioning** — Deprecated endpoints, version transitions, breaking change patterns
- **Legacy patterns** — Old code styles mixed with new (e.g., callbacks next to async/await), mixed framework usage
- **Removed or in-progress features** — Feature branches, half-implemented code, scaffolding

## Where Evolution History Lives (vs. Other Types)

- **Evolution history vs. process flow:** A *process flow* shows how the system currently works. *Evolution history* shows how it got that way (or what's about to change). Document current behavior in process-flows; document change patterns here.
- **Evolution history vs. dependency map:** A *dependency map* shows current module coupling. *Evolution history* shows which dependencies were recently added, upgraded, or deprecated.
- **Evolution history vs. glossary:** A *glossary* defines what terms currently mean. *Evolution history* notes when terms changed meaning or when old concepts were replaced.

## Hotspot Discovery

Use the Glob and Grep tools to find evolution indicators:

```
Grep:  pattern="@Deprecated|@deprecated|DEPRECATED" type=ts,js,py,go,java output_mode=files_with_matches
Grep:  pattern="TODO|FIXME|HACK|XXX|TEMP|WORKAROUND" type=ts,js,py,go,java output_mode=files_with_matches
Grep:  pattern="@ts-ignore|@ts-expect-error|@SuppressWarnings|noqa" type=ts,js,py,java output_mode=files_with_matches
Glob:  **/migrations/**/*.sql
Glob:  **/migrations/**/*.ts
Glob:  **/changelog*.{md,txt,json}
Glob:  **/CHANGELOG*
Grep:  pattern="v1|v2|version|Version|VERSION" type=ts,js,py output_mode=files_with_matches
Grep:  pattern="legacy|compat|backward|shim|polyfill" type=ts,js,py output_mode=files_with_matches
```

**Prioritize:** Start with TODO/FIXME comments (reveal active concerns), deprecation annotations (reveal planned changes), and migration files (reveal schema evolution). Then check git history for development velocity by module.

## Pattern Signals

| Code Pattern | Evolution Detail |
|--------------|-----------------|
| `@Deprecated('Use newCheckout instead')` | Deprecated: oldCheckout, replacement: newCheckout |
| `// TODO: migrate to new payment provider` | Planned change: payment provider migration |
| `// FIXME: race condition when concurrent` | Known bug: race condition |
| `// HACK: workaround for upstream bug #123` | Technical debt: workaround in place |
| `20240101000000_create_users.sql` → `20240615000000_add_roles.sql` | Schema evolution: users table extended with roles |
| `router.get('/v1/orders')` + `router.get('/v2/orders')` | API versioning: v1 and v2 both exist |
| `function oldProcess() { /* migrated to processV2 */ }` | Dead code: old function replaced |

## Output Format

**Per-module extractor output:**
```markdown
# [Module Name] Module

Extraction: [YYYY-MM-DD]
Files Analyzed: [N] files

## Artifacts

### Deprecated Items
| Item | Replacement | Since | Source |
|------|-------------|-------|--------|
| [deprecated item] | [what to use instead] | [when deprecated] | `filename.ts:42` |

### Technical Debt
| Type | Description | Priority | Source |
|------|-------------|----------|--------|
| [TODO/FIXME/HACK] | [what needs to be fixed] | [high/medium/low] | `filename.ts:15` |

### Schema Migration History
| Migration | Description | Date | Source |
|-----------|-------------|------|--------|
| [migration name] | [what changed] | [date from filename] | `migration.sql` |

### Dead Code Indicators
| File/Function | Evidence | Confidence | Source |
|---------------|----------|------------|--------|
| [unused item] | [why it appears dead] | [high/medium] | `filename.ts:30` |

### API Version History
| Version | Endpoints | Status | Source |
|---------|-----------|--------|--------|
| [version] | [endpoint list] | [active/deprecated/sunset] | `filename.ts:10` |

## Sources
| Ref | Full Path |
|-----|-----------|
| `src/payments/legacy.ts:10` | [src/payments/legacy.ts:10](src/payments/legacy.ts#L10) |
| `src/payments/stripe.ts:20` | [src/payments/stripe.ts:20](src/payments/stripe.ts#L20) |
```

**Example:**
```markdown
## payments Module

### Deprecated Items
| Item | Replacement | Since | Source |
|------|-------------|-------|--------|
| `processPaymentV1()` | `processPaymentV2()` | 2025-06 | `src/payments/legacy.ts:10` |
| `StripeClient` class | `PaymentGateway` interface | 2025-09 | `src/payments/stripe-client.ts:1` |
| `POST /v1/payments` | `POST /v2/payments` | 2025-12 | `src/payments/payments.controller.ts:5` |

### Technical Debt
| Type | Description | Priority | Source |
|------|-------------|----------|--------|
| TODO | Migrate from Stripe API v2023-10 to v2024-11 | high | `src/payments/stripe.ts:20` |
| FIXME | Retry logic doesn't handle idempotency key conflicts | medium | `src/payments/retry.ts:15` |
| HACK | Hardcoded webhook secret for local development | low | `src/payments/webhook.ts:8` |

### Dead Code Indicators
| File/Function | Evidence | Confidence | Source |
|---------------|----------|------------|--------|
| `processPaymentV1()` | No callers found, marked @Deprecated | high | `src/payments/legacy.ts:10` |
| `paypal.module.ts` | Zero imports across codebase, feature appears unused | medium | `src/payments/paypal.module.ts` |

### API Version History
| Version | Endpoints | Status | Source |
|---------|-----------|--------|--------|
| v1 | POST /v1/payments, GET /v1/payments/:id | Deprecated (sunset: 2026-06) | `src/payments/payments.controller.ts:5` |
| v2 | POST /v2/payments, GET /v2/payments/:id, POST /v2/refunds | Active | `src/payments/payments-v2.controller.ts:1` |

## Sources
| Ref | Full Path |
|-----|-----------|
| `src/payments/legacy.ts:10` | [src/payments/legacy.ts:10](src/payments/legacy.ts#L10) |
| `src/payments/stripe-client.ts:1` | [src/payments/stripe-client.ts:1](src/payments/stripe-client.ts#L1) |
| `src/payments/payments.controller.ts:5` | [src/payments/payments.controller.ts:5](src/payments/payments.controller.ts#L5) |
| `src/payments/stripe.ts:20` | [src/payments/stripe.ts:20](src/payments/stripe.ts#L20) |
| `src/payments/retry.ts:15` | [src/payments/retry.ts:15](src/payments/retry.ts#L15) |
| `src/payments/webhook.ts:8` | [src/payments/webhook.ts:8](src/payments/webhook.ts#L8) |
| `src/payments/paypal.module.ts` | [src/payments/paypal.module.ts](src/payments/paypal.module.ts) |
| `src/payments/payments-v2.controller.ts:1` | [src/payments/payments-v2.controller.ts:1](src/payments/payments-v2.controller.ts#L1) |
```

## Core Principles

**Distinguish deprecated from dead.** Deprecated code has been explicitly marked for removal (with `@Deprecated` or similar) and often has a replacement. Dead code has no callers and may have been forgotten. Both are risks, but they need different handling — deprecated code has a migration path; dead code is just noise.

**Note technical debt severity.** TODOs range from "nice to have" to "critical security issue." Use context to assess priority: a TODO about migrating off a deprecated library is higher priority than a TODO about renaming a variable.

**Map migration history chronologically.** Schema migrations are ordered — each builds on the previous. List them in order so analysts can see the evolution of the data model. This is especially important for understanding why certain constraints exist.

**Identify version transitions clearly.** If both v1 and v2 of an API exist, document which is active, which is deprecated, and what the sunset timeline is. This prevents analysts from designing new features against deprecated endpoints.

**Use confidence levels for dead code.** "High confidence" means zero imports found anywhere in the codebase. "Medium confidence" means the file/function is only referenced in tests or only imported conditionally. Don't flag things as dead that might be loaded dynamically or via configuration.

**Flag gaps.** If a module has significant technical debt (multiple high-priority TODOs) but no recent commits, note: `MISSING: Stale technical debt in [module] — no recent activity on [N] high-priority items`. If a deprecated API has no sunset date, note: `MISSING: No sunset date for deprecated [endpoint/item]`. If a migration introduces a schema change with no rollback migration, note: `MISSING: No rollback migration for [migration]`.
