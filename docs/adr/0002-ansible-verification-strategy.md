# ADR-0002: Ansible Verification Strategy

## Status

Accepted

## Context

The portfolio needs executable evidence for role safety, idempotency and effective host state. GitHub-hosted CI cannot reproduce the Windows-managed WSL2 runtime, and nested virtualization would add cost and nondeterminism to the first release.

## Decision

Use complementary validation layers:

1. GitHub Actions runs shell syntax, deterministic fault tests, `ansible-lint`, inventory parsing, playbook syntax and unsafe-input rejection.
2. The WSL2 lab runs SSH connectivity, the role twice, and `playbooks/verify.yml` against effective SSH, sysctl, service and failed-unit state.
3. Runtime drift is induced by restarting distributions and is corrected through `ansible.posix.sysctl` with `sysctl_set`.
4. Generated inventories, private keys and raw evidence remain local and ignored.

## Consequences

- Portable logic fails quickly in CI without requiring privileged runners.
- Effective-state claims are backed by the real local runtime rather than syntax alone.
- WSL2 shared-kernel results cannot prove per-node kernel isolation.
- Molecule with a hypervisor or cloud backend remains a future portability test, not a hidden dependency for v1.0.0.
