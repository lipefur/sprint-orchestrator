#!/usr/bin/env bash
# Illustrative reproduction of `scripts/create-worktree.sh` output, used only to
# render the demo GIF (assets/demo.tape -> assets/demo.gif). Runs against a fake
# project path so nothing identifying is captured. The real command to dispatch a
# sprint lives in the README Quickstart.
set -e

say() { printf '%s\n' "$1"; sleep "${2:-0.5}"; }

say "🔨 Creating worktree at .claude/worktrees/sprint-1-oauth-login..." 0.7
say "✅ Updated .sprint-orchestrator/state.md" 0.5
say "🔍 Detected environment: claude-code-cli" 0.6
printf '\n'
say "🚀 Claude Code dispatch (split mode)" 0.2
say "   Worktree: ~/projects/my-app/.claude/worktrees/sprint-1-oauth-login" 0.2
say "   Prompt saved to /tmp/sprint-1-oauth-login-prompt.md" 0.2
say "   ✓ Prompt copied to clipboard" 0.6
say "   ↳ New Claude Code window opens with the plan already loaded ✨" 0.6
printf '\n'
say "✅ Sprint 1 dispatched — executing in parallel, opens a PR when done" 0.3
