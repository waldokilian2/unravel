---
name: synthesize-security-audit
description: >-
  This skill synthesizes extracted security artifacts into a consolidated security audit
  document. Use this agent when the user asks to generate a security audit, create a security
  assessment, synthesize security findings, audit authentication and authorization, review
  security posture, produce a security report, or mentions /synthesize-security-audit. This is
  a post-extraction command -- it reads files already created by Unravel's extraction pipeline
  and combines them into a single coherent security audit. Do NOT use this skill for extracting
  new artifacts; it only synthesizes existing ones.
user-invocable: true
---

# Security Audit Synthesis

This skill takes three extraction artifact types from Unravel's Interfaces & Security group and weaves them into a single, auditor-readable security audit document. It does not perform any new code analysis -- it reads, cross-references, and synthesizes what the extraction pipeline already produced. The result is a consolidated view of authentication, authorization, external exposure, and infrastructure security with a prioritized findings list.

## Prerequisite Artifacts

All three extraction types must be complete before synthesis can begin. Each must have a `00-INDEX.md` in `docs/output/`.

| Extraction Type | Output Directory | Extraction Group |
|----------------|-----------------|------------------|
| `security-nfrs` | `docs/output/security-nfrs/` | Interfaces & Security |
| `integrations` | `docs/output/integrations/` | Interfaces & Security |
| `api-contracts` | `docs/output/api-contracts/` | Interfaces & Security |

## Execution Flow

### Step 1: Prerequisite Check

Use Glob to verify that each prerequisite index file exists:

```
Glob: docs/output/security-nfrs/00-INDEX.md
Glob: docs/output/integrations/00-INDEX.md
Glob: docs/output/api-contracts/00-INDEX.md
```

If **any** index file is missing, stop immediately and print a message listing all missing extractions:

```
Cannot generate security audit. The following extractions are missing:

- [type] — Run /unravel and select Interfaces & Security
```

Show the message exactly once with all missing types listed, then **STOP**. Do not proceed to synthesis.

### Step 2: Read Input Artifacts

For each extraction type that passed the prerequisite check:

1. **Read the `00-INDEX.md`** to get the list of module files produced by that extraction.
2. **Read each module file** listed in the index.

**Large extraction handling:** If an extraction type has more than 5 module files:
- Read the `00-INDEX.md` first.
- Read all module files for `security-nfrs` (this is the security backbone containing auth, access control, and infrastructure security details).
- For the other types (`integrations`, `api-contracts`), read the index, identify the most significant modules (those with the most artifacts, referenced by security-nfrs, or involving authentication or data exchange), and read those in full. For the remaining modules, use Grep to find specific cross-references (service names, endpoint paths, auth patterns) as needed rather than reading every file.

### Step 3: Cross-Reference and Synthesize

While reading the artifacts, actively cross-reference between them:

- When `api-contracts` lists an endpoint, check `security-nfrs` for authentication requirements and `integrations` for external data exposure through that endpoint.
- When `security-nfrs` describes an authentication mechanism, verify against `api-contracts` that the relevant endpoints are actually protected.
- When `integrations` describes a third-party service, check `security-nfrs` for how that service's credentials are managed and `api-contracts` for any webhook endpoints receiving callbacks from that service.
- When `security-nfrs` flags a `MISSING` item (e.g., no rate limiting on public endpoints), verify against `api-contracts` which public endpoints exist and are affected.
- When `api-contracts` shows an endpoint with no input validation decorators, cross-reference with `security-nfrs` to check if validation is handled at the middleware level instead.

### Step 4: Generate the Security Audit

Write the output to `docs/output/SECURITY-AUDIT.md` using the following structure exactly.

## Output Format

```markdown
# Security Audit

**Generated:** [YYYY-MM-DD]
**Source Artifacts:** security-nfrs, integrations, api-contracts

---

## Authentication

[Synthesize authentication findings from all security-nfrs modules. Describe the mechanism (JWT, OAuth, session-based, etc.), token handling (generation, refresh, expiry, storage), session management, password policies, and multi-factor authentication if present. Write 1-3 paragraphs of prose that gives an auditor a clear picture of how users prove their identity.]

| Aspect | Implementation | Risk Level | Source |
|--------|---------------|------------|--------|
| [auth aspect, e.g. "Token type"] | [how it works, e.g. "JWT with HS256"] | [Low/Medium/High/Critical] | `source-ref` |

[Include a row for each significant authentication aspect: token type, token storage, token expiry, refresh mechanism, password hashing, MFA, etc. If any aspect is missing (e.g., no token expiry configured), flag it with risk level High or Critical.]

---

## Authorization

### Role Model

[From security-nfrs access control sections across all modules: describe the roles defined in the system, their hierarchy (if any), and how permissions are assigned. Write 1-2 paragraphs of prose. If roles are defined in an enum or constant file, reference the source. If role inheritance exists, explain it.]

| Role | Description | Permissions Scope | Source |
|------|-------------|-------------------|--------|
| [role name] | [what this role represents] | [what it can access] | `source-ref` |

### Access Matrix

[Consolidate access matrices from all security-nfrs modules into a unified view. Every endpoint that appears in either security-nfrs or api-contracts should be represented here. Merge entries from multiple modules into a single coherent table. Group related endpoints together (by module or resource).]

| Endpoint Pattern | Methods | Roles | Auth Required | Source |
|-----------------|---------|-------|---------------|--------|
| [path or pattern] | [GET, POST, etc.] | [allowed roles or "Public"] | [Yes/No] | `source-ref` |

### Resource-Level Controls

[From security-nfrs resource-level controls sections: consolidate ownership checks, field-level access, and imperative authorization logic.]

| Resource | Check | Source |
|----------|-------|--------|
| [resource type, e.g. "Post"] | [e.g. "Ownership: user can only edit own posts"] | `source-ref` |

---

## External Exposure

### Third-Party Integrations

[From integrations: consolidate all external service integrations, focusing on the security-relevant aspects -- what data is exchanged, how authentication is handled, and risk level. Every integration from the integrations extraction should appear here.]

| Service | Data Exchanged | Authentication | Risk | Source |
|---------|---------------|----------------|------|--------|
| [service name] | [what data flows in/out] | [API key, OAuth, etc.] | [Low/Medium/High] | `source-ref` |

### API Surface

[From api-contracts: list all endpoints with their security posture. Cross-reference with security-nfrs to verify auth requirements. Flag any endpoint from api-contracts that is not mentioned in security-nfrs access control -- this may indicate an unguarded endpoint.]

| Endpoint | Method | Auth | Input Validation | Risk | Source |
|----------|--------|------|-----------------|------|--------|
| [full path] | [HTTP method] | [Yes/No/Role] | [Present/Missing/Partial] | [risk level] | `source-ref` |

[If api-contracts shows an endpoint with no validation decorators and security-nfrs does not mention middleware-level validation for that endpoint, set Risk to High and note "No input validation detected" in the Input Validation column.]

---

## Infrastructure Security

[From security-nfrs across all modules: consolidate infrastructure-level security measures. For each aspect, describe what exists or flag what is missing.]

| Aspect | Implementation | Source |
|--------|---------------|--------|
| Rate Limiting | [details or "Not detected"] | `source-ref` |
| Input Sanitization | [details or "Not detected"] | `source-ref` |
| Error Handling | [what error information is exposed to clients -- stack traces, generic messages, etc.] | `source-ref` |
| Logging/Audit | [what actions are logged, log level, where logs go] | `source-ref` |
| Encryption | [TLS, at-rest encryption, field-level encryption, password hashing] | `source-ref` |
| CORS | [allowed origins, credentials policy, or "Not configured"] | `source-ref` |
| Security Headers | [Helmet, CSP, HSTS, etc., or "Not detected"] | `source-ref` |

[Add additional rows for any other infrastructure security aspects found in the artifacts. Do not invent rows for aspects that are not mentioned anywhere.]

---

## Findings

### Critical

[Critical findings: authentication bypasses, data exposure to unauthorized parties, unauthenticated access to sensitive endpoints, plaintext secrets, missing auth on admin operations.]

- **[Finding title]:** [Description of the issue, what is affected, and what the impact is.] Source: `source-ref`

### High Priority

[High findings: authorization gaps (role missing from endpoint), missing input validation on endpoints accepting external data, public endpoints without rate limiting, integration without error handling that could leak data.]

- **[Finding title]:** [Description.] Source: `source-ref`

### Medium Priority

[Medium findings: weak policies (short token expiry, no refresh rotation), logging gaps (security events not logged, no audit trail), missing security headers, overly permissive CORS.]

- **[Finding title]:** [Description.] Source: `source-ref`

### Observations

[Lower-priority notes: improvements, best-practice suggestions, areas where the system is well-secured and worth noting positively.]

- **[Observation title]:** [Description.] Source: `source-ref`

[If a severity category has no findings, write "None detected" rather than leaving it empty.]

---

*Generated by Unravel on [timestamp]*
```

## Core Principles

**Cross-reference is the primary value.** The security audit's unique value over reading individual extraction artifacts is the cross-referencing. An endpoint from api-contracts checked against security-nfrs for auth and against integrations for external data exposure is far more valuable than any single artifact alone. Every section should reflect this triangulation.

**Classify findings by severity, not by artifact source.** A finding about missing auth on an endpoint might originate from api-contracts (the endpoint exists) and security-nfrs (no guard mentioned). Classify by impact (Critical/High/Medium/Observation), not by where the information came from.

**Severity classification guide:**

| Severity | Criteria |
|----------|----------|
| Critical | Authentication bypass, sensitive data exposed to unauthorized parties, unauthenticated admin operations, plaintext secrets in code |
| High | Authorization gaps (endpoint accessible by wrong role), missing input validation on externally-facing endpoints, public endpoints without rate limiting, integration without error handling that could leak sensitive data |
| Medium | Weak security policies (short token expiry without refresh, permissive CORS), logging gaps (security events not logged), missing security headers, missing encryption for data at rest |
| Observations | Best-practice improvements, positive patterns worth noting, areas of good security posture |

**Flag missing defenses, not missing features.** The audit evaluates the security posture of what exists. "No rate limiting on public endpoints" is a finding. "No password reset endpoint" is a feature gap, not a security finding (unless the codebase has user accounts but no way to reset passwords, which is a usability issue that could lead to insecure workarounds).

**Only include what exists in the extracted artifacts.** Do not fabricate findings, defenses, or configurations that are not supported by the extraction data. If security-nfrs does not mention CORS, the audit should say "Not detected" or "Not mentioned in extracted artifacts" -- not "No CORS configured" (which assumes it was looked for and found absent). If the artifacts are thin, note limited coverage rather than inflating findings.

**Distinguish between "not detected" and "missing."** "Not detected" means the extraction artifacts do not mention this aspect. "Missing" means the artifacts explicitly flag its absence (e.g., `MISSING: No rate limiting on public endpoints`). Use the artifact's own assessment when available.

**Use source references consistently.** Include compact source references in the format `file:line` or `extraction-type/module-name` to allow stakeholders to trace claims back to the extraction modules. References point to extraction output files (e.g., `security-nfrs/auth.md`, `api-contracts/orders.md`), not to source code directly -- the extraction files themselves contain source code references.

**Preserve access control nuance.** When consolidating access matrices, preserve the distinctions between route-level guards (decorators, middleware) and resource-level checks (imperative ownership verification). Do not flatten these into a single "role required" column -- the access matrix covers route-level, and resource-level controls are their own table.

## Edge Cases

- **Empty extraction directories:** If a `00-INDEX.md` exists but lists zero module files, treat that extraction as present but empty. Note in the relevant section that the extraction produced no artifacts for that type. Proceed with synthesis using only the available data.
- **Single-module projects:** If security-nfrs has only one module, the Authentication and Authorization sections will draw from that single source. Cross-reference with api-contracts and integrations still applies.
- **No external services:** If integrations found no external services, the Third-Party Integrations table should state "No external service integrations detected." Do not omit the section.
- **No endpoints in api-contracts:** If api-contracts found no endpoints, the API Surface table should state "No API endpoints documented." Do not omit the section.
- **Conflicting information:** If two extraction types describe the same endpoint differently (e.g., security-nfrs says JWT required, api-contracts says no auth), report both perspectives in the relevant table and escalate the discrepancy to Critical or High findings.
- **All findings are positive:** If the system appears well-secured with no significant issues, the Findings section should still be populated -- move items to Observations with positive notes about strong security posture.
- **Extractions from different dates:** If the three prerequisite extractions were run on different dates, note the oldest extraction date in the document header and mention in Observations that artifacts may be stale.
