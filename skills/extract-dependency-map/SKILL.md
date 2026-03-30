---
name: extract-dependency-map
description: This skill provides domain knowledge for extracting dependency maps and architecture overviews from code. It should be used when the agent is tasked with documenting module dependencies, package versions, internal service boundaries, shared libraries, import graphs, or system architecture structure. Make sure to use this skill whenever the dependency structure and architectural layout of the system needs to be understood, including module coupling, circular dependencies, and package management files.
user-invocable: false
---

# Dependency Map Extraction

Dependency maps capture how the system is structured and how its parts connect — the "what depends on what?" They document the architectural layout that developers need to understand before making changes safely.

## What to Extract

Dependency maps reveal the system's internal structure:
- **Package dependencies** — `package.json`, `requirements.txt`, `go.mod`, `pom.xml`, `Cargo.toml`, `Gemfile`
- **Internal module imports** — Which source modules import which other source modules
- **Service boundaries** — In monorepos or microservices, which directories are independent services
- **Shared libraries** — Common utilities, shared packages, internal SDKs consumed by multiple modules
- **Circular dependencies** — Module A imports B which imports A (flag as architectural concern)
- **External library usage** — Which third-party libraries are used and where
- **Build/compile dependencies** — Dev dependencies, build tools, type generators
- **Monorepo workspace structure** — `pnpm-workspace.yaml`, `lerna.json`, `nx.json`, Turborepo config

## Where Dependency Maps Live (vs. Other Types)

- **Dependency map vs. integration:** An outbound HTTP call to Stripe is an *integration* (external service the system talks to at runtime). The *npm package* `stripe` in `package.json` is a *dependency*. The *architectural coupling* between the payment module and the orders module is a *dependency map*. Document external service connections in integrations; document structural coupling here.
- **Dependency map vs. config/env:** The `DATABASE_URL` environment variable is *config/env*. The `pg` npm package that uses it is a *dependency*.
- **Dependency map vs. data specs:** A Prisma schema defining a model is a *data spec*. The `@prisma/client` package in `package.json` is a *dependency*.

## Hotspot Discovery

Use the Glob and Grep tools to find dependency information:

```
Glob:  package.json
Glob:  requirements.txt
Glob:  go.mod
Glob:  pom.xml
Glob:  Cargo.toml
Glob:  Gemfile
Glob:  pnpm-workspace.yaml
Glob:  lerna.json
Glob:  nx.json
Glob:  turbo.json
Grep:  pattern="^import\s+.*from\s+['\"]" type=ts,js output_mode=files_with_matches
Grep:  pattern="^from\s+|^import\s+" type=py output_mode=files_with_matches
Grep:  pattern="^import\s+\(^\)" type=go output_mode=files_with_matches
```

**Prioritize:** Start with package manager files (package.json, go.mod, etc.) for external dependencies. Then analyze import statements to map internal module coupling.

## Pattern Signals

| Code Pattern | Dependency |
|--------------|-----------|
| `"stripe": "^14.0.0"` in package.json | External dependency: stripe@^14.0.0 |
| `import { UserService } from '../user/user.service'` | Internal dependency: orders → user |
| `"@workspace/shared": "workspace:*"` | Internal shared library |
| `import { EventBus } from '@app/events'` | Cross-module dependency: → events module |
| `"workspaces": ["packages/*", "apps/*"]` | Monorepo workspace structure |
| `// @ts-ignore` (circular import workaround) | Potential circular dependency flag |

## Output Format

**Per-module extractor output:**
```markdown
# [Module Name] Module

Extraction: [YYYY-MM-DD]
Files Analyzed: [N] files

## Artifacts

### External Dependencies
| Package | Version | Purpose | Type | Source |
|---------|---------|---------|------|--------|
| [package name] | [version] | [what it's used for] | [runtime/dev] | `package.json` |

### Internal Dependencies (Imported From)
| Depends On | Modules | Import Count | Source |
|------------|---------|--------------|--------|
| [module name] | [specific files] | [N imports] | `filename.ts:5` |

### Internal Dependencies (Imported By)
| Consumed By | Modules | Import Count | Source |
|-------------|---------|--------------|--------|
| [module name] | [specific files] | [N imports] | `filename.ts:10` |

### Circular Dependencies (if any)
| Module A | Module B | Source |
|----------|----------|--------|
| [module] | [module] | `file:line evidence` |

### Service Boundaries (if applicable)
| Service | Directory | Description |
|---------|-----------|-------------|
| [service name] | [path] | [what it does] |

## Sources
| Ref | Full Path |
|-----|-----------|
| `package.json` | [package.json](package.json) |
| `src/orders/orders.service.ts:5` | [src/orders/orders.service.ts:5](src/orders/orders.service.ts#L5) |
```

**Example:**
```markdown
## Root Project

### External Dependencies
| Package | Version | Purpose | Type | Source |
|---------|---------|---------|------|--------|
| @nestjs/core | ^10.0.0 | Application framework | runtime | `package.json` |
| @nestjs/typeorm | ^10.0.0 | ORM integration | runtime | `package.json` |
| stripe | ^14.0.0 | Payment processing | runtime | `package.json` |
| typescript | ^5.3.0 | Language compiler | dev | `package.json` |
| jest | ^29.0.0 | Testing framework | dev | `package.json` |

### Internal Dependencies (Imported From)
| Depends On | Modules | Import Count | Source |
|------------|---------|--------------|--------|
| @app/shared | Logger, validators, types | 24 imports | Multiple files |
| @app/events | EventBus, event types | 8 imports | Multiple files |

### Internal Dependencies (Imported By)
| Consumed By | Modules | Import Count | Source |
|-------------|---------|--------------|--------|
| @app/shared | orders, auth, payments, notifications | 24 imports | Multiple files |

### Circular Dependencies
| Module A | Module B | Source |
|----------|----------|--------|
| orders | notifications | orders imports notifications, notifications imports orders.events |

### Service Boundaries
| Service | Directory | Description |
|---------|-----------|-------------|
| API Gateway | apps/api/ | Main HTTP server |
| Payment Worker | apps/payment-worker/ | Background payment processing |
| Shared Utils | packages/shared/ | Common utilities used by all services |

## Sources
| Ref | Full Path |
|-----|-----------|
| `package.json` | [package.json](package.json) |
```

## Core Principles

**Distinguish external from internal dependencies.** External dependencies (npm packages, Python packages) come from outside the project. Internal dependencies are imports between modules within the project. Both matter, but they answer different questions.

**Focus on coupling, not just listing.** A dependency map is more useful when it shows *how tightly coupled* modules are. "Module A imports 15 things from Module B" is more actionable than "Module A imports from Module B."

**Flag circular dependencies.** Circular imports are an architectural smell. If A imports B and B imports A, document it. This tells analysts where refactoring may be needed and where extension could be risky.

**Identify shared libraries.** Modules consumed by many other modules (like `@app/shared` or `utils/`) are high-impact change areas. Modifying them affects many parts of the system.

**Map service boundaries in monorepos.** If the project is a monorepo, identify which directories are independent services vs. shared packages. This is essential for understanding deployment architecture and change blast radius.

**Flag gaps.** If a module has no test files but imports many external dependencies, note: `MISSING: No test files for [module] with [N] external dependencies`. If an external dependency has no version constraint (e.g., `"*"` or latest), note: `MISSING: Unpinned dependency [package] — version could break at any time`. If there are no shared libraries but significant code duplication across modules, note: `MISSING: Potential shared library — duplicated patterns across modules`.
