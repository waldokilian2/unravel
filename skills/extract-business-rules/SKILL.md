---
name: extract-business-rules
description: Domain knowledge for extracting business rules - conditional logic, validation, exception handling
---

# Business Rules Extraction

Domain knowledge for extracting business rules from code.

## What to Extract

Business rules are conditional logic that enforces business constraints:

- **If/else chains and guard clauses** - Early returns based on conditions
- **Validation decorators and libraries** - @Min, @Max, @Email, @Validate, etc.
- **Exception throwing and error handling** - throw, raise, custom errors
- **Regex patterns and format validation** - Regular expressions for validation
- **Condition checks and assertions** - assert(), verify(), check()

## Hotspot Discovery

Use these patterns to find files with business rules:

```bash
# Find conditional logic
grep -r "if.*:" --include="*.py" --include="*.ts" --include="*.js" -l | head -20

# Find validation calls
grep -r "validate\|verify\|check" --include="*.py" --include="*.ts" -l | head -20

# Find exception throwing
grep -r "throw\|raise\|throwError" --include="*.ts" --include="*.js" -l | head -20

# Find regex patterns
grep -r "test(\|match(" --include="*.ts" --include="*.js" -l | head -20
```

Exclude generated code:
```bash
--exclude-dir=node_modules --exclude-dir=dist --exclude-dir=build --exclude-dir=.next
```

## Pattern Signals

| Code Pattern | Business Rule | Enforcement |
|--------------|---------------|-------------|
| `if (age < 18) return` | Age must be >= 18 | Guard clause returns early |
| `@Min(1) @Max(100)` | Range: 1-100 | Validation decorator |
| `throw new InvalidStateError()` | State validation required | Exception throw |
| `/^[A-Z]{2}\d{4}$/` | Format: 2 letters + 4 digits | Regex validation |
| `assert(user.canEdit)` | Permission check required | Assertion |
| `if (!isValid) return` | Validity check required | Guard clause |

## Output Format

**Note:** This format is what the extractor outputs per module. The merger will combine all module outputs and add `# Business Rules` as the top-level title.

**Per-module extractor output:**
```markdown
## [Module Name] Module

Extraction: [YYYY-MM-DD]
Files Analyzed: [N] files

| Rule | Source | Enforcement |
|------|--------|-------------|
| [Business constraint] | [file:line] | [How it's enforced] |
| [Business constraint] | [file:line] | [How it's enforced] |
```

**Final merged output (after merger combines all modules):**
```markdown
# Business Rules

Extraction: [YYYY-MM-DD]

## Extraction Summary
- **Total Artifacts:** [count]
- **Files Analyzed:** [unique file count]
- **Modules:** [list]
- **Verification:** Each module independently verified

---

## auth Module
| Rule | Source | Enforcement |
|------|--------|-------------|
| [Business constraint] | [file:line] | [How it's enforced] |

## payment Module
| Rule | Source | Enforcement |
|------|--------|-------------|
| [Business constraint] | [file:line] | [How it's enforced] |
```

## Core Principles

**Rule-first:** Extract the business constraint, not the implementation

**Hotspot-first:** Find files with patterns before reading

**Source locations:** Include file:line for every rule

**No hallucinations:** Only extract what exists in the code
