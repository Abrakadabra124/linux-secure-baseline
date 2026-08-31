#!/usr/bin/env bash
set -uo pipefail

usage() {
  cat <<'EOF'
Usage: diagnose-network.sh [OPTIONS]

Options:
  --host HOST          DNS name or IPv4 address (default: example.com)
  --port PORT          TCP port (default: 443)
  --scheme SCHEME      http or https (default: https)
  --output DIRECTORY   Evidence directory
  -h, --help           Show help

Exit codes:
  0   Resolution, route, TCP and application checks pass
  2   One or more critical path checks fail
  64  Invalid arguments
  69  Required diagnostic command is unavailable
EOF
}

target_host="example.com"
target_port=443
target_scheme="https"
output_directory="artifacts/network-$(date -u +%Y%m%dT%H%M%SZ)"

while (($# > 0)); do
  case "$1" in
    --host)
      target_host="${2:?--host requires a value}"
      shift 2
      ;;
    --port)
      target_port="${2:?--port requires a value}"
      shift 2
      ;;
    --scheme)
      target_scheme="${2:?--scheme requires a value}"
      shift 2
      ;;
    --output)
      output_directory="${2:?--output requires a directory}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 64
      ;;
  esac
done

if [[ ! "$target_host" =~ ^[A-Za-z0-9.-]+$ ]]; then
  printf 'Invalid host: %s\n' "$target_host" >&2
  exit 64
fi
if [[ ! "$target_port" =~ ^[0-9]+$ ]] || ((target_port < 1 || target_port > 65535)); then
  printf 'Invalid port: %s\n' "$target_port" >&2
  exit 64
fi
if [[ "$target_scheme" != "http" && "$target_scheme" != "https" ]]; then
  printf 'Invalid scheme: %s\n' "$target_scheme" >&2
  exit 64
fi

required_commands=(getent ip ss curl sed timeout sha256sum)
if [[ "$target_scheme" == "https" ]]; then
  required_commands+=(openssl)
fi
for command_name in "${required_commands[@]}"; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    printf 'Required command is unavailable: %s\n' "$command_name" >&2
    exit 69
  fi
done

mkdir -p "$output_directory"
report_file="$output_directory/report.txt"
summary_file="$output_directory/summary.env"
critical_failures=0

section() {
  printf '\n## %s\n' "$1" >>"$report_file"
}

{
  printf 'captured_at_utc=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf 'target=%s://%s:%s\n' "$target_scheme" "$target_host" "$target_port"
  printf 'hostname=%s\n' "$(hostname)"
  printf 'kernel=%s\n' "$(uname -sr)"
} >"$report_file"

section "Resolver configuration"
cat /etc/resolv.conf >>"$report_file" 2>&1 || true

section "DNS resolution"
if resolution_output="$(getent ahostsv4 "$target_host" 2>&1)" && [[ -n "$resolution_output" ]]; then
  printf '%s\n' "$resolution_output" >>"$report_file"
  target_address="$(awk 'NR == 1 { print $1 }' <<<"$resolution_output")"
else
  printf '%s\n' "$resolution_output" >>"$report_file"
  target_address=""
  critical_failures=$((critical_failures + 1))
fi
if command -v dig >/dev/null 2>&1; then
  dig +time=2 +tries=1 "$target_host" >>"$report_file" 2>&1 || true
fi

section "Routing and interfaces"
ip -brief address >>"$report_file" 2>&1 || true
ip route >>"$report_file" 2>&1 || true
if [[ -n "$target_address" ]]; then
  if ! ip route get "$target_address" >>"$report_file" 2>&1; then
    critical_failures=$((critical_failures + 1))
  fi
fi

section "Socket state"
ss -lntup >>"$report_file" 2>&1 || true

section "TCP handshake"
if timeout 5 bash -c "exec 3<>/dev/tcp/${target_host}/${target_port}" >>"$report_file" 2>&1; then
  printf 'tcp_status=connected\n' >>"$report_file"
else
  printf 'tcp_status=failed\n' >>"$report_file"
  critical_failures=$((critical_failures + 1))
fi

if [[ "$target_scheme" == "https" ]]; then
  section "TLS handshake"
  if timeout 8 openssl s_client \
    -connect "${target_host}:${target_port}" \
    -servername "$target_host" \
    -verify_return_error </dev/null >>"$report_file" 2>&1; then
    printf 'tls_status=verified\n' >>"$report_file"
  else
    printf 'tls_status=failed\n' >>"$report_file"
    critical_failures=$((critical_failures + 1))
  fi
fi

section "Application request"
if application_output="$(curl --silent --show-error --head \
  --connect-timeout 5 --max-time 10 \
  "${target_scheme}://${target_host}:${target_port}/" 2>&1)"; then
  sed -E 's/^(set-cookie:).*/\1 [redacted]/I' <<<"$application_output" >>"$report_file"
  printf 'application_status=reachable\n' >>"$report_file"
else
  sed -E 's/^(set-cookie:).*/\1 [redacted]/I' <<<"$application_output" >>"$report_file"
  printf 'application_status=failed\n' >>"$report_file"
  critical_failures=$((critical_failures + 1))
fi

section "Path trace"
if command -v traceroute >/dev/null 2>&1 && [[ -n "$target_address" ]]; then
  traceroute -n -m 5 -w 1 "$target_address" >>"$report_file" 2>&1 || true
else
  printf 'traceroute unavailable or target unresolved\n' >>"$report_file"
fi

if ((critical_failures == 0)); then
  diagnostic_status="healthy"
else
  diagnostic_status="failed"
fi

{
  printf 'status=%s\n' "$diagnostic_status"
  printf 'critical_failures=%d\n' "$critical_failures"
  printf 'target_host=%s\n' "$target_host"
  printf 'target_port=%s\n' "$target_port"
  printf 'target_scheme=%s\n' "$target_scheme"
  printf 'target_address=%s\n' "$target_address"
} >"$summary_file"

(
  cd "$output_directory" || exit
  sha256sum report.txt summary.env >manifest.sha256
)

printf 'status=%s critical_failures=%d evidence=%s\n' \
  "$diagnostic_status" "$critical_failures" "$output_directory"

if ((critical_failures > 0)); then
  exit 2
fi
