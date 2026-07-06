#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'USAGE'
Usage: scripts/verify-tests.sh --mode fast|strict

Runs mechanical test checks: focused/disabled test pattern scan, optional
configured test path existence, and Gradle test execution.

Optional:
  STATE_TRAIL_TEST_PATHS  Colon-separated test paths that must exist.
USAGE
}

mode=""
while [ "$#" -gt 0 ]; do
    case "$1" in
        --mode)
            mode="${2:-}"
            shift 2
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            echo "verify-tests: unknown argument: $1" >&2
            usage >&2
            exit 2
            ;;
    esac
done

case "$mode" in
    fast|strict) ;;
    *)
        echo "verify-tests: --mode must be fast or strict" >&2
        usage >&2
        exit 2
        ;;
esac

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
cd "$repo_root"

if [ ! -x "./gradlew" ]; then
    echo "verify-tests: ./gradlew is missing or not executable" >&2
    exit 1
fi

if [ -n "${STATE_TRAIL_TEST_PATHS:-}" ]; then
    IFS=':' read -r -a configured_paths <<< "$STATE_TRAIL_TEST_PATHS"
    for test_path in "${configured_paths[@]}"; do
        if [ -n "$test_path" ] && [ ! -e "$test_path" ]; then
            echo "verify-tests: configured test path does not exist: $test_path" >&2
            exit 1
        fi
    done
else
    discovered_paths=()
    while IFS= read -r discovered_path; do
        discovered_paths+=("$discovered_path")
    done < <(find . -path '*/src/test/kotlin' -type d -print | sort)
    if [ "${#discovered_paths[@]}" -eq 0 ]; then
        echo "verify-tests: no configured test source paths found; Gradle test task still runs"
    fi
fi

test_files=()
while IFS= read -r test_file; do
    test_files+=("$test_file")
done < <(find . -path '*/src/test/*' -type f \( -name '*.kt' -o -name '*.java' \) -print | sort)
if [ "${#test_files[@]}" -gt 0 ]; then
    focused_or_disabled_pattern='@Disabled|@Ignore|@Tag\("focus"\)|(^|[^[:alnum:]_])(fit|fdescribe|xit|xdescribe)[[:space:]]*\('
    if grep -En "$focused_or_disabled_pattern" "${test_files[@]}"; then
        echo "verify-tests: focused or disabled test pattern found; remove it before committing" >&2
        exit 1
    fi
fi

command=(./gradlew test)
echo "verify-tests: running ${command[*]}"
if ! "${command[@]}"; then
    echo "verify-tests: ${command[*]} failed" >&2
    exit 1
fi
