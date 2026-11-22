#!/usr/bin/env bash
# Opens the process-change PR proposed by the Process Improver.
. "$(dirname "$0")/lib.sh"
R=agent-out/result.json
need_file "$R"; need_file agent-out/summary.md
jq -e . "$R" >/dev/null || die "result.json is not valid JSON"
status=$(jget "$R" '.status')
summary="${GITHUB_STEP_SUMMARY:-/dev/null}"
if [ "$status" = "no_changes" ]; then
  { echo "### Process Improver: no changes proposed"; cat agent-out/summary.md; } >> "$summary"
  echo "No changes proposed."
  exit 0
fi
[ "$status" = "changes_proposed" ] || die "unknown status '$status'"

d=$(date -u +%Y%m%d)
branch="agent/process-$d"
bash scripts/agent/commit-push.sh "$branch" "chore(process): proposed rule changes $d" --force
sha=$(git rev-parse HEAD)
body=$(mktemp)
{
  cat agent-out/summary.md
  echo
  echo "---"
  echo "The CI check \`agentic/protected-paths\` stays red until you add the label \`rules-change-approved\`."
  echo
  echo "## Human gates"
  echo "- [ ] G6: I read every changed line in .claude/agents, CLAUDE.md and docs/PROCESS.md"
  echo "- [ ] G6: No gate, \"never\" rule, restriction or limit was loosened"
  echo "- [ ] G6: The cited evidence really supports each change"
} > "$body"
gh pr create --repo "$REPO" --base "$BASE_BRANCH" --head "$branch" --title "Process: proposed rule changes $d" --body-file "$body" >/dev/null
pr=$(gh pr list --repo "$REPO" --head "$branch" --state open --json number --jq '.[0].number')
label_add "$pr" process-change
bash scripts/ci/set-status.sh "$sha" "agentic/review" success "Not required for process PRs"
dispatch ci.yml -f "pr=$pr"
echo "Process PR #$pr opened"
