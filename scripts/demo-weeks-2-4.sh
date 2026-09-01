#!/usr/bin/env bash
set -euo pipefail

section() {
  printf '\n===== %s =====\n' "$1"
}

section "Week 2: Linux health and operations"
python3 scripts/health-check.py --require-systemd-running
bash scripts/test-linux-operations-lab.sh

section "Week 3: deterministic failures and network path"
bash scripts/test-fault-scenarios.sh
bash scripts/test-network-diagnostics.sh
bash scripts/test-reverse-proxy-lab.sh

section "Week 4: Ansible connectivity and effective state"
ansible all -i inventory/dev/hosts.yml -m ping
ansible-playbook -i inventory/dev/hosts.yml playbooks/site.yml
ansible-playbook -i inventory/dev/hosts.yml playbooks/verify.yml
bash scripts/test-invalid-ansible-input.sh

section "Demo result"
printf 'Weeks 2-4 verification passed.\n'
