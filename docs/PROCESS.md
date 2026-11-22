# How the pipeline works

Everything lives in GitHub. Requirements are **issues**. Agents are **GitHub Actions** that run
a role prompt from `.claude/agents/`. Agents only edit files in a throw-away checkout and write
result files; the **workflow** (not the agent) does every commit, push, PR, label and comment.
You approve at the human gates below.

```
 you: new "Idea" issue  ──►  [Requirements Engineer]  ──►  G1  you apply label state:req-approved
                                                              │
                  risk low ───────────────────────────────────┤
                  risk medium/high ──► [Architect] ──► design PR ──► G2 you merge it + label state:design-approved
                                                              │
                                                  [Test Designer]  failing acceptance tests (branch agent/req-N)
                                                              │
                                                  [Developer]  makes tests pass, opens PR (max 2 attempts)
                                                              │
        automated checks: lint, types, tests, protected paths ─┤ (no AI)
                                       [Reviewer] + [Security Reviewer]
                                                              │
                 G3 + G4: you read the review, test on a phone, tick the PR checklist, MERGE
                                                              │
        later: [Release Manager] opens a release PR ──► G5 you merge it ──► tag + GitHub release
        any time: [Feedback Triage] drafts ideas from feedback ──► G0 you pick which go to the RE
        any time: [Process Improver] proposes rule changes ──► G6 you apply label rules-change-approved + merge
```

## Roles (prompts in `.claude/agents/`)
| Role | Trigger | Writes | Cannot |
|---|---|---|---|
| requirements-engineer | label `state:needs-re` | requirement text, questions, risk tier | change any repo file |
| architect | label `state:req-approved` on risk medium/high | `docs/design/REQ-N.md` | change code |
| test-designer | `state:req-approved` (low) or `state:design-approved` | `app/__tests__/acceptance/req-N/**`, `docs/test-plans/REQ-N.md` | change app code |
| developer | dispatched by test-designer, or `/fix ...` comment on an agent PR | app code, own unit tests, migrations | touch acceptance tests, workflows, rules |
| reviewer | dispatched after developer/fix | review comment (read-only) | change files |
| security-reviewer | dispatched with reviewer | security comment (read-only) | change files |
| release-manager | manual dispatch | changelog + release notes | publish anything |
| feedback-triage | manual dispatch | draft idea issues | start the pipeline |
| process-improver | manual dispatch | proposed edits to prompts/process | edit HARD-RULES or workflows |

## Labels (the state machine)
- Type: `idea`, `requirement`, `feedback`, `design`, `release`, `process-change`
- Risk: `risk:low`, `risk:medium`, `risk:high`
- State: `state:needs-re` (RE should run) - `state:req-draft` (RE finished, waiting for you) - `state:needs-human` (an agent is blocked, read its comment) - `state:req-approved` (G1) - `state:design-draft` - `state:design-approved` (G2) - `state:tests-ready` - `state:in-review` - `state:triaged`
- PR: `review:ok`, `review:changes-requested`, `deps-changed`, `rules-change-approved` (G6)

Only the approver (repository variable `APPROVER`, default: the repo owner) can trigger the
pipeline with a label. A guard workflow removes gate labels applied by anyone else.

## Human gates
| Gate | You decide | Evidence | How it is enforced |
|---|---|---|---|
| G0 | Which feedback proposals become real ideas | Triage output, draft issues | Drafts lack `state:needs-re`; nothing runs until you add it |
| G1 | Requirement is right, complete, tier is right | Issue body, RE comment | Only you can add `state:req-approved`; next workflow checks the sender |
| G2 | Design, data model, new dependencies | Design PR | You install any approved package yourself (`npx expo install ...` in `app/`, committed to `main`), merge the design PR, then add `state:design-approved`; the workflow checks the design file is on `main` |
| G3 | Diff is correct, safe, on scope | Review + security comments, traceability table, files changed | Required statuses `agentic/*` + only you merge |
| G4 | It works on a real phone | Branch checkout + Expo Go | Unticked "Human gates" checklist in the PR body fails `agentic/human-gates` |
| G5 | Release now | Release PR (changelog, migration list) | Tag/GitHub release is only created if the release PR is merged by the approver |
| G6 | Change to agent rules | Process PR + evidence | `agentic/protected-paths` fails until you add `rules-change-approved` |

## Risk tiers
- **low**: copy/text, styling, small screen using existing data, docs, tests.
- **medium**: new feature on existing tables/APIs, new user flow, new non-personal table.
- **high**: auth/roles/permissions, personal data of members (names, photos, location, contacts, messages), push notifications, native-code dependency, destructive migrations, app permissions, anything touching CI or secrets.
When unsure, the higher tier. High-risk work: read the full diff yourself.

## Files exchanged with agents
- `agent-in/` - inputs prepared by the workflow (issue text, diff, logs). Git-ignored.
- `agent-out/` - outputs the agent writes (`result.json`, `comment.md`, ...). Git-ignored.
- Agents always leave outputs in exactly the names their prompt defines; the workflow validates them and posts `needs-human` if they are missing or invalid.

## When something is stuck
1. Look for the label `state:needs-human` and read the last agent comment.
2. Answer in a comment, then re-apply `state:needs-re` (requirements stage) or comment `/fix <what to change>` on the PR (build stage).
3. Failed run? Open the Actions tab; the failure comment links to it.
4. Too expensive or noisy? See "Cost knobs" in `SETUP.md`.

## Where to change things
- Product description: `docs/SPEC.md` (you).
- Agent behaviour: `.claude/agents/*.md` (you, or the Process Improver via PR + G6).
- Hard limits: `docs/HARD-RULES.md` (you only).
- Pipeline plumbing: `.github/workflows/*`, `scripts/**` (you only).
