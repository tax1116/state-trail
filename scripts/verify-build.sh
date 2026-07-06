#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'USAGE'
Usage: scripts/verify-build.sh --mode fast|strict

fast   Runs compile/static build verification without test execution.
strict Runs the full Gradle check used by CI.
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
            echo "verify-build: unknown argument: $1" >&2
            usage >&2
            exit 2
            ;;
    esac
done

case "$mode" in
    fast|strict) ;;
    *)
        echo "verify-build: --mode must be fast or strict" >&2
        usage >&2
        exit 2
        ;;
esac

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
cd "$repo_root"

if [ ! -x "./gradlew" ]; then
    echo "verify-build: ./gradlew is missing or not executable" >&2
    exit 1
fi

if [ "$mode" = "strict" ]; then
    command=(./gradlew check)
else
    command=(./gradlew classes)
fi

echo "verify-build: running ${command[*]}"
if ! "${command[@]}"; then
    echo "verify-build: ${command[*]} failed" >&2
    exit 1
fi
