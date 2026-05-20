#!/usr/bin/env bash
# create-worktree.sh — create sprint worktree + dispatch via URL scheme
#
# Reads `.sprint-orchestrator.yml` from the current repo's root.
#
# Usage:
#   bash <skill-path>/scripts/create-worktree.sh <sprint-number> <theme-slug>
#   bash <skill-path>/scripts/create-worktree.sh 14 oauth-providers

set -euo pipefail

if [ "$#" -lt 2 ]; then
  echo "Usage: $0 <sprint-number> <theme-slug>"
  echo "Example: $0 14 oauth-providers"
  exit 1
fi

N="$1"
THEME_SLUG="$2"
DATE="$(date +%Y-%m-%d)"

if ! git rev-parse --show-toplevel >/dev/null 2>&1; then
  echo "❌ Not inside a git repo"
  exit 1
fi

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

PROFILE_FILE=".sprint-orchestrator.yml"
if [ ! -f "$PROFILE_FILE" ]; then
  echo "❌ Profile not found: $PROFILE_FILE"
  echo "   Run: bash <skill-path>/scripts/init.sh"
  exit 1
fi

read_profile_key() {
  local key="$1"
  if command -v yq >/dev/null 2>&1; then
    yq eval ".$key // \"\"" "$PROFILE_FILE" 2>/dev/null
  else
    # Fallback: simple grep/sed. Only works for top-level keys or single-level nested.
    local short_key="${key##*.}"
    grep -E "^[[:space:]]*${short_key}:" "$PROFILE_FILE" | head -1 | sed -E "s/^[[:space:]]*${short_key}:[[:space:]]*//; s/[[:space:]]*$//; s/^\"//; s/\"$//"
  fi
}

PROJECT_NAME="$(read_profile_key project_name)"
PLANS_PATH="$(read_profile_key plans)"
PLANS_PATH="${PLANS_PATH:-docs/superpowers/plans}"
WORKTREES_PATH="$(read_profile_key worktrees)"
WORKTREES_PATH="${WORKTREES_PATH:-.claude/worktrees}"
DISPATCH_METHOD="$(read_profile_key method)"
DISPATCH_METHOD="${DISPATCH_METHOD:-claude-cli}"

if [ -z "$PROJECT_NAME" ]; then
  echo "❌ Could not read project_name from profile"
  exit 1
fi

PLAN_FILENAME="${DATE}-${PROJECT_NAME}-sprint-${N}-${THEME_SLUG}.md"
PLAN_PATH="${PLANS_PATH}/${PLAN_FILENAME}"

if [ ! -f "$PLAN_PATH" ]; then
  CANDIDATE="$(find "$PLANS_PATH" -maxdepth 1 -name "*-${PROJECT_NAME}-sprint-${N}-${THEME_SLUG}.md" 2>/dev/null | head -1)"
  if [ -n "$CANDIDATE" ]; then
    PLAN_PATH="$CANDIDATE"
    PLAN_FILENAME="$(basename "$CANDIDATE")"
  else
    echo "❌ Plan not found: $PLAN_PATH"
    echo "   Create the plan first using templates/plan/<type>.md as base"
    exit 1
  fi
fi

if ! git log --oneline main -- "$PLAN_PATH" 2>/dev/null | grep -q .; then
  echo "❌ Plan $PLAN_PATH is not committed to main"
  echo "   Commit and push first:"
  echo "     git add $PLAN_PATH"
  echo "     git commit -m \"docs: plan Sprint ${N} — ${THEME_SLUG}\""
  echo "     git push origin main"
  exit 1
fi

LINE_COUNT="$(wc -l < "$PLAN_PATH" | tr -d ' ')"

BRANCH_NAME="sprint-${N}-${THEME_SLUG}"
WORKTREE_RELATIVE="${WORKTREES_PATH}/sprint-${N}-${THEME_SLUG}"
WORKTREE_ABSOLUTE="${REPO_ROOT}/${WORKTREE_RELATIVE}"

if git worktree list | grep -q "$WORKTREE_RELATIVE"; then
  echo "⚠️  Worktree already exists at $WORKTREE_RELATIVE"
  echo "    Remove first: git worktree remove $WORKTREE_RELATIVE --force"
  exit 1
fi

echo "🔨 Creating worktree at $WORKTREE_RELATIVE..."
git worktree add "$WORKTREE_RELATIVE" -b "$BRANCH_NAME"

cd "$WORKTREE_RELATIVE"
git pull --ff-only origin main >/dev/null 2>&1 || true
WORKTREE_COMMIT="$(git rev-parse --short HEAD)"
cd "$REPO_ROOT"

mkdir -p .sprint-orchestrator
STATE_FILE=".sprint-orchestrator/state.md"
TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

if [ ! -f "$STATE_FILE" ]; then
  cat > "$STATE_FILE" <<EOF
# Sprint state — $PROJECT_NAME

EOF
fi

cat >> "$STATE_FILE" <<EOF

## Sprint $N — $THEME_SLUG
- **Fase**: DISPATCH (criando worktree)
- **Worktree**: $WORKTREE_RELATIVE
- **Branch**: $BRANCH_NAME
- **Plano**: $PLAN_PATH ($LINE_COUNT linhas)
- **Despachado em**: $TIMESTAMP
- **Commit base**: $WORKTREE_COMMIT
- **PR**: aguardando
- **Próximo passo**: sprint chat lê plano e implementa
EOF

echo "✅ Updated $STATE_FILE"

# Build the PROMPT using printf to avoid backtick/heredoc escaping issues.
BT='`'
BBT='```'

PROMPT="$(printf '%s\n' \
  "# Sprint ${N} — ${PROJECT_NAME}: ${THEME_SLUG}" \
  "" \
  "Você é o desenvolvedor executando Sprint ${N}. Worktree em: ${WORKTREE_ABSOLUTE}" \
  "" \
  "## VERIFICAÇÃO INICIAL OBRIGATÓRIA" \
  "" \
  "${BBT}bash" \
  "cd ${WORKTREE_ABSOLUTE}" \
  "git status   # deve estar em ${BRANCH_NAME}, limpo, em ${WORKTREE_COMMIT}" \
  "wc -l ${PLAN_PATH}   # deve ser ${LINE_COUNT} linhas" \
  "${BBT}" \
  "" \
  "**Se o plano NÃO existir ou tiver linhas erradas, PARE e reporte ao orquestrador. NÃO crie plano novo.**" \
  "" \
  "## Leia o plano PRIMEIRO" \
  "" \
  "${BT}${PLAN_PATH}${BT} (${LINE_COUNT} linhas)" \
  "" \
  "Tem TUDO detalhado: objetivos, fases, multi-agent strategy, DoD, anti-padrões." \
  "" \
  "## Padrão estabelecido" \
  "" \
  "- 1 PR único via ${BT}gh pr create${BT}" \
  "- Commits incrementais, conventional commits, mensagens PT-BR" \
  "- NÃO mergeia em main — orquestrador faz" \
  "- Roda smoke local antes do PR (se configurado em ${BT}.sprint-orchestrator.yml${BT})" \
  "- Quando addon ${BT}e2e-validation${BT} ativo: roda Playwright nos \"Fluxos E2E a validar\" do plano ANTES de abrir PR" \
  "- Atualiza ${BT}.sprint-orchestrator/state.md${BT} ao terminar com PR # e fase=REVIEW" \
  "" \
  "## Anti-padrões críticos" \
  "" \
  "Ver ${BT}<skill>/core/anti-patterns.md${BT} (5 minutos de leitura, vai economizar horas)." \
  "" \
  "## Entregar ao fim" \
  "" \
  "- N commits, +X/-Y, M arquivos" \
  "- Resultado dos fluxos E2E (PASS/FAIL com screenshots)" \
  "- PR #N criado" \
  "- Pendências orquestrador (env vars novas, migrations prod, contas externas)" \
  "- state.md atualizado" \
  "" \
  "Bora. Lê o plano primeiro (${LINE_COUNT} linhas)." \
)"

# -----------------------------------------------------------------------------
# Environment detection
# -----------------------------------------------------------------------------
# Detects the IDE/terminal the user is currently in, so dispatch can adapt.
# Returns one of: claude-code-cli | cursor | vscode | antigravity | windsurf | terminal | unknown

detect_environment() {
  # Cursor sets CURSOR_TRACE_ID and reports TERM_PROGRAM=vscode (it's a VS Code fork)
  if [ -n "${CURSOR_TRACE_ID:-}" ]; then
    echo "cursor"; return
  fi

  # Antigravity (Google) sets specific env vars
  if [ -n "${ANTIGRAVITY:-}" ] || [ -n "${ANTIGRAVITY_HOME:-}" ] || [[ "${TERM_PROGRAM_VERSION:-}" =~ [Aa]ntigravity ]]; then
    echo "antigravity"; return
  fi

  # Windsurf (Codeium) sets specific env vars
  if [ -n "${WINDSURF_PID:-}" ] || [[ "${TERM_PROGRAM_VERSION:-}" =~ [Ww]indsurf ]]; then
    echo "windsurf"; return
  fi

  # Plain VS Code
  if [ "${TERM_PROGRAM:-}" = "vscode" ] || [ -n "${VSCODE_PID:-}" ] || [ -n "${VSCODE_INJECTION:-}" ]; then
    # Inspect parent process for VS Code forks not caught above
    local parent_app="$(ps -o comm= -p "${PPID:-0}" 2>/dev/null || true)"
    case "$parent_app" in
      *Cursor*) echo "cursor"; return ;;
      *Antigravity*|*antigravity*) echo "antigravity"; return ;;
      *Windsurf*) echo "windsurf"; return ;;
      *) echo "vscode"; return ;;
    esac
  fi

  # Claude Code standalone CLI (has its own URL handler app on Mac)
  if [ -n "${CLAUDE_CODE:-}" ] || [ -n "${CLAUDECODE:-}" ]; then
    echo "claude-code-cli"; return
  fi

  # Native macOS Terminal/iTerm or generic terminal — Mac standalone
  if [ "${TERM_PROGRAM:-}" = "Apple_Terminal" ] || [ "${TERM_PROGRAM:-}" = "iTerm.app" ] || [ "${TERM_PROGRAM:-}" = "WezTerm" ] || [ "${TERM_PROGRAM:-}" = "ghostty" ] || [ "${TERM_PROGRAM:-}" = "alacritty" ]; then
    echo "claude-code-cli"; return
  fi

  echo "unknown"
}

copy_to_clipboard() {
  local text="$1"
  if command -v pbcopy >/dev/null 2>&1; then
    printf '%s' "$text" | pbcopy
    return 0
  elif command -v xclip >/dev/null 2>&1; then
    printf '%s' "$text" | xclip -selection clipboard
    return 0
  elif command -v wl-copy >/dev/null 2>&1; then
    printf '%s' "$text" | wl-copy
    return 0
  elif command -v clip.exe >/dev/null 2>&1; then
    # WSL / Windows
    printf '%s' "$text" | clip.exe
    return 0
  fi
  return 1
}

dispatch_via_claude_cli() {
  if command -v python3 >/dev/null 2>&1; then
    PROMPT_ENC=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.stdin.read()))" <<< "$PROMPT")
    FOLDER_ENC=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$WORKTREE_ABSOLUTE")
    DISPATCH_URL="claude-cli://?q=${PROMPT_ENC}&folder=${FOLDER_ENC}"

    if [ "${#DISPATCH_URL}" -gt 1800 ]; then
      TMP_PROMPT="/tmp/sprint-${N}-${THEME_SLUG}-prompt.md"
      echo "$PROMPT" > "$TMP_PROMPT"
      DISPATCH_URL="claude-cli://?folder=${FOLDER_ENC}&prompt-file=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$TMP_PROMPT")"
      echo "ℹ️  Prompt > 1800 chars; saved to $TMP_PROMPT and referenced via URL"
    fi

    if open "$DISPATCH_URL" 2>/dev/null; then
      echo "🚀 Opened Claude Code via claude-cli:// URL scheme"
      return 0
    fi
  fi
  return 1
}

dispatch_via_claude_desktop() {
  if command -v python3 >/dev/null 2>&1; then
    PROMPT_ENC=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.stdin.read()))" <<< "$PROMPT")
    FOLDER_ENC=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$WORKTREE_ABSOLUTE")
    DISPATCH_URL="claude://code/new?q=${PROMPT_ENC}&folder=${FOLDER_ENC}"
    if open "$DISPATCH_URL" 2>/dev/null; then
      echo "🚀 Opened Claude Desktop via claude:// URL scheme"
      return 0
    fi
  fi
  return 1
}

dispatch_via_cursor() {
  # Cursor doesn't have a documented URL scheme to start a new Claude chat with prompt.
  # Best effort: open the worktree in Cursor (so user is in the right folder),
  # save prompt to file + clipboard, instruct user.
  if command -v cursor >/dev/null 2>&1; then
    cursor "$WORKTREE_ABSOLUTE" 2>/dev/null || true
  fi
  TMP_PROMPT="/tmp/sprint-${N}-${THEME_SLUG}-prompt.md"
  echo "$PROMPT" > "$TMP_PROMPT"
  copy_to_clipboard "$PROMPT" && CLIP_OK=1 || CLIP_OK=0
  cat <<EOM

🪟 Cursor environment detected.
   Worktree opened in Cursor: $WORKTREE_ABSOLUTE
   Prompt saved to: $TMP_PROMPT
$( [ "$CLIP_OK" = "1" ] && echo "   ✓ Prompt copied to clipboard" )

Next: in Cursor, open a NEW Claude chat (default ⌘L / Ctrl+L) and paste.
EOM
  return 0
}

dispatch_via_vscode() {
  if command -v code >/dev/null 2>&1; then
    code "$WORKTREE_ABSOLUTE" 2>/dev/null || true
  fi
  TMP_PROMPT="/tmp/sprint-${N}-${THEME_SLUG}-prompt.md"
  echo "$PROMPT" > "$TMP_PROMPT"
  copy_to_clipboard "$PROMPT" && CLIP_OK=1 || CLIP_OK=0
  cat <<EOM

🪟 VS Code environment detected.
   Worktree opened in VS Code: $WORKTREE_ABSOLUTE
   Prompt saved to: $TMP_PROMPT
$( [ "$CLIP_OK" = "1" ] && echo "   ✓ Prompt copied to clipboard" )

Next: in VS Code, open a NEW Claude chat (extension command palette: "Claude: New Chat") and paste.
EOM
  return 0
}

dispatch_via_antigravity() {
  TMP_PROMPT="/tmp/sprint-${N}-${THEME_SLUG}-prompt.md"
  echo "$PROMPT" > "$TMP_PROMPT"
  copy_to_clipboard "$PROMPT" && CLIP_OK=1 || CLIP_OK=0
  cat <<EOM

🪟 Antigravity environment detected.
   Worktree: $WORKTREE_ABSOLUTE
   Prompt saved to: $TMP_PROMPT
$( [ "$CLIP_OK" = "1" ] && echo "   ✓ Prompt copied to clipboard" )

Next: in Antigravity, open a NEW chat (⌘L / Ctrl+L or the "+" tab button) and paste.
Make sure the agent's working directory is set to: $WORKTREE_ABSOLUTE
EOM
  return 0
}

dispatch_via_windsurf() {
  if command -v windsurf >/dev/null 2>&1; then
    windsurf "$WORKTREE_ABSOLUTE" 2>/dev/null || true
  fi
  TMP_PROMPT="/tmp/sprint-${N}-${THEME_SLUG}-prompt.md"
  echo "$PROMPT" > "$TMP_PROMPT"
  copy_to_clipboard "$PROMPT" && CLIP_OK=1 || CLIP_OK=0
  cat <<EOM

🪟 Windsurf environment detected.
   Worktree opened in Windsurf: $WORKTREE_ABSOLUTE
   Prompt saved to: $TMP_PROMPT
$( [ "$CLIP_OK" = "1" ] && echo "   ✓ Prompt copied to clipboard" )

Next: in Windsurf, open a NEW Cascade chat and paste.
EOM
  return 0
}

dispatch_via_clipboard() {
  TMP_PROMPT="/tmp/sprint-${N}-${THEME_SLUG}-prompt.md"
  echo "$PROMPT" > "$TMP_PROMPT"
  copy_to_clipboard "$PROMPT" && CLIP_OK=1 || CLIP_OK=0
  cat <<EOM

📋 Generic dispatch (env not auto-detected).
   Worktree: $WORKTREE_ABSOLUTE
   Prompt saved to: $TMP_PROMPT
$( [ "$CLIP_OK" = "1" ] && echo "   ✓ Prompt copied to clipboard" )

Next: open a new Claude session in $WORKTREE_ABSOLUTE and paste the prompt.
EOM
  return 0
}

# -----------------------------------------------------------------------------
# Resolve effective dispatch method
# -----------------------------------------------------------------------------
# Profile may set `dispatch.method` to: auto | claude-cli | claude-desktop |
# cursor | vscode | antigravity | windsurf | clipboard-only
#
# When "auto" (or unset), detect the environment and choose accordingly.

EFFECTIVE_METHOD="$DISPATCH_METHOD"
if [ -z "$EFFECTIVE_METHOD" ] || [ "$EFFECTIVE_METHOD" = "auto" ]; then
  DETECTED_ENV="$(detect_environment)"
  echo "🔍 Detected environment: $DETECTED_ENV"
  case "$DETECTED_ENV" in
    claude-code-cli) EFFECTIVE_METHOD="claude-cli" ;;
    cursor)          EFFECTIVE_METHOD="cursor" ;;
    vscode)          EFFECTIVE_METHOD="vscode" ;;
    antigravity)     EFFECTIVE_METHOD="antigravity" ;;
    windsurf)        EFFECTIVE_METHOD="windsurf" ;;
    *)               EFFECTIVE_METHOD="clipboard-only" ;;
  esac
fi

case "$EFFECTIVE_METHOD" in
  claude-cli)      dispatch_via_claude_cli      || dispatch_via_clipboard ;;
  claude-desktop)  dispatch_via_claude_desktop  || dispatch_via_clipboard ;;
  cursor)          dispatch_via_cursor ;;
  vscode)          dispatch_via_vscode ;;
  antigravity)     dispatch_via_antigravity ;;
  windsurf)        dispatch_via_windsurf ;;
  clipboard-only)  dispatch_via_clipboard ;;
  *)
    echo "Unknown dispatch.method: $EFFECTIVE_METHOD — falling back to clipboard"
    dispatch_via_clipboard
    ;;
esac

DISPATCH_METHOD="$EFFECTIVE_METHOD"

cat <<EOF

✅ Sprint $N dispatched

Variables for reference:
  PROJECT_NAME       = $PROJECT_NAME
  N                  = $N
  THEME_SLUG         = $THEME_SLUG
  WORKTREE_ABSOLUTE  = $WORKTREE_ABSOLUTE
  WORKTREE_COMMIT    = $WORKTREE_COMMIT
  PLAN_PATH          = $PLAN_PATH
  LINE_COUNT         = $LINE_COUNT
  DISPATCH_METHOD    = $DISPATCH_METHOD

Next steps:
  1. Sprint chat reads plan and executes.
  2. (Phase 2) Scheduled task watches PR every 30min.
  3. When PR opens: orchestrator wakes up automatically.

Cleanup post-merge (manual for now; cleanup-merged.sh comes in Phase 2):
  git worktree remove $WORKTREE_RELATIVE --force
  git branch -D $BRANCH_NAME
EOF
