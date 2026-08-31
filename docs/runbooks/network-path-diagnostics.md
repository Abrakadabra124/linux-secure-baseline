# Network Path Diagnostics

Use the diagnostic script before changing DNS, routes, firewall rules, certificates or reverse-proxy configuration. It records each layer independently and returns exit code `2` when a critical check fails.
HTTP `Set-Cookie` values are redacted before evidence is written.

## Capture a Public HTTPS Path

```bash
bash scripts/diagnose-network.sh \
  --host example.com \
  --port 443 \
  --scheme https
```

## Validate the Script Locally

```bash
task network:test
```

The test starts a temporary Python HTTP server on loopback, captures evidence, validates its SHA-256 manifest and removes the server.

## Layer Model

| Layer | Primary evidence | Typical root cause |
|---|---|---|
| DNS | `/etc/resolv.conf`, `getent`, `dig` | resolver, split DNS, missing record |
| Routing | `ip address`, `ip route`, `ip route get` | missing route, wrong interface, VPN policy |
| NAT | source address before and after WSL/host boundary | stale WSL NAT, host forwarding, overlapping subnets |
| TCP | `ss`, `/dev/tcp`, `tcpdump` | no listener, reject/drop, asymmetric route |
| TLS | `openssl s_client`, certificate dates and chain | expired certificate, SNI, trust chain, clock |
| Reverse proxy | `curl -v`, proxy access/error logs, upstream listener | wrong upstream, timeout, header or TLS mismatch |

## WSL NAT Comparison

From Linux:

```bash
ip -brief address
ip route
curl --silent https://api.ipify.org
```

From elevated Windows PowerShell:

```powershell
Get-NetAdapter | Where-Object Status -eq 'Up'
Get-NetIPConfiguration
Get-NetNat
```

WSL2 distributions share the Windows-managed network backend. A route or sysctl observation is therefore evidence about the shared utility VM, not proof of independent per-distribution networking.

## TCP Capture

Run packet capture only after narrowing the host and port:

```bash
sudo tcpdump -nn -i any "host TARGET_IP and tcp port TARGET_PORT"
```

Interpret `SYN` without `SYN-ACK` as a path or filtering problem. Interpret an immediate `RST` as a reachable host without a matching listener. Confirm with service logs before changing a firewall.

## Reverse Proxy Checks

```bash
curl --verbose --header 'Host: expected.example' http://PROXY_IP/
ss -lntup
journalctl -u nginx --since -10m
sudo nginx -T
curl --verbose http://UPSTREAM_IP:UPSTREAM_PORT/health
```

Validate the client-to-proxy and proxy-to-upstream paths separately. A healthy public listener does not prove that DNS, SNI, upstream routing or the backend health check is correct.
