#!/usr/bin/env bash
# Prepares agent-in/release-context.md. Usage: prepare-release.sh <patch|minor|major>
# Run in a full-history checkout of main (fetch-depth 0, tags included).
set -euo pipefail
bump="${1:-patch}"
out="${GITHUB_OUTPUT:-/dev/null}"
mkdir -p agent-in agent-out
cur=$(jq -r .version app/package.json)
last=$(git describe --tags --abbrev=0 2>/dev/null || true)
if [ -z "$last" ]; then
  new="$cur"
  range="HEAD"
else
  new=$(node -e '
    const [a,b,c] = process.argv[1].split(".").map(Number);
    const k = process.argv[2];
    console.log(k === "major" ? `${a+1}.0.0` : k === "minor" ? `${a}.${b+1}.0` : `${a}.${b}.${c+1}`);
  ' "$cur" "$bump")
  range="$last..HEAD"
fi
{
  echo "# Release context"
  echo
  echo "- Previous tag: ${last:-none (first release)}"
  echo "- New version: $new"
  echo "- Date: $(date -u +%Y-%m-%d)"
  echo
  echo "## Commits and pull requests since the previous tag"
  git log --pretty='- %s (%h)' "$range" | head -300
  echo
  echo "## New SQL migrations since the previous tag"
  if [ -z "$last" ]; then ls supabase/migrations/*.sql 2>/dev/null || echo "(none)"; else git diff --name-only "$last..HEAD" -- supabase/migrations | grep '\.sql$' || echo "(none)"; fi
  echo
  echo "## Files changed that may need a new app build"
  if [ -z "$last" ]; then echo "(first release)"; else git diff --name-only "$last..HEAD" -- app/app.json app/package.json app/package-lock.json | grep . || echo "(none)"; fi
} > agent-in/release-context.md
echo "version=$new" >> "$out"
echo "Release $new prepared (previous: ${last:-none})"
