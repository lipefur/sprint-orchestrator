# FAQ

Common questions. Open a [Q&A discussion](https://github.com/lipefur/sprint-orchestrator/discussions/categories/q-a) if yours isn't here.

## What is sprint-orchestrator?

A skill for Claude Code that splits long sprints across **multiple chats** — one for strategy (the orchestrator) and one per sprint for execution. Avoids context bloat, enables parallelism, and persists state across sprints.

## Do I need Claude Code to use it?

The skill auto-detects your IDE and adapts dispatch:

- **Claude Code standalone**: full automation via `claude-cli://` URL scheme
- **Cursor / VS Code / Antigravity / Windsurf**: opens worktree in your IDE + copies prompt → you open new chat manually
- **Anything else**: pure clipboard fallback

You'll get the most value in Claude Code standalone, but the skill works elsewhere.

## What's the minimum stack to use it?

- Git repository
- Claude Code (or supported IDE)
- `gh` CLI authenticated

That's it. Bash, `git`, `curl`. Optional but recommended: `yq` (for cleaner YAML parsing).

## Does it work in non-JavaScript projects?

Yes. The skill is **stack-agnostic in its core**. Detection in `init.sh` looks for many stacks (Postgres, Next.js, etc.) but you can skip detection and configure manually.

Languages tested via existing addons or compatible by design: Node/Bun, Next.js, any Postgres project, Hono APIs. Python/Rails/Go/etc. work but don't have stack-specific addons yet — those are open contributions.

## Does it work without GitHub?

The skill works fine on **any git host** (GitLab, Bitbucket, self-hosted Forgejo, etc.) — but some features depend on GitHub specifically:

- `addons/github-actions/preview-validation/` (would need adaptation for GitLab CI / etc.)
- `notifications.github_assignee` (replace with platform-specific equivalent)
- `gh pr create` commands (replace with `glab pr create` or equivalent)

The core workflow (orchestrator + sprint chat + worktrees + state.md) is platform-agnostic.

## Why "sprint" if I do continuous delivery?

"Sprint" here just means **a focused unit of work with a clear scope and deliverable** — not a 2-week Scrum sprint. A sprint can be:

- 2 hours (small feature)
- 1-2 days (medium feature)
- 4-5 days (major rework)

Each sprint produces 1 PR. Whether you ship it the same day (continuous) or batch (release) is your call.

## Can multiple sprints run in parallel?

Yes, but with discipline:

- Each sprint = separate worktree = separate branch
- Plans must be committed to main before dispatch (so other sprints can also see them)
- Sprints touching the same files will conflict at merge time — coordinate beforehand

The `addons/monorepo/` addon helps when sprints span different packages.

## What's the "adversarial review" workflow?

A 3rd Claude (isolated, fresh context) is dispatched as PR reviewer with an explicit prompt to **find problems**, not approve. Posts comments via `gh pr review`. You become arbiter between the implementer's optimism and the reviewer's pessimism.

Opt-in via profile:

```yaml
adversarial_review:
  enabled: true
```

See [`core/adversarial-review.md`](../core/adversarial-review.md).

## Does the skill cost more tokens than usual?

Slightly more, but predictable:

- **Multi-chat split**: token-equivalent — same total tokens, distributed across chats
- **Adversarial review**: +~10-20k tokens per PR (~$0.03-0.10 in Sonnet)
- **Multi-agent dispatch**: can save tokens by parallelizing (vs sequential 1-agent)
- **Bug patterns memory**: prevents re-discovering bugs = saves debug tokens long-term

For most teams the ROI is positive within 5-10 sprints.

## What happens if I update the skill?

`git pull` in `~/.claude/skills/sprint-orchestrator/`. Profile schema is versioned (`version: 1` currently) — breaking changes will bump the version and CHANGELOG.md will document migration steps.

## Can I fork and customize?

Absolutely. The skill is MIT — fork freely. If you build something generic enough that others would benefit, consider PR upstream.

## How do I contribute a bug pattern?

Open an [issue with the `bug-pattern` template](https://github.com/lipefur/sprint-orchestrator/issues/new?template=bug-pattern.md). Or directly open a PR to the relevant addon's `bug-patterns.md`.

Real production bugs only — speculative "what could go wrong" patterns get rejected.

## How do I add a new addon?

1. Open an [addon request issue](https://github.com/lipefur/sprint-orchestrator/issues/new?template=addon-request.md) to discuss scope
2. Create `addons/<your-stack>/README.md` following the existing addon format
3. Add detection logic to `scripts/init.sh`
4. (Optional but valued) Add at least 2-3 bug patterns from real debugging
5. Submit PR

See [CONTRIBUTING.md](../CONTRIBUTING.md).

## Is there a roadmap?

Yes — see "Status" section in [README.en.md](../README.en.md) (English) or [README.md](../README.md) (Português) and [Ideas discussions](https://github.com/lipefur/sprint-orchestrator/discussions/categories/ideas).

## Where did this come from?

Built and validated across 17+ production sprints between May 2026 and the redesign that produced v1.0, in a multi-tenant BaaS project. See [`examples/multi-tenant-saas-profile.yml`](../examples/multi-tenant-saas-profile.yml) for an anonymized reference profile.
