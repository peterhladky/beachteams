# Setup guide (Windows, step by step)

Read **docs/PROCESS.md** once first (5 minutes): it explains the roles and the human gates.
Everything below assumes Windows + PowerShell. The template itself is cross-platform.

## 0. What you get, and what it costs
- Every idea you file runs through up to 9 AI agents. Each agent run is one Claude Code run in GitHub Actions.
- A typical small feature is roughly 6 to 9 agent runs (Requirements Engineer 1-2, Test Designer 1, Developer 1-2, Reviewer 1, Security Reviewer 1; Architect +1 for medium/high risk).
  That uses your Claude plan's usage limits. On a ~20 EUR/month plan, expect to file a few small requirements per week, not dozens. See section 12 for cost knobs.
- GitHub Actions minutes: a private repo on the free plan has a monthly allowance; an agent run uses minutes while it works.

## 1. Install the tools (once per computer)
Open PowerShell and run the lines you are missing, then **close and reopen PowerShell**:
```powershell
winget install --id Git.Git -e
winget install --id GitHub.cli -e
winget install --id OpenJS.NodeJS.LTS -e
git config --global user.name  "Your Name"
git config --global user.email "you@example.com"
gh auth login          # choose GitHub.com, HTTPS, log in via browser
```
Also needed:
- **Claude Code** (to create the CI token and to use the agents locally): install it from https://code.claude.com/docs and log in with your Claude subscription.
- **Expo Go** on your phone (App Store / Google Play) to test the app.
- Free accounts: **GitHub**, **Supabase** (https://supabase.com), **Expo** (https://expo.dev, needed later for builds).

## 2. Create your project from the template
```powershell
Copy-Item -Recurse C:\_LOCAL_DATA\DEV\_AgenticMobileSample C:\_LOCAL_DATA\DEV\MyApp
cd C:\_LOCAL_DATA\DEV\MyApp
```
Keep `C:\_LOCAL_DATA\DEV\_AgenticMobileSample` untouched as your template.

## 3. Write the product description
Edit `docs/SPEC.md` (vision, users and roles, core features, data, constraints, non-goals). 15-30 minutes.
This is the one document the agents cannot guess. Do it **before** the next step so it is part of the first commit.

## 4. Run the initialiser
```powershell
node scripts/init.mjs
```
It asks for the app name, slug, bundle id, GitHub repository name, visibility and your GitHub login (the **approver**), then:
1. replaces the placeholders in `app/app.json`, `docs/SPEC.md`, `.github/CODEOWNERS`, `README.md`
2. creates the git repository and the first commit
3. creates the GitHub repository (`gh repo create`) and pushes
4. allows workflows to create pull requests (repo setting)
5. creates all labels and the repository variable `APPROVER`
6. offers to store the secret `CLAUDE_CODE_OAUTH_TOKEN` (see step 5)
7. tries to create the branch ruleset for `main` (see step 6)

You can re-run it safely; try `node scripts/init.mjs --dry-run` first to see the commands.

## 5. Give the agents their key
1. In PowerShell run `claude setup-token`. It prints a long-lived token for CI use. (If your Claude Code version does not have this command, see the Claude Code documentation for CI authentication.)
2. Store it as the repository secret (the init script offers this; otherwise):
   ```powershell
   gh secret set CLAUDE_CODE_OAUTH_TOKEN
   ```
   (paste the token when asked; it is never written to a file)
3. Install the **Claude GitHub App** on the repository: https://github.com/apps/claude, choose "Only select repositories", pick your repo.
4. In GitHub: *Settings > Actions > General > Workflow permissions*: "Read and write permissions" and "Allow GitHub Actions to create and approve pull requests" must be ticked (the init script sets this; verify once).

Prefer pay-per-use API billing instead of your subscription? Create an Anthropic API key, store it as secret `ANTHROPIC_API_KEY`, and in `.github/actions/run-agent/action.yml` replace the input `claude_code_oauth_token: ${{ inputs.oauth-token }}` with `anthropic_api_key: ${{ inputs.oauth-token }}`, and pass `secrets.ANTHROPIC_API_KEY` as `oauth-token` in the workflows.

## 6. Branch protection: what you get depends on your GitHub plan
`init.mjs` tries to create a ruleset for `main`: pull request required, and the four statuses `agentic/ci`, `agentic/protected-paths`, `agentic/human-gates`, `agentic/review` must be green. You (repository admin) can still merge a pull request if a check is missing because of a bug.

**On GitHub Free, rulesets and branch protection exist only for public repositories. Private repositories need GitHub Pro (about 4 USD/month).** If you chose a private repo on the free plan, the script reports that it could not create the ruleset. Your options:
1. **GitHub Pro** (cheapest way to get real protection for a private repo), then run `gh api -X POST repos/OWNER/REPO/rulesets --input .github/ruleset-main.json`.
2. **Make the repository public.** Then the ruleset works for free, but your code, requirements and issues are visible to everyone. Never put secrets or personal data of members anywhere in the repo.
3. **Stay private on Free** and accept weaker enforcement (see "What is enforced and what is not" below).

## 7. Supabase and the app on your phone
1. Create a Supabase project (free tier). In *Project Settings > API* copy the **Project URL** and the **anon public** key. (Never use or store the `service_role` key.)
2. Create `app/.env` from the example and fill in the two values:
   ```powershell
   Copy-Item app\.env.example app\.env
   notepad app\.env
   ```
3. Run the app:
   ```powershell
   cd app
   npm ci
   npx expo start
   ```
   Scan the QR code with Expo Go (Android) or the Camera app (iOS). Phone and PC must be on the same network (or use `npx expo start --tunnel`).
4. Check the checks locally: `npm run check` (lint + typecheck + tests).

## 8. Smoke test: run one idea through the whole pipeline
Do this once to see every gate. Use `docs/examples/first-idea.md`.
1. GitHub > **Issues > New issue > Idea**. Paste the example, submit. Because the form adds the label `state:needs-re`, the **Requirements Engineer** starts (Actions tab: `agent-requirements`).
2. In 1-3 minutes the issue gets a comment and (if everything was clear) a rewritten body with acceptance criteria and a risk tier. If it asked questions: answer in a comment, then remove and re-add the label `state:needs-re`.
3. **Gate G1**: read the requirement. Happy? Add the label `state:req-approved`.
4. Risk `low` goes straight on. For `medium`/`high`, the **Architect** opens a **design PR**: read it, install any package it names (`cd app; npx expo install <pkg>`, commit to `main`), merge the PR (**gate G2**), then add the label `state:design-approved` to the issue.
5. The **Test Designer** pushes failing acceptance tests to the branch `agent/req-N`, then the **Developer** implements (max 2 attempts) and opens a **pull request**.
6. CI runs, the **Reviewer** and **Security Reviewer** comment on the PR and set the status `agentic/review`.
7. **Gates G3 + G4**: read the review comments, test it on your phone (section 9), then tick every box under "Human gates" in the PR description (editing the description re-checks `agentic/human-gates`). Merge the PR.
8. Something to change? Comment `/fix <what to change>` on the PR. The Developer applies it and the checklist is unticked again.

## 9. Test a pull request on your phone
```powershell
git fetch origin
git switch agent/req-N        # N = issue number, see the PR's branch name
cd app
npm ci
npx expo start
```
Go back with `git switch main`.
Note: Expo Go cannot run every native library. If a requirement adds one, you will need a development build (see Expo docs: EAS development build).

## 10. Daily use cheat sheet
| You want to... | You do | Then |
|---|---|---|
| Add a requirement | New issue from the **Idea** form | RE runs; answer questions; add `state:req-approved` |
| Answer agent questions | Comment, then remove and re-add the trigger label named in the agent's comment | Agent runs again |
| Change a requirement | Edit your answer in a comment and re-apply `state:needs-re` | RE rewrites; old approvals are removed |
| Get a PR changed | Comment `/fix ...` on the PR | New commit, checks and review run again |
| Re-run the Developer | Actions > `agent-developer` > Run workflow (issue number) | e.g. after you installed a package it asked for |
| Re-run a review | `gh workflow run agent-review.yml -f pr=N` | Fresh review and status |
| Collect member feedback | Paste it into the **Feedback** form, then Actions > `agent-feedback` | Up to 5 draft ideas; add `state:needs-re` to the ones you want |
| Improve the agents | Actions > `agent-process` | PR; read it; add `rules-change-approved` (G6); merge |
| Release | Actions > `agent-release` | Release PR; follow its checklist (G5); merge = tag + GitHub release |

## 11. Shipping to friends (simple release)
1. Run `agent-release`, read the release PR and its checklist.
2. **Apply new SQL migrations** to your Supabase project, in order, *before* shipping the matching app version: see `supabase/README.md`.
3. Merge the release PR (as approver): the tag `vX.Y.Z` and a GitHub release with the notes are created.
4. Put the new version into your friends' hands. Options (check the current Expo documentation, plans and limits change):
   - **Quick circle of testers**: friends use Expo Go and you keep `npx expo start --tunnel` running while you demo; fine for early stages.
   - **Android**: `npx eas-cli@latest build --platform android --profile preview` produces an installable APK you can share by link. EAS has a free tier with a limited number of builds.
   - **iOS**: sharing installable builds outside Expo Go needs an Apple Developer account (about 99 USD/year, TestFlight or ad-hoc).
   - After the first build, JavaScript-only changes can be sent over the air with `npx eas-cli@latest update`.
   Run `npx eas-cli@latest login` and `npx eas-cli@latest build:configure` once to create `eas.json`; it is not part of the template.

## 12. Cost knobs
- Repository variable `AGENT_MODEL` (Settings > Secrets and variables > Actions > Variables): a cheaper model alias for all agents, e.g. `haiku`. Default is `sonnet`.
- Repository variable `SECURITY_AGENT` = `off`: skip the Security Reviewer (saves one run per PR; keep it on for risk `high`).
- `max-turns` in each workflow caps how long an agent may work.
- Keep requirements small: the Requirements Engineer splits big ideas.
- Do not label things you do not want processed yet; nothing runs without your label.

## 13. What is enforced and what is not
| Control | Public repo / Pro plan | Private repo on Free |
|---|---|---|
| Only you can start pipeline stages (labels checked by sender) | yes | yes |
| Gate labels applied by others are removed (`gate-guard`) | yes | yes |
| Agents cannot commit/push/merge/label (the workflow does it; tools are allow-listed) | yes | yes |
| Agents cannot edit workflows, scripts, prompts, hard rules (guard fails before any push) | yes | yes |
| Developer cannot touch acceptance tests or package.json (guard) | yes | yes |
| Reviewers run with the base branch's rules, not the PR's | yes | yes |
| PR cannot be merged with red/missing `agentic/*` statuses or unticked human gates | **yes (ruleset)** | **no - GitHub does not enforce it; you must look** |
| Nobody can push directly to `main` | **yes (ruleset)** | **no - `main-watch` opens an alert issue afterwards** |
| Code scanning (CodeQL) | free on public repos | needs paid GitHub plans; use the Security Reviewer |

Other things to know:
- CI runs code that agents wrote (jest). In the jobs that do so, the checkout keeps no credentials and the token is not in the environment, but treat agent PRs like code from a stranger: read the diff for risky changes (G3).
- Turn on **Dependabot alerts** (Settings > Code security) for vulnerability warnings; the template ships no Dependabot update PRs because they would not pass the `agentic/*` checks.
- Never invite people you do not fully trust as collaborators: write access can start workflows.
- Prompt injection is the main AI-specific risk. The agents are told to treat issue and PR text as data, their tools are restricted, and every outcome passes your gates. Do not weaken these.

## 14. What I could and could not verify when building this template
Verified in a sandbox: the Expo app (lint, typecheck, tests, Android bundle export), workflow YAML (`actionlint`), shell scripts (`shellcheck`), and the helper scripts' logic against a fake `gh` (requirement apply, PR creation, guards, review verdict, human-gate checks), and `init.mjs` placeholder patching plus its dry-run.
**Not verified (needs a real GitHub repository and your Claude token):** the live behaviour of `anthropics/claude-code-action` inside these workflows, exact `--allowedTools` pattern syntax, `claude setup-token`, the ruleset API on your plan, and `workflow_dispatch` chaining with `GITHUB_TOKEN`. The smoke test in section 8 is how you find out; section 15 lists the likely fixes.

## 15. Troubleshooting
| Symptom | Likely cause and fix |
|---|---|
| Nothing starts after you create the idea | Is `state:needs-re` on the issue? Did *you* (the `APPROVER` login) create it? Is Actions enabled? Check the Actions tab for `agent-requirements`. |
| Run fails at the agent step with an auth error | Secret `CLAUDE_CODE_OAUTH_TOKEN` missing/expired: create a new token (step 5). The Claude GitHub App must be installed on the repo. |
| The agent step runs but creates its own branch/PR or comments instead of writing files | Switch the step in `.github/actions/run-agent/action.yml` to the commented **CLI fallback** (same secret, no GitHub App). |
| "agent did not produce agent-out/result.json" | The agent was denied a tool or hit the turn limit. Open the run log; adjust `allowed-tools`/`max-turns` in that workflow. |
| PR is created but no checks appear | The `ci` workflow dispatch needs `actions: write`; check the run log of the developer workflow, or start it manually: `gh workflow run ci.yml -f pr=N`. |
| `gh pr create` fails with "not permitted to create pull requests" | Settings > Actions > General > allow Actions to create and approve pull requests. |
| Merge button blocked by a missing `agentic/review` | Run `gh workflow run agent-review.yml -f pr=N`. As admin you may also bypass (your decision). |
| `agentic/protected-paths` is red | The PR changes rules/automation files. If you really want that, read it fully and add `rules-change-approved` (G6). |
| `agentic/human-gates` is red | Untick/missing checklist: tick the boxes you really did. |
| Developer says `blocked`, needs a package | Install it yourself (`cd app; npx expo install <pkg>`, commit to the branch `agent/req-N` or main as the comment says), then re-run `agent-developer`. |
| Expo Go cannot open the app | Same Wi-Fi? Try `npx expo start --tunnel`. A native library needs a development build. |
| `main-watch` opened an alert issue | Someone other than the approver pushed to `main`. Review the commit; revert it if it was not yours. |

## 16. Customising
- Roles and behaviour: edit `.claude/agents/<role>.md`. Keep the "Ground rules" block of each prompt.
- New hard limits: `docs/HARD-RULES.md` (you only).
- Change who approves: set the repository variable `APPROVER` to another GitHub login.
- Different stack later: change `CLAUDE.md`, `app/`, and the commands in `.github/workflows/ci.yml` and the developer/test-designer workflows.
