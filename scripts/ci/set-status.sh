#!/usr/bin/env bash
# Posts a commit status. Usage: set-status.sh <sha> <context> <state> <description>
# state: success | failure | error | pending.  Needs GH_TOKEN, REPO; optional RUN_URL.
set -euo pipefail
: "${GH_TOKEN:?}" "${REPO:?}"
sha="${1:?sha}"; context="${2:?context}"; state="${3:?state}"; desc="${4:-}"
args=(-f "state=$state" -f "context=$context" -f "description=${desc:0:140}")
if [ -n "${RUN_URL:-}" ]; then args+=(-f "target_url=$RUN_URL"); fi
gh api -X POST "repos/${REPO}/statuses/${sha}" "${args[@]}" >/dev/null
echo "status $context=$state on ${sha:0:7}"
