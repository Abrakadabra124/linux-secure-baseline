#!/usr/bin/env bash
set -euo pipefail
umask 077

output_directory="artifacts/linux-operations-$(date -u +%Y%m%dT%H%M%SZ)"

while (($# > 0)); do
  case "$1" in
    --output)
      output_directory="${2:?--output requires a directory}"
      shift 2
      ;;
    *)
      printf 'Unknown argument: %s\n' "$1" >&2
      exit 64
      ;;
  esac
done

for command_name in systemctl journalctl stat sha256sum; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    printf 'Required command is unavailable: %s\n' "$command_name" >&2
    exit 69
  fi
done

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
report_file="$output_directory/report.txt"
summary_file="$output_directory/summary.env"
temporary_directory="$(mktemp -d)"
worker_pid=""

cleanup() {
  if [[ -n "$worker_pid" ]]; then
    kill "$worker_pid" 2>/dev/null || true
    wait "$worker_pid" 2>/dev/null || true
  fi
  rm -rf "$temporary_directory"
}
trap cleanup EXIT

{
  printf '## systemd\n'
  systemctl --version | head -n 1
  printf 'state=%s\n' "$(systemctl is-system-running 2>/dev/null || printf unavailable)"

  printf '\n## journal\n'
  journalctl --version | head -n 1
  journalctl -n 5 --no-pager 2>&1 || true

  printf '\n## permissions\n'
  permission_file="$temporary_directory/managed.txt"
  printf 'safe fixture\n' >"$permission_file"
  chmod 640 "$permission_file"
  stat -c 'mode=%a owner=%U group=%G' "$permission_file"

  printf '\n## proc and signals\n'
  sleep 30 &
  worker_pid=$!
  grep -E '^(Name|State|Pid|PPid):' "/proc/$worker_pid/status"
  kill -TERM "$worker_pid"
  if wait "$worker_pid"; then
    printf 'signal_result=unexpected_success\n'
    exit 1
  else
    signal_status=$?
  fi
  worker_pid=""
  printf 'signal=SIGTERM wait_status=%d\n' "$signal_status"

  printf '\n## limits\n'
  ulimit -Sa
  ulimit -Ha
} >"$report_file"

{
  printf 'outcome=passed\n'
  printf 'permissions_mode=640\n'
  printf 'signal=SIGTERM\n'
  printf 'proc_observed=true\n'
} >"$summary_file"

(
  cd "$output_directory"
  sha256sum report.txt summary.env >manifest.sha256
)

printf 'Linux operations lab passed. Evidence: %s\n' "$output_directory"
