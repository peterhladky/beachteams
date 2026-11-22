#!/usr/bin/env bash
# Writes agent-in/issue.md (+ existing-requirements.md) for the agent. Usage: prepare-issue.sh <issue-number>
. "$(dirname "$0")/lib.sh"
N="${1:?issue number}"
mkdir -p agent-in agent-out
gh issue view "$N" --repo "$REPO" --json number,title,body,labels,author,comments > agent-in/issue.json
jq -r '
  "# Issue #\(.number): \(.title)\n\n" +
  "Author: \(.author.login // "unknown")\n" +
  "Labels: \([.labels[].name] | join(", "))\n\n" +
  "## Body\n\n\(.body // "")\n\n## Comments\n\n" +
  ( [ .comments[] | "### \(.author.login // "unknown") at \(.createdAt)\n\n\(.body)\n" ] | join("\n") )
' agent-in/issue.json > agent-in/issue.md
gh issue list --repo "$REPO" --label requirement --state all --limit 200 --json number,title,state,labels \
  | jq -r '.[] | "- #\(.number) [\(.state)] \(.title) (\([.labels[].name] | join(", ")))"' > agent-in/existing-requirements.md
[ -s agent-in/existing-requirements.md ] || echo "(no requirements yet)" > agent-in/existing-requirements.md
echo "Prepared agent-in/issue.md for #$N"
