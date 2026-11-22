#!/usr/bin/env bash
# Collects open, not yet triaged feedback issues into agent-in/feedback.md.
. "$(dirname "$0")/lib.sh"
mkdir -p agent-in agent-out
gh issue list --repo "$REPO" --label feedback --state open --limit 50 \
  --json number,title,body,author,labels,comments \
  | jq '[ .[] | select(([.labels[].name] | index("state:triaged")) | not) ]' > agent-in/feedback.json
count=$(jq length agent-in/feedback.json)
jq -r '
  .[] |
  "## Feedback #\(.number): \(.title)\nAuthor: \(.author.login // "unknown")\n\n\(.body // "")\n\n" +
  ( [ .comments[] | "> comment by \(.author.login // "unknown"): \(.body)" ] | join("\n") ) + "\n\n---\n"
' agent-in/feedback.json > agent-in/feedback.md
gh issue list --repo "$REPO" --label requirement --state all --limit 200 --json number,title,state,labels \
  | jq -r '.[] | "- #\(.number) [\(.state)] \(.title)"' > agent-in/existing-requirements.md
[ -s agent-in/existing-requirements.md ] || echo "(no requirements yet)" > agent-in/existing-requirements.md
echo "count=$count" >> "${GITHUB_OUTPUT:-/dev/null}"
echo "Collected $count feedback issue(s)"
