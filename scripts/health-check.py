#!/usr/bin/env python3
import argparse
import json
import resource
import shutil
import subprocess
import sys
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Check essential Linux host capabilities.")
    parser.add_argument("--json", action="store_true", help="print machine-readable output")
    parser.add_argument(
        "--proc-root",
        type=Path,
        default=Path("/proc"),
        help="procfs root used for validation",
    )
    parser.add_argument(
        "--require-systemd-running",
        action="store_true",
        help="fail unless systemd reports running or degraded",
    )
    return parser.parse_args()


def command_available(command: str) -> bool:
    return shutil.which(command) is not None


def systemd_state() -> tuple[str, bool]:
    if not command_available("systemctl"):
        return "unavailable", False

    result = subprocess.run(
        ["systemctl", "is-system-running"],
        capture_output=True,
        check=False,
        text=True,
        timeout=5,
    )
    state = (result.stdout or result.stderr).strip() or "unknown"
    return state, state in {"running", "degraded"}


def proc_status_readable(proc_status: Path) -> bool:
    try:
        with proc_status.open(encoding="utf-8") as status_file:
            return bool(status_file.read(1))
    except (OSError, UnicodeError):
        return False


def main() -> int:
    args = parse_args()
    proc_status = args.proc_root / "1" / "status"
    soft_nofile, hard_nofile = resource.getrlimit(resource.RLIMIT_NOFILE)
    current_systemd_state, systemd_healthy = systemd_state()

    checks = {
        "proc_pid1_readable": proc_status_readable(proc_status),
        "nofile_soft_limit_positive": soft_nofile > 0,
        "nofile_limit_order_valid": hard_nofile == resource.RLIM_INFINITY
        or soft_nofile <= hard_nofile,
        "systemctl_available": command_available("systemctl"),
        "journalctl_available": command_available("journalctl"),
    }
    if args.require_systemd_running:
        checks["systemd_running"] = systemd_healthy

    healthy = all(checks.values())
    report = {
        "status": "healthy" if healthy else "failed",
        "checks": checks,
        "systemd_state": current_systemd_state,
        "nofile_soft": soft_nofile,
        "nofile_hard": "unlimited"
        if hard_nofile == resource.RLIM_INFINITY
        else hard_nofile,
    }

    if args.json:
        print(json.dumps(report, sort_keys=True))
    else:
        print(f"status={report['status']}")
        for check_name, passed in checks.items():
            print(f"{check_name}={'ok' if passed else 'failed'}")
        print(f"systemd_state={current_systemd_state}")
        print(f"nofile_soft={soft_nofile}")
        print(f"nofile_hard={report['nofile_hard']}")

    return 0 if healthy else 2


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except subprocess.TimeoutExpired:
        print("systemd_state=timeout", file=sys.stderr)
        raise SystemExit(2)
