#!/usr/bin/env python3
import argparse
import hashlib
import http.client
import json
import os
import shutil
import subprocess
import threading
import time
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path


class BackendHandler(BaseHTTPRequestHandler):
    def do_GET(self) -> None:
        body = json.dumps({"service": "backend", "status": "ok"}).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, format_string: str, *args: object) -> None:
        return


class ProxyHandler(BaseHTTPRequestHandler):
    backend_port = 0

    def do_GET(self) -> None:
        connection = http.client.HTTPConnection("127.0.0.1", self.backend_port, timeout=3)
        try:
            connection.request(
                "GET",
                self.path,
                headers={
                    "Host": "backend.internal",
                    "X-Forwarded-For": self.client_address[0],
                    "X-Forwarded-Proto": "http",
                },
            )
            response = connection.getresponse()
            body = response.read()
            response_status = response.status
            response_type = response.getheader("Content-Type", "application/octet-stream")
        finally:
            connection.close()

        self.send_response(response_status)
        self.send_header("Content-Type", response_type)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Via", "devsecops-loopback-proxy")
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, format_string: str, *args: object) -> None:
        return


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Run a safe loopback reverse-proxy lab.")
    parser.add_argument("--output", type=Path, required=True, help="evidence directory")
    parser.add_argument(
        "--check-egress-nat",
        action="store_true",
        help="compare the private route source with a redacted public egress address",
    )
    return parser.parse_args()


def prepare_output_directory(output_directory: Path) -> None:
    if output_directory.is_symlink() or (output_directory.exists() and not output_directory.is_dir()):
        raise ValueError(f"Output path must be a real directory: {output_directory}")
    if output_directory.is_dir() and any(output_directory.iterdir()):
        raise ValueError(f"Output directory must be empty: {output_directory}")
    output_directory.mkdir(mode=0o700, parents=True, exist_ok=True)
    output_directory.chmod(0o700)


def run_command(command: list[str]) -> str:
    result = subprocess.run(command, capture_output=True, check=False, text=True, timeout=8)
    return f"$ {' '.join(command)}\nexit={result.returncode}\n{result.stdout}{result.stderr}"


def start_packet_capture(proxy_port: int, backend_port: int) -> subprocess.Popen[str] | None:
    if not shutil.which("tcpdump") or not shutil.which("sudo"):
        return None
    return subprocess.Popen(
        [
            "sudo",
            "-n",
            "tcpdump",
            "-nn",
            "-i",
            "lo",
            "-c",
            "4",
            f"tcp port {proxy_port} or tcp port {backend_port}",
        ],
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
    )


def capture_egress_nat() -> dict[str, object]:
    route = subprocess.run(
        ["ip", "route", "get", "1.1.1.1"],
        capture_output=True,
        check=False,
        text=True,
        timeout=5,
    )
    source_address = ""
    route_fields = route.stdout.split()
    if "src" in route_fields:
        source_address = route_fields[route_fields.index("src") + 1]

    try:
        with urllib.request.urlopen("https://api.ipify.org", timeout=8) as response:
            egress_address = response.read(128).decode().strip()
    except Exception:
        return {
            "checked": True,
            "private_source_observed": bool(source_address),
            "public_egress_observed": False,
            "translation_observed": False,
        }

    return {
        "checked": True,
        "private_source_observed": bool(source_address),
        "public_egress_observed": bool(egress_address),
        "translation_observed": bool(source_address and egress_address != source_address),
    }


def main() -> int:
    args = parse_args()
    os.umask(0o077)
    try:
        prepare_output_directory(args.output)
    except ValueError as error:
        print(error)
        return 64

    backend = ThreadingHTTPServer(("127.0.0.1", 0), BackendHandler)
    ProxyHandler.backend_port = backend.server_port
    proxy = ThreadingHTTPServer(("127.0.0.1", 0), ProxyHandler)
    backend_thread = threading.Thread(target=backend.serve_forever, daemon=True)
    proxy_thread = threading.Thread(target=proxy.serve_forever, daemon=True)
    backend_thread.start()
    proxy_thread.start()

    packet_capture = start_packet_capture(proxy.server_port, backend.server_port)
    if packet_capture is not None:
        time.sleep(0.3)

    request = urllib.request.Request(f"http://127.0.0.1:{proxy.server_port}/health")
    with urllib.request.urlopen(request, timeout=5) as response:
        response_body = json.loads(response.read())
        proxy_status = response.status
        via_header = response.headers.get("Via", "")

    with urllib.request.urlopen(request, timeout=5) as response:
        response.read()

    packet_output = "tcpdump_unavailable_or_not_permitted\n"
    if packet_capture is not None:
        try:
            packet_output, _ = packet_capture.communicate(timeout=5)
        except subprocess.TimeoutExpired:
            packet_capture.terminate()
            packet_output, _ = packet_capture.communicate(timeout=2)

    proxy.shutdown()
    backend.shutdown()
    proxy.server_close()
    backend.server_close()

    network_report = "\n\n".join(
        [
            run_command(["ip", "-brief", "address"]),
            run_command(["ip", "route"]),
            run_command(["ip", "route", "get", "127.0.0.1"]),
            run_command(["ss", "-lnt"]),
            run_command(["traceroute", "-n", "-m", "3", "127.0.0.1"])
            if shutil.which("traceroute")
            else "traceroute unavailable",
        ]
    )
    nat_evidence = (
        capture_egress_nat()
        if args.check_egress_nat
        else {"checked": False, "reason": "network-independent mode"}
    )
    passed = (
        proxy_status == 200
        and via_header == "devsecops-loopback-proxy"
        and response_body == {"service": "backend", "status": "ok"}
    )

    summary = {
        "outcome": "passed" if passed else "failed",
        "proxy_status": proxy_status,
        "via_header": via_header,
        "backend_response": response_body,
        "nat": nat_evidence,
        "tcpdump_capture_observed": " IP " in packet_output,
    }
    (args.output / "summary.json").write_text(
        json.dumps(summary, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    (args.output / "network.txt").write_text(network_report + "\n", encoding="utf-8")
    (args.output / "tcpdump.txt").write_text(packet_output, encoding="utf-8")

    manifest_lines = []
    for evidence_file in ("network.txt", "summary.json", "tcpdump.txt"):
        digest = hashlib.sha256((args.output / evidence_file).read_bytes()).hexdigest()
        manifest_lines.append(f"{digest}  {evidence_file}")
    (args.output / "manifest.sha256").write_text("\n".join(manifest_lines) + "\n", encoding="utf-8")

    print(json.dumps(summary, sort_keys=True))
    return 0 if passed else 2


if __name__ == "__main__":
    raise SystemExit(main())
