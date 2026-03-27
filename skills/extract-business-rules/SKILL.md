---
name: extract-business-rules
description: This skill provides domain knowledge for extracting business rules from code. It should be used when the agent is tasked with finding conditional logic, validation rules, guard clauses, exception handling, regex validation, or any if/else-based business constraints in source code. Make sure to use this skill whenever business constraints, domain validation, or conditional enforcement logic needs to be documented, even if the code is in Python, Go, Java, or Rust rather than TypeScript.
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

| Rule | Source | Enforcement |
|------|--------|-------------|
| [Business constraint] | [filename.ts:42](path/to/filename.ts#L42) | [How it's enforced] |
| [Business constraint] | [filename.ts:15](path/to/filename.ts#L15) | [How it's enforced] |
```

**Example:**
```markdown
## auth Module

| Rule | Source | Enforcement |
|------|--------|-------------|
| Age must be >= 18 | [src/auth/registration.ts:12](src/auth/registration.ts#L12) | Guard clause returns early |
| Password must be 8+ chars | [src/auth/validation.ts:5](src/auth/validation.ts#L5) | @MinLength(8) decorator |
| Email format validated | [src/auth/validation.ts:8](src/auth/validation.ts#L8) | Regex: /^[^\s@]+@[^\s@]+\.[^\s@]+$/ |
| Invalid token throws 401 | [src/auth/jwt.ts:23](src/auth/jwt.ts#L23) | throw new UnauthorizedError() |
```

## Core Principles

**Extract the constraint, not the code.** Stakeholders need to know "passwords must be 8+ characters", not "there's a @MinLength decorator on line 5". The source location is for traceability — the rule text is for understanding.

**Verify before recording.** For each artifact found, re-read the referenced line in the source file. Confirm the rule actually exists at that location before including it. This prevents hallucinated line references.

**One rule per row.** Don't combine multiple constraints into one artifact. If a function has three guard clauses, extract each as a separate rule.

**Use plain language.** Write rules as natural language constraints ("Order total must be positive"), not code descriptions ("if total <= 0 return error").
