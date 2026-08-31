#!/usr/bin/env bash
set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
test_directory="$(mktemp -d)"
trap 'chmod -R u+rwX "$test_directory" 2>/dev/null || true; rm -rf "$test_directory"' EXIT

scenarios=(
  dns
  closed-port
  expired-certificate
  permission-denied
  disk-full
)

for scenario in "${scenarios[@]}"; do
  output_directory="$test_directory/$scenario"
  bash "$repository_root/scripts/run-fault-scenario.sh" "$scenario" --output "$output_directory"
  grep -Fx 'outcome=expected_failure' "$output_directory/summary.env" >/dev/null
  test -s "$output_directory/evidence.log"
done

set +e
bash "$repository_root/scripts/run-fault-scenario.sh" unknown --output "$test_directory/unknown" >/dev/null 2>&1
invalid_status=$?
set -e

if ((invalid_status != 64)); then
  printf 'Expected invalid scenario exit code 64, got %d\n' "$invalid_status" >&2
  exit 1
fi

printf 'All fault scenarios reproduced their expected failures.\n'
