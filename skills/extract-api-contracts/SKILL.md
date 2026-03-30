---
name: extract-api-contracts
description: This skill provides domain knowledge for extracting API contracts and interface specifications from code. It should be used when the agent is tasked with documenting request/response schemas, query parameters, path parameters, status codes, pagination patterns, API versioning, OpenAPI specs, or reconstructing the external interface of an API. Make sure to use this skill whenever the input/output contract of an API needs to be documented, including endpoint signatures, payload shapes, and response formats, regardless of framework.
user-invocable: false
---

# API Contracts Extraction

API contracts capture the precise interface the system exposes to consumers — the "what does this API look like from the outside?" They document the shapes of requests and responses that frontend developers, API consumers, and integration partners need to work with.

## What to Extract

API contracts define the external interface of the system:
- **Request schemas** — Path parameters, query parameters, request body shapes (DTOs, Pydantic models, Zod schemas)
- **Response schemas** — Response body shapes, status codes per endpoint, paginated responses
- **Path and route definitions** — Full URL patterns with HTTP methods, path parameters annotated
- **Validation decorators on inputs** — `@IsString()`, `@IsOptional()`, `@Min()`, Pydantic `Field()` constraints on request DTOs
- **API versioning** — URL prefixes (`/v1/`), header-based versioning, `@ApiVersion` decorators
- **Pagination patterns** — Offset/limit, cursor-based, page/pageSize query parameters
- **Content negotiation** — Accepted content types, response format variations
- **OpenAPI/Swagger annotations** — `@ApiResponse`, `@ApiOperation`, `swagger-ui`, OpenAPI JSON specs

## Where API Contracts Live (vs. Other Types)

- **API contract vs. user story:** A route definition tells you what the user can do (*user story*). The request body shape and response schema are the *API contract*. The user story is "As a user, I can create an order." The contract is "POST /orders accepts `{ items: OrderItem[], shippingAddress: string }` and returns `201 { id, status, total }`."
- **API contract vs. data spec:** The `User` entity in the database is a *data spec*. The `CreateUserDTO` or `UserResponse` that shapes the API input/output is an *API contract*. They may overlap but serve different audiences.
- **API contract vs. integration:** An outbound HTTP call to Stripe is an *integration*. An inbound endpoint that your system exposes is an *API contract*.

## Hotspot Discovery

Use the Glob and Grep tools to find API contract definitions:

```
Glob:  **/dto/**/*.{ts,js,py,go,java}
Glob:  **/requests/**/*.{ts,js,py}
Glob:  **/responses/**/*.{ts,js,py}
Glob:  **/swagger*.{json,yaml,yml}
Glob:  **/openapi*.{json,yaml,yml}
Grep:  pattern="@Body|@Query|@Param|@ReqBody|@RequestParam" type=ts,java output_mode=files_with_matches
Grep:  pattern="@ApiProperty|@ApiModelProperty|@Schema|@ApiResponse" type=ts,java,py output_mode=files_with_matches
Grep:  pattern="z\.object|z\.string|z\.number" type=ts,js output_mode=files_with_matches
Grep:  pattern="class.*DTO|class.*Request|class.*Response|class.*Payload" type=ts,java,py output_mode=files_with_matches
Grep:  pattern="res\.status\(|HttpCode\(|@HttpCode|status_code" type=ts,js,py,java output_mode=files_with_matches
```

**Prioritize:** Start with DTO/request/response classes and route handler files. These contain the most concentrated API contract information. Check for existing OpenAPI/Swagger specs which may already have much of this documented.

## Pattern Signals

| Code Pattern | API Contract Detail |
|--------------|-------------------|
| `@Post('users') create(@Body() dto: CreateUserDTO)` | POST /users, body: CreateUserDTO |
| `@Get(':id') findOne(@Param('id') id: string)` | GET /users/:id, path param: id |
| `@Get('search') search(@Query('q') q: string, @Query('page') page: number)` | GET /search, query params: q, page |
| `@HttpCode(201) createUser()` | Returns 201 on success |
| `class CreateUserDTO { @IsEmail() email: string }` | Request field: email (email format) |
| `res.json({ data: [], meta: { total, page } })` | Paginated response shape |
| `z.object({ name: z.string().min(1) })` | Zod-validated request body |
| `@ApiProperty({ example: 'john@example.com' })` | OpenAPI field documentation |

## Output Format

**Per-module extractor output:**
```markdown
# [Module Name] Module

Extraction: [YYYY-MM-DD]
Files Analyzed: [N] files

## Artifacts

### [METHOD] [path]
| Detail | Value | Source |
|--------|-------|--------|
| Method | [HTTP method] | `filename.ts:42` |
| Path | [URL pattern] | `filename.ts:42` |
| Auth | [Required/None] | `guard/annotation location` |
| Success Status | [HTTP status code] | `filename.ts:42` |

**Request:**
| Field | Location | Type | Required | Constraints | Source |
|-------|----------|------|----------|-------------|--------|
| [field name] | [body/query/param] | [type] | [yes/no] | [validation] | `filename.ts:10` |

**Response (Success):**
| Field | Type | Description | Source |
|-------|------|-------------|--------|
| [field name] | [type] | [what it represents] | `filename.ts:30` |

**Error Responses:**
| Status Code | Condition | Source |
|-------------|-----------|--------|
| [HTTP status] | [when this error occurs] | `filename.ts:25` |

## Sources
| Ref | Full Path |
|-----|-----------|
| `src/orders/orders.controller.ts:15` | [src/orders/orders.controller.ts:15](src/orders/orders.controller.ts#L15) |
| `src/orders/dto/create-order.dto.ts:5` | [src/orders/dto/create-order.dto.ts:5](src/orders/dto/create-order.dto.ts#L5) |
```

**Example:**
```markdown
## orders Module

### POST /api/v1/orders
| Detail | Value | Source |
|--------|-------|--------|
| Method | POST | `src/orders/orders.controller.ts:15` |
| Path | /api/v1/orders | `src/orders/orders.controller.ts:15` |
| Auth | JWT required | `src/orders/orders.controller.ts:14` |
| Success Status | 201 Created | `src/orders/orders.controller.ts:15` |

**Request:**
| Field | Location | Type | Required | Constraints | Source |
|-------|----------|------|----------|-------------|--------|
| items | body | OrderItem[] | yes | Min 1 item | `src/orders/dto/create-order.dto.ts:5` |
| shippingAddress | body | string | yes | Non-empty | `src/orders/dto/create-order.dto.ts:6` |
| couponCode | body | string | no | — | `src/orders/dto/create-order.dto.ts:7` |

**Response (Success):**
| Field | Type | Description | Source |
|-------|------|-------------|--------|
| id | uuid | Order identifier | `src/orders/orders.controller.ts:20` |
| status | enum | PENDING, CONFIRMED | `src/orders/orders.controller.ts:20` |
| total | number | Order total in cents | `src/orders/orders.controller.ts:20` |

**Error Responses:**
| Status Code | Condition | Source |
|-------------|-----------|--------|
| 400 | Invalid request body | `src/orders/orders.controller.ts:16` |
| 401 | Missing or invalid JWT | `src/orders/orders.controller.ts:14` |

## Sources
| Ref | Full Path |
|-----|-----------|
| `src/orders/orders.controller.ts:15` | [src/orders/orders.controller.ts:15](src/orders/orders.controller.ts#L15) |
| `src/orders/orders.controller.ts:14` | [src/orders/orders.controller.ts:14](src/orders/orders.controller.ts#L14) |
| `src/orders/orders.controller.ts:16` | [src/orders/orders.controller.ts:16](src/orders/orders.controller.ts#L16) |
| `src/orders/orders.controller.ts:20` | [src/orders/orders.controller.ts:20](src/orders/orders.controller.ts#L20) |
| `src/orders/dto/create-order.dto.ts:5` | [src/orders/dto/create-order.dto.ts:5](src/orders/dto/create-order.dto.ts#L5) |
| `src/orders/dto/create-order.dto.ts:6` | [src/orders/dto/create-order.dto.ts:6](src/orders/dto/create-order.dto.ts#L6) |
| `src/orders/dto/create-order.dto.ts:7` | [src/orders/dto/create-order.dto.ts:7](src/orders/dto/create-order.dto.ts#L7) |
```

## Core Principles

**Document the interface, not the implementation.** Consumers of this artifact need to know what to send and what to expect back — not how the server processes the request internally. Focus on shapes, types, constraints, and status codes.

**Capture all parameter locations.** Parameters can arrive in the path (`:id`), query string (`?page=1`), request body, or headers. Each location is a different part of the contract and must be documented.

**Record success and error responses.** A complete API contract includes both what success looks like (200/201 with this shape) and what failures look like (400/401/403/500 with that shape). Error response shapes matter for consumers building error handling.

**Note validation constraints at the field level.** `@IsEmail()` means the field must be a valid email. `@Min(1)` means the value must be at least 1. These constraints are part of the contract that consumers must satisfy.

**Track pagination patterns consistently.** If endpoints use pagination, document the pagination parameters (`page`, `limit`, `cursor`, etc.) and the response envelope (`data`, `meta.total`, `meta.nextCursor`, etc.) as part of the contract.

**Flag gaps.** If an endpoint has no documented error responses, note: `MISSING: No error responses documented for [METHOD] [path]`. If a request body DTO has no validation decorators, note: `MISSING: No validation on request body for [METHOD] [path]`. If a response has no defined schema or type, note: `MISSING: No typed response schema for [METHOD] [path]`.
