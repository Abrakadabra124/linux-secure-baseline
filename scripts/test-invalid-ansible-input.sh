#!/usr/bin/env bash
set -euo pipefail

output_file="$(mktemp)"
trap 'rm -f "$output_file"' EXIT

set +e
ANSIBLE_ROLES_PATH=roles ansible-playbook \
  -i 'localhost,' \
  playbooks/test-invalid-input.yml >"$output_file" 2>&1
exit_code=$?
set -e

cat "$output_file"

if ((exit_code == 0)); then
  printf 'Expected invalid SSH input to fail validation.\n' >&2
  exit 1
fi

if ! grep -Fq 'validated SSH values only' "$output_file"; then
  printf 'The playbook failed for an unexpected reason.\n' >&2
  exit 1
fi

printf 'Unsafe SSH input was rejected before host changes.\n'
