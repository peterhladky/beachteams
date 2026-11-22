#!/usr/bin/env bash
# Fails if the working tree contains changes outside <allow-regex> (paths relative to repo root).
#   assert-only-changed.sh <allow-regex> [--require-change]
# Ignored files (agent-in/, agent-out/, node_modules) are not reported by git status.
set -euo pipefail
allow="${1:?allow regex}"
require="${2:-}"
changed=$(git status --porcelain --untracked-files=all | sed -E 's/^.{3}//; s/^.* -> //')
if [ -z "$changed" ]; then
  if [ "$require" = "--require-change" ]; then
    echo "::error::the agent changed no files, but changes were expected" >&2
    exit 1
  fi
  echo "No working tree changes."
  exit 0
fi
bad=$(printf '%s\n' "$changed" | grep -Ev "$allow" || true)
if [ -n "$bad" ]; then
  echo "::error::the agent changed files outside its allowed paths:" >&2
  printf '%s\n' "$bad" >&2
  exit 1
fi
echo "Changed files are all within the allowed paths:"
printf '%s\n' "$changed"
