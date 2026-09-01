# Linux Operations Lab

This lab exercises the Week 2 administration primitives without changing host-wide configuration.

```bash
task health:test
task linux:lab
task linux:test
```

The Python health-check validates procfs, process limits, `systemctl` and `journalctl`. It returns `0` when required checks pass and `2` when a health invariant fails. Use `--require-systemd-running` on the WSL2 lab nodes.

The operations lab records:

- the systemd manager state and recent journal access;
- a mode `0640` permission fixture;
- `/proc/PID/status` for a temporary process;
- delivery and observation of `SIGTERM`;
- current soft and hard process limits.

Evidence is written under ignored `artifacts/` with private permissions and a SHA-256 manifest. The temporary process and file are removed by the cleanup trap, including interruption paths.
