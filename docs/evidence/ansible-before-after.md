# Ansible Before and After Evidence

## Scope

The secure baseline was applied to `linux-node1` and `linux-node2` through the control-node inventory. Values below summarize executable checks and omit machine identifiers, keys and raw host exports.

| Control | Before or drifted state | Managed state |
|---|---|---|
| SSH root login | Bootstrap-only restriction | `permitrootlogin no` verified by `sshd -T` |
| SSH password auth | Bootstrap-only restriction | `passwordauthentication no` verified by `sshd -T` |
| SSH auth attempts | Distribution default | `maxauthtries 3` |
| Kernel pointer exposure | `kernel.kptr_restrict=1` after shared-kernel drift | `kernel.kptr_restrict=2` |
| Reverse-path filtering | `rp_filter=2` after Docker/WSL drift | Managed value `1` |
| Journal retention | Distribution default | Persistent journal, bounded size and retention |
| Time synchronization | Backend-dependent default | `chrony` active |
| Failed units | Unsupported WSL units initially failed | Zero failed units on both targets |

## Idempotency

The drift-correction run reported `changed=1`, `failed=0` for each target. The immediate second run reported:

```text
linux-node1: ok=11 changed=0 unreachable=0 failed=0
linux-node2: ok=11 changed=0 unreachable=0 failed=0
```

## Effective-State Verification

`playbooks/verify.yml` reported:

```text
linux-node1: ok=7 changed=0 unreachable=0 failed=0
linux-node2: ok=7 changed=0 unreachable=0 failed=0
```

The playbook checks effective SSH output, every managed live sysctl, active SSH/time/journal services and the absence of failed systemd units.

## Limitations

- WSL2 distributions share one kernel and network backend.
- Kernel values are therefore verified as shared runtime state, not independent per-node isolation.
- Firewall and audit controls remain outside the default role until their WSL capability boundaries are tested explicitly.
- Hypervisor-backed portability is deferred and documented in ADR-0002.
