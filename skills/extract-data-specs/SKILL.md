---
name: extract-data-specs
description: Domain knowledge for extracting data specifications - schemas, ORMs, DTOs, type definitions
---

# Data Specifications Extraction

Domain knowledge for extracting data structures and schemas from code.

## What to Extract

Data specifications define what data the system processes:

- **ORM classes** - @Entity, @Table, Model decorators
- **Database schema definitions** - CREATE TABLE, schema files
- **DTOs** - Data Transfer Objects, Request/Response classes
- **TypeScript interfaces/types** - interface, type definitions
- **Validation annotations** - @IsEmail, @Min, @Max, @Validate
- **Schema files** - JSON Schema, GraphQL, OpenAPI, Prisma

## Hotspot Discovery

```bash
# Find ORM models
grep -r "class.*Model\|@Entity\|@Table" --include="*.ts" --include="*.js" -l | head -20

# Find interfaces
grep -r "interface " --include="*.ts" -l | head -20

# Find validation decorators
grep -r "@Is\|@Min\|@Max\|@Validate" --include="*.ts" -l | head -20

# Find DTOs
grep -r "DTO\|dto\|Request\|Response" --include="*.ts" --include="*.js" -l | head -20
```

## Pattern Signals

| Code Pattern | Data Spec |
|--------------|-----------|
| `@Entity class User` | Database table schema |
| `interface CreateUserRequest` | API contract |
| `@IsEmail() email: string` | Field constraint |
| `@Column({ type: 'uuid' })` | Database type |
| `enum UserRole { ADMIN, USER }` | Allowed values |
| `@Min(0) @Max(150)` | Field validation |

## Output Format

**Note:** This format is what the extractor outputs per module. The merger will combine all module outputs and add `# Data Specifications` as the top-level title.

**Per-module extractor output:**
```markdown
## [Module Name] Module

Extraction: [YYYY-MM-DD]
Files Analyzed: [N] files

| Field | Type | Constraints | Source |
|-------|------|-------------|--------|
| [field name] | [data type] | [validation/rules] | [filename.ts:42](path/to/filename.ts#L42) |
| [field name] | [data type] | [validation/rules] | [filename.ts:15](path/to/filename.ts#L15) |
```

**Final merged output (after merger combines all modules):**
```markdown
# Data Specifications

Extraction: [YYYY-MM-DD]

## Extraction Summary
- **Total Artifacts:** [count]
- **Files Analyzed:** [unique file count]
- **Modules:** [list]
- **Verification:** Each module independently verified

---

## auth Module
| Field | Type | Constraints | Source |
|-------|------|-------------|--------|
| [field name] | [data type] | [validation/rules] | [filename.ts:42](path/to/filename.ts#L42) |

## payment Module
| Field | Type | Constraints | Source |
|-------|------|-------------|--------|
| [field name] | [data type] | [validation/rules] | [filename.ts:15](path/to/filename.ts#L15) |
```

## Core Principles

**Schema-first:** Find data definitions before reading implementation code

**Document constraints:** Include validation, database, and application constraints

**Note relationships:** Document foreign keys, refs, and relationships

**Required vs optional:** Clearly mark which fields are required
