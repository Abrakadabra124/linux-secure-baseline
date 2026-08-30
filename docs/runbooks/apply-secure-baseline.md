# Apply the Secure Baseline

## Scope

The `secure_baseline` role provides a deliberately small, reviewable baseline for Ubuntu lab nodes:

- installs SSH and sudo prerequisites;
- disables root and password-based SSH authentication;
- limits authentication attempts and forwarding features;
- applies selected kernel hardening settings;
- persists journald with bounded retention;
- configures file descriptor limits;
- enables systemd time synchronization.

Firewall and audit rules are not enabled by default. WSL2 shares a Microsoft-managed kernel and network backend, so those controls require separate capability tests before they can be presented as effective evidence.

## Preflight

Keep the current WSL terminal open while changing SSH settings. Confirm that key-based access works before applying the role:

```bash
ansible all -i inventory/generated/hosts.yml -m ping
ansible all -i inventory/generated/hosts.yml -b -m command -a 'sshd -t'
```

Capture the initial state:

```bash
bash scripts/capture-baseline.sh --strict --output artifacts/node-before
```

## Check Mode

```bash
ansible-playbook -i inventory/generated/hosts.yml playbooks/site.yml --check --diff
```

Review every SSH and sysctl change before removing `--check`.

Validate the fail-fast guard independently:

```bash
task ansible:test-invalid
```

The test passes only when an out-of-range SSH authentication limit is rejected by the first role task.

## Apply

```bash
ansible-playbook -i inventory/generated/hosts.yml playbooks/site.yml --diff
```

Run the same command a second time. A successful idempotency check reports `changed=0` for every host.

## Validate

```bash
ansible all -i inventory/generated/hosts.yml -b -m command -a 'sshd -T'
ansible all -i inventory/generated/hosts.yml -b -m command -a 'sysctl kernel.randomize_va_space kernel.kptr_restrict'
ansible all -i inventory/generated/hosts.yml -b -m command -a 'systemctl is-active ssh systemd-journald systemd-timesyncd'
```

Capture the resulting state and compare manifests and selected evidence files:

```bash
bash scripts/capture-baseline.sh --strict --output artifacts/node-after
diff -u artifacts/node-before/security-settings.txt artifacts/node-after/security-settings.txt
```

## Recovery

If SSH validation fails, do not close the current terminal. Enter the node directly with `wsl -d linux-node1 -u root`, remove `/etc/ssh/sshd_config.d/70-secure-baseline.conf`, run `sshd -t`, and restart `ssh`. The role validates the generated SSH file before replacement, reducing but not eliminating service-level risk.
