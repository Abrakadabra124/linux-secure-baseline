# Linux Secure Baseline

Reproducible Linux hardening, systemd and networking troubleshooting with tested Ansible roles.

## Status

Planned as **Weeks 2-4** of the [24-week Middle DevSecOps roadmap](https://github.com/Abrakadabra124/github-middle-devsecops-roadmap). Target release: **v1.0.0 by 27 September 2026**.

## Engineering Evidence

Linux internals, TCP/IP and TLS diagnostics, idempotent configuration, fault scenarios and runbooks.

## Current Milestone

Week 2 establishes the reproducible laboratory and captures the host baseline before any hardening is applied.

- [x] Repository quality gates and contribution workflow
- [x] Host capability and dependency verification
- [x] WSL2-based lab architecture and limitations
- [x] Ubuntu control node bootstrap automation
- [x] Two isolated Ubuntu target instance automation
- [x] Key-only SSH and generated Ansible inventory
- [x] Integrity-checked node baseline capture
- [x] Ansible role for SSH, sysctl, journald and limits
- [ ] Bootstrap execution after host restart
- [ ] Ansible connectivity smoke test
- [ ] Idempotency and negative tests on WSL2 nodes

## Quick Start

```bash
task lint
task verify
task verify:strict
task lab:bootstrap
task ansible:lint
task ansible:syntax
```

The strict verification intentionally fails when required Linux administration tools are absent. See the [host prerequisites runbook](docs/runbooks/host-prerequisites.md) for remediation.

## Architecture

The local lab uses isolated WSL2 distributions for the control and target nodes. They have separate filesystems and process trees but share the Windows-managed WSL2 kernel. This limitation is explicit and will be covered by negative tests rather than hidden.

- [Architecture and trust boundaries](docs/architecture.md)
- [ADR-0001: WSL2 lab backend](docs/adr/0001-wsl2-lab-backend.md)
- [Host prerequisites runbook](docs/runbooks/host-prerequisites.md)
- [WSL2 lab bootstrap runbook](docs/runbooks/bootstrap-wsl-lab.md)
- [Node baseline capture runbook](docs/runbooks/capture-node-baseline.md)
- [Apply and validate the Ansible baseline](docs/runbooks/apply-secure-baseline.md)

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
