---
name: extract-domain-vocabulary
description: This skill provides domain knowledge for extracting domain vocabulary and error catalogs from code. It should be used when the agent is tasked with documenting enums, status values, domain constants, business terminology, custom error classes, error codes, error response formats, or any encoded domain concepts and failure modes in source code. Make sure to use this skill whenever the business domain language, terminology, conceptual model, or error model needs to be documented, including enum values, status definitions, business thresholds, error code mappings, and naming conventions that encode domain meaning.
user-invocable: false
---

# Domain Vocabulary & Error Catalog Extraction

This skill captures two complementary aspects of a codebase's shared language: **domain vocabulary** (the terms and concepts the business uses) and **error catalogs** (the ways the system can fail). Together they answer "what do these terms mean?" and "what can go wrong?"

## What to Extract

### Domain Vocabulary
- **Enums and union types** — `enum OrderStatus { PENDING, SHIPPED, DELIVERED }`, `type Role = 'admin' | 'user'`
- **Status definitions** — Named states that entities can be in, status codes with business meaning
- **Domain constants** — `MAX_RETRIES = 3`, `FREE_TIER_LIMIT = 100`, `GRACE_PERIOD_DAYS = 7`
- **Business terminology in type names** — What `SKU`, `SLA`, `MRR`, `churn` mean in this codebase's context
- **Localization/i18n keys** — `t('order.status.pending')` revealing domain concepts
- **Configuration constants** — Feature names, tier definitions, plan names

### Error Catalog
- **Custom error/exception classes** — `class NotFoundError extends AppError`, custom exception types
- **Error codes** — Numeric or string error codes (`ERR_001`, `ORDER_NOT_FOUND`, `auth/invalid-token`)
- **HTTP status code mappings** — Which error types return which HTTP statuses (404, 403, 422, 500)
- **Error response schemas** — The shape of error JSON responses (`{ error: { code, message, details } }`)
- **Error-to-message mappings** — Internal error codes mapped to user-facing messages
- **Error severity classification** — Recoverable (retry OK), terminal (don't retry), transient (may resolve)

## Where This Lives (vs. Other Types)

- **Domain vocabulary vs. data spec:** A `status: enum` field on an entity is a *data spec* (the field and its type). The *meaning of each enum value* (what PENDING actually means in this business) is *domain vocabulary*. Document the field in data-specs; document the domain meaning here.
- **Domain vocabulary vs. business rule:** `if (status === 'PENDING') throw new Error('Cannot ship pending order')` is a *business rule*. The definition of what PENDING means is *domain vocabulary*.
- **Error catalog vs. business rule:** `if (order.total < 50) throw new MinOrderError()` — the *business constraint* (min order $50) is a *business rule*. The *error class* (`MinOrderError`), its code, and its HTTP status mapping are the *error catalog*.
- **Error catalog vs. security/NFR:** The *infrastructure* of error handling (global catch, logging, circuit breakers) is a *security/NFR*. The *error types and their meanings* are the *error catalog*.

## Hotspot Discovery

Use the Glob and Grep tools to find domain vocabulary and error definitions:

```
Grep:  pattern="enum\s+\w+\s*\{" type=ts,js,py,go,java output_mode=files_with_matches
Grep:  pattern="type\s+\w+\s*=\s*'[^']*'\|'[^']*'" type=ts output_mode=files_with_matches
Grep:  pattern="const\s+\w+\s*=\s*\d+|const\s+\w+\s*=\s*'[A-Z_]+'" type=ts,js,py output_mode=files_with_matches
Grep:  pattern="MAX_|MIN_|DEFAULT_|LIMIT|THRESHOLD|GRACE_" type=ts,js,py,go,java output_mode=files_with_matches
Grep:  pattern="i18n|t\(|translate|gettext|formatMessage" type=ts,js,py output_mode=files_with_matches
Grep:  pattern="PLAN_|TIER_|SUBSCRIPTION_" type=ts,js,py,go output_mode=files_with_matches
Glob:  **/errors/**/*.{ts,js,py,go,java}
Glob:  **/exceptions/**/*.{ts,js,py,java}
Grep:  pattern="class\s+\w+Error|class\s+\w+Exception|class\s+\w+ extends Error" type=ts,js,py,java output_mode=files_with_matches
Grep:  pattern="ErrorCode|ErrorCodes|ERROR_|ERR_" type=ts,js,py,go,java output_mode=files_with_matches
Grep:  pattern="throw new|raise\s+\w+|panic\(" type=ts,js,py,go output_mode=files_with_matches
Grep:  pattern="status.*\d{3}|statusCode|httpStatus" type=ts,js,py,java output_mode=files_with_matches
Grep:  pattern="@Catch|@ExceptionHandler|ErrorHandler|error.*handler" type=ts,js,py,java output_mode=files_with_matches
Grep:  pattern="\.code\s*=|error_code|errorCode" type=ts,js,py output_mode=files_with_matches
```

**Prioritize:** Start with enum files, constants files, error/exception class definitions, and error code constants. Then check global error handlers and exception filters for response formatting.

## Pattern Signals

| Code Pattern | What to Extract |
|--------------|-----------------|
| `enum OrderStatus { PENDING, CONFIRMED, SHIPPED }` | Enum: Order statuses and their values |
| `const FREE_TIER_LIMIT = 100` | Domain constant: Free tier limit |
| `class NotFoundError extends AppError` | Error class: NotFoundError |
| `throw new UnauthorizedError('Invalid token')` | Error with message and context |
| `status: 404, code: 'USER_NOT_FOUND'` | Error mapped to HTTP 404 |
| `messages[ErrorCode.EXPIRED] = 'Session expired'` | Error-to-message mapping |

## Output Format

**Per-module extractor output:**
```markdown
# [Module Name] Module

Extraction: [YYYY-MM-DD]
Files Analyzed: [N] files

## Domain Vocabulary

### Enum: [Name]
[1-2 sentence summary of what this enum represents and its role in the domain.]

| Value | Meaning | Source |
|-------|---------|--------|
| [enum value] | [domain definition] | `filename.ts:5` |

### Domain Constants
[1-2 sentence context.]

| Constant | Value | Meaning | Source |
|----------|-------|---------|--------|
| [name] | [value] | [what it represents] | `filename.ts:10` |

### Domain Terms
[1-2 sentence context.]

| Term | Definition | Context | Source |
|------|------------|---------|--------|
| [term] | [what it means here] | [where it's used] | `filename.ts:20` |

## Error Catalog

### Error Classes
[1-2 sentence summary of the error hierarchy for this module.]

| Error Class | HTTP Status | Default Message | Recoverable | Source |
|-------------|-------------|-----------------|-------------|--------|
| [class name] | [status code] | [message] | [yes/no] | `filename.ts:5` |

### Error Codes
| Code | Error Class | Meaning | User Message | Source |
|------|-------------|---------|--------------|--------|
| [error code] | [class] | [internal meaning] | [user-facing message] | `filename.ts:10` |

### Error Response Schema
The standard error response shape:
```json
{
  "error": {
    "code": "[error code]",
    "message": "[user-facing message]",
    "details": "[optional validation details]"
  }
}
```
Source: `filename.ts:42`

## Sources
| Ref | Full Path |
|-----|-----------|
| `src/auth/roles.enum.ts:2` | [src/auth/roles.enum.ts:2](src/auth/roles.enum.ts#L2) |
| `src/errors/auth.errors.ts:5` | [src/errors/auth.errors.ts:5](src/errors/auth.errors.ts#L5) |
```

**Example:**
```markdown
## auth Module

### Enum: UserRole
Roles governing user access levels in the system.

| Value | Meaning | Source |
|-------|---------|--------|
| ADMIN | Full system access, can manage users and settings | `src/auth/roles.enum.ts:2` |
| USER | Standard access, can manage own resources | `src/auth/roles.enum.ts:3` |
| VIEWER | Read-only access to public resources | `src/auth/roles.enum.ts:4` |

### Domain Constants
Configuration values controlling authentication behavior.

| Constant | Value | Meaning | Source |
|----------|-------|---------|--------|
| SESSION_DURATION_HOURS | 24 | How long a session lasts before re-auth | `src/auth/constants.ts:3` |
| MAX_LOGIN_ATTEMPTS | 5 | Lock account after this many failed logins | `src/auth/constants.ts:5` |

### Error Classes
Authentication error hierarchy. All auth errors extend AppError.

| Error Class | HTTP Status | Default Message | Recoverable | Source |
|-------------|-------------|-----------------|-------------|--------|
| UnauthorizedError | 401 | Authentication required | no | `src/errors/auth.errors.ts:5` |
| ForbiddenError | 403 | Insufficient permissions | no | `src/errors/auth.errors.ts:12` |
| TokenExpiredError | 401 | Token has expired | yes (re-auth) | `src/errors/auth.errors.ts:19` |

### Error Codes
| Code | Error Class | Meaning | User Message | Source |
|------|-------------|---------|--------------|--------|
| auth/token-expired | TokenExpiredError | JWT refresh token expired | "Your session has expired. Please log in again." | `src/errors/codes.ts:5` |
| auth/invalid-credentials | UnauthorizedError | Wrong email or password | "Invalid email or password." | `src/errors/codes.ts:6` |

## Sources
| Ref | Full Path |
|-----|-----------|
| `src/auth/roles.enum.ts:2` | [src/auth/roles.enum.ts:2](src/auth/roles.enum.ts#L2) |
| `src/auth/roles.enum.ts:3` | [src/auth/roles.enum.ts:3](src/auth/roles.enum.ts#L3) |
| `src/auth/roles.enum.ts:4` | [src/auth/roles.enum.ts:4](src/auth/roles.enum.ts#L4) |
| `src/auth/constants.ts:3` | [src/auth/constants.ts:3](src/auth/constants.ts#L3) |
| `src/auth/constants.ts:5` | [src/auth/constants.ts:5](src/auth/constants.ts#L5) |
| `src/errors/auth.errors.ts:5` | [src/errors/auth.errors.ts:5](src/errors/auth.errors.ts#L5) |
| `src/errors/auth.errors.ts:12` | [src/errors/auth.errors.ts:12](src/errors/auth.errors.ts#L12) |
| `src/errors/auth.errors.ts:19` | [src/errors/auth.errors.ts:19](src/errors/auth.errors.ts#L19) |
| `src/errors/codes.ts:5` | [src/errors/codes.ts:5](src/errors/codes.ts#L5) |
| `src/errors/codes.ts:6` | [src/errors/codes.ts:6](src/errors/codes.ts#L6) |
```

## Core Principles

**Define terms in business language, not code language.** "Order cancelled by customer or system" is useful. "Enum value CANCELLED" is not. The glossary exists to bridge the gap between code and domain understanding.

**Infer meaning from context.** An enum value `PENDING` is meaningless without context. Look at how it's used — in validation rules, state transitions, error messages — to understand its business meaning.

**Catalog every error the system can produce.** The goal is a complete map of failure modes. Every custom error class, every error code, every place the system throws — catalog it.

**Map errors to HTTP status codes.** API consumers need to know what HTTP status to expect for each error type. Deviations from convention must be documented.

**Distinguish recoverable from terminal errors.** A `TokenExpiredError` is recoverable (the user can log in again). A `UserNotFoundError` is terminal (the resource doesn't exist). This distinction guides retry logic and UX decisions.

**Note user-facing vs. internal messages.** `PAYMENT_GATEWAY_TIMEOUT` is an internal error code. "Something went wrong processing your payment. Please try again." is the user-facing message. Both should be documented.

**Capture business thresholds.** Constants like `FREE_SHIPPING_THRESHOLD = 5000` or `GRACE_PERIOD_DAYS = 7` encode business policies. These are domain knowledge that analysts need when specifying changes.

**Use brief prose for context.** A 1-2 sentence summary before each enum, constant group, or error class table helps stakeholders understand the domain context without reading every row. Focus on the business purpose and relationships between terms.

**Flag gaps.** If an enum has values that are never used in the codebase, note: `MISSING: Enum value [value] in [enum] is never referenced`. If an error class exists but is never thrown, note: `MISSING: Error class [class] is defined but never thrown`. If there's a common business term used throughout the code (e.g., in variable names or comments) but no formal definition, note: `MISSING: No formal definition for domain term "[term]"`.
