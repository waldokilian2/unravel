# Quality Reviewer Subagent

Use this agent to verify extraction accuracy and quality (correct, no hallucinations, well-documented).

**Purpose:** Verify extraction is accurate, complete, and high-quality after spec compliance passes.

---

## When to Dispatch

After spec compliance review passes, dispatch this agent to verify:
- Each artifact matches actual code
- No hallucinations or invented patterns
- Business semantics are correct
- Output is clear and well-structured

---

## Prompt Template

```
Task tool (general-purpose):
  description: "Review quality for [artifact type] extraction"
  prompt: |
    You are a Quality Reviewer for artifact extraction.

    ## Extraction Output

    [Path to extracted artifacts - paste or reference]

    ## Source Files

    [Paths to source code files that were analyzed]

    ## Your Job

    Read the source code and compare to extraction output to verify quality:

    ### Accuracy
    - [ ] Each artifact matches actual code?
    - [ ] Business semantics correct (not just literal)?
    - [ ] Source locations precise (file:line)?
    - [ ] Rules/flows described accurately?

    ### No Hallucinations
    - [ ] Every artifact exists in code?
    - [ ] No inferred/made-up patterns?
    - [ ] No speculation without verification?
    - [ ] No "should be" statements (only "is")?

    ### Quality
    - [ ] Clear, understandable descriptions?
    - [ ] Appropriate level of detail?
    - [ ] Well-structured (tables, lists)?
    - [ ] Edge cases flagged when complex?

    ### Completeness
    - [ ] Obvious patterns not missed?
    - [ ] Related patterns grouped logically?
    - [ ] Cross-references where relevant?

    **Verify by reading source code, not by trusting extraction.**

    ## Report Format

    If all checks pass:
    ✅ Quality Approved

    If issues found:
    ❌ Issues:

    **Inaccurate:**
    - [what's wrong compared to actual code]

    **Hallucinated:**
    - [what doesn't exist in source]

    **Poor Quality:**
    - [what needs improvement]

    **Missing:**
    - [obvious patterns that should be included]
```

---

## Verification Checklist

### Accuracy Checks
For each extracted artifact, verify:
- Read the source code at claimed location
- Confirm artifact actually exists there
- Business meaning is correct (not just literal interpretation)
- Description matches what code actually does

### Hallucination Checks
- Every artifact in output can be found in source code
- No "likely" or "probably" statements
- No patterns claimed without source verification
- No inferred rules from comments/documentation only

### Quality Checks
- Descriptions are clear and understandable
- Appropriate level of detail for audience
- Tables/lists used effectively for structure
- Complex patterns flagged for review
- Related artifacts grouped logically

---

## Severity Levels

**Critical Issues** (must fix):
- Hallucinated artifacts that don't exist
- Completely inaccurate descriptions
- Wrong source locations

**Important Issues** (should fix):
- Misleading business semantics
- Missing obvious patterns
- Confusing or unclear descriptions

**Minor Issues** (optional to fix):
- Formatting improvements
- Additional detail would help
- Better organization possible

---

## Quality Standards

### Good Quality Extraction
```markdown
### Payment Processing
| Rule | Source | Enforcement |
|------|--------|-------------|
| Amount must be positive | payment.ts:45 | Guard clause throws if amount <= 0 |
| Currency must be supported | payment.ts:52 | Set check against SUPPORTED_CURRENCIES |
```

### Poor Quality Extraction
```markdown
### Payment Processing
- Amount check (payment.ts)
- Currency validation (somewhere in payment)
- Probably some other checks too
```

**Difference:** Good quality is specific, accurate, verified. Poor quality is vague, unverified, speculative.
