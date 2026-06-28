---
name: copilot-byok-assistant
description: Use GitHub Copilot CLI with a user-configured BYOK/custom model provider. Use when Codex should consult a local Copilot CLI session through OpenAI-compatible, Anthropic-compatible, or Azure OpenAI-compatible endpoints for second opinions, code review, plan critique, debugging hypotheses, repo exploration, cross-agent test design, blast-radius analysis, or structured multi-agent collaboration without hard-coding provider secrets.
---

# Copilot BYOK Assistant

## Overview

Invoke GitHub Copilot CLI through a custom model provider configured by environment variables. Treat the result as advisory: use it to widen reasoning, then verify claims with local files, commands, tests, or diffs before acting.

This skill is provider-neutral. Do not hard-code provider names, private endpoints, API keys, bearer tokens, local aliases, or machine-specific paths.

For multi-agent work, use Copilot as a constrained reviewer role, not as an authority. Follow the protocol in `references/collaboration-protocol.md` when the task needs structured collaboration, adjudication, or verification gates.

## Quick Start

Configure the provider in the environment or a local `.env` file:

```bash
cp .env.example .env
$EDITOR .env
```

Run a read-only consultation:

```bash
./scripts/run-copilot-byok.sh -p "Review the current git diff for correctness bugs. Do not modify files." --silent
```

Run a structured collaboration preset:

```bash
./scripts/pack-context.sh --status --diff --output /tmp/copilot-context.md
./scripts/run-copilot-byok.sh consult review --context /tmp/copilot-context.md --async --wait-timeout 30
```

Start a long-running consultation without blocking the caller:

```bash
run_id=$(./scripts/run-copilot-byok.sh start -- -p "Review this large refactor. Do not modify files." --silent)
./scripts/run-copilot-byok.sh wait "$run_id" --timeout 25
./scripts/run-copilot-byok.sh status "$run_id"
./scripts/run-copilot-byok.sh logs "$run_id" --tail 80
./scripts/run-copilot-byok.sh result "$run_id"
```

Inspect sanitized configuration:

```bash
./scripts/run-copilot-byok.sh --print-config
```

## Workflow

1. Confirm `copilot` is installed and the provider variables are present:

```bash
./scripts/run-copilot-byok.sh --check
```

2. Use a bounded prompt. Ask for one job: review a diff, critique a plan, identify relevant files, propose tests, or diagnose a failure.

3. Prefer `consult <preset>` for repeatable cross-agent collaboration:

```bash
./scripts/run-copilot-byok.sh consult --list-templates
```

Use `review` for adversarial diff review, `plan-critique` before implementation, `spec-rederive` for ambiguous tasks, `test-design` for independent test ideas, `debug-root-cause` for failures, and `blast-radius` for high-risk changes.

4. Prefer non-interactive `-p` or `consult` calls. Interactive sessions can block automation and are better for a user's own terminal.

5. Verify advisory output independently. Do not let Copilot CLI replace direct evidence. Accept a Copilot finding only after local evidence supports it.

6. Use `start` or `consult --async` plus bounded `wait --timeout` for long tasks so outer agents do not confuse their own wait timeout with Copilot task failure.

7. If a prompt may have caused edits, inspect `git status --short` and relevant diffs immediately.

## Invocation Patterns

Second-opinion review:

```bash
./scripts/run-copilot-byok.sh \
  -p "Review the current git diff for correctness bugs. Return concrete findings with file paths and line hints only. Do not modify files." \
  --silent
```

Plan critique:

```bash
./scripts/run-copilot-byok.sh \
  -p "Critique this implementation plan for missing cases, risky assumptions, and verification gaps: <plan>" \
  --silent
```

Debugging hypothesis:

```bash
./scripts/run-copilot-byok.sh \
  -p "Given this failing command and output, identify likely root causes and the next checks. Do not modify files: <details>" \
  --silent
```

## Safety Rules

- Never commit `.env`, API keys, bearer tokens, private endpoints, internal model names, or machine-specific paths.
- Prefer prompts that explicitly say `Do not modify files` for analysis-only consultations.
- Redact `sk-*`, bearer tokens, and provider URLs when showing diagnostics in public logs.
- Use a fresh Git repository for public release if any private material ever existed in local history.
- Run a secret scan before publishing.

## Resources

- `scripts/run-copilot-byok.sh`: provider-neutral wrapper around `copilot` custom-provider environment variables.
- `scripts/pack-context.sh`: read-only, redacted context packet builder for diffs, status, selected files, and logs.
- `references/collaboration-protocol.md`: role protocol, consultation gates, finding contract, and adjudication rules for multi-agent collaboration. Read it before using Copilot as more than a one-shot advisor.
- `references/prompts/*.md`: prompt presets used by `consult`.
- `references/copilot-cli-byok.md`: detailed variable mapping, examples, troubleshooting, and publication checklist. Read it when configuring providers, debugging setup, or preparing a public release.
