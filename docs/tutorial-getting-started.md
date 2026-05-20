# Getting Started Tutorial

A complete walkthrough from zero to your first sprint. Estimated time: **15 minutes**.

## Prerequisites

- macOS, Linux, or WSL2 on Windows
- Git installed
- [Claude Code](https://claude.com/claude-code) installed and logged in (or any supported IDE — Cursor, VS Code, Antigravity, Windsurf)
- `gh` CLI installed and authenticated (`gh auth status`)
- A project repository (we'll use a fictional Next.js + Postgres example below)

## Step 1: Install the skill

**Recommended (one-liner):**

```bash
curl -fsSL https://raw.githubusercontent.com/lipefur/sprint-orchestrator/main/install.sh | bash
```

The installer checks dependencies, clones the skill to `~/.claude/skills/sprint-orchestrator/`, and prints next steps.

**Manual (if you prefer to inspect the install script first):**

```bash
curl -fsSL https://raw.githubusercontent.com/lipefur/sprint-orchestrator/main/install.sh -o /tmp/install.sh
less /tmp/install.sh         # review it
bash /tmp/install.sh
```

**Direct clone (skip installer entirely):**

```bash
git clone https://github.com/lipefur/sprint-orchestrator.git ~/.claude/skills/sprint-orchestrator
```

Verify Claude Code sees it:

```bash
ls ~/.claude/skills/sprint-orchestrator/SKILL.md
```

## Step 2: Initialize in your project

```bash
cd path/to/your/project
bash ~/.claude/skills/sprint-orchestrator/scripts/init.sh
```

You'll see:

```
🔍 Inspecting repository at /path/to/your/project...

  ✓ Monorepo detected (package.json workspaces)
  ✓ Next.js detected (next in deps)
  ✓ Postgres detected (Prisma)
  ✓ GitHub Actions detected
  ✓ e2e-validation auto-activated (UI project)

Summary of detected addons: monorepo nextjs postgres github-actions e2e-validation

🔧 Configuration

Project name [my-app]:
```

Press Enter to accept defaults, or customize as you go. Eventually you'll see:

```
✅ Wrote .sprint-orchestrator.yml
✅ Initialized .sprint-orchestrator/state.md

Next steps:
  1. Review the profile and adjust paths/notifications if needed
  2. Create the plans directory:
       mkdir -p docs/superpowers/plans
  3. When ready for your first sprint:
       bash <skill-path>/scripts/create-worktree.sh <N> <theme-slug>
```

## Step 3: Review the profile

```bash
cat .sprint-orchestrator.yml
```

Adjust as needed. Common tweaks:

- `notifications.github_assignee: <your-github-username>` — get auto-assigned to PRs
- `dispatch.method: auto` — leave as auto unless you have a preference
- `adversarial_review.enabled: true` — opt-in to 3rd-Claude review

## Step 4: Plan your first sprint

In Claude Code, open the orchestrator chat in your project's root and say:

> "Vamos pro sprint 1 — implementar login com email/senha"
> *(or in English: "Let's start sprint 1 — implement email/password login")*

Claude will:

1. Use the `superpowers:brainstorming` skill to clarify requirements
2. Write a detailed plan using `templates/plan/feature.md`
3. Save it to `docs/superpowers/plans/YYYY-MM-DD-<project>-sprint-1-email-login.md`
4. Commit + push to `main`

**Important:** The plan must be committed to `main` and pushed before you proceed. The `create-worktree.sh` script will refuse to continue otherwise (the sprint chat wouldn't find the plan).

## Step 5: Dispatch the sprint

```bash
bash ~/.claude/skills/sprint-orchestrator/scripts/create-worktree.sh 1 email-login
```

You'll see:

```
🔨 Creating worktree at .claude/worktrees/sprint-1-email-login...
✅ Updated .sprint-orchestrator/state.md
🔍 Detected environment: claude-code-cli
🚀 Opened Claude Code via claude-cli:// URL scheme
```

A **new Claude Code window opens** with the plan as initial prompt. The sprint chat starts executing autonomously.

## Step 6: Sprint chat runs

In the new window, Claude will:

1. Verify the plan exists with the expected line count
2. Read the full plan
3. Execute the implementation (possibly with multi-agent parallelism)
4. Run smoke tests locally
5. (If e2e-validation addon active) Run Playwright against the E2E flows defined in the plan
6. Open a PR via `gh pr create`
7. Update `.sprint-orchestrator/state.md` with the PR number

You **don't need to babysit** this window. Let it run. When it's done, it'll tell you.

## Step 7: Back to orchestrator — review

Back in your orchestrator chat:

> "PR #5 está aberto"

Claude will:

1. (If `adversarial_review` enabled) Dispatch a 3rd Claude as adversarial reviewer
2. Read CI status, PR diff, state.md
3. Run the `checklists/post-pr-review.md` checklist
4. Suggest merging OR specific fixes

You arbitrate. Approve or request changes. When ready:

```bash
gh pr merge 5 --merge --delete-branch
```

## Step 8: Deploy + capture learnings

After merge, Claude runs `checklists/deploy-prod.md`:

- Apply migrations to prod (mechanism depends on deploy addon)
- Set new env vars
- Trigger deploy
- Run smoke E2E against prod URL
- **Triage `fix:` commits from the sprint and propose new bug patterns** to add to addons

The bug patterns get committed to your local copy of the skill (or proposed as PR upstream to share with the community).

## What you should do next

- **Star the repo** if you found this useful
- **Run a real sprint** in your project
- **Share your bug patterns** via [Issue templates](https://github.com/lipefur/sprint-orchestrator/issues/new/choose)
- **Build an addon** for your stack if it's missing

## Troubleshooting

### `init.sh` says "Not inside a git repository"

Make sure you're inside a `git init`'d project. Run `git status` to confirm.

### `create-worktree.sh` says "Plan not found"

The plan needs to be committed to `main` first. Run:

```bash
git status
git log --oneline main -- docs/superpowers/plans/
```

If the plan isn't in main's history, commit it.

### Sprint chat opens but doesn't have the plan

Two possible causes:
1. Plan wasn't pushed to remote (worktree might pull from origin)
2. URL scheme didn't pass the prompt correctly (rare)

Check `.sprint-orchestrator/state.md` for the plan path, then manually `cat` it in the sprint chat window.

### `claude-cli://` URL scheme doesn't open Claude Code

You're probably in an IDE other than Claude Code standalone. The script falls back to clipboard automatically — just paste the prompt into a new chat.

Verify with: `bash <skill>/scripts/create-worktree.sh 1 test 2>&1 | grep "Detected environment"`

### More questions

Open a [discussion](https://github.com/lipefur/sprint-orchestrator/discussions/categories/q-a) in the Q&A category.
