# Expired TLS Certificate

## Symptoms

TLS clients reject the peer certificate even though DNS and the TCP handshake succeed. Monitoring may show a certificate expiration or verification error.

## Hypotheses

- The leaf certificate is expired.
- The server presents the wrong certificate or an incomplete chain.
- Client time is incorrect.

## Commands

```bash
openssl s_client -connect HOST:443 -servername HOST -showcerts </dev/null
openssl x509 -in certificate.crt -noout -subject -issuer -dates
openssl x509 -in certificate.crt -checkend 604800
curl --verbose https://HOST/
bash scripts/run-fault-scenario.sh expired-certificate
```

## Root Cause

The repository fixture expired on 2 January 2020. The scenario validates it with `openssl x509 -checkend 0` and expects rejection without starting a network service or storing a private key.

## Prevention

Automate renewal, alert before the full chain expires, validate the served certificate after deployment, and keep host time synchronized.
