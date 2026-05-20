#!/usr/bin/env bash
# dashboard.sh — visual dashboard for sprint-orchestrator
#
# Usage:
#   bash dashboard.sh                    # generate static HTML + open in browser (Level 1)
#   bash dashboard.sh --serve            # run local web server with live updates (Level 2)
#   bash dashboard.sh --workspace        # multi-project view from ~/.config/sprint-orchestrator/workspace.yml (Level 3)
#   bash dashboard.sh --serve --workspace # combines: server + multi-project
#
# Flags:
#   --port N        Override server port (default: 8765, only with --serve)
#   --no-open       Don't auto-open browser
#   --json          Output state as JSON to stdout (for piping/scripting)
#   --help / -h     Show this message

set -euo pipefail

# -----------------------------------------------------------------------------
# Args
# -----------------------------------------------------------------------------

SERVE=0
WORKSPACE=0
NO_OPEN=0
JSON_ONLY=0
PORT=8765

for arg in "$@"; do
  case "$arg" in
    --serve)        SERVE=1 ;;
    --workspace)    WORKSPACE=1 ;;
    --no-open)      NO_OPEN=1 ;;
    --json)         JSON_ONLY=1 ;;
    --port=*)       PORT="${arg#*=}" ;;
    --port)         shift; PORT="${1:-8765}" ;;
    --help|-h)
      grep -E "^#" "$0" | sed 's/^# \?//' | head -20
      exit 0
      ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DASHBOARD_DIR="${SCRIPT_DIR}/dashboard"

# -----------------------------------------------------------------------------
# Dependency check
# -----------------------------------------------------------------------------

if ! command -v python3 >/dev/null 2>&1; then
  echo "❌ python3 required (used for HTML template rendering + optional server)" >&2
  exit 1
fi

if ! command -v git >/dev/null 2>&1; then
  echo "❌ git required" >&2
  exit 1
fi

# -----------------------------------------------------------------------------
# Discover projects
# -----------------------------------------------------------------------------

WORKSPACE_FILE="${HOME}/.config/sprint-orchestrator/workspace.yml"

discover_projects() {
  if [ "$WORKSPACE" -eq 1 ]; then
    if [ ! -f "$WORKSPACE_FILE" ]; then
      cat >&2 <<EOF
❌ Workspace file not found: $WORKSPACE_FILE

Create it with:

  mkdir -p ~/.config/sprint-orchestrator
  cat > $WORKSPACE_FILE <<'YAML'
projects:
  - name: my-project-a
    path: ~/Code/project-a
  - name: my-project-b
    path: ~/Code/project-b
YAML
EOF
      exit 1
    fi
    # Simple YAML parse: extract path: values
    python3 -c "
import yaml, os, sys
try:
    with open('$WORKSPACE_FILE') as f:
        cfg = yaml.safe_load(f)
    for p in cfg.get('projects', []):
        path = os.path.expanduser(p['path'])
        name = p.get('name', os.path.basename(path))
        print(f'{name}\\t{path}')
except ImportError:
    # No PyYAML? Use crude regex parser
    import re
    with open('$WORKSPACE_FILE') as f: text = f.read()
    pairs = re.findall(r'-\s+name:\s*(\S+).*?path:\s*(\S+)', text, re.DOTALL)
    for name, path in pairs:
        path = os.path.expanduser(path.strip())
        print(f'{name}\\t{path}')
"
  else
    # Single-project mode: current dir must be a git repo with profile
    if ! git rev-parse --show-toplevel >/dev/null 2>&1; then
      echo "❌ Not inside a git repository (and --workspace not specified)" >&2
      exit 1
    fi
    local repo
    repo="$(git rev-parse --show-toplevel)"
    if [ ! -f "${repo}/.sprint-orchestrator.yml" ]; then
      echo "❌ No .sprint-orchestrator.yml in $repo — run init.sh first" >&2
      exit 1
    fi
    local name
    name="$(grep -E '^project_name:' "${repo}/.sprint-orchestrator.yml" | head -1 | sed -E 's/^project_name:\s*//' | tr -d '"' | tr -d "'")"
    name="${name:-$(basename "$repo")}"
    echo -e "${name}\t${repo}"
  fi
}

# -----------------------------------------------------------------------------
# Build state JSON from each project
# -----------------------------------------------------------------------------

build_state_json() {
  python3 <<'PYEOF'
import json, os, re, subprocess, sys
from datetime import datetime, timezone
from pathlib import Path

projects_input = os.environ.get('PROJECTS_TSV', '').strip()
projects = []
for line in projects_input.splitlines():
    if '\t' not in line: continue
    name, path = line.split('\t', 1)
    projects.append({'name': name.strip(), 'path': path.strip()})

def parse_state_md(path):
    state_file = Path(path) / '.sprint-orchestrator' / 'state.md'
    if not state_file.exists():
        return []
    content = state_file.read_text(encoding='utf-8', errors='replace')
    # Naive parse: each "## Sprint N — theme" starts a sprint block
    blocks = re.split(r'\n## ', content)
    sprints = []
    for blk in blocks[1:]:  # first is header
        title_match = re.match(r'^Sprint\s+(\d+)\s*—\s*(.+?)(?:\s*\(mergeado\))?$', blk.split('\n', 1)[0])
        if not title_match: continue
        number = title_match.group(1)
        theme = title_match.group(2).strip()
        body = blk
        def field(key):
            m = re.search(rf'\*\*{key}\*\*:\s*(.+?)$', body, re.MULTILINE)
            return m.group(1).strip() if m else None
        sprints.append({
            'number': int(number),
            'theme': theme,
            'phase': field('Fase') or field('Status') or 'unknown',
            'branch': field('Branch'),
            'worktree': field('Worktree'),
            'plan': field('Plano') or field('Plan'),
            'pr': field('PR'),
            'dispatched_at': field('Despachado em') or field('Despatched at'),
            'commit_base': field('Commit base'),
        })
    return sprints

def get_open_prs(path):
    try:
        out = subprocess.run(
            ['gh', 'pr', 'list', '--state', 'open', '--json',
             'number,title,headRefName,url,createdAt,labels,statusCheckRollup'],
            cwd=path, capture_output=True, text=True, timeout=10
        )
        if out.returncode == 0:
            return json.loads(out.stdout)
    except Exception:
        pass
    return []

def get_recent_merges(path, limit=5):
    try:
        out = subprocess.run(
            ['git', 'log', '--oneline', '--merges', f'-{limit}', 'main'],
            cwd=path, capture_output=True, text=True, timeout=5
        )
        if out.returncode == 0:
            return [l for l in out.stdout.strip().split('\n') if l]
    except Exception:
        pass
    return []

result = {
    'generated_at': datetime.now(timezone.utc).isoformat(),
    'projects': []
}

for p in projects:
    if not Path(p['path']).exists():
        result['projects'].append({**p, 'error': 'path does not exist'})
        continue
    sprints = parse_state_md(p['path'])
    prs = get_open_prs(p['path'])
    merges = get_recent_merges(p['path'])
    result['projects'].append({
        **p,
        'sprints': sprints,
        'open_prs': prs,
        'recent_merges': merges,
    })

print(json.dumps(result, indent=2, default=str))
PYEOF
}

# -----------------------------------------------------------------------------
# Render HTML
# -----------------------------------------------------------------------------

render_html() {
  local state_json="$1"
  python3 - "$state_json" "$DASHBOARD_DIR/template.html" <<'PYEOF'
import json, sys, html
from pathlib import Path

state_json = sys.argv[1]
template_path = sys.argv[2]

state = json.loads(state_json)
template = Path(template_path).read_text(encoding='utf-8')

# Bucket sprints by phase
def phase_bucket(phase):
    if not phase: return 'unknown'
    p = phase.upper()
    if 'PLAN' in p or 'DISPATCH' in p: return 'planning'
    if 'EXECUTE' in p or 'EXEC' in p or 'BLOCKED' in p: return 'in_progress'
    if 'REVIEW' in p: return 'review'
    if 'DONE' in p or '✅' in phase or 'completo' in phase.lower() or 'mergeado' in phase.lower(): return 'done'
    return 'in_progress'

def render_card(project, sprint):
    cls = phase_bucket(sprint.get('phase', ''))
    pr_info = ''
    if sprint.get('pr') and 'aguardando' not in sprint.get('pr', '').lower():
        pr_info = f"<div class='card-meta'>🔀 {html.escape(sprint['pr'])}</div>"
    branch = sprint.get('branch') or '—'
    return f"""
      <div class='card card-{cls}' data-project='{html.escape(project["name"])}'>
        <div class='card-header'>
          <span class='card-num'>#{sprint['number']}</span>
          <span class='card-theme'>{html.escape(sprint['theme'])}</span>
        </div>
        <div class='card-meta'>🌿 {html.escape(branch)}</div>
        <div class='card-meta phase'>📍 {html.escape(sprint.get('phase', 'unknown'))}</div>
        {pr_info}
      </div>
    """

# For multi-project workspace, group by project
projects_html = []
for project in state.get('projects', []):
    if project.get('error'):
        projects_html.append(f"""
          <section class='project'>
            <h2>{html.escape(project['name'])} <span class='error'>⚠️ {html.escape(project['error'])}</span></h2>
          </section>
        """)
        continue

    sprints = project.get('sprints', [])
    buckets = {'planning': [], 'in_progress': [], 'review': [], 'done': []}
    for s in sprints:
        b = phase_bucket(s.get('phase', ''))
        if b not in buckets: b = 'in_progress'
        buckets[b].append(s)

    columns_html = ''
    for col_id, col_title, col_emoji in [
        ('planning',    'Planning',    '📋'),
        ('in_progress', 'In Progress', '🚀'),
        ('review',      'Review',      '👀'),
        ('done',        'Recently Done', '✅'),
    ]:
        col_sprints = buckets[col_id]
        cards = ''.join(render_card(project, s) for s in col_sprints[-5:])  # cap done at 5
        columns_html += f"""
          <div class='column column-{col_id}'>
            <h3>{col_emoji} {col_title} <span class='count'>{len(col_sprints)}</span></h3>
            {cards or '<div class="empty">—</div>'}
          </div>
        """

    open_prs = project.get('open_prs', [])
    pr_section = ''
    if open_prs:
        pr_items = ''
        for pr in open_prs[:8]:
            labels = ' '.join(f"<span class='label'>{html.escape(l.get('name',''))}</span>" for l in pr.get('labels', []))
            pr_items += f"<li><a href='{html.escape(pr.get('url',''))}' target='_blank'>#{pr.get('number')} {html.escape(pr.get('title',''))}</a> {labels}</li>"
        pr_section = f"<details><summary>🔀 Open PRs ({len(open_prs)})</summary><ul class='pr-list'>{pr_items}</ul></details>"

    projects_html.append(f"""
      <section class='project'>
        <h2>📦 {html.escape(project['name'])}</h2>
        <div class='kanban'>{columns_html}</div>
        {pr_section}
      </section>
    """)

output = template.replace('{{GENERATED_AT}}', state['generated_at'])
output = output.replace('{{PROJECTS}}', '\n'.join(projects_html))
output = output.replace('{{PROJECT_COUNT}}', str(len(state.get('projects', []))))
print(output)
PYEOF
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------

PROJECTS_TSV="$(discover_projects)"

if [ -z "$PROJECTS_TSV" ]; then
  echo "❌ No projects found" >&2
  exit 1
fi

export PROJECTS_TSV

STATE_JSON="$(build_state_json)"

if [ "$JSON_ONLY" -eq 1 ]; then
  echo "$STATE_JSON"
  exit 0
fi

OUTPUT_HTML="${TMPDIR:-/tmp}/sprint-orchestrator-dashboard.html"
render_html "$STATE_JSON" > "$OUTPUT_HTML"
echo "📊 Dashboard generated: $OUTPUT_HTML"

if [ "$SERVE" -eq 1 ]; then
  echo "🌐 Starting live dashboard server on http://localhost:$PORT"
  echo "   Press Ctrl-C to stop."
  if [ "$NO_OPEN" -eq 0 ]; then
    (sleep 1 && (open "http://localhost:$PORT" 2>/dev/null || xdg-open "http://localhost:$PORT" 2>/dev/null || true)) &
  fi
  cd "$(dirname "$OUTPUT_HTML")"
  exec python3 "$DASHBOARD_DIR/server.py" --port "$PORT" --projects-tsv "$PROJECTS_TSV" --template "$DASHBOARD_DIR/template.html"
fi

if [ "$NO_OPEN" -eq 0 ]; then
  if command -v open >/dev/null 2>&1; then
    open "$OUTPUT_HTML"
  elif command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$OUTPUT_HTML"
  else
    echo "ℹ️  Open this file in your browser: $OUTPUT_HTML"
  fi
fi
