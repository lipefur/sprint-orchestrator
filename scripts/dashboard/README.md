# Dashboard

Visual dashboard for `sprint-orchestrator`. Renders `.sprint-orchestrator/state.md` as a kanban board + open PRs view.

**Zero impact on Claude token usage** — runs entirely in your browser + local bash/Python.

## Three modes

### 1. Static HTML (default)

```bash
bash <skill>/scripts/dashboard.sh
```

Generates `$TMPDIR/sprint-orchestrator-dashboard.html` and opens it in your browser. No server, no live updates — refresh the page (or re-run the script) to update.

Use for: occasional check-ins, sharing snapshots with team.

### 2. Live server (`--serve`)

```bash
bash <skill>/scripts/dashboard.sh --serve
# → http://localhost:8765 opens automatically
```

Runs a local Python HTTP server with Server-Sent Events. When `.sprint-orchestrator/state.md` changes (sprint chat updates it after each phase), the dashboard auto-refreshes in your browser.

Use for: daily driver — leave a tab open in a side monitor.

Stop with `Ctrl-C`.

### 3. Multi-project workspace (`--workspace`)

```bash
bash <skill>/scripts/dashboard.sh --workspace
# or combined:
bash <skill>/scripts/dashboard.sh --workspace --serve
```

Reads `~/.config/sprint-orchestrator/workspace.yml`:

```yaml
projects:
  - name: project-a
    path: ~/Code/project-a
  - name: project-b
    path: ~/Code/project-b
  - name: client-work
    path: ~/Work/client-thing
```

Shows all projects in one view. Each project's kanban is collapsible.

Use for: when you have 2+ projects using the skill simultaneously.

## Flags

| Flag | Effect |
|---|---|
| `--serve` | Local web server with live updates via SSE |
| `--workspace` | Multi-project mode from `~/.config/sprint-orchestrator/workspace.yml` |
| `--port N` | Override server port (default 8765, only with `--serve`) |
| `--no-open` | Don't auto-open browser |
| `--json` | Output state as JSON to stdout (for piping/scripting) |
| `--help` | Show usage |

## What it shows

- **Kanban**: Planning · In Progress · Review · Recently Done
- **Per-sprint card**: number, theme, phase, branch, PR (if linked)
- **Open PRs section**: list with labels (`auto-validated`, `needs-fix`, etc.) from `gh pr list`
- **Multi-project view** (when `--workspace`): one kanban per project

Color coding by phase:
- 🟡 Planning
- 🔵 In Progress
- 🟣 Review
- 🟢 Done

## How it reads state

1. Parses `.sprint-orchestrator/state.md` from each tracked project
2. Calls `gh pr list --state open` for live PR data (labels, titles, URLs)
3. Builds a JSON state representation
4. Renders into HTML using `template.html`

In `--serve` mode, also polls state.md files every 2s and pushes SSE events when they change.

## Dependencies

- `bash`
- `python3` (standard library only — no pip installs)
- `git`
- `gh` (optional, but skips PR section if missing)
- `PyYAML` is **optional** (for `--workspace` mode it falls back to regex if missing)

## Customizing

Edit `template.html` — it's vanilla HTML/CSS, no framework. The template uses three placeholders:

- `{{GENERATED_AT}}` — ISO timestamp
- `{{PROJECTS}}` — rendered project sections
- `{{PROJECT_COUNT}}` — count for footer

## What it does NOT do

- ❌ Write to any file (read-only — won't mess up your state.md)
- ❌ Make any external network call beyond `gh pr list`
- ❌ Send any data anywhere
- ❌ Consume Claude tokens

100% local, 100% read-only, 100% optional.
