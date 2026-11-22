#!/usr/bin/env bash
# Collects 30 days of pipeline evidence for the Process Improver into agent-in/evidence.md.
. "$(dirname "$0")/lib.sh"
mkdir -p agent-in agent-out
since=$(date -u -d '30 days ago' +%Y-%m-%dT00:00:00Z)
{
  echo "# Evidence since $since"
  echo
  echo "## Agent pull requests (branch agent/*)"
  gh pr list --repo "$REPO" --state all --limit 200 \
    --json number,title,state,mergedAt,createdAt,headRefName,labels,comments,url \
    | jq -r --arg since "$since" '
        .[] | select(.headRefName | startswith("agent/")) | select(.createdAt >= $since) |
        "### PR #\(.number) [\(.state)] \(.title)\nbranch: \(.headRefName)  labels: \([.labels[].name] | join(", "))\n\(.url)\n" +
        ( [ .comments[] | select(.body | test("^/fix|Reviewer verdict|Security review|Fix applied"))
            | "- \(.author.login // "unknown"): \(.body | .[0:400] | gsub("\n"; " "))" ] | join("\n") ) + "\n"'
  echo
  echo "## Failed workflow runs"
  gh run list --repo "$REPO" --status failure --limit 50 --json workflowName,displayTitle,createdAt,url \
    | jq -r --arg since "$since" '.[] | select(.createdAt >= $since) | "- \(.createdAt) \(.workflowName): \(.displayTitle) \(.url)"'
  echo
  echo "## Issues that needed a human (state:needs-human)"
  gh issue list --repo "$REPO" --label "state:needs-human" --state all --limit 50 --json number,title,state,url \
    | jq -r '.[] | "- #\(.number) [\(.state)] \(.title) \(.url)"'
} > agent-in/evidence.md
echo "Evidence written ($(wc -l < agent-in/evidence.md) lines)"
