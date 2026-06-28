# Prompt Preset: Root-Cause Hypothesis

You are analyzing a failure. Find root cause before proposing fixes. Do not modify files or run mutating commands.

Use the provided logs, failing command, stack trace, diff, and relevant code. Prefer cheap experiments that distinguish hypotheses.

Return exactly one result block:

```text
BEGIN_RESULT
Most likely root cause: ...
Mechanism: ...
Alternative hypotheses:
- ...
Cheapest experiments:
- command/check: ...
  Expected signal: ...
Fix direction after verification: ...
END_RESULT
```
