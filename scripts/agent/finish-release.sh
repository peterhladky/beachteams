#!/usr/bin/env bash
# Applies the Release Manager output and opens the release PR. Usage: finish-release.sh <version>
. "$(dirname "$0")/lib.sh"
V="${1:?version}"
need_file agent-out/changelog-entry.md
need_file agent-out/release-notes.md
need_file agent-out/result.json
jq -e . agent-out/result.json >/dev/null || die "result.json is not valid JSON"

npm --prefix app version "$V" --no-git-tag-version --allow-same-version >/dev/null
tmp=$(mktemp)
jq --arg v "$V" '.expo.version = $v' app/app.json > "$tmp" && mv "$tmp" app/app.json

{
  echo "# Changelog"; echo
  cat agent-out/changelog-entry.md; echo
  if [ -f CHANGELOG.md ]; then tail -n +2 CHANGELOG.md | sed '1{/^$/d}'; fi
} > CHANGELOG.new
mv CHANGELOG.new CHANGELOG.md

notes="docs/releases/v$V.md"
{
  cat agent-out/release-notes.md
  echo
  echo "## Before shipping (from the Release Manager)"
  jq -r '(.needs_attention // [])[] | "- " + .' agent-out/result.json
  jq -r 'if (.migrations // [] | length) > 0 then "- Apply these SQL migrations to the production Supabase project first, in order:\n" + ((.migrations | map("  - `" + . + "`")) | join("\n")) else empty end' agent-out/result.json
  jq -r 'if .needs_new_build then "- A NEW BUILD is required (native dependencies or app config changed)." else empty end' agent-out/result.json
} > "$notes"

branch="agent/release-v$V"
bash scripts/agent/commit-push.sh "$branch" "chore(release): v$V" --force
sha=$(git rev-parse HEAD)

body=$(mktemp)
{
  echo "# Release v$V"; echo
  cat "$notes"; echo
  echo "---"
  echo "Merging this PR (as the approver) creates the tag \`v$V\` and a GitHub release. Publishing the update to phones is a separate manual step: see SETUP.md, section \"Shipping to friends\"."
  echo
  echo "## Human gates"
  echo "- [ ] G5: I read the changelog and the release notes"
  echo "- [ ] G5: Every SQL migration listed above is applied to the production Supabase project (in order), or there are none"
  echo "- [ ] G5: I tested exactly this commit on a phone"
  echo "- [ ] G5: I know how I will ship it (update vs. new build) and when"
} > "$body"
gh pr create --repo "$REPO" --base "$BASE_BRANCH" --head "$branch" --title "Release v$V" --body-file "$body" >/dev/null
pr=$(gh pr list --repo "$REPO" --head "$branch" --state open --json number --jq '.[0].number')
label_add "$pr" release
bash scripts/ci/set-status.sh "$sha" "agentic/review" success "Not required for release PRs"
dispatch ci.yml -f "pr=$pr"
echo "Release PR #$pr opened"
