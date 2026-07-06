#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'USAGE'
Usage: scripts/verify-logql.sh --mode fast|strict

Validates LogQL query definitions under observability/logql/queries and
representative fixture metadata under observability/logql/fixtures.

Definition convention:
  # name: stable-kebab-case-name
  # description: concise purpose
  # live: optional|required
  {app="state-trail-demo"} |= "Started"

Strict mode runs live Loki queries only for definitions with live: required.
Fixtures with live: required also trigger strict live checks for the referenced query.
Set STATE_TRAIL_LOKI_URL, LOKI_ADDR, or LOKI_URL and install logcli for live checks.
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
            echo "verify-logql: unknown argument: $1" >&2
            usage >&2
            exit 2
            ;;
    esac
done

case "$mode" in
    fast|strict) ;;
    *)
        echo "verify-logql: --mode must be fast or strict" >&2
        usage >&2
        exit 2
        ;;
esac

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
query_dir="$repo_root/observability/logql/queries"
fixture_dir="$repo_root/observability/logql/fixtures"
cd "$repo_root"

if [ ! -d "$query_dir" ]; then
    echo "verify-logql: query directory is missing: observability/logql/queries" >&2
    exit 1
fi

query_files=()
while IFS= read -r query_file; do
    query_files+=("$query_file")
done < <(find "$query_dir" -type f -name '*.logql' -print | sort)
if [ "${#query_files[@]}" -eq 0 ]; then
    echo "verify-logql: no LogQL query definitions found in observability/logql/queries" >&2
    exit 1
fi

live_required=()

metadata_value() {
    local key="$1"
    local file="$2"
    sed -nE "s/^#[[:space:]]*$key:[[:space:]]*(.*)$/\\1/p" "$file" | head -n 1
}

query_body() {
    local file="$1"
    sed -E '/^[[:space:]]*#/d; /^[[:space:]]*$/d' "$file"
}

validate_query_file() {
    local file="$1"
    local rel="${file#$repo_root/}"
    local name description live query

    name="$(metadata_value "name" "$file")"
    description="$(metadata_value "description" "$file")"
    live="$(metadata_value "live" "$file")"
    query="$(query_body "$file")"

    if [[ ! "$name" =~ ^[a-z][a-z0-9-]*$ ]]; then
        echo "verify-logql: $rel has invalid or missing '# name:' metadata" >&2
        return 1
    fi

    if [ "${#description}" -lt 12 ]; then
        echo "verify-logql: $rel has missing or too-short '# description:' metadata" >&2
        return 1
    fi

    if [ "$live" != "optional" ] && [ "$live" != "required" ]; then
        echo "verify-logql: $rel must declare '# live: optional' or '# live: required'" >&2
        return 1
    fi

    if [ -z "$query" ]; then
        echo "verify-logql: $rel has no LogQL query body" >&2
        return 1
    fi

    if grep -Eiq 'TODO|TBD|placeholder|your-|<[^>]+>' "$file"; then
        echo "verify-logql: $rel contains placeholder text" >&2
        return 1
    fi

    if ! grep -Eq '^\s*\{[^}]+="[^"]+"\}' <<< "$query"; then
        echo "verify-logql: $rel query must start with a concrete label selector" >&2
        return 1
    fi

    local open_braces close_braces quote_count
    open_braces="$(grep -o '{' <<< "$query" | wc -l | tr -d ' ')"
    close_braces="$(grep -o '}' <<< "$query" | wc -l | tr -d ' ')"
    quote_count="$(grep -o '"' <<< "$query" | wc -l | tr -d ' ')"

    if [ "$open_braces" -ne "$close_braces" ]; then
        echo "verify-logql: $rel has unbalanced braces" >&2
        return 1
    fi

    if [ $((quote_count % 2)) -ne 0 ]; then
        echo "verify-logql: $rel has unbalanced double quotes" >&2
        return 1
    fi

    if [ "$live" = "required" ]; then
        live_required+=("$file")
    fi

    echo "verify-logql: static validation passed for $rel"
}

query_file_by_name() {
    local expected_name="$1"
    local query_file query_name

    for query_file in "${query_files[@]}"; do
        query_name="$(metadata_value "name" "$query_file")"
        if [ "$query_name" = "$expected_name" ]; then
            printf '%s\n' "$query_file"
            return 0
        fi
    done

    return 1
}

validate_fixture_file() {
    local file="$1"
    local rel="${file#$repo_root/}"
    local name description query_name live body query_file

    name="$(metadata_value "name" "$file")"
    description="$(metadata_value "description" "$file")"
    query_name="$(metadata_value "query" "$file")"
    live="$(metadata_value "live" "$file")"
    body="$(query_body "$file")"

    if [[ ! "$name" =~ ^[a-z][a-z0-9-]*$ ]]; then
        echo "verify-logql: $rel has invalid or missing '# name:' metadata" >&2
        return 1
    fi

    if [ "${#description}" -lt 12 ]; then
        echo "verify-logql: $rel has missing or too-short '# description:' metadata" >&2
        return 1
    fi

    if [[ ! "$query_name" =~ ^[a-z][a-z0-9-]*$ ]]; then
        echo "verify-logql: $rel has invalid or missing '# query:' metadata" >&2
        return 1
    fi

    query_file="$(query_file_by_name "$query_name" || true)"
    if [ -z "$query_file" ]; then
        echo "verify-logql: $rel references unknown query '$query_name'" >&2
        return 1
    fi

    if [ "$live" != "optional" ] && [ "$live" != "required" ]; then
        echo "verify-logql: $rel must declare '# live: optional' or '# live: required'" >&2
        return 1
    fi

    if [ -z "$body" ]; then
        echo "verify-logql: $rel has no representative log fixture body" >&2
        return 1
    fi

    if grep -Eiq 'TODO|TBD|placeholder|your-|<[^>]+>' "$file"; then
        echo "verify-logql: $rel contains placeholder text" >&2
        return 1
    fi

    if [ "$live" = "required" ]; then
        live_required+=("$query_file")
    fi

    echo "verify-logql: static fixture validation passed for $rel"
}

for query_file in "${query_files[@]}"; do
    validate_query_file "$query_file"
done

fixture_files=()
if [ -d "$fixture_dir" ]; then
    while IFS= read -r fixture_file; do
        fixture_files+=("$fixture_file")
    done < <(find "$fixture_dir" -type f -name '*.logql-fixture' -print | sort)
fi

if [ "${#fixture_files[@]}" -gt 0 ]; then
    for fixture_file in "${fixture_files[@]}"; do
        validate_fixture_file "$fixture_file"
    done
fi

if [ "$mode" = "fast" ]; then
    echo "verify-logql: fast mode completed static LogQL validation"
    exit 0
fi

if [ "${#live_required[@]}" -eq 0 ]; then
    echo "verify-logql: no live LogQL checks configured; skipping live Loki queries"
    exit 0
fi

loki_addr="${STATE_TRAIL_LOKI_URL:-${LOKI_ADDR:-${LOKI_URL:-}}}"
if [ -z "$loki_addr" ]; then
    echo "verify-logql: live-required LogQL checks exist but no Loki URL is configured" >&2
    echo "verify-logql: set STATE_TRAIL_LOKI_URL, LOKI_ADDR, or LOKI_URL for strict live checks" >&2
    exit 1
fi

if ! command -v logcli >/dev/null 2>&1; then
    echo "verify-logql: live-required LogQL checks exist but logcli is not installed or not on PATH" >&2
    exit 1
fi

logcli_args=(--addr="$loki_addr")
if [ -n "${LOKI_TENANT_ID:-}" ]; then
    logcli_args+=(--org-id="$LOKI_TENANT_ID")
fi

if [ -n "${LOKI_BEARER_TOKEN:-}" ]; then
    if [ -n "${LOKI_USERNAME:-}" ] || [ -n "${LOKI_PASSWORD:-}" ]; then
        echo "verify-logql: use either LOKI_BEARER_TOKEN or LOKI_USERNAME/LOKI_PASSWORD, not both" >&2
        exit 1
    fi
    logcli_args+=(--bearer-token="$LOKI_BEARER_TOKEN")
elif [ -n "${LOKI_USERNAME:-}" ] || [ -n "${LOKI_PASSWORD:-}" ]; then
    if [ -z "${LOKI_USERNAME:-}" ] || [ -z "${LOKI_PASSWORD:-}" ]; then
        echo "verify-logql: both LOKI_USERNAME and LOKI_PASSWORD are required for basic auth" >&2
        exit 1
    fi
    logcli_args+=(--username="$LOKI_USERNAME" --password="$LOKI_PASSWORD")
fi

since="${STATE_TRAIL_LOGQL_SINCE:-1h}"
for query_file in "${live_required[@]}"; do
    rel="${query_file#$repo_root/}"
    query="$(query_body "$query_file" | tr '\n' ' ')"
    echo "verify-logql: running live Loki query for $rel"
    output="$(logcli "${logcli_args[@]}" query --limit=1 --since="$since" "$query" 2>&1)" || {
        echo "$output" >&2
        echo "verify-logql: live Loki query failed for $rel" >&2
        exit 1
    }
    if [ -z "$output" ] || grep -Eiq 'no entries found|0 entries' <<< "$output"; then
        echo "$output" >&2
        echo "verify-logql: expected live log evidence was not found for $rel" >&2
        exit 1
    fi
done

echo "verify-logql: strict live LogQL checks passed"
