# Bootstrap the WSL2 Lab

## Purpose

Create a reproducible three-node Ubuntu lab for Linux administration and Ansible exercises:

- `linux-control` — Ansible control node, SSH port `2221`;
- `linux-node1` — managed node, SSH port `2222`;
- `linux-node2` — managed node, SSH port `2223`.

Each node is a separate WSL2 distribution. Existing distributions are never unregistered or overwritten.

## Prerequisites

1. Restart Windows after enabling WSL and Virtual Machine Platform.
2. Confirm that hardware virtualization is enabled in UEFI/BIOS.
3. Convert the base distribution and verify version `2`:

```powershell
wsl --set-version Ubuntu 2
wsl --list --verbose
```

The bootstrap stops before making changes if `Ubuntu` is not running as WSL2.

## Run

From an elevated or regular PowerShell terminal in the repository:

```powershell
task lab:bootstrap
```

The script exports the base Ubuntu distribution, imports three WSL2 nodes, enables systemd, creates the `devsecops` user, configures key-only SSH and writes an ignored inventory file to `inventory/generated/hosts.yml`.

The nodes use dedicated UIDs outside the base distribution's default range and unique SSH socket ports because WSL distributions share parts of the utility VM runtime and network namespace. Existing nodes are stopped before reconfiguration, so repeated bootstrap runs can safely change local identities. The script restarts only its own distributions and leaves unrelated WSL workloads such as Docker Desktop running. Hidden `wsl.exe` keepalive processes keep all three distributions running for the duration of the lab. The bootstrap also uses configurable public DNS fallbacks and HTTPS for Ubuntu security updates when the Windows VPN adapter cannot forward WSL DNS or HTTP traffic.

## Validate

```powershell
wsl --list --verbose
wsl -d linux-control -- systemctl is-system-running
wsl -d linux-node1 -- systemctl is-active ssh
wsl -d linux-node2 -- systemctl is-active ssh
```

Copy the generated inventory into the control node and run the Ansible smoke test:

```powershell
wsl -d linux-control -- mkdir -p /home/devsecops/lab/inventory
wsl -d linux-control -- cp /mnt/c/path/to/repository/inventory/generated/hosts.yml /home/devsecops/lab/inventory/hosts.yml
wsl -d linux-control -- ansible all -i /home/devsecops/lab/inventory/hosts.yml -m ping
```

Replace `/mnt/c/path/to/repository` with the repository path translated to WSL syntax.

## Security Notes

- Password authentication and root SSH login are disabled.
- The private key stays inside `linux-control`.
- The generated inventory, exports and keys are ignored by Git.
- Passwordless sudo is limited to this disposable local lab and must not be copied to production hosts.

## Troubleshooting

If conversion to WSL2 fails immediately after Windows features were enabled, restart Windows first. If it still fails, verify that virtualization is enabled in UEFI/BIOS and visible in Task Manager.
