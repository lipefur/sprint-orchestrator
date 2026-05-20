#!/usr/bin/env bash
# init.sh — auto-discover project profile and write .sprint-orchestrator.yml
#
# Usage:
#   bash <skill-path>/scripts/init.sh                # interactive, in current repo
#   bash <skill-path>/scripts/init.sh --dry-run      # show what would be written
#   bash <skill-path>/scripts/init.sh --force        # overwrite existing profile
#   bash <skill-path>/scripts/init.sh --non-interactive  # use defaults, skip prompts (for CI/test)

set -euo pipefail

# -----------------------------------------------------------------------------
# Pre-flight checks
# -----------------------------------------------------------------------------

if ! git rev-parse --show-toplevel >/dev/null 2>&1; then
  echo "❌ Not inside a git repository. Cd into your project's repo and re-run."
  exit 1
fi

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

PROFILE_FILE=".sprint-orchestrator.yml"

DRY_RUN=0
FORCE=0
NON_INTERACTIVE=0

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --force) FORCE=1 ;;
    --non-interactive) NON_INTERACTIVE=1 ;;
    --help|-h)
      grep -E "^#" "$0" | head -10
      exit 0
      ;;
    *)
      echo "Unknown flag: $arg" >&2
      exit 1
      ;;
  esac
done

if [ -f "$PROFILE_FILE" ] && [ "$FORCE" -eq 0 ]; then
  echo "ℹ️  $PROFILE_FILE already exists. Use --force to overwrite, or edit manually."
  echo ""
  echo "Current profile:"
  cat "$PROFILE_FILE"
  exit 0
fi

# -----------------------------------------------------------------------------
# Auto-discovery
# -----------------------------------------------------------------------------

echo "🔍 Inspecting repository at $REPO_ROOT..."
echo ""

DETECTED_ADDONS=()
PROJECT_NAME_GUESS=""

if [ -f "package.json" ]; then
  PROJECT_NAME_GUESS="$(grep -oE '"name"[[:space:]]*:[[:space:]]*"[^"]+"' package.json | head -1 | sed -E 's/.*"name"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/' || echo "")"
  if grep -q '"workspaces"' package.json 2>/dev/null; then
    DETECTED_ADDONS+=("monorepo")
    echo "  ✓ Monorepo detected (package.json workspaces)"
  fi
  if grep -qE '"next"[[:space:]]*:' package.json 2>/dev/null; then
    DETECTED_ADDONS+=("nextjs")
    echo "  ✓ Next.js detected (next in deps)"
  fi
  if grep -qE '"hono"[[:space:]]*:' package.json 2>/dev/null; then
    DETECTED_ADDONS+=("hono")
    echo "  ✓ Hono detected (hono in deps)"
  fi
fi

if [ -f "pnpm-workspace.yaml" ] && [[ ! " ${DETECTED_ADDONS[*]:-} " =~ " monorepo " ]]; then
  DETECTED_ADDONS+=("monorepo")
  echo "  ✓ Monorepo detected (pnpm-workspace.yaml)"
fi

if [ -f "prisma/schema.prisma" ] && grep -q 'provider[[:space:]]*=[[:space:]]*"postgresql"' prisma/schema.prisma 2>/dev/null; then
  DETECTED_ADDONS+=("postgres")
  echo "  ✓ Postgres detected (Prisma)"
elif find . -maxdepth 4 -type d -name "migrations" 2>/dev/null | head -1 | grep -q . ; then
  if find . -maxdepth 5 -path "*/migrations/*.sql" 2>/dev/null | head -1 | grep -q .; then
    DETECTED_ADDONS+=("postgres")
    echo "  ✓ Postgres detected (SQL migrations)"
  fi
fi

if [[ " ${DETECTED_ADDONS[*]:-} " =~ " postgres " ]]; then
  if find . -maxdepth 5 -path "*/migrations/*.sql" -exec grep -l -E "auth_global|provision_|tenant_schema|proj_management" {} \; 2>/dev/null | head -1 | grep -q .; then
    DETECTED_ADDONS+=("multi-tenant")
    echo "  ✓ Multi-tenant pattern detected (provision_* or auth_global in migrations)"
  fi
fi

if find . -maxdepth 3 \( -name "nginx.conf" -o -path "*/nginx/*.conf" -o -name "default.conf" \) 2>/dev/null | head -1 | grep -q .; then
  DETECTED_ADDONS+=("nginx")
  echo "  ✓ nginx detected (config files)"
fi

if [ -f "docker-compose.yml" ] || [ -f "docker-compose.yaml" ] || [ -f "compose.yml" ]; then
  echo "  ✓ docker-compose detected"
fi

if [ -d ".github/workflows" ] && find .github/workflows -name "*.yml" 2>/dev/null | head -1 | grep -q .; then
  DETECTED_ADDONS+=("github-actions")
  echo "  ✓ GitHub Actions detected"
fi

if find . -maxdepth 3 -type d \( -name "docs" -o -name "landing" -o -name "website" \) 2>/dev/null | head -1 | grep -q .; then
  PUBLIC_FILES="$(find docs landing website 2>/dev/null \( -name "*.html" -o -name "*.md" -o -name "*.mdx" \) 2>/dev/null | wc -l | tr -d ' ')"
  if [ "${PUBLIC_FILES:-0}" -gt 5 ]; then
    DETECTED_ADDONS+=("docs-public")
    echo "  ✓ Public docs detected ($PUBLIC_FILES doc files)"
  fi
fi

if [[ " ${DETECTED_ADDONS[*]:-} " =~ " nextjs " ]]; then
  DETECTED_ADDONS+=("e2e-validation")
  echo "  ✓ e2e-validation auto-activated (UI project)"
fi

SMOKE_LOCAL_GUESS=""
if [ -f "bin/smoke-local.sh" ]; then
  SMOKE_LOCAL_GUESS="bin/smoke-local.sh"
elif [ -f "scripts/smoke.sh" ]; then
  SMOKE_LOCAL_GUESS="scripts/smoke.sh"
elif grep -qE '"smoke"[[:space:]]*:|"test:e2e"[[:space:]]*:' package.json 2>/dev/null; then
  SMOKE_LOCAL_GUESS="npm run smoke"
fi

echo ""
echo "Summary of detected addons: ${DETECTED_ADDONS[*]:-none}"
echo ""

# -----------------------------------------------------------------------------
# Ask-on-missing (interactive)
# -----------------------------------------------------------------------------

if [ "$NON_INTERACTIVE" -eq 1 ]; then
  echo "ℹ️  --non-interactive: using all defaults, no prompts"
  PROJECT_NAME="${PROJECT_NAME_GUESS:-$(basename "$REPO_ROOT")}"
  DEPLOY_METHOD="manual"
  PLANS_PATH="docs/superpowers/plans"
  WORKTREES_PATH=".claude/worktrees"
  SMOKE_LOCAL="$SMOKE_LOCAL_GUESS"
  DISPATCH_METHOD="auto"
else
  echo "🔧 Configuration"
  echo ""
  read -r -p "Project name [${PROJECT_NAME_GUESS:-$(basename "$REPO_ROOT")}]: " PROJECT_NAME
  PROJECT_NAME="${PROJECT_NAME:-${PROJECT_NAME_GUESS:-$(basename "$REPO_ROOT")}}"

  echo ""
  echo "Deploy method:"
  echo "  1) coolify-ssh   (Coolify self-hosted + SSH for migrations)"
  echo "  2) vercel        (Vercel)"
  echo "  3) railway       (Railway)"
  echo "  4) fly           (Fly.io)"
  echo "  5) render        (Render)"
  echo "  6) manual        (any other — you handle deploy yourself)"
  echo "  7) none          (no deploy — library/CLI/SDK)"
  read -r -p "Choose [6]: " DEPLOY_CHOICE
  case "${DEPLOY_CHOICE:-6}" in
    1) DEPLOY_METHOD="coolify-ssh"; DETECTED_ADDONS+=("coolify-ssh") ;;
    2) DEPLOY_METHOD="vercel" ;;
    3) DEPLOY_METHOD="railway" ;;
    4) DEPLOY_METHOD="fly" ;;
    5) DEPLOY_METHOD="render" ;;
    6) DEPLOY_METHOD="manual" ;;
    7) DEPLOY_METHOD="none" ;;
    *) echo "Invalid choice"; exit 1 ;;
  esac

  echo ""
  read -r -p "Plans directory [docs/superpowers/plans]: " PLANS_PATH
  PLANS_PATH="${PLANS_PATH:-docs/superpowers/plans}"

  read -r -p "Worktrees directory [.claude/worktrees]: " WORKTREES_PATH
  WORKTREES_PATH="${WORKTREES_PATH:-.claude/worktrees}"

  if [ -n "$SMOKE_LOCAL_GUESS" ]; then
    read -r -p "Smoke local command [$SMOKE_LOCAL_GUESS]: " SMOKE_LOCAL
    SMOKE_LOCAL="${SMOKE_LOCAL:-$SMOKE_LOCAL_GUESS}"
  else
    read -r -p "Smoke local command (or empty to skip): " SMOKE_LOCAL
  fi

  echo ""
  echo "Dispatch method (how to open new sprint chat):"
  echo "  1) auto             (detect IDE/terminal automatically — recommended)"
  echo "  2) claude-cli       (Claude Code standalone — opens new terminal window)"
  echo "  3) claude-desktop   (Claude Desktop app — composer prefilled)"
  echo "  4) cursor           (Cursor IDE — opens worktree + copies prompt)"
  echo "  5) vscode           (VS Code — opens worktree + copies prompt)"
  echo "  6) antigravity      (Google Antigravity — copies prompt + instructions)"
  echo "  7) windsurf         (Codeium Windsurf — opens worktree + copies prompt)"
  echo "  8) clipboard-only   (copy prompt to clipboard, you open chat manually)"
  read -r -p "Choose [1]: " DISPATCH_CHOICE
  case "${DISPATCH_CHOICE:-1}" in
    1) DISPATCH_METHOD="auto" ;;
    2) DISPATCH_METHOD="claude-cli" ;;
    3) DISPATCH_METHOD="claude-desktop" ;;
    4) DISPATCH_METHOD="cursor" ;;
    5) DISPATCH_METHOD="vscode" ;;
    6) DISPATCH_METHOD="antigravity" ;;
    7) DISPATCH_METHOD="windsurf" ;;
    8) DISPATCH_METHOD="clipboard-only" ;;
    *) echo "Invalid choice"; exit 1 ;;
  esac
fi

# -----------------------------------------------------------------------------
# Write profile YAML
# -----------------------------------------------------------------------------

DEDUP_ADDONS=()
for a in "${DETECTED_ADDONS[@]:-}"; do
  [ -z "$a" ] && continue
  if [[ ! " ${DEDUP_ADDONS[*]:-} " =~ " $a " ]]; then
    DEDUP_ADDONS+=("$a")
  fi
done

ADDONS_YAML=""
for a in "${DEDUP_ADDONS[@]:-}"; do
  [ -z "$a" ] && continue
  ADDONS_YAML="${ADDONS_YAML}  - $a"$'\n'
done

SMOKE_YAML="smoke:"$'\n'
if [ -n "${SMOKE_LOCAL:-}" ]; then
  SMOKE_YAML="${SMOKE_YAML}  local: $SMOKE_LOCAL"$'\n'
else
  SMOKE_YAML="${SMOKE_YAML}  # local: <command to run local smoke>"$'\n'
fi

PROFILE_CONTENT=$(cat <<EOF
# Generated by sprint-orchestrator init.sh on $(date -u +%Y-%m-%dT%H:%M:%SZ)
version: 1
project_name: $PROJECT_NAME
default_branch: main

paths:
  plans: $PLANS_PATH
  worktrees: $WORKTREES_PATH
  memory: ~/.claude/projects/<PROJECT-HASH>/memory

$SMOKE_YAML
git:
  worktree_prefix: sprint
  pr_title_prefix: "feat(sprint-N):"
  conventional_commits: true
  semantic_release: false

dispatch:
  method: $DISPATCH_METHOD

deploy_method: $DEPLOY_METHOD

addons:
$ADDONS_YAML
notifications:
  github_assignee: null   # set to your GitHub username for auto-assignment on PR
  github_label: ready-for-review
  macos: false
  webhook: null
  email: null
EOF
)

if [ "$DRY_RUN" -eq 1 ]; then
  echo "📋 Would write the following to $PROFILE_FILE:"
  echo ""
  echo "$PROFILE_CONTENT"
  exit 0
fi

echo "$PROFILE_CONTENT" > "$PROFILE_FILE"

mkdir -p .sprint-orchestrator
if [ ! -f ".sprint-orchestrator/state.md" ]; then
  cat > .sprint-orchestrator/state.md <<EOF
# Sprint state — $PROJECT_NAME

> Inicializado em $(date -u +%Y-%m-%dT%H:%M:%SZ) via init.sh
> Não há sprints ativos ainda.
EOF
fi

echo ""
echo "✅ Wrote $PROFILE_FILE"
echo "✅ Initialized .sprint-orchestrator/state.md"
echo ""
echo "Next steps:"
echo "  1. Review the profile and adjust paths/notifications if needed:"
echo "       cat $PROFILE_FILE"
echo "  2. Create the plans directory:"
echo "       mkdir -p $PLANS_PATH"
echo "  3. When ready for your first sprint:"
echo "       bash <skill-path>/scripts/create-worktree.sh <N> <theme-slug>"
echo ""
