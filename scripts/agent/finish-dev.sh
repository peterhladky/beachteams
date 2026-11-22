#!/usr/bin/env bash
# Applies the Developer result: commit, push, open the PR, start CI + review.
# Usage: finish-dev.sh <issue-number> <branch> <check-outcome: success|failure>
. "$(dirname "$0")/lib.sh"
N="${1:?issue number}"; branch="${2:?branch}"; CHECK="${3:?check outcome}"
R=agent-out/result.json
need_file "$R"
jq -e . "$R" >/dev/null || die "result.json is not valid JSON"
status=$(jget "$R" '.status')

if [ "$status" = "blocked" ]; then
  msg=$(mktemp)
  {
    echo "The Developer agent stopped and needs a human decision."
    echo
    jq -r '.blocked_reason // "(no reason given)"' "$R"
    if [ -s agent-out/pr-body.md ]; then echo; echo "---"; cat agent-out/pr-body.md; fi
    echo
    echo "When resolved, run the Developer again: Actions > agent-developer > Run workflow (issue number $N)."
  } > "$msg"
  label_add "$N" "state:needs-human"
  comment "$N" "$msg"
  [ -z "$RUN_URL" ] || comment_text "$N" "Workflow run: $RUN_URL"
  exit 0
fi
[ "$status" = "done" ] || die "unknown status '$status'"

before=$(git rev-parse HEAD)
bash scripts/agent/commit-push.sh "$branch" "feat: implement REQ-$N" 
after=$(git rev-parse HEAD)
if [ "$before" = "$after" ]; then
  needs_human "$N" "The Developer finished without changing any file. Nothing was pushed."
  exit 0
fi

title=$(issue_title "$N")
risk=$(risk_of "$N")
changed=$(git diff --name-only "origin/$BASE_BRANCH...HEAD")
deps=false; migs=""
printf '%s\n' "$changed" | grep -qE '^app/package(-lock)?\.json$' && deps=true
migs=$(printf '%s\n' "$changed" | grep -E '^supabase/migrations/.*\.sql$' || true)

body=$(mktemp)
{
  if [ -s agent-out/pr-body.md ]; then
    sed -E 's/^## [Hh]uman gates/## (agent text) Human gates/' agent-out/pr-body.md
  else
    echo "## What changed"; echo "(The Developer agent did not provide a description.)"
  fi
  echo
  echo "---"
  echo "Closes #$N"
  echo
  echo "## Pipeline status"
  echo "- Checks run by the workflow (lint, types, tests): **$([ "$CHECK" = success ] && echo PASSED || echo FAILED)**"
  echo "- Risk tier: \`risk:${risk:-unknown}\`"
  echo "- Branch: \`$branch\`"
  if [ "$deps" = true ]; then echo "- **Dependencies changed** - read the package.json / lockfile diff carefully"; fi
  if [ -n "$migs" ]; then echo "- **SQL migrations in this PR** (apply to Supabase only after merge, by you):"; printf '%s\n' "$migs" | sed 's/^/  - `/; s/$/`/'; fi
  echo
  echo "## Human gates"
  echo "- [ ] G3: I read the review and security comments and the traceability table"
  echo "- [ ] G3: I looked at the Files changed tab for surprises (dependencies, permissions, supabase/, auth)"
  echo "- [ ] G4: I tested the acceptance criteria on a real phone (branch \`$branch\`)"
  echo "- [ ] G4: Any SQL migration was reviewed by me and will be applied by me after merge"
} > "$body"

draft=()
[ "$CHECK" = success ] || draft=(--draft)
existing=$(gh pr list --repo "$REPO" --head "$branch" --state open --json number --jq '.[0].number // empty')
if [ -n "$existing" ]; then
  pr="$existing"
  gh api -X PATCH "repos/$REPO/pulls/$pr" -F "body=@$body" >/dev/null
else
  gh pr create --repo "$REPO" --base "$BASE_BRANCH" --head "$branch" --title "$title" --body-file "$body" "${draft[@]}" >/dev/null
  pr=$(gh pr list --repo "$REPO" --head "$branch" --state open --json number --jq '.[0].number')
fi
[ -z "$risk" ] || label_add "$pr" "risk:$risk"
[ "$deps" = false ] || label_add "$pr" "deps-changed"
label_rm "$N" state:tests-ready state:needs-human
label_add "$N" "state:in-review"
if [ "$CHECK" != success ]; then
  needs_human "$N" "The Developer could not get all checks green after two attempts. A draft PR (#$pr) was opened with the current state. Look at it, then comment \`/fix <what to change>\` on the PR."
fi
dispatch ci.yml -f "pr=$pr"
dispatch agent-review.yml -f "pr=$pr"
echo "PR #$pr ready"
