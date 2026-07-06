#!/usr/bin/env bash
set -u

usage() {
    cat <<'USAGE'
Usage: scripts/verify-harness.sh --mode fast|strict

Runs the canonical StateTrail quality harness.
USAGE
}

mode=""
while [ "$#" -gt 0 ]; do
    case "$1" in
        --mode)
            if [ "$#" -lt 2 ]; then
                echo "verify-harness: missing value for --mode" >&2
                usage >&2
                exit 2
            fi
            mode="$2"
            shift 2
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            echo "verify-harness: unknown argument: $1" >&2
            usage >&2
            exit 2
            ;;
    esac
done

case "$mode" in
    fast|strict) ;;
    "")
        echo "verify-harness: --mode is required" >&2
        usage >&2
        exit 2
        ;;
    *)
        echo "verify-harness: invalid mode '$mode' (expected fast or strict)" >&2
        usage >&2
        exit 2
        ;;
esac

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
check_dir="${VERIFY_HARNESS_CHECK_DIR:-$script_dir}"

cd "$repo_root" || exit 1

failures=0
failed_checks=()

run_check() {
    local check_name="$1"
    local check_script="$2"

    if [ ! -x "$check_script" ]; then
        echo "[FAIL] $check_name: check script is missing or not executable: $check_script" >&2
        failures=$((failures + 1))
        failed_checks+=("$check_name")
        return
    fi

    echo "[RUN ] $check_name ($mode)"
    "$check_script" --mode "$mode"
    local status=$?
    if [ "$status" -ne 0 ]; then
        echo "[FAIL] $check_name: required check failed with exit code $status" >&2
        failures=$((failures + 1))
        failed_checks+=("$check_name")
    else
        echo "[PASS] $check_name"
    fi
}

run_check "build" "$check_dir/verify-build.sh"
run_check "tests" "$check_dir/verify-tests.sh"
run_check "logql" "$check_dir/verify-logql.sh"

if [ "$mode" = "strict" ]; then
    run_check "harness-smoke" "$script_dir/smoke-verify-harness.sh"
fi

if [ "$failures" -ne 0 ]; then
    joined_checks="$(IFS=', '; echo "${failed_checks[*]}")"
    echo "verify-harness: $failures required check(s) failed: $joined_checks" >&2
    exit 1
fi

echo "verify-harness: all required $mode checks passed"
