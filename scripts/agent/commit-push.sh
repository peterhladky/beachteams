#!/usr/bin/env bash
# Commits all working-tree changes (ignored files excluded) and pushes them.
# Usage: commit-push.sh <branch> <message> [--force]
# Needs GH_TOKEN (used only for the push; checkouts that run agent-written code keep no credentials).
# Writes changed=true|false to $GITHUB_OUTPUT.
set -euo pipefail
branch="${1:?branch}"; msg="${2:?message}"; force="${3:-}"
: "${GH_TOKEN:?GH_TOKEN is required to push}"
out="${GITHUB_OUTPUT:-/dev/null}"
git config user.name "agentic-pipeline[bot]"
git config user.email "agentic-pipeline@users.noreply.github.com"
git checkout -B "$branch"
git add -A
if git diff --cached --quiet; then
  echo "Nothing to commit."
  echo "changed=false" >> "$out"
  exit 0
fi
git commit -q -m "$msg"
auth="AUTHORIZATION: basic $(printf 'x-access-token:%s' "$GH_TOKEN" | base64 | tr -d '\n')"
push=(git -c "http.https://github.com/.extraheader=$auth" push)
if [ "$force" = "--force" ]; then push+=(--force); fi
"${push[@]}" origin "HEAD:refs/heads/$branch"
echo "changed=true" >> "$out"
