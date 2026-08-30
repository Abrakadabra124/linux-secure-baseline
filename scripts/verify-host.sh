#!/usr/bin/env bash
set -euo pipefail

strict=false
if [[ "${1:-}" == "--strict" ]]; then
  strict=true
fi

required_commands=(bash systemctl journalctl ip ss openssl curl python3)
optional_commands=(ansible ansible-lint dig tcpdump traceroute)
missing_required=()

printf 'Linux host capability report\n'
printf '%-22s %s\n' 'Kernel' "$(uname -srmo)"

if [[ -r /etc/os-release ]]; then
  . /etc/os-release
  printf '%-22s %s\n' 'Operating system' "${PRETTY_NAME:-unknown}"
fi

if command -v systemd-detect-virt >/dev/null 2>&1; then
  printf '%-22s %s\n' 'Virtualization' "$(systemd-detect-virt 2>/dev/null || printf 'none')"
fi

if [[ -f /sys/fs/cgroup/cgroup.controllers ]]; then
  printf '%-22s %s\n' 'Cgroups' 'v2'
else
  printf '%-22s %s\n' 'Cgroups' 'v1 or unavailable'
fi

printf '\nRequired commands\n'
for command_name in "${required_commands[@]}"; do
  if command -v "$command_name" >/dev/null 2>&1; then
    printf '  [ok]      %s\n' "$command_name"
  else
    printf '  [missing] %s\n' "$command_name"
    missing_required+=("$command_name")
  fi
done

printf '\nOptional commands\n'
for command_name in "${optional_commands[@]}"; do
  if command -v "$command_name" >/dev/null 2>&1; then
    printf '  [ok]      %s\n' "$command_name"
  else
    printf '  [missing] %s\n' "$command_name"
  fi
done

if [[ ${#missing_required[@]} -gt 0 ]]; then
  printf '\nMissing required commands: %s\n' "${missing_required[*]}"
  if [[ "$strict" == true ]]; then
    exit 1
  fi
fi
