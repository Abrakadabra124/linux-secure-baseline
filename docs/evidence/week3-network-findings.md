# Week 3 Network Findings

## Incident

The base Ubuntu distribution inherited the generated WSL resolver `172.22.192.1` while the Windows host used an active tunnel adapter. `getent` and `dig` timed out, and a Bash TCP check could not resolve `github.com`.

At the same time, `openssl s_client` completed a verified TLS 1.3 handshake and `curl` received HTTP 200 through the host VPN path. This split result proved that application traffic could be transparently forwarded while the Linux resolver path remained broken.

## Comparison

| Check | Base Ubuntu | `linux-control` |
|---|---|---|
| Resolver | Generated WSL DNS, timeout | Static public fallback resolvers |
| DNS evidence | Failed | Healthy |
| TCP evidence | Failed before name resolution | Connected |
| TLS verification | Healthy through tunnel | Healthy |
| HTTP request | Healthy through tunnel | Healthy |
| Diagnostic result | `critical_failures=2` | `critical_failures=0` |

## Root Cause

The active Windows tunnel did not forward requests sent to the WSL virtual DNS address. The lab bootstrap already handled this condition by disabling generated `resolv.conf` for its managed distributions and writing explicit fallback resolvers.

## Recovery

1. Capture `/etc/resolv.conf`, `ip route`, `getent`, `dig`, TLS and HTTP evidence before changing configuration.
2. Confirm a resolver timeout rather than an absent DNS record.
3. Apply a documented fallback resolver only to the affected lab distribution.
4. Repeat the layered diagnostic and verify its SHA-256 manifest.

## Prevention

- Run the network diagnostic after VPN, proxy, sleep or WSL lifecycle changes.
- Keep resolver changes scoped and reproducible instead of editing generated files manually.
- Alert separately on DNS, TCP, TLS and HTTP failures because a transparent tunnel can make higher-layer checks succeed while libc DNS remains unavailable.
- Do not claim per-node routing isolation in WSL2; the distributions share the Windows-managed network backend.
