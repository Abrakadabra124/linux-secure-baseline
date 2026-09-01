#!/usr/bin/env bash
set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
test_directory="$(mktemp -d)"
trap 'rm -rf "$test_directory"' EXIT

bash "$repository_root/scripts/run-linux-operations-lab.sh" --output "$test_directory/evidence"
grep -Fx 'outcome=passed' "$test_directory/evidence/summary.env" >/dev/null
grep -Fx 'permissions_mode=640' "$test_directory/evidence/summary.env" >/dev/null
grep -F 'signal=SIGTERM' "$test_directory/evidence/report.txt" >/dev/null
grep -F '## limits' "$test_directory/evidence/report.txt" >/dev/null
(
  cd "$test_directory/evidence"
  sha256sum --check manifest.sha256 >/dev/null
)

printf 'Linux operations lab evidence passed integrity checks.\n'
