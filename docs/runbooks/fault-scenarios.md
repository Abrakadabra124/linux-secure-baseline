# Fault Scenario Catalog

Week 3 uses deterministic failures that do not modify DNS settings, firewall rules or production files. Every scenario writes `evidence.log` and `summary.env` under an ignored output directory and returns success only when the expected failure is observed.

## Run All Scenarios

```bash
task faults:test
```

## Run One Scenario

```bash
bash scripts/run-fault-scenario.sh dns
bash scripts/run-fault-scenario.sh closed-port
bash scripts/run-fault-scenario.sh expired-certificate
bash scripts/run-fault-scenario.sh permission-denied
bash scripts/run-fault-scenario.sh disk-full
```

## Exit Codes

| Code | Meaning |
|---:|---|
| 0 | Expected failure reproduced |
| 1 | Scenario unexpectedly succeeded |
| 64 | Invalid arguments |
| 69 | Required command or fixture unavailable |

## Runbooks

- [DNS resolution failure](fault-dns.md)
- [Closed TCP port](fault-closed-port.md)
- [Expired TLS certificate](fault-expired-certificate.md)
- [Permission denied](fault-permission-denied.md)
- [No space left on device](fault-disk-full.md)

The DNS scenario uses the reserved `.invalid` namespace. The disk scenario writes one byte to `/dev/full`, which deterministically returns `ENOSPC`; it does not consume the workstation filesystem.
