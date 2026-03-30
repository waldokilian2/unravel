---
name: extract-business-rules
description: This skill provides domain knowledge for extracting business rules from code. It should be used when the agent is tasked with finding conditional logic, validation rules, guard clauses, exception handling, regex validation, or any if/else-based business constraints in source code. Make sure to use this skill whenever business constraints, domain validation, or conditional enforcement logic needs to be documented, even if the code is in Python, Go, Java, or Rust rather than TypeScript.
user-invocable: false
---

# Business Rules Extraction

Business rules are the constraints that the system enforces on data and behavior. They capture the "what must be true" that stakeholders care about — not the mechanism, but the constraint itself.

## What to Extract

Business rules are conditional logic that enforces business constraints:

- **If/else chains and guard clauses** — Early returns, preconditions, guard expressions
- **Validation decorators and annotations** — `@Min`, `@Max`, `@Valid`, `@Validate`, Pydantic validators, Bean Validation
- **Exception throwing and error raising** — `throw`, `raise`, `panic`, custom error types
- **Regex patterns and format validation** — Regular expressions constraining input shape
- **Assertion checks** — `assert()`, `verify()`, `check()`, `require()`

## Where Business Rules Live (vs. Other Types)

Business rules overlap with other artifact types. Apply these boundaries:

- **Business rule vs. data spec:** A `@MinLength(8)` decorator is a *data spec* (field constraint on a schema). The business rule is the *reason* — "Passwords must be at least 8 characters." Extract the business constraint here; the schema annotation belongs in data-specs.
- **Business rule vs. security/NFR:** A `if (!user.isActive) throw new ForbiddenError()` is a *security measure* (authorization check). Extract it in security-nfrs. But `if (order.total < 50) throw new MinOrderError()` is a *business constraint* — extract it here.
- **Business rule vs. user story:** A `@Post('checkout')` endpoint is a *user story*. The validation logic *inside* that endpoint (e.g., checking stock levels) is a *business rule*.

**Guideline:** If the constraint exists because the business requires it (not because of security architecture or data shape), it's a business rule.

## Hotspot Discovery

Use the Glob and Grep tools to find files with business rules. Focus on directories that contain domain logic, not infrastructure:

```
Grep:  pattern="if\s*\(.*return" type=ts,js,py,go,java output_mode=files_with_matches
Grep:  pattern="validate|verify|check|require" type=ts,js,py,go,java output_mode=files_with_matches
Grep:  pattern="throw|raise|panic|Error\(" type=ts,js,py,go,java output_mode=files_with_matches
Grep:  pattern="assert|invariant|precondition" type=ts,js,py,go,java output_mode=files_with_matches
```

**Prioritize:** Start with files in directories named `domain`, `rules`, `validation`, `services`, or `logic` — these tend to contain concentrated business rules. Skip test files and generated code.

## Pattern Signals

| Code Pattern | Business Rule | Enforcement |
|--------------|---------------|-------------|
| `if (age < 18) return` | Age must be >= 18 | Guard clause returns early |
| `@Min(1) @Max(100)` | Range: 1-100 | Validation decorator |
| `raise ValueError("expired")` | Token must not be expired | Exception raising |
| `if !valid { return }` | Validity check required | Guard expression |
| `func MustBeAdmin(u User) error` | Admin role required | Go error return pattern |
| `assert(user.canEdit)` | Edit permission required | Assertion |

## Output Format

**Per-module extractor output:**
```markdown
# [Module Name] Module

Extraction: [YYYY-MM-DD]
Files Analyzed: [N] files

## Artifacts

### [Domain Area Name]
[1-2 sentence summary of what this area covers and why it matters.]

| Rule | Impact | Enforcement | Source |
|------|--------|-------------|--------|
| [Business constraint] | [Low/Medium/High/Critical] | [How it's enforced] | `filename.ts:42` |
| [Business constraint] | [Low/Medium/High/Critical] | [How it's enforced] | `filename.ts:15` |

### [Another Domain Area Name]
[1-2 sentence context.]

| Rule | Impact | Enforcement | Source |
|------|--------|-------------|--------|
| ... | ... | ... | ... |

## Sources
| Ref | Full Path |
|-----|-----------|
| `src/auth/validation.ts:5` | [src/auth/validation.ts:5](src/auth/validation.ts#L5) |
| `src/auth/registration.ts:12` | [src/auth/registration.ts:12](src/auth/registration.ts#L12) |
```

When a module has fewer than 5 rules, a single table without sub-headings is acceptable. Include a brief prose intro before the table.

**Example (fewer than 5 rules):**
```markdown
# auth Module

Extraction: [YYYY-MM-DD]
Files Analyzed: [N] files

## Artifacts

These rules govern user authentication and registration validation.

| Rule | Impact | Enforcement | Source |
|------|--------|-------------|--------|
| Age must be >= 18 | High | Guard clause returns early | `src/auth/registration.ts:12` |
| Password must be 8+ chars | Critical | @MinLength(8) decorator | `src/auth/validation.ts:5` |
| Email format validated | High | Regex: /^[^\s@]+@[^\s@]+\.[^\s@]+$/ | `src/auth/validation.ts:8` |
| Invalid token throws 401 | Critical | throw new UnauthorizedError() | `src/auth/jwt.ts:23` |

## Sources
| Ref | Full Path |
|-----|-----------|
| `src/auth/registration.ts:12` | [src/auth/registration.ts:12](src/auth/registration.ts#L12) |
| `src/auth/validation.ts:5` | [src/auth/validation.ts:5](src/auth/validation.ts#L5) |
| `src/auth/validation.ts:8` | [src/auth/validation.ts:8](src/auth/validation.ts#L8) |
| `src/auth/jwt.ts:23` | [src/auth/jwt.ts:23](src/auth/jwt.ts#L23) |
```

**Example (many rules, sub-sectioned):**
```markdown
# orders Module

Extraction: [YYYY-MM-DD]
Files Analyzed: [N] files

## Artifacts

### Order Validation
Orders must pass several checks before being accepted. These rules enforce minimum values and stock availability.

| Rule | Impact | Enforcement | Source |
|------|--------|-------------|--------|
| Order total must be >= $50 | High | Guard clause throws MinOrderError | `src/orders/validation.ts:12` |
| Maximum 100 items per order | Medium | @Max(100) on items array | `src/orders/dto/create-order.dto.ts:5` |
| Items must be in stock | High | Stock check before persistence | `src/orders/orders.service.ts:20` |

### Payment Constraints
Payment processing has additional safety rules to prevent fraud and ensure revenue recognition.

| Rule | Impact | Enforcement | Source |
|------|--------|-------------|--------|
| Payment method must be active | Critical | Guard clause in payment service | `src/orders/payment.ts:15` |
| Refund window is 30 days | High | Date comparison in refund handler | `src/orders/refund.ts:8` |
| Daily payment limit is $10,000 | Critical | Cumulative check in payment service | `src/orders/payment.ts:30` |

## Sources
| Ref | Full Path |
|-----|-----------|
| `src/orders/validation.ts:12` | [src/orders/validation.ts:12](src/orders/validation.ts#L12) |
| `src/orders/dto/create-order.dto.ts:5` | [src/orders/dto/create-order.dto.ts:5](src/orders/dto/create-order.dto.ts#L5) |
| `src/orders/orders.service.ts:20` | [src/orders/orders.service.ts:20](src/orders/orders.service.ts#L20) |
| `src/orders/payment.ts:15` | [src/orders/payment.ts:15](src/orders/payment.ts#L15) |
| `src/orders/refund.ts:8` | [src/orders/refund.ts:8](src/orders/refund.ts#L8) |
| `src/orders/payment.ts:30` | [src/orders/payment.ts:30](src/orders/payment.ts#L30) |
```

## Core Principles

**Extract the constraint, not the code.** Stakeholders need to know "passwords must be 8+ characters", not "there's a @MinLength decorator on line 5". The source location is for traceability — the rule text is for understanding.

**Verify before recording.** For each artifact found, re-read the referenced line in the source file. Confirm the rule actually exists at that location before including it. This prevents hallucinated line references.

**One rule per row.** Don't combine multiple constraints into one artifact. If a function has three guard clauses, extract each as a separate rule.

**Use plain language.** Write rules as natural language constraints ("Order total must be positive"), not code descriptions ("if total <= 0 return error").

**Assess impact.** Categorize each rule's business impact:
- **Critical** — Safety, security, or data loss prevention
- **High** — Core business logic that directly affects revenue or compliance
- **Medium** — Operational rules that govern normal system behavior
- **Low** — Cosmetic preferences or UX polish

Default to Medium when the impact is unclear from context.

**Group by business domain.** When a module has many rules, organize them into logical groups using `###` headings named after the business concern (e.g., "Order Validation", "Payment Constraints", "Inventory Rules"). If a module has fewer than 5 rules, a single table is acceptable.

**Use brief prose for context.** A 1-2 sentence summary before each table or group helps stakeholders understand the business context without reading every row. Focus on *why* the rules exist, not what they say.

**Flag gaps.** If an endpoint handler performs operations but has no validation or guard clauses, note it: `MISSING: No validation rules found for [endpoint/handler]`. If a domain area appears to lack explicit rules that would normally be expected, flag it: `MISSING: No business rules extracted for [area]`.
