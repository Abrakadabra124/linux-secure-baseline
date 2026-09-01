#!/usr/bin/env bash
set -uo pipefail
umask 077

usage() {
  cat <<'EOF'
Usage: run-fault-scenario.sh SCENARIO [--output DIRECTORY]

Scenarios:
  dns
  closed-port
  expired-certificate
  permission-denied
  disk-full

Exit codes:
  0   Expected failure was reproduced
  1   Scenario did not reproduce the expected failure
  64  Invalid arguments
  69  Required command or fixture is unavailable
EOF
}

scenario="${1:-}"
if [[ -z "$scenario" || "$scenario" == "--help" || "$scenario" == "-h" ]]; then
  usage
  [[ -n "$scenario" ]] && exit 0
  exit 64
fi
shift

output_directory="artifacts/faults/${scenario}-$(date -u +%Y%m%dT%H%M%SZ)"
while (($# > 0)); do
  case "$1" in
    --output)
      output_directory="${2:?--output requires a directory}"
      shift 2
      ;;
    *)
      printf 'Unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 64
      ;;
  esac
done

script_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -L "$output_directory" || (-e "$output_directory" && ! -d "$output_directory") ]]; then
  printf 'Output path must be a real directory: %s\n' "$output_directory" >&2
  exit 64
fi
if [[ -d "$output_directory" ]] && find "$output_directory" -mindepth 1 -print -quit | grep -q .; then
  printf 'Output directory must be empty: %s\n' "$output_directory" >&2
  exit 64
fi
mkdir -p "$output_directory"
chmod 0700 "$output_directory"
evidence_file="$output_directory/evidence.log"
summary_file="$output_directory/summary.env"
: >"$evidence_file"

require_commands() {
  local command_name
  for command_name in "$@"; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
      printf 'Required command is unavailable: %s\n' "$command_name" >&2
      exit 69
    fi
  done
}

finish() {
  local outcome="$1"
  local detail="$2"
  {
    printf 'scenario=%s\n' "$scenario"
    printf 'outcome=%s\n' "$outcome"
    printf 'captured_at_utc=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    printf 'detail=%s\n' "$detail"
  } >"$summary_file"
  printf '%s: %s\nEvidence: %s\n' "$outcome" "$detail" "$output_directory"
  [[ "$outcome" == "expected_failure" ]]
}

case "$scenario" in
  dns)
    require_commands getent timeout
    dns_name="does-not-exist.invalid"
    printf 'query=%s\n' "$dns_name" >>"$evidence_file"
    if timeout 10 getent ahosts "$dns_name" >>"$evidence_file" 2>&1; then
      finish unexpected_success "reserved invalid DNS name resolved"
    else
      finish expected_failure "DNS resolution failed for the reserved .invalid name"
    fi
    ;;

  closed-port)
    require_commands curl python3
    closed_port="$(python3 - <<'PY'
import socket

with socket.socket() as listener:
    listener.bind(("127.0.0.1", 0))
    print(listener.getsockname()[1])
PY
)"
    printf 'target=127.0.0.1:%s\n' "$closed_port" >>"$evidence_file"
    if curl --silent --show-error --connect-timeout 2 "http://127.0.0.1:${closed_port}/" >>"$evidence_file" 2>&1; then
      finish unexpected_success "connection to the released local port succeeded"
    else
      finish expected_failure "TCP connection was refused on a closed local port"
    fi
    ;;

  expired-certificate)
    require_commands openssl
    certificate_path="$script_directory/fixtures/expired-certificate.crt"
    if [[ ! -r "$certificate_path" ]]; then
      printf 'Certificate fixture is unavailable: %s\n' "$certificate_path" >&2
      exit 69
    fi
    openssl x509 -in "$certificate_path" -noout -subject -issuer -dates >"$evidence_file" 2>&1
    if openssl x509 -in "$certificate_path" -checkend 0 >>"$evidence_file" 2>&1; then
      finish unexpected_success "certificate fixture is not expired"
    else
      finish expected_failure "OpenSSL rejected the expired test certificate"
    fi
    ;;

  permission-denied)
    require_commands chmod
    restricted_file="$output_directory/restricted.txt"
    printf 'non-sensitive test fixture\n' >"$restricted_file"
    chmod 000 "$restricted_file"
    if ((EUID == 0)); then
      require_commands runuser
      if runuser -u nobody -- cat "$restricted_file" >>"$evidence_file" 2>&1; then
        permission_result=0
      else
        permission_result=$?
      fi
    elif cat "$restricted_file" >>"$evidence_file" 2>&1; then
      permission_result=0
    else
      permission_result=$?
    fi
    chmod 600 "$restricted_file"
    if ((permission_result == 0)); then
      finish unexpected_success "mode 000 file was readable by an unprivileged user"
    else
      finish expected_failure "read access was denied by filesystem permissions"
    fi
    ;;

  disk-full)
    require_commands dd
    if dd if=/dev/zero of=/dev/full bs=1 count=1 status=none >>"$evidence_file" 2>&1; then
      finish unexpected_success "/dev/full accepted a write"
    else
      finish expected_failure "the deterministic /dev/full device returned ENOSPC"
    fi
    ;;

  *)
    printf 'Unknown scenario: %s\n' "$scenario" >&2
    usage >&2
    exit 64
    ;;
esac
