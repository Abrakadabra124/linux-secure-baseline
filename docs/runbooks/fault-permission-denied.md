# Permission Denied

## Symptoms

A process can locate a file but receives `Permission denied`; the same operation may succeed under root and hide the real service-user problem.

## Hypotheses

- File mode, owner or group is incorrect.
- A parent directory lacks execute permission.
- The service runs under an unexpected UID or supplementary group.

## Commands

```bash
id
namei -l PATH
stat -c '%A %a %U:%G %n' PATH
getfacl PATH
journalctl -u SERVICE --since -10m
bash scripts/run-fault-scenario.sh permission-denied
```

## Root Cause

The scenario creates a non-sensitive temporary file with mode `000` and confirms that an unprivileged identity cannot read it. Permissions are restored before cleanup.

## Prevention

Manage ownership and modes as code, run tests as the service account, avoid blanket `chmod 777`, and verify parent directory permissions and ACLs.
