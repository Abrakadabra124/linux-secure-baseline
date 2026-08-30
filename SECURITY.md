# Security Policy

## Supported Version

Security fixes apply to the latest commit on `main` until the first tagged release is published.

## Repository Rules

- Never commit passwords, tokens, SSH private keys or generated WSL exports.
- Use test fixtures that cannot authenticate to any real system.
- Keep generated inventory and evidence under ignored local paths.
- Review third-party actions and pin them to immutable commit SHAs.

## Reporting

Open a private GitHub security advisory for a vulnerability that exposes credentials or enables unintended access. Use a regular issue for hardening suggestions without sensitive details.
