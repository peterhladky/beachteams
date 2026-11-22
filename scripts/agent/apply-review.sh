#!/usr/bin/env bash
# Combines reviewer + security output into one PR comment and sets the agentic/review status.
# Usage: apply-review.sh <pr-number> <head-sha>
. "$(dirname "$0")/lib.sh"
PR="${1:?pr number}"; SHA="${2:?sha}"
setstatus() { bash "$(dirname "$0")/../ci/set-status.sh" "$SHA" "agentic/review" "$1" "$2"; }

if [ ! -s agent-out/review.json ] || ! jq -e . agent-out/review.json >/dev/null 2>&1 || [ ! -s agent-out/review.md ]; then
  comment_text "$PR" "The Reviewer agent did not produce valid output.${RUN_URL:+ Workflow run: $RUN_URL}"
  setstatus error "reviewer output missing or invalid"
  exit 0
fi
verdict=$(jget agent-out/review.json '.verdict')
missing=$(jq -r '[.traceability[]? | select(.status=="missing" or .status=="partial")] | length' agent-out/review.json)
sec="skipped"
if [ -s agent-out/security.json ] && jq -e . agent-out/security.json >/dev/null 2>&1; then
  sec=$(jget agent-out/security.json '.verdict')
elif [ "${SECURITY_ENABLED:-true}" != "false" ]; then
  sec="invalid"
fi

ok=true
[ "$verdict" = "approve" ] || ok=false
[ "$missing" = "0" ] || ok=false
case "$sec" in pass|warn|skipped) ;; *) ok=false;; esac

out=$(mktemp)
{
  cat agent-out/review.md
  echo
  if [ -s agent-out/security.md ]; then cat agent-out/security.md; echo; fi
  echo "---"
  echo "**agentic/review status: $([ "$ok" = true ] && echo SUCCESS || echo FAILURE)** - reviewer: \`$verdict\`, unmet acceptance criteria: \`$missing\`, security: \`$sec\`."
  echo "This is advice for gate G3. You decide."
} > "$out"
comment "$PR" "$out"

label_rm "$PR" review:ok review:changes-requested
if [ "$ok" = true ]; then
  label_add "$PR" review:ok
  setstatus success "reviewer approve, security $sec"
else
  label_add "$PR" review:changes-requested
  setstatus failure "reviewer $verdict, unmet ACs $missing, security $sec"
fi
