# Codex-Copilot Collaboration Protocol

Use this protocol when Copilot CLI is more than a one-off answer source. The goal is independent, evidence-grounded collaboration between a primary code agent and Copilot CLI.

## Roles

- **Primary agent**: Owns repository inspection, edits, tests, and final judgment.
- **Copilot reviewer**: Gives read-only second opinions, risks, missing tests, and root-cause hypotheses.
- **Evidence**: Files, diffs, logs, commands, tests, and reproducible failures decide disagreements.

## Default Loop

1. **Propose**: Primary agent states the task, constraints, and intended approach.
2. **Critique**: Copilot reviews the plan, diff, failure, or test surface using a prompt preset.
3. **Adjudicate**: Primary agent accepts, rejects, or escalates each finding with evidence.
4. **Verify**: Primary agent runs targeted checks before treating a finding as resolved.

Use at most two critique/adjudication rounds for one concern. If evidence is still inconclusive, escalate to the user with both positions and the missing experiment.

## When to Consult

Consult Copilot when any condition is true:

- The diff is large, cross-cutting, or touches shared contracts.
- The task is ambiguous and could be implemented in more than one meaningfully different way.
- The change touches auth, security, data integrity, billing, migrations, concurrency, or public APIs.
- A test or CI failure survives one fix attempt.
- The primary agent wants independent test ideas before accepting an implementation.

Skip Copilot for trivial mechanical edits, formatting-only changes, or localized changes already covered by strong tests.

## Finding Contract

Ask Copilot to return a single `BEGIN_RESULT` / `END_RESULT` block. Each finding should include:

- severity: `blocker`, `high`, `medium`, `low`, or `question`
- location: file path plus line hint when available
- claim: the concrete risk or defect
- trigger: input, state, or condition that exposes the issue
- evidence_needed: command, test, file inspection, or experiment needed to verify it
- confidence: `0.00` to `1.00`

Primary agents should not fix a Copilot finding until they can reproduce, inspect, or otherwise verify the claim. Unverified claims become watch notes or user questions, not accepted facts.

## Adjudication Rules

- Accept a finding only when local evidence supports it.
- Reject a finding with a concrete reason, such as an existing test, contract, or code path that contradicts it.
- Convert unclear findings into targeted experiments.
- Do not let agent consensus replace tests or source evidence.
- Do not paste Copilot's suggested code blindly. Re-derive the fix locally and verify it.

## Context Packet

Use `scripts/pack-context.sh` to give Copilot bounded, redacted evidence:

```bash
./scripts/pack-context.sh --status --diff --output /tmp/copilot-context.md
./scripts/run-copilot-byok.sh consult review --context /tmp/copilot-context.md --async --wait-timeout 30
```

Context packets should be smaller than the model budget, include only relevant evidence, and avoid secrets. The packer redacts common keys and tokens, but the primary agent is still responsible for not sending private data that should not leave the machine or provider boundary.

## Timeout Contract

Use `wait --timeout` as the outer agent's patience budget. It must not be treated as Copilot failure. Use `--max-wall` and `--idle-timeout` on `start` or `consult --async` as the real task lifetime controls.
