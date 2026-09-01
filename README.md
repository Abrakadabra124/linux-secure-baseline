# Linux Secure Baseline

Reproducible Linux hardening, systemd and networking troubleshooting with tested Ansible roles.

## Status

Delivered as **Weeks 2-4** of the [24-week Middle DevSecOps roadmap](https://github.com/Abrakadabra124/github-middle-devsecops-roadmap). Current release: **v1.0.0**.

## Engineering Evidence

Linux internals, TCP/IP and TLS diagnostics, idempotent configuration, fault scenarios and runbooks.

## Current Milestone

Weeks 2-4 establish the reproducible laboratory, apply the secure baseline, add deterministic troubleshooting failures and publish a verified release.

- [x] Repository quality gates and contribution workflow
- [x] Host capability and dependency verification
- [x] WSL2-based lab architecture and limitations
- [x] Ubuntu control node bootstrap automation
- [x] Two isolated Ubuntu target instance automation
- [x] Key-only SSH and generated Ansible inventory
- [x] Integrity-checked node baseline capture
- [x] Ansible role for SSH, sysctl, journald and limits
- [x] Bootstrap execution after host restart
- [x] Ansible connectivity smoke test
- [x] Idempotency and negative tests on WSL2 nodes
- [x] Deterministic DNS, TCP, TLS, permissions and ENOSPC scenarios
- [x] Automated fault harness with evidence and explicit exit codes
- [x] Symptom-to-prevention troubleshooting runbooks
- [x] Layered DNS, route, TCP, TLS and HTTP diagnostic capture
- [x] Separate dev and prod-like Ansible inventories
- [x] Ignored Ansible Vault workflow without committed secrets
- [x] Runtime verification strategy and before/after evidence
- [x] Python health-check with explicit success and failure exit codes
- [x] Safe systemd, journal, permissions, signals, procfs and limits exercise
- [x] Loopback reverse-proxy lab with packet-capture and redacted NAT evidence modes

## Quick Start

```bash
task lint
task verify
task verify:strict
task health:test
task linux:test
task lab:bootstrap
task ansible:lint
task ansible:syntax
task ansible:verify
task ansible:inventory
task faults:test
task network:test
task network:diagnose
task network:lab:test
```

The strict verification intentionally fails when required Linux administration tools are absent. See the [host prerequisites runbook](docs/runbooks/host-prerequisites.md) for remediation.

## Architecture

The local lab uses isolated WSL2 distributions for the control and target nodes. They have separate filesystems and process trees but share the Windows-managed WSL2 kernel. This limitation is explicit and will be covered by negative tests rather than hidden.

- [Architecture and trust boundaries](docs/architecture.md)
- [ADR-0001: WSL2 lab backend](docs/adr/0001-wsl2-lab-backend.md)
- [ADR-0002: Ansible verification strategy](docs/adr/0002-ansible-verification-strategy.md)
- [Host prerequisites runbook](docs/runbooks/host-prerequisites.md)
- [WSL2 lab bootstrap runbook](docs/runbooks/bootstrap-wsl-lab.md)
- [Node baseline capture runbook](docs/runbooks/capture-node-baseline.md)
- [Apply and validate the Ansible baseline](docs/runbooks/apply-secure-baseline.md)
- [Environment inventories and Vault workflow](docs/runbooks/ansible-inventories.md)
- [Fault scenario catalog](docs/runbooks/fault-scenarios.md)
- [Network path diagnostics](docs/runbooks/network-path-diagnostics.md)
- [Linux operations lab](docs/runbooks/linux-operations-lab.md)
- [Reverse proxy and NAT lab](docs/runbooks/reverse-proxy-nat-lab.md)
- [Observed WSL DNS failure and recovery evidence](docs/evidence/week3-network-findings.md)
- [Ansible before/after evidence](docs/evidence/ansible-before-after.md)
- [Security baseline control matrix](docs/security-baseline-controls.md)
- [Recorded Weeks 2-4 terminal demo](docs/demo/README.md)
- [Weeks 2-4 completion audit](docs/evidence/weeks-2-4-completion-audit.md)

## Delivery Standard

- Reproducible bootstrap and cleanup
- Automated quality and security checks
- Architecture decisions and trade-offs
- Negative tests and failure scenarios
- Runbooks, measurable results and honest limitations

## Work Tracking

Implementation is tracked in the repository issues and the [master roadmap](https://github.com/Abrakadabra124/github-middle-devsecops-roadmap/blob/main/docs/24-week-roadmap.md).

## Security

No credentials, private keys, WSL exports or generated inventories containing host secrets may be committed. See [SECURITY.md](SECURITY.md).
