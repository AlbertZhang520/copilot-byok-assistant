# Copilot CLI BYOK Reference

## Purpose

Use this reference when configuring GitHub Copilot CLI to route through a custom model provider. Keep provider details outside the skill and outside Git history.

## Environment Variables

This skill accepts `COPILOT_BYOK_*` variables and maps them to the native `COPILOT_PROVIDER_*` variables used by Copilot CLI.

| Portable variable | Native Copilot CLI variable | Required | Notes |
| --- | --- | --- | --- |
| `COPILOT_BYOK_BASE_URL` | `COPILOT_PROVIDER_BASE_URL` | Yes | Custom provider endpoint URL. |
| `COPILOT_BYOK_TYPE` | `COPILOT_PROVIDER_TYPE` | No | `openai`, `anthropic`, or `azure`. Defaults to `openai`. |
| `COPILOT_BYOK_API_KEY` | `COPILOT_PROVIDER_API_KEY` | Usually | Use for API-key providers. |
| `COPILOT_BYOK_BEARER_TOKEN` | `COPILOT_PROVIDER_BEARER_TOKEN` | No | Takes precedence over API key when set. |
| `COPILOT_BYOK_MODEL` | `COPILOT_MODEL` | Yes | Simple model selector. |
| `COPILOT_BYOK_MODEL_ID` | `COPILOT_PROVIDER_MODEL_ID` | No | Base model ID for agent config and token limits. |
| `COPILOT_BYOK_WIRE_MODEL` | `COPILOT_PROVIDER_WIRE_MODEL` | No | Model/deployment name sent to provider. |
| `COPILOT_BYOK_WIRE_API` | `COPILOT_PROVIDER_WIRE_API` | No | `completions` or `responses`. |
| `COPILOT_BYOK_MAX_PROMPT_TOKENS` | `COPILOT_PROVIDER_MAX_PROMPT_TOKENS` | No | Override prompt token limit. |
| `COPILOT_BYOK_MAX_OUTPUT_TOKENS` | `COPILOT_PROVIDER_MAX_OUTPUT_TOKENS` | No | Override output token limit. |

## Examples

OpenAI-compatible endpoint:

```bash
COPILOT_BYOK_TYPE=openai
COPILOT_BYOK_BASE_URL=https://your-provider.example.com/v1
COPILOT_BYOK_API_KEY=your-api-key-here
COPILOT_BYOK_MODEL=your-model-name
```

Anthropic-compatible endpoint:

```bash
COPILOT_BYOK_TYPE=anthropic
COPILOT_BYOK_BASE_URL=https://api.example.com
COPILOT_BYOK_API_KEY=your-api-key-here
COPILOT_BYOK_MODEL=claude-model-name
```

Azure OpenAI endpoint:

```bash
COPILOT_BYOK_TYPE=azure
COPILOT_BYOK_BASE_URL=https://your-resource.openai.azure.com
COPILOT_BYOK_API_KEY=your-azure-openai-key
COPILOT_BYOK_MODEL_ID=gpt-4
COPILOT_BYOK_WIRE_MODEL=your-deployment-name
```

## Prompt Patterns

Read-only code review:

```text
Review the current git diff for correctness bugs. Do not modify files or run mutating commands. Return only concrete findings with file paths and line hints.
```

Plan critique:

```text
Critique this implementation plan for the current repository. Return missing cases, risky assumptions, and concrete verification steps. Do not modify files.
```

Debugging:

```text
Given this failing command and output, identify likely root causes and the next checks. Do not modify files.
```

## Long-Running Tasks

Use async mode when the caller may stop waiting before Copilot CLI finishes.

```bash
run_id=$(./scripts/run-copilot-byok.sh start -- -p "Review this large change. Do not modify files." --silent)
./scripts/run-copilot-byok.sh wait "$run_id" --timeout 25
./scripts/run-copilot-byok.sh status "$run_id"
./scripts/run-copilot-byok.sh logs "$run_id" --tail 80
```

Commands:

- `start`: create a run directory, launch Copilot CLI under a supervisor, print `run_id`, and return immediately.
- `status <run_id>`: print machine-readable state, elapsed time, idle time, reason, and exit code.
- `wait <run_id> --timeout N`: wait for up to `N` seconds. If the run is still active, return `state=running` without killing it.
- `logs <run_id>`: print stdout; add `--stderr` or `--events` for other logs.
- `cancel <run_id>`: terminate the Copilot process group and mark the run as cancelled.
- `list`: show recent runs.

Timeouts:

- `--max-wall N` on `start`: hard wall-clock cap. Default: `600` seconds. Terminal state: `timed_out`, exit code `125`.
- `--idle-timeout N` on `start`: no-output timeout. Default: `120` seconds. Terminal state: `idle_timeout`, exit code `124`.
- `wait --timeout N`: caller wait budget only. It does not cancel the run.

Run files are stored under `.copilot-byok/runs/<run_id>/` by default. Set `COPILOT_BYOK_RUNS_DIR` to override this location.

## Troubleshooting

Run:

```bash
./scripts/run-copilot-byok.sh --check
./scripts/run-copilot-byok.sh --print-config
./scripts/run-copilot-byok.sh list
copilot help providers
copilot help environment
```

Common issues:

- Missing `copilot`: install GitHub Copilot CLI and ensure it is on `PATH`.
- Missing base URL: set `COPILOT_BYOK_BASE_URL` or `COPILOT_PROVIDER_BASE_URL`.
- Missing model: set `COPILOT_BYOK_MODEL`, `COPILOT_MODEL`, or `COPILOT_PROVIDER_MODEL_ID`.
- Provider rejects model name: set `COPILOT_BYOK_MODEL_ID` to a well-known base model and `COPILOT_BYOK_WIRE_MODEL` to the provider deployment name.

## Publication Checklist

Before publishing a repository:

1. Confirm `.env` is ignored.
2. Search for secrets and private endpoints in the working tree.
3. Search Git history if the repository has prior commits.
4. Prefer a fresh repository if any private values were ever committed.
5. Keep examples generic and provider-neutral.
