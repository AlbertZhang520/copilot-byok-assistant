#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/secret.log" <<'EOF'
COPILOT_BYOK_BASE_URL=https://secret.internal/v1
COPILOT_BYOK_API_KEY=placeholder-secret
EOF

./scripts/pack-context.sh --log "$tmpdir/secret.log" --output "$tmpdir/context.md"
if grep -q 'secret.internal' "$tmpdir/context.md"; then
  echo "BASE_URL was not redacted" >&2
  exit 1
fi
grep -q '<configured>' "$tmpdir/context.md"
grep -q '<redacted>' "$tmpdir/context.md"

if ./scripts/pack-context.sh --staged --diff HEAD >/dev/null 2>&1; then
  echo "--staged with --diff range should fail" >&2
  exit 1
fi

cat >"$tmpdir/copilot" <<'EOF'
#!/usr/bin/env bash
cat <<'OUT'
prefix
BEGIN_RESULT
Verdict: approve
Findings:
END_RESULT
suffix
OUT
EOF
chmod +x "$tmpdir/copilot"

PATH="$tmpdir:$PATH" \
COPILOT_BYOK_BASE_URL=https://example.invalid/v1 \
COPILOT_BYOK_API_KEY=placeholder \
COPILOT_BYOK_MODEL=test-model \
  ./scripts/run-copilot-byok.sh consult review --context "$tmpdir/context.md" --async --wait-timeout 5 \
  >"$tmpdir/run_id" 2>"$tmpdir/wait.json"

run_id="$(cat "$tmpdir/run_id")"
case "$run_id" in
  20*T*Z-*) ;;
  *)
    echo "consult stdout did not contain only a run id: $run_id" >&2
    exit 1
    ;;
esac

grep -q '"state": "succeeded"' "$tmpdir/wait.json"

result="$(PATH="$tmpdir:$PATH" ./scripts/run-copilot-byok.sh result "$run_id")"
expected=$'Verdict: approve\nFindings:'
if [[ "$result" != "$expected" ]]; then
  echo "unexpected result output: $result" >&2
  exit 1
fi
