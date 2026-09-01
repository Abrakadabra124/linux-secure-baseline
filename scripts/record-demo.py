#!/usr/bin/env python3
import argparse
import json
import os
import pty
import select
import subprocess
import time
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Record the Weeks 2-4 demo as asciicast v2.")
    parser.add_argument("--output", type=Path, required=True, help="target .cast file")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    args.output.parent.mkdir(parents=True, exist_ok=True)
    master_fd, slave_fd = pty.openpty()
    started_at = time.monotonic()
    process = subprocess.Popen(
        ["bash", "scripts/demo-weeks-2-4.sh"],
        stdin=subprocess.DEVNULL,
        stdout=slave_fd,
        stderr=slave_fd,
        close_fds=True,
    )
    os.close(slave_fd)

    header = {
        "version": 2,
        "width": 120,
        "height": 30,
        "timestamp": int(time.time()),
        "env": {"SHELL": "/bin/bash", "TERM": "xterm-256color"},
        "title": "linux-secure-baseline Weeks 2-4",
    }

    with args.output.open("w", encoding="utf-8", newline="\n") as cast_file:
        cast_file.write(json.dumps(header, separators=(",", ":")) + "\n")
        stream_open = True
        while True:
            readable, _, _ = select.select([master_fd], [], [], 0.1)
            if master_fd in readable:
                try:
                    output = os.read(master_fd, 65536)
                except OSError:
                    output = b""
                if output:
                    event = [round(time.monotonic() - started_at, 6), "o", output.decode("utf-8", "replace")]
                    cast_file.write(json.dumps(event, separators=(",", ":")) + "\n")
                    cast_file.flush()
                else:
                    stream_open = False
            if process.poll() is not None and not stream_open:
                break

    os.close(master_fd)
    return process.returncode


if __name__ == "__main__":
    raise SystemExit(main())
