---
name: extract-test-coverage
description: This skill provides domain knowledge for extracting test coverage analysis from code. It should be used when the agent is tasked with documenting test suites, mapping tests to business rules or features, identifying coverage gaps, cataloging test types (unit, integration, e2e), or analyzing what mocked dependencies reveal about the system. Make sure to use this skill whenever the test landscape of the system needs to be understood, including what's tested, what's not, test organization, and what tests reveal about requirements.
user-invocable: false
---

# Test Coverage Extraction

Test coverage analysis captures what the codebase's tests actually verify — the "what do we have tests for, and what's missing?" It documents the test landscape that QA teams and analysts need to understand quality and find requirements gaps.

## What to Extract

Test coverage analysis maps the testing landscape:
- **Test descriptions mapped to features** — What each test file/describe block covers in business terms
- **Test types per module** — Unit, integration, e2e, smoke tests per area of the system
- **Coverage gaps** — Modules or features with no corresponding tests
- **Mocked dependencies** — What external services are mocked in tests (reveals what the system considers "external")
- **Test data and fixtures** — Key test data patterns that reveal expected system behavior
- **Edge cases tested** — Boundary conditions, error scenarios, and negative tests
- **Test infrastructure** — Test setup, fixtures, factories, helpers, test databases

## Where Test Coverage Lives (vs. Other Types)

- **Test coverage vs. business rule:** A business rule says "orders under $50 are rejected." A test that asserts this (`expect(createOrder({total: 49})).toThrow(MinOrderError)`) documents that this rule *is tested*. The rule itself is a *business rule*; whether it has test coverage is *test coverage*.
- **Test coverage vs. process flow:** A process flow shows the registration sequence. A test for registration (`describe('register user')`) confirms that flow *is tested*. Document the flow in process-flows; document the test existence here.
- **Test coverage vs. error catalog:** An error class definition is an *error catalog*. A test that verifies the error response format is *test coverage* of that error.

## Hotspot Discovery

Use the Glob and Grep tools to find test files:

```
Glob:  **/*.spec.{ts,js,py,go,java}
Glob:  **/*.test.{ts,js,py,go,java}
Glob:  **/*.e2e-spec.{ts,js}
Glob:  **/*.integration.{ts,js,py}
Glob:  **/__tests__/**/*.{ts,js,py}
Glob:  **/test/**/*.{ts,js,py}
Glob:  **/tests/**/*.{ts,js,py}
Grep:  pattern="describe\(|it\(|test\(|context\(" type=ts,js,py output_mode=files_with_matches
Grep:  pattern="jest\.mock|vi\.mock|mock\(|@MockBean|MockMvc" type=ts,js,java,py output_mode=files_with_matches
Grep:  pattern="beforeEach|beforeAll|setup|setUp|@BeforeEach" type=ts,js,py,java output_mode=files_with_matches
```

**Prioritize:** Start by mapping test files to source files. Then examine describe/it blocks for feature coverage. Finally check for modules that have no corresponding test files.

## Pattern Signals

| Code Pattern | Test Coverage Detail |
|--------------|---------------------|
| `describe('UserService')` | Test suite for UserService |
| `it('should reject orders under $50')` | Business rule test: min order amount |
| `jest.mock('../stripe')` | External dependency mocked: Stripe |
| `test('register returns 201 with user')` | Happy path test for registration |
| `it('throws UnauthorizedError for expired tokens')` | Error scenario test |
| `beforeEach(() => setupTestDB())` | Integration test (uses test DB) |
| `describe('POST /orders', () => { ... })` | API endpoint test |

## Output Format

**Per-module extractor output:**
```markdown
# [Module Name] Module

Extraction: [YYYY-MM-DD]
Files Analyzed: [N] files

## Artifacts

### Test Suites
| Suite | Source File | Tests | Type | Source |
|-------|-------------|-------|------|--------|
| [suite name] | [test file path] | [N tests] | [unit/integration/e2e] | `test-file.ts:1` |

### Test-to-Feature Mapping
| Test Description | Feature/Rule Tested | Source |
|------------------|--------------------|--------|
| [test it/describe text] | [what business rule or feature] | `test-file.ts:10` |

### Mocked Dependencies
| Mock | What It Replaces | Mock Files | Source |
|------|-----------------|------------|--------|
| [mock name] | [real service/module] | [mock file] | `test-file.ts:5` |

### Coverage Gaps
| Source Module | Expected Tests | Has Tests | Gap |
|---------------|---------------|-----------|-----|
| [source file/module] | [what should be tested] | [yes/no] | [description of gap] |

## Sources
| Ref | Full Path |
|-----|-----------|
| `src/orders/orders.service.spec.ts:1` | [src/orders/orders.service.spec.ts:1](src/orders/orders.service.spec.ts#L1) |
| `src/orders/orders.service.spec.ts:15` | [src/orders/orders.service.spec.ts:15](src/orders/orders.service.spec.ts#L15) |
```

**Example:**
```markdown
## orders Module

### Test Suites
| Suite | Source File | Tests | Type | Source |
|-------|-------------|-------|------|--------|
| OrderService | src/orders/orders.service.spec.ts | 12 | unit | `orders.service.spec.ts:1` |
| OrderController | src/orders/orders.controller.spec.ts | 8 | unit | `orders.controller.spec.ts:1` |
| Orders API | test/orders-api.e2e-spec.ts | 5 | e2e | `orders-api.e2e-spec.ts:1` |

### Test-to-Feature Mapping
| Test Description | Feature/Rule Tested | Source |
|------------------|--------------------|--------|
| should create order with valid items | Business rule: order creation | `orders.service.spec.ts:15` |
| should reject order under minimum amount | Business rule: $50 minimum | `orders.service.spec.ts:30` |
| should apply coupon discount | Business rule: coupon validation | `orders.service.spec.ts:45` |
| should return 201 with order data | API contract: POST /orders response | `orders.controller.spec.ts:12` |
| should handle concurrent stock checks | NFR: race condition handling | `orders.service.spec.ts:60` |
| should cancel expired orders | Business rule: 48h expiry | `orders.service.spec.ts:72` |

### Mocked Dependencies
| Mock | What It Replaces | Source |
|------|-----------------|--------|
| PaymentService | Stripe payment processing | `orders.service.spec.ts:3` |
| NotificationService | Email/push notifications | `orders.service.spec.ts:4` |
| InventoryService | Stock checking/reservation | `orders.service.spec.ts:5` |

### Coverage Gaps
| Source Module | Expected Tests | Has Tests | Gap |
|---------------|---------------|-----------|-----|
| src/orders/order-export.job.ts | Export pipeline, CSV generation | no | No tests for batch export job |
| src/orders/cancellation.service.ts | Order cancellation rules | no | Cancellation logic untested |

## Sources
| Ref | Full Path |
|-----|-----------|
| `src/orders/orders.service.spec.ts:1` | [src/orders/orders.service.spec.ts:1](src/orders/orders.service.spec.ts#L1) |
| `src/orders/orders.service.spec.ts:15` | [src/orders/orders.service.spec.ts:15](src/orders/orders.service.spec.ts#L15) |
| `src/orders/orders.service.spec.ts:30` | [src/orders/orders.service.spec.ts:30](src/orders/orders.service.spec.ts#L30) |
| `src/orders/orders.service.spec.ts:45` | [src/orders/orders.service.spec.ts:45](src/orders/orders.service.spec.ts#L45) |
| `src/orders/orders.service.spec.ts:60` | [src/orders/orders.service.spec.ts:60](src/orders/orders.service.spec.ts#L60) |
| `src/orders/orders.service.spec.ts:72` | [src/orders/orders.service.spec.ts:72](src/orders/orders.service.spec.ts#L72) |
| `src/orders/orders.service.spec.ts:3` | [src/orders/orders.service.spec.ts:3](src/orders/orders.service.spec.ts#L3) |
| `src/orders/orders.service.spec.ts:4` | [src/orders/orders.service.spec.ts:4](src/orders/orders.service.spec.ts#L4) |
| `src/orders/orders.service.spec.ts:5` | [src/orders/orders.service.spec.ts:5](src/orders/orders.service.spec.ts#L5) |
```

## Core Principles

**Map tests to business meaning, not code.** "Test line 42 of service.ts" is not useful. "Tests that orders under $50 are rejected (business rule: minimum order amount)" is what analysts need. Read the test assertions and describe what business scenario they verify.

**Identify coverage gaps by cross-referencing.** Compare the list of source modules against the list of test files. Any source module without a corresponding test file is a coverage gap. Within test files, compare `describe`/`it` blocks against known business rules and user stories to find untested scenarios.

**Analyze mocks to reveal architecture.** What a test mocks tells you what the system considers an external boundary. If every test mocks `PaymentService`, that's a clear module boundary. If tests mock the database, the system treats the DB as external (good). This indirectly documents the system's architecture.

**Distinguish test types.** Unit tests (mock everything, test one function), integration tests (real DB, real HTTP), and e2e tests (full stack) provide different confidence levels. Knowing the mix helps assess overall quality.

**Note edge cases and negative tests.** Tests for error scenarios, boundary conditions, and invalid inputs are often the most valuable for understanding requirements. These tests encode "what should NOT happen" — information that's critical for writing accurate specifications.

**Flag gaps.** If a source module has no test file at all, note: `MISSING: No tests for [module]`. If a test suite has only happy-path tests with no error/boundary tests, note: `MISSING: No negative tests for [suite]`. If a business rule or user story has no corresponding test coverage, note: `MISSING: No test for [rule/story]`.
