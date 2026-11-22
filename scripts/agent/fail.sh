#!/usr/bin/env bash
# Called by workflows when an agent run fails. Removes trigger labels, adds state:needs-human, comments.
# Usage: fail.sh <issue-or-pr-number> <message> [label-to-remove ...]
. "$(dirname "$0")/lib.sh"
N="${1:?number}"; msg="${2:?message}"; shift 2
if [ "$#" -gt 0 ]; then label_rm "$N" "$@"; fi
needs_human "$N" "$msg"
