# sprint-orchestrator

> Portable multi-chat sprint orchestration skill for Claude Code. Validated in 17+ production sprints.

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

## Quickstart (in your project)

```bash
# 1. Make sure you're in a git repo
cd path/to/your/project

# 2. Initialize the orchestrator's profile for this project
bash ~/.claude/skills/sprint-orchestrator/scripts/init.sh

# This will:
#   - Inspect your repo (package.json, docker-compose, etc.)
#   - Detect addons (postgres, nextjs, monorepo, etc.)
#   - Ask what it couldn't infer (deploy method, smoke command)
#   - Write `.sprint-orchestrator.yml` to your repo root

# 3. Review the profile
cat .sprint-orchestrator.yml

# 4. When ready for sprint #1, in Claude Code orchestrator chat:
#    "Plano sprint 1 — tema X" (or similar)
#    Claude brainstorms with you, writes plan, commits to main.

# 5. Dispatch the sprint:
#    Claude runs: bash <skill>/scripts/create-worktree.sh 1 tema-x
#    This opens a new Claude Code window via `claude-cli://` URL scheme,
#    already running in the worktree with the plan as initial prompt.

# 6. Sprint chat executes, opens PR, updates state.md.

# 7. (Phase 2) Scheduled task detects PR aperto, opens orchestrator
#    automatically for review.
```

## How it differs from alternatives

| Approach | Trade-off |
|---|---|
| **Single long chat** | Context bloat, no parallelism, no persistent memory across sprints |
| **`superpowers:executing-plans`** | Great for executing a known plan in single session; doesn't orchestrate multi-sprint flows |
| **Plain TODO list / Notion** | Doesn't carry over learned anti-patterns; no automation around dispatch + review |
| **This skill** | Multi-chat workflow, addon-modular, state-persistent, validated in production |

## Architecture overview

```
sprint-orchestrator/
├── core/            # always loaded — workflow, multi-agent, conventional commits
├── addons/          # loaded on-demand based on project profile
│   ├── postgres/
│   ├── nextjs/
│   ├── e2e-validation/   # mandatory if project has UI
│   └── ...
├── templates/
│   ├── plan/        # by sprint type: feature, bugfix, refactor, migration, infra
│   └── prompt-dispatch.md
├── scripts/
│   ├── init.sh
│   └── create-worktree.sh
└── examples/        # reference profiles
```

## Configuration

Project consumer creates `.sprint-orchestrator.yml` (via `init.sh`):

```yaml
version: 1
project_name: my-app
addons: [postgres, nextjs, e2e-validation]
dispatch:
  method: claude-cli   # opens Claude Code in new terminal window
notifications:
  github_assignee: my-username   # PR auto-assigned, GitHub notifies natively
```

Full schema in `CHANGELOG.md`.

## Validated patterns

This skill grew from concrete production usage. Bug patterns (Postgres GRANTs, Next.js SSR fetch, Hono middleware leakage, etc.) are documented per addon. Workflow phases (PLAN → DISPATCH → EXECUTE → REVIEW+DEPLOY) and anti-patterns are battle-tested.

See `examples/superdb-profile.yml` for a complete real-world profile.

## Status

**Phase 1** of the redesign (this version): foundation — modular structure, profile schema, auto-discovery, URL scheme dispatch, e2e-validation addon complete, addon placeholders for stack-specific bug patterns.

**Phase 2 (planned)**: bug-patterns split per addon, more templates, scheduled task implementation, additional examples (nextjs-vercel, simple-monolith, django).

**Phase 3 (planned)**: polish, publish to GitHub as installable skill.

## License

MIT — see `LICENSE`.

## Contributing

This is a young project. PRs welcome especially for:
- New addons (your stack — Rails, Django, Spring, Go services, etc.)
- More example profiles
- Bug patterns from your own production lessons

See `CHANGELOG.md` for version history and `core/workflow.md` for the formal workflow.
