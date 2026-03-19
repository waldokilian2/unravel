---
name: orchestrating-verification
description: Use when verifying extracted artifacts - coordinates two-stage review (spec compliance + quality) across multiple outputs
---

# Orchestrating Verification

## Overview

Coordinate two-stage verification of extracted artifacts: Stage 1 (spec compliance - all patterns extracted?) and Stage 2 (quality - accurate, no hallucinations?).

**Core principle:** Verify before trusting. Two-stage review ensures completeness and accuracy.

**Announce at start:** "I'm using the orchestrating-verification skill to verify this extraction."

## When to Use

**Use when:**
- Orchestrated extraction just completed
- Multiple output files need verification
- User explicitly requests verification
- `/verify` command invoked

**Two-stage review process:**
- Stage 1: Spec compliance (all requested patterns extracted?)
- Stage 2: Quality review (accurate, no hallucinations?)

## The Process

### Step 1: Identify Outputs to Verify

Find all extraction outputs:
- docs/output/business-rules.md
- docs/output/process-flows.md
- docs/output/data-specs.md
- docs/output/user-stories.md
- docs/output/security-nfrs.md
- docs/output/integrations.md

### Step 2: Stage 1 - Spec Compliance Review

For each output file, dispatch spec compliance reviewer:

```markdown
Task("Review spec compliance for [artifact type] extraction")

Review:
- All patterns in scope extracted?
- No artifacts outside scope?
- Output format followed?
- Source locations accurate?
```

**Spec compliance review checks:**
- Completeness: All patterns in scope captured
- Boundaries: No artifacts outside scope
- Format: Output template followed
- Accuracy of claims: Counts and locations match

**If issues found:**
- Document missing/extra/inaccurate items
- Re-extract with guidance if needed
- Re-review until passes

### Step 3: Stage 2 - Quality Review

**Only after Stage 1 passes for all outputs.**

For each output file, dispatch quality reviewer:

```markdown
Task("Review quality for [artifact type] extraction")

Review:
- Each artifact matches actual code?
- No hallucinations?
- Clear, well-documented?
```

**Quality review checks:**
- Accuracy: Each artifact verified against source code
- No hallucinations: Every artifact exists in code
- Quality: Clear descriptions, appropriate detail, well-structured

**If issues found:**
- Document inaccurate/hallucinated/poor quality items
- Re-extract with guidance if needed
- Re-review until passes

### Step 4: Final Report

Generate verification report:

```markdown
## Verification Report: [Artifact Types]

**Date:** [YYYY-MM-DD]

### Summary
- Files verified: [count]
- Spec compliance: ✅ All passed / ❌ Issues found
- Quality review: ✅ All passed / ❌ Issues found

### Stage 1: Spec Compliance
[Per-file results]

### Stage 2: Quality Review
[Per-file results]

### Issues Found (if any)
[Detailed list with file:line references]

### Recommendation
✅ Approved for use / ❌ Requires fixes
```

## Example Workflow

**Context:** Orchestrated extraction just completed

**Outputs to verify:**
- docs/output/business-rules.md (75 rules)
- docs/output/process-flows.md (30 flows)

**Step 1: Spec Compliance Review**
```
Task("Review spec compliance for business-rules")
→ 75 rules found, all in scope, format correct ✅

Task("Review spec compliance for process-flows")
→ 28 flows found, 2 missing ❌
→ Re-extract missing flows
→ Re-review: 30 flows found, all in scope ✅
```

**Step 2: Quality Review**
```
Task("Review quality for business-rules")
→ All verified against source, no hallucinations ✅

Task("Review quality for process-flows")
→ 1 flow description unclear, 1 source location wrong ❌
→ Fix descriptions and locations
→ Re-review: All accurate and clear ✅
```

**Step 3: Final Report**
```
## Verification Report

Files verified: 2
Spec compliance: ✅ All passed
Quality review: ✅ All passed

Recommendation: ✅ Approved for use
```

## Red Flags

**Never:**
- Run quality review before spec compliance passes
- Skip re-review after fixes are made
- Trust extraction output without verification
- Verify only some outputs (verify all)
- Proceed with known issues

**Always:**
- Run Stage 1 (spec compliance) first
- Run Stage 2 (quality) only after Stage 1 passes
- Re-review after any fixes
- Verify all extracted outputs
- Document all issues found

## Reviewer Agents

**Stage 1: Spec Compliance**
- unravel:spec-compliance-reviewer
  - Verifies: All patterns extracted, boundaries respected, format followed

**Stage 2: Quality**
- unravel:quality-reviewer
  - Verifies: Accurate, no hallucinations, well-documented

## Integration

**Used with:**
- **unravel:orchestrating-extractions** - After extraction completes
- **unravel:dispatching-parallel-extractors** - After parallel extraction completes
- **Direct extraction skills** - After any extraction (optional verification)

**Commands:**
- `/verify` - Trigger this verification skill

## Severity Levels

**Critical Issues** (must fix before approval):
- Missing patterns that were in scope
- Hallucinated artifacts that don't exist
- Wrong source locations

**Important Issues** (should fix):
- Missing edge cases
- Unclear descriptions
- Format inconsistencies

**Minor Issues** (optional to fix):
- Formatting improvements
- Additional detail would help
- Better organization possible
