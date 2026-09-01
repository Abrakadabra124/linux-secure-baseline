# Weeks 2-4 Terminal Demo

`weeks-2-4.cast` is a real terminal recording captured on the `linux-control` WSL2 node. It runs the health-check, Linux operations exercise, all five deterministic failures, network and reverse-proxy tests, Ansible connectivity, idempotent convergence, effective-state verification and the unsafe-input negative test.

Play it locally:

```bash
asciinema play docs/demo/weeks-2-4.cast
```

Re-record after a material change without external dependencies:

```bash
python3 scripts/record-demo.py --output docs/demo/weeks-2-4.cast
```

The recorder uses a Linux pseudo-terminal and writes the open asciicast v2 format. `asciinema` is needed only for optional playback.

The recording contains only repository test output and lab host aliases. Raw baseline, public egress addresses, credentials and local Windows paths are excluded.
