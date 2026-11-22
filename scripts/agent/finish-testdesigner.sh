#!/usr/bin/env bash
# Applies the Test Designer result and hands over to the Developer.
# Usage: finish-testdesigner.sh <issue-number> <trigger-label>
. "$(dirname "$0")/lib.sh"
N="${1:?issue number}"
TRIGGER="${2:?trigger label}"
R=agent-out/result.json
need_file "$R"; need_file agent-out/comment.md
jq -e . "$R" >/dev/null || die "result.json is not valid JSON"
status=$(jget "$R" '.status')

case "$status" in
  needs_answers)
    label_rm "$N" "$TRIGGER"
    needs_human "$N" "$(cat agent-out/comment.md)

Answer in a comment, then re-apply the label \`$TRIGGER\` to run the Test Designer again."
    exit 0
    ;;
  ready) ;;
  *) die "unknown status '$status'";;
esac

compgen -G "app/__tests__/acceptance/req-$N/*.test.*" >/dev/null || die "no acceptance test files were created for REQ-$N"
need_file "docs/test-plans/REQ-$N.md"

branch="agent/req-$N"
bash scripts/agent/commit-push.sh "$branch" "test: acceptance tests for REQ-$N" --force
label_rm "$N" state:needs-human
label_add "$N" "state:tests-ready"
comment "$N" agent-out/comment.md
dispatch agent-developer.yml -f "issue=$N"
echo "Tests pushed to $branch; Developer dispatched"
