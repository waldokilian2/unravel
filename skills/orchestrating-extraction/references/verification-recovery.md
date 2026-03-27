# Verification Recovery Examples

The following examples illustrate the verification and recovery workflow.

## Example 1: Surgical fix succeeded (automatic recovery)

```
❌ Verification FAILED for module 'payment'
Issues found: 3

🔧 Applying surgical fixes...
   Removed 1 hallucinated rule
   Updated 1 wrong location
   Augmented 1 incomplete rule

✅ Re-verification PASSED for module 'payment'
Proceeding to create index...
```

## Example 2: Surgical fix failed, manual recovery needed

```
❌ Verification FAILED for module 'payment'
Issues found: 5

🔧 Applying surgical fixes...
   Fixed 3 issues
   2 issues remain (complex structural problems)

Recovery options:
1. Re-extract payment module: Agent(unravel-extractor, "...payment...")
2. Manually review and fix the 2 remaining issues in docs/output/business-rules/payment.md
3. Skip payment module and create index with other modules

Which option would you like?
```

## Example 3: Re-verification with fix context

After the fixer completes, re-verification includes context about what was fixed:

```
Agent(unravel-verifier,
       "Verify extraction output

        **DOMAIN KNOWLEDGE:**
        [Business rules skill content embedded here]

        Output File: docs/output/business-rules/payment.md
        Source Files: src/payment/charge.ts, src/payment/refund.ts
        Artifact Type: business-rules

        **RE-VERIFICATION MODE:**
        This output was just fixed. The following issues were addressed:

        Issue 1: [remove] - Line 45: Hallucinated rule about admin requirements
          Action: remove
        Issue 2: [update] - Line 78: Incorrect file location reference
          Action: update
        Issue 3: [augment] - Line 102: Missing validation pattern details
          Action: augment

        **INSTRUCTIONS:**
        1. Focus verification on the fixed items above (specific line numbers)
        2. Confirm each fix was applied correctly
        3. Quick scan for any new issues introduced by the fixes
        4. Report PASSED if fixes are correct, or FAILED with remaining issues")
```

The verifier now knows exactly what to check instead of re-reading the entire file.

## Fixer Output Parsing

The fixer output must include a "Fixes:" section listing each fix applied with line numbers, action type, and description. Parse this format:

```
Fixes:
 - Line 45: Removed hallucinated rule "User must be admin to delete"
 - Line 78: Updated location from src/auth/password.ts:45 to src/auth/validation.ts:23
 - Line 102: Augmented with regex pattern and error message details
```

Map action words to issue types:
- "Removed" → remove (hallucinated)
- "Updated" → update (wrong_location)
- "Augmented" → augment (incomplete)
- "Corrected" → correct (misdescribed)

Pass this parsed context to the re-verifier so it can focus on the specific lines that changed.
