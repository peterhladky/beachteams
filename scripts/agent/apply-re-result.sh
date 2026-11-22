#!/usr/bin/env bash
# Validates and applies the Requirements Engineer output. Usage: apply-re-result.sh <issue-number>
. "$(dirname "$0")/lib.sh"
N="${1:?issue number}"
R=agent-out/result.json
need_file "$R"
need_file agent-out/comment.md
jq -e . "$R" >/dev/null || die "result.json is not valid JSON"
status=$(jget "$R" '.status')
risk=$(jget "$R" '.risk // empty')
title=$(jget "$R" '.title // empty')

case "$status" in
  ready_for_approval)
    need_file agent-out/issue-body.md
    for h in "## Summary" "## User story" "## Acceptance criteria" "## Non-functional requirements" "## Out of scope" "## Risk tier" "## Open questions"; do
      grep -qF "$h" agent-out/issue-body.md || die "issue body lacks required heading '$h'"
    done
    grep -qE '^- \[ \] AC-1:' agent-out/issue-body.md || die "issue body lacks acceptance criterion AC-1"
    case "$risk" in low|medium|high) ;; *) die "invalid risk '$risk'";; esac
    [ -n "$title" ] || die "result.json has no title"
    gh api -X PATCH "repos/$REPO/issues/$N" -F "body=@agent-out/issue-body.md" -f "title=REQ-$N: $title" >/dev/null
    # A rewritten requirement invalidates earlier approvals.
    label_rm "$N" state:needs-re state:needs-human state:req-approved state:design-draft state:design-approved risk:low risk:medium risk:high
    label_add "$N" requirement "state:req-draft" "risk:$risk"
    comment "$N" agent-out/comment.md
    ;;
  needs_answers)
    label_rm "$N" state:needs-re
    label_add "$N" "state:needs-human"
    comment "$N" agent-out/comment.md
    ;;
  duplicate)
    label_rm "$N" state:needs-re
    label_add "$N" "state:needs-human"
    comment "$N" agent-out/comment.md
    ;;
  *) die "unknown status '$status'";;
esac
echo "Applied requirements-engineer result: $status"
