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
    -e 's/(API_KEY=).+/\1<redacted>/g' \
    -e 's/(BEARER_TOKEN=).+/\1<redacted>/g' \
    -e 's/(BASE_URL=).+/\1<configured>/g' \
    -e 's/sk-[A-Za-z0-9_-]{12,}/<redacted-key>/g' \
    -e 's/(xai-|gsk_|github_pat_|ghp_)[A-Za-z0-9_-]{12,}/<redacted-key>/g' \
    -e 's/[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+/<redacted-jwt>/g' \
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
  scripts/run-copilot-byok.sh start [--max-wall N] [--idle-timeout N] -- [copilot arguments...]
  scripts/run-copilot-byok.sh status <run-id>
  scripts/run-copilot-byok.sh wait <run-id> [--timeout N]
  scripts/run-copilot-byok.sh logs <run-id> [--stderr|--events] [--tail N] [--follow]
  scripts/run-copilot-byok.sh cancel <run-id>
  scripts/run-copilot-byok.sh list [--limit N]
  scripts/run-copilot-byok.sh [copilot arguments...]

Configuration:
  Set COPILOT_BYOK_* variables in the environment or in a local .env file.
  See .env.example and references/copilot-cli-byok.md.
EOF
    ;;
  start)
    check_config
    shift
    run_async start "$@"
    ;;
  status|wait|logs|cancel|list)
    cmd="$1"
    shift
    run_async "$cmd" "$@"
    ;;
  *)
    check_config
    exec copilot "$@"
    ;;
esac
