#!/usr/bin/env bash
set -euo pipefail

# Starts the macOS VM if needed and opens the shared SSH control socket,
# reading the VM-only password from local.md without printing it. The caller
# holds the vm lock. Prints VM_CONNECTED once commands can run over the socket.
socket=/tmp/apple-lab-ssh
target=(-p2223 builder@127.0.0.1)
local_md=/home/nico/.codex/skills/apple-lab/local.md
deadline=$((SECONDS + ${1:-600}))

if ssh -S "$socket" -O check "${target[@]}" 2>/dev/null; then
  echo VM_CONNECTED
  exit 0
fi
grep -q 'account password: `' "$local_md" ||
  { echo "vm-connect: no builder password in $local_md" >&2; exit 2; }
[[ $(docker inspect --format '{{.State.Status}}' macos) == running ]] ||
  docker start macos >/dev/null

askpass=$(mktemp "${TMPDIR:-/tmp}/apple-lab-askpass.XXXXXX")
trap 'rm -f "$askpass"' EXIT
cat >"$askpass" <<EOF
#!/bin/sh
sed -n 's/.*account password: \`\(.*\)\`.*/\1/p' '$local_md' | head -n 1
EOF
chmod 700 "$askpass"

# Early in boot the port accepts connections but resets them or never sends
# a banner, so retry until a login succeeds.
until error=$(SSH_ASKPASS=$askpass SSH_ASKPASS_REQUIRE=force ssh -fN -M -S "$socket" \
  -o ControlPersist=8h -o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new \
  -o PubkeyAuthentication=no -o NumberOfPasswordPrompts=1 "${target[@]}" 2>&1); do
  if [[ $error == *'Permission denied'* ]]; then
    echo "vm-connect: password rejected; check $local_md" >&2
    exit 1
  fi
  if ((SECONDS >= deadline)); then
    echo "vm-connect: no SSH login in time (${error##*$'\n'}); check the console at http://127.0.0.1:8006" >&2
    exit 124
  fi
  sleep 5
done
ssh -S "$socket" "${target[@]}" true
echo VM_CONNECTED
