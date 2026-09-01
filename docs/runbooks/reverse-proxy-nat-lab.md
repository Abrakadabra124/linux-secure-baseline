# Reverse Proxy and NAT Lab

The lab starts a backend and a reverse proxy on random loopback ports. The proxy has a fixed loopback upstream, adds forwarding headers, and returns a `Via` marker. No privileged port, production configuration or external upstream is used.

```bash
task network:lab:test
task network:lab
```

On the WSL2 control node, run the optional NAT observation:

```bash
task network:lab:nat
```

The NAT mode compares the private source selected by `ip route get` with an HTTPS egress address. The address itself is never stored. A network failure leaves the reverse-proxy result valid while marking public egress as unobserved.

When passwordless lab sudo and `tcpdump` are available, the script captures four loopback packets using a port-restricted filter. Otherwise it records that packet capture was unavailable without weakening the proxy behavior test. `ip`, `ss` and `traceroute` output are stored in the ignored evidence directory.

Interpretation:

- `proxy_status=200` and the expected `Via` header prove the client-to-proxy-to-backend flow;
- `tcpdump_capture_observed=true` proves packets were observed on loopback;
- `translation_observed=true` proves the WSL private source and public egress differ;
- a failed egress observation is a network/VPN diagnostic result, not permission to change DNS or firewall configuration.
