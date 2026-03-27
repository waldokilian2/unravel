---
name: extract-data-specs
description: This skill provides domain knowledge for extracting data specifications from code. It should be used when the agent is tasked with documenting ORM classes, database schemas, TypeScript interfaces, DTOs, validation annotations, Prisma schemas, Pydantic models, or any data structure definitions. Make sure to use this skill whenever data shapes, field constraints, or entity relationships need to be documented, regardless of the language or ORM used.
---

# Data Specifications Extraction

Data specifications capture the shape and constraints of the data that flows through the system — the "what data exists and what shape must it have."

## What to Extract

Data specifications define what data the system processes:

- **ORM classes and models** — `@Entity`, `@Table`, Model, Pydantic BaseModel, SQLAlchemy models
- **Database schema definitions** — `CREATE TABLE`, migration files, schema SQL
- **DTOs** — Data Transfer Objects, Request/Response classes, Pydantic schemas
- **Type definitions** — TypeScript interfaces/types, Go structs, Python dataclasses/TypedDict
- **Validation annotations** — `@IsEmail`, `@Min`, `@Max`, Pydantic `Field()`, Bean Validation
- **Schema files** — JSON Schema, GraphQL types, OpenAPI specs, Protobuf, Prisma schemas

## Where Data Specs Live (vs. Other Types)

- **Data spec vs. business rule:** A `@MinLength(8)` on a field is a *data spec* (the field's constraint). The business meaning ("passwords must be 8+ characters") is a *business rule*. Document the schema constraint here; the business interpretation belongs in business-rules.
- **Data spec vs. integration:** A `DATABASE_URL` env var pointing to PostgreSQL is an *integration*. The schema of the `users` table in that database is a *data spec*.

## Hotspot Discovery

Use the Glob and Grep tools to find files with data specifications:

```
Glob:  **/models/**/*.{ts,js,py,go,java}
Glob:  **/entities/**/*.{ts,js,py,go,java}
Glob:  **/schemas/**/*.{ts,js,py}
Glob:  **/dto/**/*.{ts,js,py}
Glob:  **/*.prisma
Glob:  **/migrations/**/*.sql
Grep:  pattern="class.*Model|@Entity|@Table|BaseModel|dataclass" type=ts,js,py,go,java output_mode=files_with_matches
Grep:  pattern="interface\s+\w+" type=ts output_mode=files_with_matches
Grep:  pattern="type\s+\w+\s*=\s*\{|struct\s+\w+" type=ts,go output_mode=files_with_matches
```

**Prioritize:** Start with model/entity/schema directories, then search for type definitions and DTOs. Skip test fixtures and mock data.

## Pattern Signals

| Code Pattern | Data Spec |
|--------------|-----------|
| `@Entity class User` | Database table schema |
| `class User(BaseModel):` (Pydantic) | Validated data model |
| `type User = { id: string; ... }` | TypeScript type definition |
| `type User struct { ID uuid }` | Go struct / DB mapping |
| `@IsEmail() email: string` | Field constraint |
| `@Column({ type: 'uuid' })` | Database column type |
| `enum UserRole { ADMIN, USER }` | Allowed values |
| `model User { id Int @id }` (Prisma) | Prisma schema |

## Output Format

**Per-module extractor output:**
```markdown
# [Module Name] Module

Extraction: [YYYY-MM-DD]
Files Analyzed: [N] files

## Artifacts

### Entity: [Name]
| Field | Type | Constraints | Source |
|-------|------|-------------|--------|
| [field name] | [data type] | [validation/rules] | [filename.ts:42](path/to/filename.ts#L42) |
```

**Example:**
```markdown
## user Module

### Entity: User
| Field | Type | Constraints | Source |
|-------|------|-------------|--------|
| id | uuid | Primary key, auto-generated | [src/user/user.entity.ts:5](src/user/user.entity.ts#L5) |
| email | string | @IsEmail, unique, required | [src/user/user.entity.ts:6](src/user/user.entity.ts#L6) |
| password | string | @MinLength(8), required | [src/user/user.entity.ts:7](src/user/user.entity.ts#L7) |
| role | enum | ADMIN, USER, default: USER | [src/user/user.entity.ts:8](src/user/user.entity.ts#L8) |

### Relationships
| From | To | Type | Source |
|------|----|----|--------|
| User.id | Order.userId | One-to-many | [src/user/user.entity.ts:12](src/user/user.entity.ts#L12) |
```

## Core Principles

**Document the schema, not the behavior.** A data spec captures what data looks like — field names, types, constraints. It does not capture what the system *does* with that data (that's process flows or business rules).

**Include constraints at the field level.** Record validation decorators, database constraints, defaults, nullability, and uniqueness. These are what downstream systems and developers need to know.

**Document relationships.** Foreign keys, one-to-many/many-to-many mappings, and join tables are essential for understanding the data model. Group relationships in a separate table.

**Mark required vs. optional clearly.** Distinguish between `email: string` (required) and `email?: string` (optional). This matters for API consumers and data validation.
