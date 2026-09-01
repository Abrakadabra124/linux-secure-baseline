#!/usr/bin/env bash
set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
test_directory="$(mktemp -d)"
trap 'rm -rf "$test_directory"' EXIT

python3 "$repository_root/scripts/reverse-proxy-lab.py" \
  --output "$test_directory/evidence" >"$test_directory/output.json"

python3 - "$test_directory/evidence/summary.json" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as summary_file:
    summary = json.load(summary_file)

assert summary["outcome"] == "passed"
assert summary["proxy_status"] == 200
assert summary["via_header"] == "devsecops-loopback-proxy"
assert summary["backend_response"] == {"service": "backend", "status": "ok"}
PY

(
  cd "$test_directory/evidence"
  sha256sum --check manifest.sha256 >/dev/null
)

ln -s "$test_directory/evidence" "$test_directory/evidence-link"
set +e
python3 "$repository_root/scripts/reverse-proxy-lab.py" \
  --output "$test_directory/evidence-link" >/dev/null 2>&1
unsafe_status=$?
set -e
if ((unsafe_status != 64)); then
  printf 'Expected unsafe output exit code 64, got %d\n' "$unsafe_status" >&2
  exit 1
fi

printf 'Reverse-proxy lab and evidence integrity checks passed.\n'
