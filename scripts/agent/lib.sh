#!/usr/bin/env bash
# Shared helpers for the agent workflows. Usage: . "$(dirname "$0")/lib.sh"
# Requires: gh, jq. Env: GH_TOKEN, REPO (owner/name); optional BASE_BRANCH (default main), RUN_URL.
set -euo pipefail
: "${GH_TOKEN:?GH_TOKEN is required}"
: "${REPO:?REPO is required (owner/name)}"
BASE_BRANCH="${BASE_BRANCH:-main}"
RUN_URL="${RUN_URL:-}"

die() { echo "::error::$*" >&2; exit 1; }
need_file() { [ -s "$1" ] || die "expected agent output '$1' is missing or empty"; }
jget() { jq -r "$2" "$1"; }

# Works for issues AND pull requests (GitHub treats a PR as an issue for labels/comments).
comment() { gh api "repos/$REPO/issues/$1/comments" -F "body=@$2" >/dev/null; }
comment_text() { local f; f=$(mktemp); printf '%s\n' "$2" > "$f"; comment "$1" "$f"; rm -f "$f"; }
label_add() {
  local n="$1"; shift
  local args=() l
  for l in "$@"; do args+=(-f "labels[]=$l"); done
  gh api "repos/$REPO/issues/$n/labels" "${args[@]}" >/dev/null
}
label_rm() {
  local n="$1"; shift
  local l enc
  for l in "$@"; do
    enc=$(jq -rn --arg l "$l" '$l|@uri')
    gh api -X DELETE "repos/$REPO/issues/$n/labels/$enc" >/dev/null 2>&1 || true
  done
}
needs_human() {
  local n="$1" msg="$2"
  label_add "$n" "state:needs-human"
  if [ -n "$RUN_URL" ]; then msg="$msg

Workflow run: $RUN_URL"; fi
  comment_text "$n" "$msg"
}
issue_title() { gh issue view "$1" --repo "$REPO" --json title --jq .title; }
issue_labels() { gh issue view "$1" --repo "$REPO" --json labels --jq '.labels[].name'; }
risk_of() { issue_labels "$1" | grep -E '^risk:' | head -1 | sed 's/^risk://' || true; }
dispatch() { local wf="$1"; shift; gh workflow run "$wf" --repo "$REPO" --ref "$BASE_BRANCH" "$@"; }
