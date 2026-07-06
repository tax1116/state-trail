#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

cat > "$tmp_dir/verify-build.sh" <<'STUB'
#!/usr/bin/env bash
echo "stub build failure"
exit 42
STUB

cat > "$tmp_dir/verify-tests.sh" <<'STUB'
#!/usr/bin/env bash
echo "stub tests pass"
exit 0
STUB

cat > "$tmp_dir/verify-logql.sh" <<'STUB'
#!/usr/bin/env bash
echo "stub logql pass"
exit 0
STUB

chmod +x "$tmp_dir/verify-build.sh" "$tmp_dir/verify-tests.sh" "$tmp_dir/verify-logql.sh"

set +e
output="$(cd "$repo_root" && VERIFY_HARNESS_CHECK_DIR="$tmp_dir" scripts/verify-harness.sh --mode fast 2>&1)"
status=$?
set -e

printf '%s\n' "$output"

if [ "$status" -eq 0 ]; then
    echo "smoke-verify-harness: expected harness to fail when build check fails" >&2
    exit 1
fi

if ! grep -Fq "[FAIL] build" <<< "$output"; then
    echo "smoke-verify-harness: failure output did not include failing check name 'build'" >&2
    exit 1
fi

if ! grep -Fq "required check(s) failed: build" <<< "$output"; then
    echo "smoke-verify-harness: summary did not propagate failing check name" >&2
    exit 1
fi

echo "smoke-verify-harness: checking Codex pre-commit hook command detection"
"$repo_root/.codex/hooks/pre-tool-use-pre-commit" --self-test

echo "smoke-verify-harness: sub-check failure propagated with non-zero status and check name"
