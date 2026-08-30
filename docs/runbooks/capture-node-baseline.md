# Capture a Node Baseline

## Purpose

Record the observable state of a Linux node before hardening. The snapshot provides reviewable evidence for later configuration changes and incident-style troubleshooting exercises.

## Collected Evidence

- operating system, kernel, uptime and process state;
- local login users and resource limits;
- failed and running systemd services;
- interfaces, routes, listeners and resolver state;
- time synchronization status;
- installed package versions;
- selected kernel, SSH and firewall security settings;
- permissions on authentication and authorization files.

The script never reads password hashes, private keys or environment variables. Output can still contain usernames, internal addresses and package data, so `artifacts/` is excluded from Git.

## Run

```bash
task baseline
```

Use strict mode when all privileged and systemd-backed checks are expected to work:

```bash
bash scripts/capture-baseline.sh --strict --output artifacts/node1-before
```

Exit codes:

- `0` — snapshot completed; non-strict mode may contain warnings;
- `2` — strict mode detected incomplete evidence;
- `64` — command-line usage error.

## Validate Integrity

```bash
cd artifacts/node1-before
sha256sum --check manifest.sha256
cat warnings.txt
```

Store only sanitized summaries or intentionally published demo artifacts in Git. Keep raw snapshots local.
