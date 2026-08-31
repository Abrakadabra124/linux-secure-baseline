# DNS Resolution Failure

## Symptoms

Applications report `Name or service not known`, package downloads fail before connecting, and direct requests by IP may still work.

## Hypotheses

- The configured resolver is unreachable after a VPN or WSL network change.
- The queried record does not exist.
- Search domains or split-DNS rules send the query to the wrong resolver.

## Commands

```bash
cat /etc/resolv.conf
getent ahosts does-not-exist.invalid
dig does-not-exist.invalid
ip route
bash scripts/run-fault-scenario.sh dns
```

## Root Cause

The automated scenario queries the reserved `.invalid` namespace and proves that name resolution fails before any TCP handshake occurs. In the WSL lab, compare this deterministic failure with resolver reachability before replacing `/etc/resolv.conf`.

## Prevention

Monitor resolver latency and failure rate, preserve VPN-aware DNS configuration, test fallback resolvers, and distinguish NXDOMAIN from resolver timeout in alerts.
