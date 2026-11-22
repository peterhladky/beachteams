#!/usr/bin/env bash
# Creates draft idea issues from the Feedback Triage proposals (gate G0 stays with the human).
. "$(dirname "$0")/lib.sh"
P=agent-out/proposals.json
need_file "$P"
jq -e . "$P" >/dev/null || die "proposals.json is not valid JSON"
summary="${GITHUB_STEP_SUMMARY:-/dev/null}"

is_feedback_issue() { jq -e --argjson n "$1" 'any(.[]; .number == $n)' agent-in/feedback.json >/dev/null; }

created=0
total=$(jq '.proposals | length' "$P")
[ "$total" -le 5 ] || total=5
for i in $(seq 0 $((total - 1))); do
  kind=$(jq -r ".proposals[$i].kind" "$P")
  title=$(jq -r ".proposals[$i].title" "$P")
  file=$(jq -r ".proposals[$i].body_file" "$P")
  case "$file" in agent-out/proposal-*.md) ;; *) echo "skipping proposal $i: unexpected body file path"; continue;; esac
  [ -s "$file" ] || { echo "skipping proposal $i: missing body file"; continue; }
  labels=(idea)
  [ "$kind" != "bug" ] || labels+=(bug)
  body=$(mktemp)
  { cat "$file"; echo; echo "---"; echo "Drafted by the Feedback Triage agent. To send this to the Requirements Engineer, add the label \`state:needs-re\` (gate G0)."; } > "$body"
  args=(); for l in "${labels[@]}"; do args+=(--label "$l"); done
  url=$(gh issue create --repo "$REPO" --title "Idea: $title" --body-file "$body" "${args[@]}")
  num="${url##*/}"
  created=$((created + 1))
  echo "- created #$num: $title" >> "$summary"
  for s in $(jq -r ".proposals[$i].sources[]" "$P"); do
    if is_feedback_issue "$s"; then
      comment_text "$s" "Triaged: draft idea #$num was created from this feedback."
      label_add "$s" "state:triaged"
    fi
  done
done

for i in $(seq 0 $(( $(jq '.handled_without_proposal | length' "$P") - 1 ))); do
  note=$(jq -r ".handled_without_proposal[$i].classification + \": \" + .handled_without_proposal[$i].note" "$P")
  for s in $(jq -r ".handled_without_proposal[$i].sources[]" "$P"); do
    if is_feedback_issue "$s"; then
      comment_text "$s" "Triaged (no build planned): $note"
      label_add "$s" "state:triaged"
    fi
  done
done

[ ! -s agent-out/summary.md ] || cat agent-out/summary.md >> "$summary"
echo "Created $created draft idea issue(s)"
