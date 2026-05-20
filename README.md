# sprint-orchestrator

> Portable multi-chat sprint orchestration skill for Claude Code. Validated in 17+ production sprints.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Status](https://img.shields.io/badge/status-active-success.svg)](#status)
[![Claude Code](https://img.shields.io/badge/built%20for-Claude%20Code-orange.svg)](https://claude.com/claude-code)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)
[![Discussions](https://img.shields.io/badge/💬-Discussions-blueviolet)](https://github.com/lipefur/sprint-orchestrator/discussions)

**🌍 Languages:** [English](README.md) · [Português](README.pt-BR.md) · [Español](README.es.md)
**📚 Docs:** [Tutorial](docs/tutorial-getting-started.md) · [FAQ](docs/faq.md) · [Recipes](docs/recipes/)

---

## What this is

A skill that teaches Claude Code to orchestrate software sprints across **multiple chats**:

- An **orchestrator chat** where you brainstorm, plan, review and merge
- One or more **sprint chats** spawned per sprint that execute the plan in parallel

This pattern avoids context bloat in long chats and enables real parallelism via multi-agent dispatch.

## Why it exists

Long Claude chats forget context. A single chat for "build feature X" eventually:

- Forgets decisions made early
- Serializes work that could parallelize
- Mixes brainstorming with implementation
- Loses lessons from previous sprints

This skill separates the **strategic** chat (you + orchestrator) from **execution** chats (Claude focused on one sprint at a time), with persistent state in a `state.md` file and learned anti-patterns documented per addon.

## Workflow at a glance

```
┌─────────────────────────────────┐
│  ORCHESTRATOR CHAT (you stay)   │
│  • Brainstorm + plan            │
│  • Review + merge + deploy      │
└─────────────────────────────────┘
              ↓ dispatch via URL scheme
┌─────────────────────────────────┐
│  SPRINT CHAT (new Claude)       │
│  • Reads committed plan         │
│  • Multi-agent parallel exec    │
│  • Opens PR (doesn't merge)     │
└─────────────────────────────────┘
              ↓ PR ready
       back to orchestrator
```

## Quickstart

### 1. Install the skill (one-liner)

```bash
curl -fsSL https://raw.githubusercontent.com/lipefur/sprint-orchestrator/main/install.sh | bash
```

The installer:
- Checks dependencies (`git`, `bash`, `gh`, `yq`, `python3`)
- Clones to `~/.claude/skills/sprint-orchestrator/`
- Prints next steps

Manual install (if you prefer to review first):

```bash
git clone https://github.com/lipefur/sprint-orchestrator.git ~/.claude/skills/sprint-orchestrator
```

Update later:

```bash
curl -fsSL https://raw.githubusercontent.com/lipefur/sprint-orchestrator/main/install.sh | bash -s -- update
```

### 2. Initialize in your project

```bash
cd path/to/your/project
bash ~/.claude/skills/sprint-orchestrator/scripts/init.sh
```

The script will:

- Inspect your repo (`package.json`, `docker-compose.yml`, `next.config.*`, `vercel.json`, `migrations/`, etc.)
- Detect addons (`postgres`, `nextjs`, `monorepo`, etc.)
- Ask what it couldn't infer (deploy method, smoke command)
- Write `.sprint-orchestrator.yml` to your repo root

### 3. Start a sprint

In Claude Code, in your project's orchestrator chat:

> "Plan sprint 1 — implement OAuth login"

Claude brainstorms with you, writes the plan, commits to main. Then:

```bash
bash ~/.claude/skills/sprint-orchestrator/scripts/create-worktree.sh 1 oauth-login
```

This opens a new Claude Code window via `claude-cli://` URL scheme, already running in the worktree with the plan as initial prompt.

### 4. Sprint chat executes, opens PR, updates `.sprint-orchestrator/state.md`

### 5. (Optional) Advanced workflows kick in:

- **Adversarial review** — 3rd Claude reviews PR adversarially
- **Preview validation** — GitHub Action deploys preview + runs Playwright
- **Capture learnings** — after deploy, propose bug patterns to add to skill

## Multi-IDE support

The dispatch script auto-detects your environment and adapts:

| Environment | Dispatch behavior |
|---|---|
| **Claude Code standalone** (Terminal/iTerm) | `claude-cli://` URL scheme opens new window with prompt |
| **Cursor** | Opens worktree in Cursor + copies prompt → press ⌘L for new chat |
| **VS Code** + Claude extension | Opens worktree in VS Code + copies prompt → "Claude: New Chat" command |
| **Antigravity** (Google) | Copies prompt + instruction + working dir |
| **Windsurf** (Codeium) | Opens worktree in Windsurf + copies prompt → new Cascade chat |
| **Others** | Pure clipboard + temp file with prompt |

Override per-project via `dispatch.method` in profile.

## How it differs from alternatives

| Approach | Trade-off |
|---|---|
| **Single long chat** | Context bloat, no parallelism, no memory across sprints |
| **`superpowers:executing-plans`** | Great for executing a known plan in a single session; doesn't orchestrate multi-sprint flows |
| **Plain TODO list / Notion** | No learned anti-patterns; no automation around dispatch + review |
| **This skill** | Multi-chat workflow, addon-modular, state-persistent, validated in production |

## Architecture

```
sprint-orchestrator/
├── core/             # always loaded — workflow, multi-agent, conventional commits, anti-patterns, adversarial-review
├── addons/           # loaded on-demand based on project profile
│   ├── postgres/
│   ├── nextjs/
│   ├── multi-tenant/
│   ├── monorepo/
│   ├── coolify-ssh/
│   ├── github-actions/    # includes preview-validation/ subsystem
│   ├── e2e-validation/    # Playwright + Chrome DevTools + Chrome extension
│   ├── legalese/          # content-filter workarounds for LICENSE/CoC
│   ├── hono/
│   ├── nginx/
│   └── docs-public/
├── templates/
│   ├── plan/         # by sprint type: feature, bugfix, refactor, migration, infra
│   └── prompt-dispatch.md
├── checklists/       # pre-dispatch, post-pr-review, deploy-prod, capture-learnings
├── scripts/          # init.sh, create-worktree.sh (multi-IDE)
└── examples/         # reference profiles
```

## Configuration

Project consumer creates `.sprint-orchestrator.yml` (via `init.sh`):

```yaml
version: 1
project_name: my-app
default_branch: main

paths:
  plans: docs/superpowers/plans
  worktrees: .claude/worktrees

addons: [postgres, nextjs, e2e-validation, github-actions]

dispatch:
  method: auto      # auto-detect IDE | claude-cli | cursor | vscode | antigravity | windsurf | clipboard-only

notifications:
  github_assignee: my-username
  github_label: ready-for-review

# Advanced workflows (opt-in)
adversarial_review:
  enabled: true
  skip_types: [infra]
  reviewer_model: sonnet
  max_comments: 8

github-actions:
  preview_validation: true
  preview_platform: vercel  # vercel | fly | railway | coolify | generic
```

Full schema in [CHANGELOG.md](CHANGELOG.md).

## Advanced workflows

### 🤖 Adversarial review

When sprint chat opens a PR, a **3rd isolated Claude** is dispatched as adversarial reviewer:

- Has no context of the implementation
- Receives only the PR diff + original plan
- Has explicit prompt to **find problems** (not approve)
- Posts comments via `gh pr review`
- You become arbiter, not reviewer

See [`core/adversarial-review.md`](core/adversarial-review.md).

### 🚀 Preview deploy + auto-validation

GitHub Action workflows for Vercel/Fly/Railway/Coolify:

1. PR opens → spins up preview deploy
2. Runs Playwright against preview URL
3. Posts structured PR comment with PASS/FAIL + screenshots
4. Applies `auto-validated` or `needs-fix` label
5. Orchestrator wakes up via GitHub notification (no polling)

See [`addons/github-actions/preview-validation/`](addons/github-actions/preview-validation/).

### 🧠 Capture learnings

After each deploy, orchestrator proactively triages `fix:` commits and proposes new bug patterns to add to addon-specific files. Skill evolves with use.

See [`checklists/capture-learnings.md`](checklists/capture-learnings.md).

## Validated patterns

This skill grew from concrete production usage. Bug patterns (Postgres GRANTs, Next.js SSR fetch, Hono middleware leakage, etc.) are documented per addon. Workflow phases (PLAN → DISPATCH → EXECUTE → REVIEW+DEPLOY) and anti-patterns are battle-tested.

See [`examples/superdb-profile.yml`](examples/superdb-profile.yml) for a complete real-world profile.

## Status

**v1.0** of the redesign (current): foundation + 3 advanced workflows.

**Roadmap (v2.0):**

- Bug patterns split per addon (currently most are placeholders)
- Additional example profiles (Next.js+Vercel, Django, simple monolith)
- Cleanup scripts (`cleanup-merged.sh`, `list-sprints.sh`)
- Sprint stuck recovery checklist
- Kickoff template for new projects
- Scheduled task implementation (for projects without GitHub Actions)

## Contributing

PRs welcome! Especially:

- **New addons** for your stack (Rails, Django, Spring, Go services, etc.)
- **More example profiles**
- **Bug patterns** from your own production lessons
- **Translations** of this README

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT — see [LICENSE](LICENSE).

## Acknowledgments

Built on top of [Anthropic's Claude Code](https://claude.com/claude-code) and the [superpowers](https://github.com/anthropics/superpowers) skill ecosystem. Initial validation in the SuperDB project (Brazilian multi-tenant BaaS).
