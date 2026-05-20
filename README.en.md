# sprint-orchestrator

> **Stop losing context in long Claude chats.** Build big features sprint-by-sprint with persistent memory, parallel execution, and learned anti-patterns.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Latest](https://img.shields.io/github/v/release/lipefur/sprint-orchestrator?color=blue)](https://github.com/lipefur/sprint-orchestrator/releases)
[![Status](https://img.shields.io/badge/status-active-success.svg)](#status)
[![Claude Code](https://img.shields.io/badge/built%20for-Claude%20Code-orange.svg)](https://claude.com/claude-code)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)
[![Discussions](https://img.shields.io/badge/💬-Discussions-blueviolet)](https://github.com/lipefur/sprint-orchestrator/discussions)

**🌍 Languages:** [Português](README.md) · [English](README.en.md) · [Español](README.es.md)
**📚 Docs:** [Tutorial](docs/tutorial-getting-started.md) · [FAQ](docs/faq.md) · [Recipes](docs/recipes/)

---

## 🤔 The problem

You want to build something big with Claude. You start a chat. You explain what you want. Claude starts coding. Two hours later:

- 😵 The chat is huge. Claude forgot the decisions you made early.
- 🐌 Everything happens one task at a time, even when 4 things could run in parallel.
- 🔁 You explain the same conventions over and over.
- 💔 Bugs from last sprint? Forgotten. Claude makes them again.

**Sound familiar?**

## ✨ The idea

Think of building software like making a movie:

| Role | Who |
|---|---|
| 🎬 **Director** (creative vision, approves cuts) | **You** |
| 📋 **Production Manager** (plans, reviews, ships) | **Orchestrator chat** (stays open for the project) |
| 🎥 **Film Crew** (each one shoots one scene) | **Sprint chats** (one per feature, spawned and disposed) |

You don't film every frame yourself. You **direct**, the production manager **plans and reviews**, the crews **execute in parallel**.

That's it. That's the skill.

## 🎯 Before / After

| | **Without this skill** | **With this skill** |
|---|---|---|
| **Chat structure** | 1 giant chat that forgets context | 1 orchestrator + N focused sprint chats |
| **Decisions** | Made early, lost later | Captured in plans, committed to git |
| **Parallelism** | One thing at a time | 1-4 agents per sprint, multi-sprint possible |
| **Memory between sprints** | None | `state.md` + `bug-patterns.md` per addon |
| **Quality control** | You read every PR manually | Adversarial Claude reviews first, you arbitrate |
| **Validation** | "It works on my machine" | GitHub Action deploys preview + runs Playwright automatically |
| **Lessons learned** | Lost in chat history | Auto-captured as bug patterns after each deploy |

## 👥 Who this is for

- **Devs using Claude Code daily** on real projects (not just demos)
- **Solo founders / indie hackers** building multi-feature products
- **Small teams** that want structured AI-assisted workflows
- **Anyone with multiple repos** wanting consistent process across them

**Not for:** one-off scripts, throwaway prototypes, "just fix this typo" tasks. Use Claude directly for those.

## 🚀 Install (1 command)

```bash
curl -fsSL https://raw.githubusercontent.com/lipefur/sprint-orchestrator/main/install.sh | bash
```

The installer checks dependencies, clones the skill to `~/.claude/skills/sprint-orchestrator/`, and prints next steps.

<details>
<summary>Other install methods (manual / review-first / custom location)</summary>

**Review the installer first:**

```bash
curl -fsSL https://raw.githubusercontent.com/lipefur/sprint-orchestrator/main/install.sh -o /tmp/install.sh
less /tmp/install.sh        # inspect it
bash /tmp/install.sh
```

**Direct clone (skip installer):**

```bash
git clone https://github.com/lipefur/sprint-orchestrator.git ~/.claude/skills/sprint-orchestrator
```

**Custom location:**

```bash
SPRINT_ORCHESTRATOR_DIR=/custom/path bash install.sh
```

**Update later:**

```bash
curl -fsSL https://raw.githubusercontent.com/lipefur/sprint-orchestrator/main/install.sh | bash -s -- update
```

</details>

## 📖 Quickstart (3 steps)

### 1. Set up your project (once)

```bash
cd path/to/your/project
bash ~/.claude/skills/sprint-orchestrator/scripts/init.sh
```

The script inspects your repo, detects your stack (Postgres? Next.js? Monorepo?), asks a few questions, and writes `.sprint-orchestrator.yml`.

### 2. Plan a sprint

Open Claude Code in your project. Say:

> "Let's plan sprint 1 — implement OAuth login"

Claude brainstorms with you, writes a detailed plan, commits it to `main`.

### 3. Dispatch the sprint

```bash
bash ~/.claude/skills/sprint-orchestrator/scripts/create-worktree.sh 1 oauth-login
```

A **new Claude Code window opens**, already running in an isolated worktree with the plan loaded. It executes autonomously, opens a PR, then goes back to you for review.

That's it. Full walkthrough: [docs/tutorial-getting-started.md](docs/tutorial-getting-started.md).

---

# Technical summary

For those who want to understand the architecture before installing.

## How it works under the hood

The skill is structured as **modular markdown** that Claude reads on demand:

```
sprint-orchestrator/
├── SKILL.md             # entry point — Claude always reads this
├── core/                # workflow + universal anti-patterns + commits style
├── addons/              # stack-specific (loaded only if your profile activates them)
├── templates/           # plan templates by type, dispatch prompt, memory
├── checklists/          # pre-dispatch, post-pr-review, deploy-prod, capture-learnings
└── scripts/             # init.sh, create-worktree.sh (multi-IDE dispatch)
```

When you invoke the skill in Claude Code:

1. Claude reads `.sprint-orchestrator.yml` from your project
2. Loads `core/` (universal stuff)
3. Loads only the `addons/` your project uses (e.g. `postgres`, `nextjs`)
4. Reaches for templates/checklists just-in-time per phase

Result: **~6-12k tokens of context** even with all addons active.

## The 4-phase workflow

```
┌─────────────────────────────────┐
│  ORCHESTRATOR CHAT (you stay)   │
│  1. PLAN — brainstorm + plan    │
│  2. DISPATCH — create worktree  │
│              + open new chat    │
└─────────────────────────────────┘
              ↓
┌─────────────────────────────────┐
│  SPRINT CHAT (new Claude)       │
│  3. EXECUTE — read plan, code,  │
│     test, open PR, update state │
└─────────────────────────────────┘
              ↓
┌─────────────────────────────────┐
│  BACK TO ORCHESTRATOR           │
│  4. REVIEW + DEPLOY             │
│     (with optional auto-checks) │
└─────────────────────────────────┘
```

## Configuration (one file per project)

`.sprint-orchestrator.yml` at your project root (generated by `init.sh`):

```yaml
version: 1
project_name: my-app
default_branch: main

paths:
  plans: docs/superpowers/plans
  worktrees: .claude/worktrees

addons: [postgres, nextjs, e2e-validation, github-actions]

dispatch:
  method: auto      # auto-detect IDE (Cursor, VS Code, Claude Code, etc.)

notifications:
  github_assignee: my-username       # auto-assigned on PR
  github_label: ready-for-review

# Advanced workflows (opt-in)
adversarial_review:
  enabled: true                       # 3rd Claude reviews PRs adversarially
  reviewer_model: sonnet

github-actions:
  preview_validation: true            # preview deploy + auto Playwright on PR
  preview_platform: vercel            # vercel | fly | railway | coolify | generic
```

## Advanced workflows

Three opt-in workflows that elevate the basic flow:

### 🤖 Adversarial review

When the sprint chat opens a PR, a **3rd isolated Claude** is dispatched as reviewer with an explicit prompt: *"find problems the implementer missed."* It posts comments via `gh pr review`. You become **arbiter**, not line-by-line reviewer.

→ [`core/adversarial-review.md`](core/adversarial-review.md)

### 🚀 Preview deploy + auto-validation

GitHub Action templates for Vercel/Fly/Railway/Coolify. On PR open: spins up preview deploy, runs Playwright against the preview URL, posts a structured PR comment with PASS/FAIL + screenshots. Orchestrator wakes up via GitHub notification — **no polling**.

→ [`addons/github-actions/preview-validation/`](addons/github-actions/preview-validation/)

### 🧠 Capture learnings

After each deploy, the orchestrator triages `fix:` commits from the sprint and proposes new bug patterns to add to addon files. The skill **evolves with use** instead of staying static.

→ [`checklists/capture-learnings.md`](checklists/capture-learnings.md)

### 📊 Visual dashboard

Local kanban board rendered from `state.md`. Three modes:

```bash
bash <skill>/scripts/dashboard.sh              # static HTML, opens in browser
bash <skill>/scripts/dashboard.sh --serve      # live server with auto-refresh (SSE)
bash <skill>/scripts/dashboard.sh --workspace  # multi-project from ~/.config/sprint-orchestrator/workspace.yml
```

Runs 100% locally, **zero Claude tokens consumed**. See everything at a glance: sprints by phase, open PRs with labels, recent merges.

→ [`scripts/dashboard/`](scripts/dashboard/)

## Multi-IDE support

The dispatch script **auto-detects your environment** and adapts:

| Environment | Behavior |
|---|---|
| **Claude Code standalone** (Terminal/iTerm) | `claude-cli://` URL scheme opens new window with prompt pre-loaded |
| **Cursor** | Opens worktree in Cursor + copies prompt → press ⌘L for new chat |
| **VS Code** + Claude extension | Opens worktree in VS Code + copies prompt → "Claude: New Chat" |
| **Antigravity** (Google) | Copies prompt + instruction + working dir |
| **Windsurf** (Codeium) | Opens worktree in Windsurf + copies prompt → new Cascade chat |
| **Others** | Pure clipboard + temp file with prompt |

Override per-project via `dispatch.method` in profile.

## How it differs from alternatives

| Approach | Trade-off |
|---|---|
| **Single long chat** | Context bloat, no parallelism, no memory across sprints |
| **`superpowers:executing-plans`** | Great for executing a known plan in one session; doesn't orchestrate multi-sprint flows |
| **Plain TODO list / Notion** | No learned anti-patterns; no automation around dispatch + review |
| **This skill** | Multi-chat workflow, addon-modular, state-persistent, validated in production |

## Status

**v1.0.1** (current): foundation + 3 advanced workflows + one-liner installer.

**Roadmap (v2.0):**

- Bug patterns split per addon (most are placeholders right now — biggest gap)
- More example profiles (Next.js+Vercel, Django, simple monolith)
- Cleanup scripts (`cleanup-merged.sh`, `list-sprints.sh`)
- Sprint stuck recovery checklist
- Kickoff template for new projects
- Scheduled task implementation (for projects without GitHub Actions)

## Contributing

The most valuable contributions:

- 🧠 **Bug patterns** from your real production debugging → see [bug-pattern issue template](.github/ISSUE_TEMPLATE/bug-pattern.md)
- 🧩 **New addons** for your stack (Rails, Django, Spring, Go, etc.) → see [CONTRIBUTING.md](CONTRIBUTING.md)
- 📋 **Example profiles** in `examples/`
- 🌍 **Translations** of this README

## License

MIT — see [LICENSE](LICENSE). Fork freely.

## Origin

Built and validated in 17+ production sprints between May 2026 and the public release — in a production multi-tenant BaaS project. See [`examples/multi-tenant-saas-profile.yml`](examples/multi-tenant-saas-profile.yml) for an anonymized real-world profile.
