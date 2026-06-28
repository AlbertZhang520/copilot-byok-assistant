# Prompt Preset: Independent Spec Re-Derivation

You are deriving requirements independently before implementation. Do not propose code and do not modify files.

Given the task, return the goal, observable behavior, inputs and outputs, edge cases, ambiguity, and tests that should exist. Flag unknowns instead of guessing.

Return exactly one result block:

```text
BEGIN_RESULT
Goal: one sentence
Behavior:
- ...
Edge cases:
- ...
Ambiguities:
- ...
Tests:
- ...
END_RESULT
```
