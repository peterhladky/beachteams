#!/usr/bin/env bash
# Detects changes to protected (automation / rules) paths.
#   protected-paths.sh worktree <repo-dir> [allow-regex]            uncommitted changes in the working tree
#   protected-paths.sh diff <repo-dir> <base-ref> [allow-regex]     committed changes base...HEAD
# Prints offending paths and exits 1 if any are found outside allow-regex.
set -euo pipefail

PROTECTED='^(\.github/|\.claude/|CLAUDE\.md$|scripts/|docs/HARD-RULES\.md$|docs/PROCESS\.md$)'

mode="${1:?mode: worktree|diff}"
dir="${2:?repo dir}"
allow=""
case "$mode" in
  worktree)
    allow="${3:-}"
    changed=$(git -C "$dir" status --porcelain --untracked-files=all | sed -E 's/^.{3}//; s/^.* -> //')
    ;;
  diff)
    base="${3:?base ref}"
    allow="${4:-}"
    changed=$(git -C "$dir" diff --name-only "$base"...HEAD)
    ;;
  *)
    echo "unknown mode: $mode" >&2
    exit 2
    ;;
esac

hits=$(printf '%s\n' "$changed" | grep -E "$PROTECTED" || true)
if [ -n "$allow" ] && [ -n "$hits" ]; then
  hits=$(printf '%s\n' "$hits" | grep -Ev "$allow" || true)
fi
if [ -n "$hits" ]; then
  echo "Protected paths changed:"
  printf '%s\n' "$hits"
  exit 1
fi
echo "No protected paths changed."
