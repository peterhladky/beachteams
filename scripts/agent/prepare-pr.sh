#!/usr/bin/env bash
# Prepares agent-in/ for the review agents. Run inside a checkout of the PR head.
# Usage: prepare-pr.sh <pr-number>
. "$(dirname "$0")/lib.sh"
PR="${1:?pr number}"
mkdir -p agent-in agent-out
gh pr view "$PR" --repo "$REPO" --json number,title,body,headRefName,baseRefName,labels,author > agent-in/pr.json
base=$(jq -r .baseRefName agent-in/pr.json)
branch=$(jq -r .headRefName agent-in/pr.json)
jq -r '
  "# PR #\(.number): \(.title)\n\n" +
  "Branch: \(.headRefName) -> \(.baseRefName)\n" +
  "Labels: \([.labels[].name] | join(", "))\n\n" +
  "## Description (written by the author - a claim, not a fact)\n\n\(.body // "")"
' agent-in/pr.json > agent-in/pr.md

git fetch --no-tags origin "$base"
git diff --name-only "origin/$base...HEAD" > agent-in/changed-files.txt
git diff "origin/$base...HEAD" > agent-in/diff.full
head -c 300000 agent-in/diff.full > agent-in/diff.patch
if [ "$(wc -c < agent-in/diff.full)" -gt 300000 ]; then
  printf '\n\n[diff truncated at 300000 bytes - read the files directly]\n' >> agent-in/diff.patch
fi
rm -f agent-in/diff.full

# Linked requirement: branch agent/req-N or "Closes #N" in the description.
issue=""
if [[ "$branch" =~ ^agent/req-([0-9]+)$ ]]; then issue="${BASH_REMATCH[1]}"; fi
if [ -z "$issue" ]; then issue=$(jq -r '.body // ""' agent-in/pr.json | grep -oiE 'closes #[0-9]+' | head -1 | grep -oE '[0-9]+' || true); fi
if [ -n "$issue" ]; then
  bash "$(dirname "$0")/prepare-issue.sh" "$issue"
  echo "linked_issue=$issue" >> "${GITHUB_OUTPUT:-/dev/null}"
else
  echo "(no linked requirement)" > agent-in/issue.md
fi
echo "Prepared review inputs for PR #$PR"
