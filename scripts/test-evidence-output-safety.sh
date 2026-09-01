#!/usr/bin/env bash
set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
test_directory="$(mktemp -d)"
trap 'rm -rf "$test_directory"' EXIT

mkdir "$test_directory/target"
ln -s "$test_directory/target" "$test_directory/output-link"

assert_rejected() {
  local expected_status="$1"
  shift
  set +e
  "$@" >/dev/null 2>&1
  local actual_status=$?
  set -e
  if ((actual_status != expected_status)); then
    printf 'Expected exit %d, got %d: %s\n' "$expected_status" "$actual_status" "$*" >&2
    exit 1
  fi
}

assert_rejected 64 bash "$repository_root/scripts/capture-baseline.sh" \
  --output "$test_directory/output-link"
assert_rejected 64 bash "$repository_root/scripts/diagnose-network.sh" \
  --host 127.0.0.1 --port 1 --scheme http --output "$test_directory/output-link"
assert_rejected 64 bash "$repository_root/scripts/run-fault-scenario.sh" \
  dns --output "$test_directory/output-link"

bash "$repository_root/scripts/run-fault-scenario.sh" \
  dns --output "$test_directory/private-output" >/dev/null

directory_mode="$(stat -c '%a' "$test_directory/private-output")"
summary_mode="$(stat -c '%a' "$test_directory/private-output/summary.env")"
if [[ "$directory_mode" != "700" || "$summary_mode" != "600" ]]; then
  printf 'Unexpected evidence modes: directory=%s summary=%s\n' "$directory_mode" "$summary_mode" >&2
  exit 1
fi

printf 'Evidence output paths reject symlinks and use private modes.\n'
