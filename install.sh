#!/usr/bin/env bash
# sprint-orchestrator installer
#
# One-liner install:
#   curl -fsSL https://raw.githubusercontent.com/lipefur/sprint-orchestrator/main/install.sh | bash
#
# With explicit command:
#   curl -fsSL https://raw.githubusercontent.com/lipefur/sprint-orchestrator/main/install.sh | bash -s -- install
#   curl -fsSL https://raw.githubusercontent.com/lipefur/sprint-orchestrator/main/install.sh | bash -s -- update
#   curl -fsSL https://raw.githubusercontent.com/lipefur/sprint-orchestrator/main/install.sh | bash -s -- uninstall
#
# Override install location:
#   SPRINT_ORCHESTRATOR_DIR=/custom/path bash install.sh

set -euo pipefail

REPO_URL="https://github.com/lipefur/sprint-orchestrator.git"
SKILL_DIR="${SPRINT_ORCHESTRATOR_DIR:-$HOME/.claude/skills/sprint-orchestrator}"
COMMAND="${1:-install}"

# -----------------------------------------------------------------------------
# Pretty printing
# -----------------------------------------------------------------------------

if [ -t 1 ] && [ "${NO_COLOR:-}" = "" ]; then
  GREEN='\033[0;32m'
  YELLOW='\033[0;33m'
  RED='\033[0;31m'
  BLUE='\033[0;34m'
  BOLD='\033[1m'
  NC='\033[0m'
else
  GREEN='' YELLOW='' RED='' BLUE='' BOLD='' NC=''
fi

header() { printf "\n${BLUE}${BOLD}==> %s${NC}\n" "$1"; }
ok()     { printf "  ${GREEN}✓${NC} %s\n" "$1"; }
warn()   { printf "  ${YELLOW}!${NC} %s\n" "$1"; }
err()    { printf "  ${RED}✗${NC} %s\n" "$1" >&2; }

# -----------------------------------------------------------------------------
# Dependency check
# -----------------------------------------------------------------------------

check_deps() {
  header "Checking dependencies"

  local missing=()
  for cmd in git bash; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      missing+=("$cmd")
    fi
  done

  if [ ${#missing[@]} -gt 0 ]; then
    err "Missing required dependencies: ${missing[*]}"
    err "Install them first, then re-run."
    exit 1
  fi
  ok "git, bash present"

  if command -v gh >/dev/null 2>&1; then
    ok "gh CLI present (needed for PR workflows)"
  else
    warn "gh CLI not found — install for PR workflows: https://cli.github.com/"
  fi

  if command -v yq >/dev/null 2>&1; then
    ok "yq present (cleaner YAML parsing)"
  else
    warn "yq not found — scripts will fall back to grep/sed (works but less robust)"
  fi

  if command -v python3 >/dev/null 2>&1; then
    ok "python3 present (used for URL encoding in dispatch)"
  else
    warn "python3 not found — URL scheme dispatch will fall back to clipboard"
  fi
}

# -----------------------------------------------------------------------------
# Install
# -----------------------------------------------------------------------------

do_install() {
  check_deps

  if [ -d "$SKILL_DIR" ]; then
    warn "Already installed at $SKILL_DIR"
    if [ -t 0 ]; then
      read -r -p "  Reinstall (deletes existing, keeps git history)? [y/N]: " confirm
      if [ "${confirm:-N}" != "y" ] && [ "${confirm:-N}" != "Y" ]; then
        printf "\nAborted. Use 'update' command to pull latest changes:\n"
        printf "  ${BLUE}curl -fsSL https://raw.githubusercontent.com/lipefur/sprint-orchestrator/main/install.sh | bash -s -- update${NC}\n\n"
        exit 0
      fi
      rm -rf "$SKILL_DIR"
    else
      err "Cannot prompt for confirmation (non-interactive stdin)."
      err "Use 'update' command instead, or remove $SKILL_DIR manually first."
      exit 1
    fi
  fi

  header "Installing sprint-orchestrator"
  mkdir -p "$(dirname "$SKILL_DIR")"

  if git clone --depth 1 --quiet "$REPO_URL" "$SKILL_DIR"; then
    local commit
    commit=$(cd "$SKILL_DIR" && git rev-parse --short HEAD)
    ok "Cloned to $SKILL_DIR (at commit $commit)"
  else
    err "Failed to clone $REPO_URL"
    err "Check network and try again."
    exit 1
  fi

  print_next_steps
}

# -----------------------------------------------------------------------------
# Update
# -----------------------------------------------------------------------------

do_update() {
  if [ ! -d "$SKILL_DIR" ]; then
    err "Not installed at $SKILL_DIR"
    err "Run install first:"
    err "  curl -fsSL https://raw.githubusercontent.com/lipefur/sprint-orchestrator/main/install.sh | bash"
    exit 1
  fi

  header "Updating sprint-orchestrator"
  cd "$SKILL_DIR"

  local before
  before=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")

  if ! git pull --ff-only --quiet origin main; then
    err "Update failed (possibly local changes conflict with upstream)."
    err "If you customized the skill locally, your changes are blocking the update."
    err "Options:"
    err "  1. Stash changes: cd $SKILL_DIR && git stash && bash $SKILL_DIR/install.sh update"
    err "  2. Reset to upstream (loses local changes): cd $SKILL_DIR && git reset --hard origin/main"
    exit 1
  fi

  local after
  after=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")

  if [ "$before" = "$after" ]; then
    ok "Already up to date ($after)"
  else
    ok "Updated $before → $after"

    if git log --pretty=format:"  • %s" "$before..$after" 2>/dev/null | head -10 | grep -q .; then
      printf "\n  Recent changes:\n"
      git log --pretty=format:"  • %s" "$before..$after" 2>/dev/null | head -10
      printf "\n"
    fi
  fi
}

# -----------------------------------------------------------------------------
# Uninstall
# -----------------------------------------------------------------------------

do_uninstall() {
  if [ ! -d "$SKILL_DIR" ]; then
    warn "Not installed at $SKILL_DIR — nothing to uninstall."
    exit 0
  fi

  header "Uninstall sprint-orchestrator"
  warn "About to delete $SKILL_DIR"

  if [ -t 0 ]; then
    read -r -p "  Confirm? [y/N]: " confirm
    if [ "${confirm:-N}" != "y" ] && [ "${confirm:-N}" != "Y" ]; then
      printf "Aborted.\n"
      exit 0
    fi
  else
    err "Cannot prompt for confirmation (non-interactive stdin)."
    err "Remove $SKILL_DIR manually if you really want to uninstall."
    exit 1
  fi

  rm -rf "$SKILL_DIR"
  ok "Uninstalled."
  printf "\n  Your project-level configs (.sprint-orchestrator.yml in each repo) were NOT removed.\n"
  printf "  Delete them manually per project if needed.\n\n"
}

# -----------------------------------------------------------------------------
# Help / next steps
# -----------------------------------------------------------------------------

print_next_steps() {
  cat <<EOF

${BOLD}Next steps:${NC}

  ${BOLD}1.${NC} Go to one of your projects:
       ${BLUE}cd path/to/your/project${NC}

  ${BOLD}2.${NC} Initialize the skill for this project:
       ${BLUE}bash $SKILL_DIR/scripts/init.sh${NC}

  ${BOLD}3.${NC} Open Claude Code in that project, say:
       "Vamos planejar sprint 1 — <tema>"
       (or in English: "Plan sprint 1 — <theme>")

  ${BOLD}Documentation:${NC}
    • Tutorial:    $SKILL_DIR/docs/tutorial-getting-started.md
    • FAQ:         $SKILL_DIR/docs/faq.md
    • Discussions: https://github.com/lipefur/sprint-orchestrator/discussions
    • Issues:      https://github.com/lipefur/sprint-orchestrator/issues

  ${BOLD}Update later:${NC}
    ${BLUE}curl -fsSL https://raw.githubusercontent.com/lipefur/sprint-orchestrator/main/install.sh | bash -s -- update${NC}

EOF
}

print_help() {
  cat <<EOF
sprint-orchestrator installer

USAGE:
  install.sh [COMMAND]

COMMANDS:
  install      Clone the skill to \$HOME/.claude/skills/sprint-orchestrator (default)
  update       git pull latest changes
  uninstall    Delete the installation
  help         Show this message

ENVIRONMENT:
  SPRINT_ORCHESTRATOR_DIR    Override install location
                             (default: \$HOME/.claude/skills/sprint-orchestrator)
  NO_COLOR                   Disable colored output

ONE-LINER INSTALL:
  curl -fsSL https://raw.githubusercontent.com/lipefur/sprint-orchestrator/main/install.sh | bash

EOF
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------

case "$COMMAND" in
  install)   do_install ;;
  update)    do_update ;;
  uninstall) do_uninstall ;;
  help|--help|-h) print_help ;;
  *)
    err "Unknown command: $COMMAND"
    print_help
    exit 1
    ;;
esac
