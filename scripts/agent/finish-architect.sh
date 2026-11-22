#!/usr/bin/env bash
# Applies the Architect result: opens a design PR or asks the human. Usage: finish-architect.sh <issue-number>
. "$(dirname "$0")/lib.sh"
N="${1:?issue number}"
R=agent-out/result.json
need_file "$R"; need_file agent-out/comment.md
jq -e . "$R" >/dev/null || die "result.json is not valid JSON"
status=$(jget "$R" '.status')

case "$status" in
  needs_answers|too_large)
    label_rm "$N" state:req-approved
    needs_human "$N" "$(cat agent-out/comment.md)

Answer in a comment, then re-apply the label \`state:req-approved\` to run the Architect again."
    exit 0
    ;;
  ready) ;;
  *) die "unknown status '$status'";;
esac

DESIGN="docs/design/REQ-$N.md"
need_file "$DESIGN"
branch="agent/design-req-$N"
bash scripts/agent/commit-push.sh "$branch" "docs: design for REQ-$N" --force
sha=$(git rev-parse HEAD)
title=$(issue_title "$N")

body=$(mktemp)
{
  cat agent-out/comment.md
  echo
  echo "---"
  echo "Design note: \`$DESIGN\`   Requirement: #$N"
  echo
  echo "## Human gates"
  echo "- [ ] G2: I reviewed the design (data model, RLS policies, dependencies, threats, rollback) and accept it"
  echo "- [ ] G2: Any new package named in the design is installed by me (\`npx expo install ...\` inside app/) and already on main, or the design needs none"
  echo
  echo "After merging this PR, add the label \`state:design-approved\` to issue #$N to start test design and development."
} > "$body"

gh pr create --repo "$REPO" --base "$BASE_BRANCH" --head "$branch" --title "Design: $title" --body-file "$body" >/dev/null
pr=$(gh pr list --repo "$REPO" --head "$branch" --state open --json number --jq '.[0].number')
label_add "$pr" design
label_add "$N" "state:design-draft"
comment_text "$N" "Design PR opened: #$pr. Review it, merge it (gate G2) and then add the label \`state:design-approved\` to this issue."
bash scripts/ci/set-status.sh "$sha" "agentic/review" success "Not required for design PRs"
dispatch ci.yml -f "pr=$pr"
echo "Design PR #$pr opened"
