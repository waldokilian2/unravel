---
description: Verify an extracted artifact file for accuracy and completeness
---

Verify an extraction output file against its source code.

## Usage

```
/verify <output-file> [artifact-type]
```

### Arguments

| Argument | Required | Description | Example |
|----------|----------|-------------|---------|
| `output-file` | Yes | Path to the extraction output to verify | `docs/output/business-rules.md` |
| `artifact-type` | No | Auto-detected from filename if omitted | `business-rules` |

### Examples

```
/verify docs/output/business-rules.md
/verify docs/output/business-rules.auth.tmp.md
/verify docs/output/process-flows.md process-flows
```

## What Gets Verified

The verifier agent cross-checks the output file against the source code:

- **Accuracy:** Artifacts exist in source code (no hallucinations)
- **Source locations:** File:line references are correct
- **Semantics:** Descriptions match what the code actually does
- **Completeness:** All claimed artifacts were extracted
- **Boundaries:** No artifacts from files outside the specified scope

## Supported Files

You can verify both:
- **Final merged files:** `docs/output/[artifact-type].md`
- **Intermediate temp files:** `docs/output/[artifact-type].[module].tmp.md`

## Output

The verifier reports either:
- **PASSED** - All artifacts verified accurate
- **FAILED** - List of specific issues found (with severity levels)
