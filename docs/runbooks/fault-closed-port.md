# Closed TCP Port

## Symptoms

Clients receive `Connection refused`; DNS succeeds and routing reaches the destination, but no application accepts the connection.

## Hypotheses

- The service is stopped or listening on another port.
- The service listens only on a different address family or interface.
- A firewall rejects the connection.

## Commands

```bash
ss -lntup
ip route get 127.0.0.1
curl --verbose --connect-timeout 2 http://127.0.0.1:PORT/
tcpdump -nn -i any 'tcp port PORT'
bash scripts/run-fault-scenario.sh closed-port
```

## Root Cause

The scenario reserves and releases a random loopback port, then proves that the TCP connection is refused because no listener owns that socket.

## Prevention

Add service readiness checks, verify listeners after deployment, alert on restart loops, and test network policy separately from process availability.
