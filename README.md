# BeachTeams - agentic development template

A ready-to-copy repository for building a **non-commercial mobile app for a community of friends**
(Expo / React Native + TypeScript, Supabase backend) with a team of AI agents, where **you stay in
control through explicit human gates**.

You write ideas. Agents refine them into requirements, design, test, build, review and release
them. Nothing risky happens without your approval.

```
Idea ─► Requirements Engineer ─► [you approve] ─► (Architect ─► [you approve]) ─► Test Designer
     ─► Developer ─► automated checks ─► Reviewer + Security Reviewer ─► [you test on a phone and merge]
     ─► Release Manager ─► [you merge the release PR]
```

## Quick start
1. Read **[SETUP.md](SETUP.md)** (about 45 minutes the first time) and follow it top to bottom.
2. Copy this folder to a new project folder, write `docs/SPEC.md`, run `node scripts/init.mjs`.
3. Create an issue from the **Idea** form. Done - the pipeline starts.

## What is where
| Path | What |
|---|---|
| `SETUP.md` | Step-by-step setup and daily use |
| `docs/SPEC.md` | **You write this**: what the product is |
| `docs/PROCESS.md` | Pipeline, roles, labels, gates, risk tiers |
| `docs/HARD-RULES.md` | Non-negotiable rules for agents (human-only file) |
| `.claude/agents/*.md` | The full prompt of each of the 9 agents |
| `CLAUDE.md` | Conventions every agent reads first |
| `.github/workflows/` | The pipeline (GitHub Actions) |
| `.github/ISSUE_TEMPLATE/` | Idea and Feedback forms |
| `scripts/` | Pipeline plumbing + `init.mjs` (one-time setup) |
| `app/` | The Expo app (Expo Router, Supabase client, tests) |
| `supabase/migrations/` | SQL migrations (agents write, you apply) |
| `docs/design/`, `docs/test-plans/`, `docs/releases/` | Generated design notes, test plans, release notes |

## The nine agents
Requirements Engineer, Architect, Test Designer, Developer, Reviewer, Security Reviewer,
Release Manager, Feedback Triage, Process Improver. Edit their prompts in `.claude/agents/`.

## Local use
Open the folder in Claude Code (`claude`) and ask for any role, for example
"use the requirements-engineer agent on this idea: ...". The same prompts are used.
