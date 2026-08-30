#!/usr/bin/env bash
set -uo pipefail

strict=0
output_directory="artifacts/baseline-$(date -u +%Y%m%dT%H%M%SZ)"

while (($# > 0)); do
  case "$1" in
    --output)
      output_directory="${2:?--output requires a directory}"
      shift 2
      ;;
    --strict)
      strict=1
      shift
      ;;
    *)
      printf 'Unknown argument: %s\n' "$1" >&2
      exit 64
      ;;
  esac
done

mkdir -p "$output_directory"
warnings_file="$output_directory/warnings.txt"
: >"$warnings_file"
warning_count=0

capture() {
  local name="$1"
  local command="$2"
  local destination="$output_directory/$name.txt"

  {
    printf 'captured_at_utc=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    printf 'hostname=%s\n\n' "$(hostname)"
    bash -o pipefail -c "$command"
  } >"$destination" 2>&1 || {
    warning_count=$((warning_count + 1))
    printf '%s: command failed or data is unavailable\n' "$name" >>"$warnings_file"
  }
}

capture identity 'id; printf "\nlogin users:\n"; getent passwd | awk -F: '\''$3 >= 1000 && $1 != "nobody" { print $1 ":" $3 ":" $4 ":" $6 ":" $7 }'\'''
capture operating-system 'uname -a; printf "\nos-release:\n"; cat /etc/os-release; printf "\nuptime:\n"; uptime'
capture processes 'ps -eo user,pid,ppid,stat,etimes,comm --sort=-etimes | head -n 101; printf "\nlimits:\n"; ulimit -a'
capture services 'systemctl --failed --no-pager; printf "\nrunning services:\n"; systemctl list-units --type=service --state=running --no-pager'
capture networking 'ip -brief address; printf "\nroutes:\n"; ip route; printf "\nlisteners:\n"; ss -lntup; printf "\nresolver:\n"; cat /etc/resolv.conf'
capture time-sync 'timedatectl status; printf "\ntimesync service:\n"; systemctl status systemd-timesyncd --no-pager'
capture packages 'if command -v dpkg-query >/dev/null; then dpkg-query -W | sort; elif command -v rpm >/dev/null; then rpm -qa | sort; else exit 127; fi'
capture security-settings 'printf "umask="; umask; printf "\nselected sysctl:\n"; sysctl kernel.randomize_va_space kernel.kptr_restrict fs.protected_hardlinks fs.protected_symlinks net.ipv4.conf.all.rp_filter; printf "\nsshd effective configuration:\n"; if command -v sshd >/dev/null; then sshd -T | grep -E "^(port|permitrootlogin|passwordauthentication|pubkeyauthentication|maxauthtries) "; else exit 127; fi'
capture privileged-security 'sudo -n true; printf "sudo_noninteractive=available\n"; if command -v ufw >/dev/null; then sudo -n ufw status verbose; elif command -v nft >/dev/null; then sudo -n nft list ruleset; else exit 127; fi'
capture filesystem-permissions 'stat -c "%A %a %U:%G %n" /etc/passwd /etc/group /etc/shadow /etc/sudoers /etc/ssh 2>/dev/null'

find "$output_directory" -maxdepth 1 -type f ! -name manifest.sha256 -print0 \
  | sort -z \
  | xargs -0 sha256sum >"$output_directory/manifest.sha256"

printf 'Baseline written to %s\n' "$output_directory"
printf 'Warnings: %d\n' "$warning_count"

if ((strict == 1 && warning_count > 0)); then
  exit 2
fi
