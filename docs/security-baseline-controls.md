# Security Baseline Controls

| Area | Lab implementation | Effective verification | Production boundary |
|---|---|---|---|
| Users | Dedicated `devsecops` account with unique UID per WSL distribution | `id`, `getent passwd`, bootstrap assertions | Central identity, lifecycle and break-glass access are external |
| SSH | Unique host keys, key-only login, no root login, restricted forwarding, managed early drop-in | `sshd -T`, exact host-key enrollment, Ansible verify playbook | Certificate authority, bastion and key rotation are external |
| Sudo | `NOPASSWD:ALL` only in the disposable local lab | `sudo -n true`, documented trust boundary | Production must use least-privilege command rules and audited elevation |
| Firewall | State is captured with `ufw` or `nft`; no WSL firewall policy is claimed | baseline snapshot and Windows/WSL network diagnostics | Enforce default-deny and approved management paths at host and network layers |
| Time sync | `chrony` is installed, enabled and started | `systemctl is-active chrony`, `timedatectl` | Production requires approved NTP sources and drift alerting |
| Packages | Required packages are declared in the Ansible role | idempotent `apt`, package baseline snapshot | Repository allowlists, patch SLAs and artifact provenance are external |
| Audit | Journal persistence and limits are managed; `auditd` is deliberately not claimed on the shared WSL kernel | `journalctl`, persistent journal path and effective journald config | Production should enable `auditd`, protect logs and monitor identity, sudo and SSH policy changes |

## Firewall Validation

```bash
sudo ufw status verbose
sudo nft list ruleset
ss -lntup
```

The lab does not enable a firewall automatically because WSL2 networking is controlled jointly by the distribution, the Windows host and the selected WSL networking mode. Enabling a distribution rule without validating the Windows boundary would create misleading evidence.

## Audit Validation

```bash
journalctl --disk-usage
journalctl -p warning --since today
systemctl status auditd
sudo auditctl -s
```

On a hypervisor-backed production-like node, the minimum audit policy should record changes to identity databases, `/etc/sudoers*`, `/etc/ssh/sshd_config*`, time configuration and privileged execution. The current role manages journald only; absence of a tested independent audit kernel boundary remains an explicit limitation rather than a false security claim.
