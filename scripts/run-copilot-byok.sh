#!/usr/bin/env bash
set -euo pipefail
set +x

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_dir="$(cd "${script_dir}/.." && pwd)"

if [[ -f "${repo_dir}/.env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "${repo_dir}/.env"
  set +a
fi

redact() {
  sed -E \
    -e 's#(BASE_URL=)[^[:space:];]+#\1<configured>#g' \
    -e 's/(API_KEY=).+/\1<redacted>/g' \
    -e 's/(BEARER_TOKEN=).+/\1<redacted>/g' \
    -e 's/sk-[A-Za-z0-9_-]{12,}/<redacted-key>/g' \
    -e 's/(xai-|gsk_|github_pat_|ghp_)[A-Za-z0-9_-]{12,}/<redacted-key>/g' \
    -e 's/eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+/<redacted-jwt>/g' \
    -e 's/(Authorization: Bearer )[A-Za-z0-9._~+\/=-]+/\1<redacted>/g'
}

require_copilot() {
  if ! command -v copilot >/dev/null 2>&1; then
    echo "GitHub Copilot CLI was not found on PATH. Install it first, then retry." >&2
    exit 127
  fi
}

map_env() {
  export COPILOT_PROVIDER_BASE_URL="${COPILOT_PROVIDER_BASE_URL:-${COPILOT_BYOK_BASE_URL:-}}"
  export COPILOT_PROVIDER_TYPE="${COPILOT_PROVIDER_TYPE:-${COPILOT_BYOK_TYPE:-openai}}"
  export COPILOT_PROVIDER_API_KEY="${COPILOT_PROVIDER_API_KEY:-${COPILOT_BYOK_API_KEY:-}}"
  export COPILOT_PROVIDER_BEARER_TOKEN="${COPILOT_PROVIDER_BEARER_TOKEN:-${COPILOT_BYOK_BEARER_TOKEN:-}}"
  export COPILOT_MODEL="${COPILOT_MODEL:-${COPILOT_BYOK_MODEL:-}}"
  export COPILOT_PROVIDER_MODEL_ID="${COPILOT_PROVIDER_MODEL_ID:-${COPILOT_BYOK_MODEL_ID:-}}"
  export COPILOT_PROVIDER_WIRE_MODEL="${COPILOT_PROVIDER_WIRE_MODEL:-${COPILOT_BYOK_WIRE_MODEL:-}}"
  export COPILOT_PROVIDER_WIRE_API="${COPILOT_PROVIDER_WIRE_API:-${COPILOT_BYOK_WIRE_API:-}}"
  export COPILOT_PROVIDER_MAX_PROMPT_TOKENS="${COPILOT_PROVIDER_MAX_PROMPT_TOKENS:-${COPILOT_BYOK_MAX_PROMPT_TOKENS:-}}"
  export COPILOT_PROVIDER_MAX_OUTPUT_TOKENS="${COPILOT_PROVIDER_MAX_OUTPUT_TOKENS:-${COPILOT_BYOK_MAX_OUTPUT_TOKENS:-}}"
}

check_config() {
  require_copilot
  map_env

  if [[ -z "${COPILOT_PROVIDER_BASE_URL}" ]]; then
    echo "Missing COPILOT_BYOK_BASE_URL or COPILOT_PROVIDER_BASE_URL." >&2
    exit 2
  fi

  if [[ -z "${COPILOT_MODEL}" && -z "${COPILOT_PROVIDER_MODEL_ID}" ]]; then
    echo "Missing COPILOT_BYOK_MODEL, COPILOT_MODEL, or COPILOT_PROVIDER_MODEL_ID." >&2
    exit 2
  fi
}

print_config() {
  check_config
  {
    echo "copilot_path=$(command -v copilot)"
    echo "COPILOT_PROVIDER_TYPE=${COPILOT_PROVIDER_TYPE}"
    echo "COPILOT_PROVIDER_BASE_URL=${COPILOT_PROVIDER_BASE_URL}"
    echo "COPILOT_PROVIDER_API_KEY=${COPILOT_PROVIDER_API_KEY}"
    echo "COPILOT_PROVIDER_BEARER_TOKEN=${COPILOT_PROVIDER_BEARER_TOKEN}"
    echo "COPILOT_MODEL=${COPILOT_MODEL}"
    echo "COPILOT_PROVIDER_MODEL_ID=${COPILOT_PROVIDER_MODEL_ID}"
    echo "COPILOT_PROVIDER_WIRE_MODEL=${COPILOT_PROVIDER_WIRE_MODEL}"
    echo "COPILOT_PROVIDER_WIRE_API=${COPILOT_PROVIDER_WIRE_API}"
  } | redact
}

run_async() {
  exec python3 "${script_dir}/copilot_byok_async.py" "$@"
}

list_templates() {
  find "${repo_dir}/references/prompts" -maxdepth 1 -type f -name '*.md' -print \
    | sed -E 's#^.*/([^/]+)\.md$#\1#' \
    | sort
}

consult() {
  if [[ $# -eq 0 || "${1:-}" == "--help" ]]; then
    cat <<'EOF'
Usage:
  scripts/run-copilot-byok.sh consult --list-templates
  scripts/run-copilot-byok.sh consult <preset> [--context FILE] [--extra TEXT] [--async] [--wait-timeout N] [--] [copilot arguments...]

Examples:
  scripts/pack-context.sh --status --diff --output /tmp/copilot-context.md
  scripts/run-copilot-byok.sh consult review --context /tmp/copilot-context.md --async --wait-timeout 30
EOF
    return 0
  fi

  if [[ "${1:-}" == "--list-templates" ]]; then
    list_templates
    return 0
  fi

  local preset="$1"
  shift
  local template="${repo_dir}/references/prompts/${preset}.md"
  if [[ ! -f "$template" ]]; then
    echo "Unknown consult preset: ${preset}" >&2
    echo "Available presets:" >&2
    list_templates >&2
    return 2
  fi

  local async=0
  local wait_timeout=""
  local extra=""
  local context_files=()
  local async_args=()
  local copilot_args=("--silent")

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --context)
        [[ $# -ge 2 ]] || { echo "--context requires a file" >&2; return 2; }
        context_files+=("$2")
        shift 2
        ;;
      --extra)
        [[ $# -ge 2 ]] || { echo "--extra requires text" >&2; return 2; }
        extra+=$'\n'"$2"
        shift 2
        ;;
      --async)
        async=1
        shift
        ;;
      --wait-timeout)
        [[ $# -ge 2 ]] || { echo "--wait-timeout requires seconds" >&2; return 2; }
        async=1
        wait_timeout="$2"
        shift 2
        ;;
      --max-wall|--idle-timeout|--heartbeat|--grace)
        [[ $# -ge 2 ]] || { echo "$1 requires seconds" >&2; return 2; }
        async_args+=("$1" "$2")
        shift 2
        ;;
      --)
        shift
        if [[ $# -gt 0 ]]; then
          copilot_args=("$@")
        fi
        break
        ;;
      *)
        echo "Unknown consult option: $1" >&2
        return 2
        ;;
    esac
  done

  local prompt
  prompt="$(cat "$template")"
  if [[ "${#context_files[@]}" -gt 0 ]]; then
    prompt+=$'\n\n## Context Packets\n'
    local context_file
    for context_file in "${context_files[@]}"; do
      if [[ ! -f "$context_file" ]]; then
        echo "Missing context file: ${context_file}" >&2
        return 2
      fi
      prompt+=$'\n### '"${context_file}"$'\n\n'
      prompt+="$(cat "$context_file")"
      prompt+=$'\n'
    done
  fi
  if [[ -n "$extra" ]]; then
    prompt+=$'\n\n## Additional Instructions\n'
    prompt+="$extra"
    prompt+=$'\n'
  fi

  if [[ "$async" -eq 1 ]]; then
    local run_id
    run_id="$(python3 "${script_dir}/copilot_byok_async.py" start "${async_args[@]+"${async_args[@]}"}" -- -p "$prompt" "${copilot_args[@]}")"
    echo "$run_id"
    if [[ -n "$wait_timeout" ]]; then
      python3 "${script_dir}/copilot_byok_async.py" wait "$run_id" --timeout "$wait_timeout" >&2
    fi
  else
    exec copilot -p "$prompt" "${copilot_args[@]}"
  fi
}

case "${1:-}" in
  --check)
    check_config
    echo "Copilot BYOK configuration looks usable."
    ;;
  --print-config)
    print_config
    ;;
  --help-wrapper)
    cat <<'EOF'
Usage:
  scripts/run-copilot-byok.sh --check
  scripts/run-copilot-byok.sh --print-config
  scripts/run-copilot-byok.sh consult --list-templates
  scripts/run-copilot-byok.sh consult <preset> [--context FILE] [--extra TEXT] [--async] [--wait-timeout N] [--] [copilot arguments...]
  scripts/run-copilot-byok.sh start [--max-wall N] [--idle-timeout N] -- [copilot arguments...]
  scripts/run-copilot-byok.sh status <run-id>
  scripts/run-copilot-byok.sh wait <run-id> [--timeout N]
  scripts/run-copilot-byok.sh logs <run-id> [--stderr|--events] [--tail N] [--follow]
  scripts/run-copilot-byok.sh result <run-id> [--raw|--json|--status-code]
  scripts/run-copilot-byok.sh cancel <run-id>
  scripts/run-copilot-byok.sh list [--limit N]
  scripts/run-copilot-byok.sh [copilot arguments...]

Configuration:
  Set COPILOT_BYOK_* variables in the environment or in a local .env file.
  See .env.example and references/copilot-cli-byok.md.
EOF
    ;;
  consult)
    shift
    if [[ $# -gt 0 && "${1:-}" != "--help" && "${1:-}" != "--list-templates" ]]; then
      check_config
    fi
    consult "$@"
    ;;
  start)
    check_config
    shift
    run_async start "$@"
    ;;
  status|wait|logs|result|cancel|list)
    cmd="$1"
    shift
    run_async "$cmd" "$@"
    ;;
  *)
    check_config
    exec copilot "$@"
    ;;
esac
