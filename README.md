# Unravel

Unravel the mysteries in your code. Automatic business artifact extraction from source code - understand what any system does by reading what it's built from.

## Installation

```bash
/plugin marketplace add waldokilian2/unravel-marketplace
/plugin install unravel@unravel-marketplace
```

## Usage

Simply open any codebase and start asking questions. The plugin automatically triggers when relevant patterns are detected.

### Example Usage

```
You: What are the business rules in this codebase?
Claude: [automatically uses extract-business-rules skill]
```

```
You: Analyze the payment flow
Claude: [automatically uses extract-process-flows skill]
```

### Manual Invocation

You can also invoke specific skills:

```
You: Use extract-data-specs to analyze the models
```

### Output

All extracted artifacts are saved to `docs/output/`:

- business-rules.md
- process-flows.md
- data-specs.md
- user-stories.md
- security-nfrs.md
- integrations.md

### Verification

After extraction, verify accuracy:

```
You: Verify the business rules output
Claude: [dispatches verification-agent]
```
