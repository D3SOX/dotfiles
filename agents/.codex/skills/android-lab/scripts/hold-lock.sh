#!/usr/bin/env bash
set -euo pipefail

# Holds /tmp/SKILL-NAME.lock, where SKILL is the skill directory it is run from
# (android-lab, apple-lab or windows-lab). The lock lives only in this process,
# with no child process, so killing the printed PID releases it and exits 0.
skill=$(basename "$(cd "$(dirname "$0")/.." && pwd)")
usage() {
  echo 'Usage: hold-lock.sh [--wait SECONDS] NAME | hold-lock.sh --status [NAME...]' >&2
  exit 2
}

if [[ ${1-} == --status ]]; then
  shift
  pattern="^/tmp/$skill-.*\\.lock\$"
  (($#)) && pattern="^/tmp/$skill-($(IFS='|'; echo "$*"))\\.lock\$"
  lslocks -n -o PID,MODE,PATH | while read -r pid mode path; do
    [[ $path =~ $pattern ]] || continue
    state=held
    [[ $mode == *'*' ]] && state=waiting
    echo "$path $state pid=$pid age=$(ps -o etime= -p "$pid" | xargs) cwd=$(readlink "/proc/$pid/cwd")"
  done
  exit 0
fi

wait_args=(-n)
if [[ ${1-} == --wait ]]; then
  [[ ${2-} =~ ^[0-9]+$ ]] || usage
  wait_args=(-w "$2")
  shift 2
fi
[[ $# -eq 1 && $1 =~ ^[a-zA-Z0-9_-]+$ ]] || usage

exec 9>>"/tmp/$skill-$1.lock"
flock "${wait_args[@]}" -E 75 9
echo "LAB_LOCK_ACQUIRED pid=$$"
trap 'exit 0' TERM INT HUP
# Block in a builtin on a pipe nobody writes to, so no child inherits fd 9.
exec 8<> <(:)
read -r -u 8
