#!/usr/bin/env bash
# Applies a /fix run to an existing agent PR. Usage: finish-fix.sh <pr-number> <branch> <check-outcome>
. "$(dirname "$0")/lib.sh"
PR="${1:?pr number}"; branch="${2:?branch}"; CHECK="${3:?check outcome}"
R=agent-out/result.json
need_file "$R"
jq -e . "$R" >/dev/null || die "result.json is not valid JSON"
status=$(jget "$R" '.status')

if [ "$status" = "blocked" ]; then
  msg=$(mktemp)
  { echo "The Developer could not apply the requested fix:"; echo; jq -r '.blocked_reason // "(no reason given)"' "$R"; } > "$msg"
  comment "$PR" "$msg"
  exit 0
fi
[ "$status" = "done" ] || die "unknown status '$status'"

before=$(git rev-parse HEAD)
bash scripts/agent/commit-push.sh "$branch" "fix: requested changes on PR #$PR"
after=$(git rev-parse HEAD)
if [ "$before" = "$after" ]; then
  comment_text "$PR" "The Developer finished without changing any file."
  exit 0
fi

# New commits invalidate earlier human sign-off: untick the Human gates checklist.
cur=$(mktemp); new=$(mktemp)
gh pr view "$PR" --repo "$REPO" --json body --jq .body > "$cur"
awk '/^## Human gates/{f=1; print; next} /^## /{f=0} f{sub(/^- \[[xX]\]/, "- [ ]")} {print}' "$cur" > "$new"
gh api -X PATCH "repos/$REPO/pulls/$PR" -F "body=@$new" >/dev/null

msg=$(mktemp)
{
  echo "### Fix applied"
  echo "- Checks run by the workflow (lint, types, tests): **$([ "$CHECK" = success ] && echo PASSED || echo FAILED)**"
  echo "- The Human gates checklist was reset: please re-check before merging."
  echo
  [ ! -s agent-out/pr-body.md ] || sed -E 's/^## [Hh]uman gates/## (agent text) Human gates/' agent-out/pr-body.md
} > "$msg"
comment "$PR" "$msg"
dispatch ci.yml -f "pr=$PR"
dispatch agent-review.yml -f "pr=$PR"
echo "Fix pushed to $branch"
