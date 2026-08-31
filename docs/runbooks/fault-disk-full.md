# No Space Left on Device

## Symptoms

Writes fail with `No space left on device`, applications stop persisting state, and logging or package operations may fail unexpectedly.

## Hypotheses

- Filesystem blocks or inodes are exhausted.
- Deleted files remain open by a process.
- Logs, container layers or temporary files grow without limits.

## Commands

```bash
df -hT
df -ih
du -xhd1 /var | sort -h
lsof +L1
journalctl --disk-usage
bash scripts/run-fault-scenario.sh disk-full
```

## Root Cause

The automated scenario writes to `/dev/full`, a deterministic Linux device that always returns `ENOSPC`. This tests error handling without consuming real filesystem capacity.

## Prevention

Alert on blocks and inodes, enforce log retention, set container storage limits, reserve emergency capacity, and document safe cleanup and rollback procedures.
