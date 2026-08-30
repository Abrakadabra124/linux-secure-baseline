# Runbook: Host Prerequisites

## Purpose

Validate that a Linux instance can participate in the baseline lab before applying configuration.

## Check

```bash
task verify:strict
```

## Expected Result

The report identifies Ubuntu, cgroups v2, the virtualization backend and every required command. Exit code `0` means the host is ready for the next bootstrap step.

## Common Failures

### `ip` or `ss` is missing

Install `iproute2`:

```bash
sudo apt-get update
sudo apt-get install -y iproute2
```

### `systemctl` cannot connect to the bus

Confirm systemd is enabled in `/etc/wsl.conf`, then shut down and restart WSL from Windows:

```ini
[boot]
systemd=true
```

### DNS resolution fails after VPN change

Capture `/etc/resolv.conf`, `ip route`, `getent hosts example.com` and the Windows DNS configuration before changing files. Restart WSL only after preserving the evidence.

## Escalation Evidence

- Full capability report
- `/etc/os-release`
- `uname -a`
- `ip address` and `ip route`
- `systemctl is-system-running`
- Exact command, exit code and timestamp
