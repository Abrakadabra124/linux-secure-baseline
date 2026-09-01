# Changelog

## v1.0.0 - 2026-09-01

### Added

- Reproducible three-node WSL2 Linux lab with exact SSH host-key enrollment.
- Idempotent Ansible role for SSH, sysctl, process limits, journald, packages and time synchronization.
- Dev and non-routable prod-like inventories with a secret-free Vault workflow example.
- Bash and Python health checks, Linux operations exercises and explicit exit codes.
- Five deterministic failure scenarios with symptom-to-prevention runbooks.
- Layered DNS, route, TCP, TLS, HTTP, reverse-proxy, packet-capture and NAT diagnostics.
- Real asciicast v2 terminal demo and before/after hardening evidence.

### Security

- Rejects DNS parameter injection into the WSL root bootstrap.
- Sanitizes cloned homes and machine state, rotates SSH host keys and removes temporary exports on failure.
- Enforces SSH hardening through an early drop-in plus complete effective-state assertions.
- Creates raw evidence with private modes and rejects symlink or non-empty output targets.

### Limitations

- WSL2 distributions share a Windows-managed kernel and are not independent production hosts.
- Firewall and `auditd` enforcement remain explicit production controls, not falsely claimed WSL evidence.
- Public NAT egress observation depends on the host VPN and may be unavailable while the local proxy/packet lab still passes.
- Prod-like hosts use `.invalid` and cannot be contacted until an operator supplies approved private inventory.
