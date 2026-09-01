# Weeks 2-4 Completion Audit

Audit date: 2026-09-01.

## Week 2

- Three WSL2 distributions run with separate filesystems, processes, machine IDs, UIDs and SSH host keys.
- Users, SSH, sudo, firewall boundary, time sync, packages and audit settings are mapped in `docs/security-baseline-controls.md`.
- `systemctl`, `journalctl`, permissions, `SIGTERM`, `/proc` and soft/hard limits are exercised by `run-linux-operations-lab.sh`.
- Bash capability reporting and Python health checks use explicit success, failure and argument exit codes.
- Exact target host keys are enrolled in `known_hosts`; Ansible ping succeeds for both nodes.

## Week 3

- DNS, closed-port TCP, expired TLS certificate, permission-denied and ENOSPC scenarios pass deterministically.
- Every failure has a symptoms, hypotheses, commands, root-cause and prevention runbook.
- Layered diagnostics use `ss`, `ip`, `dig`, `curl`, `openssl` and `traceroute`; the live reverse-proxy lab captures loopback packets with `tcpdump`.
- The local backend-to-proxy flow returns HTTP 200 with the expected `Via` marker.
- WSL private route source is observed; public egress is optional and was unavailable through the active VPN during the audit.

## Week 4

- Ansible lint and dev/prod-like syntax checks pass.
- First post-fix convergence changed three SSH tasks per node; the second run reported `ok=14`, `changed=0`, `failed=0` on both nodes.
- Effective-state verification reported `ok=7`, `changed=0`, `failed=0` on both nodes.
- Unsafe role input is rejected before host changes.
- The terminal demo contains 144 output events and ends with `Weeks 2-4 verification passed.`

## Security Audit

The scan of pre-fix revision `4a399e1652efffd497a55890935693dc16e36893` found three medium and one low issue: root shell injection through DNS values, cloned credential/host-key state, SSH drop-in precedence and permissive evidence modes. This release remediates all four and adds regression coverage.

Canonical Codex Security scan ID: `7b6219c0-0775-4dc6-a6fe-ead66d675cf6`.
