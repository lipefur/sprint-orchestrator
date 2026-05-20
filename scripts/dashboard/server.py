#!/usr/bin/env python3
"""
Local web server for sprint-orchestrator dashboard with live updates.

Watches .sprint-orchestrator/state.md files in tracked projects.
When any of them change, pushes a Server-Sent Event to the browser.
The browser auto-reloads on event.

Usage (invoked by dashboard.sh, not directly):
  python3 server.py --port 8765 --projects-tsv "name\tpath\n..." --template path/to/template.html
"""

import argparse
import json
import os
import re
import subprocess
import sys
import threading
import time
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from queue import Queue, Empty
import html as html_lib


# ---------------------------------------------------------------------------
# State parsing (mirrors dashboard.sh logic)
# ---------------------------------------------------------------------------

def parse_state_md(project_path):
    state_file = Path(project_path) / '.sprint-orchestrator' / 'state.md'
    if not state_file.exists():
        return []
    content = state_file.read_text(encoding='utf-8', errors='replace')
    blocks = re.split(r'\n## ', content)
    sprints = []
    for blk in blocks[1:]:
        title_match = re.match(r'^Sprint\s+(\d+)\s*—\s*(.+?)(?:\s*\(mergeado\))?$', blk.split('\n', 1)[0])
        if not title_match:
            continue
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
            'dispatched_at': field('Despachado em') or field('Dispatched at'),
        })
    return sprints


def get_open_prs(project_path):
    try:
        out = subprocess.run(
            ['gh', 'pr', 'list', '--state', 'open', '--json',
             'number,title,headRefName,url,createdAt,labels'],
            cwd=project_path, capture_output=True, text=True, timeout=10
        )
        if out.returncode == 0:
            return json.loads(out.stdout)
    except Exception:
        pass
    return []


def build_state(projects):
    result = {
        'generated_at': datetime.now(timezone.utc).isoformat(),
        'projects': []
    }
    for p in projects:
        if not Path(p['path']).exists():
            result['projects'].append({**p, 'error': 'path does not exist'})
            continue
        result['projects'].append({
            **p,
            'sprints': parse_state_md(p['path']),
            'open_prs': get_open_prs(p['path']),
        })
    return result


# ---------------------------------------------------------------------------
# HTML render (mirrors dashboard.sh logic)
# ---------------------------------------------------------------------------

def phase_bucket(phase):
    if not phase:
        return 'unknown'
    p = phase.upper()
    if 'PLAN' in p or 'DISPATCH' in p:
        return 'planning'
    if 'EXECUTE' in p or 'EXEC' in p or 'BLOCKED' in p:
        return 'in_progress'
    if 'REVIEW' in p:
        return 'review'
    if 'DONE' in p or '✅' in phase or 'completo' in phase.lower() or 'mergeado' in phase.lower():
        return 'done'
    return 'in_progress'


def render_card(project, sprint):
    cls = phase_bucket(sprint.get('phase', ''))
    pr_info = ''
    if sprint.get('pr') and 'aguardando' not in (sprint.get('pr') or '').lower():
        pr_info = f"<div class='card-meta'>🔀 {html_lib.escape(sprint['pr'])}</div>"
    branch = sprint.get('branch') or '—'
    return f"""
      <div class='card card-{cls}' data-project='{html_lib.escape(project["name"])}'>
        <div class='card-header'>
          <span class='card-num'>#{sprint['number']}</span>
          <span class='card-theme'>{html_lib.escape(sprint['theme'])}</span>
        </div>
        <div class='card-meta'>🌿 {html_lib.escape(branch)}</div>
        <div class='card-meta phase'>📍 {html_lib.escape(sprint.get('phase', 'unknown'))}</div>
        {pr_info}
      </div>
    """


def render_html(state, template):
    projects_html = []
    for project in state.get('projects', []):
        if project.get('error'):
            projects_html.append(
                f"<section class='project'><h2>{html_lib.escape(project['name'])} "
                f"<span class='error'>⚠️ {html_lib.escape(project['error'])}</span></h2></section>"
            )
            continue
        sprints = project.get('sprints', [])
        buckets = {'planning': [], 'in_progress': [], 'review': [], 'done': []}
        for s in sprints:
            b = phase_bucket(s.get('phase', ''))
            if b not in buckets:
                b = 'in_progress'
            buckets[b].append(s)

        columns_html = ''
        for col_id, col_title, col_emoji in [
            ('planning',    'Planning',      '📋'),
            ('in_progress', 'In Progress',   '🚀'),
            ('review',      'Review',        '👀'),
            ('done',        'Recently Done', '✅'),
        ]:
            col_sprints = buckets[col_id]
            cards = ''.join(render_card(project, s) for s in col_sprints[-5:])
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
                labels = ' '.join(
                    f"<span class='label'>{html_lib.escape(l.get('name',''))}</span>"
                    for l in pr.get('labels', [])
                )
                pr_items += (
                    f"<li><a href='{html_lib.escape(pr.get('url',''))}' target='_blank'>"
                    f"#{pr.get('number')} {html_lib.escape(pr.get('title',''))}</a> {labels}</li>"
                )
            pr_section = (
                f"<details><summary>🔀 Open PRs ({len(open_prs)})</summary>"
                f"<ul class='pr-list'>{pr_items}</ul></details>"
            )

        projects_html.append(f"""
          <section class='project'>
            <h2>📦 {html_lib.escape(project['name'])}</h2>
            <div class='kanban'>{columns_html}</div>
            {pr_section}
          </section>
        """)

    output = template.replace('{{GENERATED_AT}}', state['generated_at'])
    output = output.replace('{{PROJECTS}}', '\n'.join(projects_html))
    output = output.replace('{{PROJECT_COUNT}}', str(len(state.get('projects', []))))
    return output


# ---------------------------------------------------------------------------
# File watcher (polling-based — no extra deps)
# ---------------------------------------------------------------------------

class StateWatcher(threading.Thread):
    """Polls state.md files every 2s; queues 'update' event when any changes."""

    def __init__(self, projects, queues):
        super().__init__(daemon=True)
        self.projects = projects
        self.queues = queues  # list of Queue objects (one per connected SSE client)
        self.mtimes = {}

    def run(self):
        # Prime mtimes
        for p in self.projects:
            f = Path(p['path']) / '.sprint-orchestrator' / 'state.md'
            self.mtimes[f] = f.stat().st_mtime if f.exists() else 0

        while True:
            time.sleep(2)
            changed = False
            for p in self.projects:
                f = Path(p['path']) / '.sprint-orchestrator' / 'state.md'
                m = f.stat().st_mtime if f.exists() else 0
                if m != self.mtimes.get(f, 0):
                    self.mtimes[f] = m
                    changed = True
            if changed:
                for q in list(self.queues):
                    try:
                        q.put('update', timeout=0.1)
                    except Exception:
                        pass


# ---------------------------------------------------------------------------
# HTTP server
# ---------------------------------------------------------------------------

class DashboardHandler(BaseHTTPRequestHandler):
    PROJECTS = []
    TEMPLATE = ''
    SSE_QUEUES = []

    def log_message(self, format, *args):
        # Quiet logs (don't spam stdout)
        if '/events' not in args[0] if args else True:
            sys.stderr.write(f"[server] {self.address_string()} {args[0] if args else ''}\n")

    def do_GET(self):
        if self.path == '/' or self.path.startswith('/index'):
            state = build_state(self.PROJECTS)
            html_body = render_html(state, self.TEMPLATE)
            self.send_response(200)
            self.send_header('Content-Type', 'text/html; charset=utf-8')
            self.send_header('Cache-Control', 'no-cache')
            self.end_headers()
            self.wfile.write(html_body.encode('utf-8'))
        elif self.path == '/state.json':
            state = build_state(self.PROJECTS)
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(state, default=str).encode('utf-8'))
        elif self.path == '/events':
            self.send_response(200)
            self.send_header('Content-Type', 'text/event-stream')
            self.send_header('Cache-Control', 'no-cache')
            self.send_header('Connection', 'keep-alive')
            self.end_headers()
            q = Queue()
            self.SSE_QUEUES.append(q)
            try:
                self.wfile.write(b": connected\n\n")
                self.wfile.flush()
                while True:
                    try:
                        msg = q.get(timeout=15)
                        self.wfile.write(f"data: {msg}\n\n".encode('utf-8'))
                        self.wfile.flush()
                    except Empty:
                        self.wfile.write(b": keepalive\n\n")
                        self.wfile.flush()
            except (BrokenPipeError, ConnectionResetError):
                pass
            finally:
                if q in self.SSE_QUEUES:
                    self.SSE_QUEUES.remove(q)
        else:
            self.send_error(404)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--port', type=int, default=8765)
    ap.add_argument('--projects-tsv', required=True)
    ap.add_argument('--template', required=True)
    args = ap.parse_args()

    projects = []
    for line in args.projects_tsv.strip().split('\n'):
        if '\t' not in line:
            continue
        name, path = line.split('\t', 1)
        projects.append({'name': name.strip(), 'path': os.path.expanduser(path.strip())})

    template = Path(args.template).read_text(encoding='utf-8')

    DashboardHandler.PROJECTS = projects
    DashboardHandler.TEMPLATE = template

    watcher = StateWatcher(projects, DashboardHandler.SSE_QUEUES)
    watcher.start()

    server = ThreadingHTTPServer(('localhost', args.port), DashboardHandler)
    print(f"[server] listening on http://localhost:{args.port}")
    print(f"[server] tracking {len(projects)} project(s)")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n[server] shutting down")
        server.shutdown()


if __name__ == '__main__':
    main()
