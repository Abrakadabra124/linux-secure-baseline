#!/usr/bin/env bash
set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
test_directory="$(mktemp -d)"
server_pid=""

cleanup() {
  if [[ -n "$server_pid" ]]; then
    kill "$server_pid" 2>/dev/null || true
    wait "$server_pid" 2>/dev/null || true
  fi
  rm -rf "$test_directory"
}
trap cleanup EXIT

port="$(python3 - <<'PY'
import socket

with socket.socket() as listener:
    listener.bind(("127.0.0.1", 0))
    print(listener.getsockname()[1])
PY
)"

python3 -m http.server "$port" \
  --bind 127.0.0.1 \
  --directory "$test_directory" \
  >"$test_directory/server.log" 2>&1 &
server_pid=$!

for _ in {1..20}; do
  if curl --silent --fail "http://127.0.0.1:${port}/" >/dev/null; then
    break
  fi
  sleep 0.1
done

bash "$repository_root/scripts/diagnose-network.sh" \
  --host 127.0.0.1 \
  --port "$port" \
  --scheme http \
  --output "$test_directory/healthy"

grep -Fx 'status=healthy' "$test_directory/healthy/summary.env" >/dev/null
(
  cd "$test_directory/healthy"
  sha256sum --check manifest.sha256 >/dev/null
)

set +e
bash "$repository_root/scripts/diagnose-network.sh" \
  --host 127.0.0.1 \
  --port 70000 \
  --scheme http \
  --output "$test_directory/invalid" >/dev/null 2>&1
invalid_status=$?
set -e

if ((invalid_status != 64)); then
  printf 'Expected invalid argument exit code 64, got %d\n' "$invalid_status" >&2
  exit 1
fi

printf 'Network diagnostic healthy-path and input validation tests passed.\n'
