#!/usr/bin/env bash
set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
test_directory="$(mktemp -d)"
trap 'rm -rf "$test_directory"' EXIT

python3 "$repository_root/scripts/health-check.py" --json >"$test_directory/healthy.json"
python3 - "$test_directory/healthy.json" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as report_file:
    report = json.load(report_file)

assert report["status"] == "healthy"
assert all(report["checks"].values())
PY

set +e
python3 "$repository_root/scripts/health-check.py" \
  --proc-root "$test_directory/missing-proc" \
  >"$test_directory/failed.txt"
failure_status=$?
set -e

if ((failure_status != 2)); then
  printf 'Expected health failure exit code 2, got %d\n' "$failure_status" >&2
  exit 1
fi

grep -Fx 'status=failed' "$test_directory/failed.txt" >/dev/null
grep -Fx 'proc_pid1_readable=failed' "$test_directory/failed.txt" >/dev/null

printf 'Python health-check success and failure paths passed.\n'
