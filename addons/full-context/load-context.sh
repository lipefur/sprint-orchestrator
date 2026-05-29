#!/usr/bin/env bash
# load-context.sh — dump filtered repo for full-context loading (1m context window)
#
# Usage:
#   bash load-context.sh > /tmp/repo-context.txt
#   FULL_CONTEXT_LIMIT_BYTES=3000000 bash load-context.sh   # override limit
#
# Exits 2 if the filtered repo exceeds the size limit (use incremental instead).

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT"

LIMIT_BYTES="${FULL_CONTEXT_LIMIT_BYTES:-2000000}"   # ~500k tokens ≈ 2MB text

# Collect files, excluding noise
FILES=$(find . -type f \
  -not -path "*/node_modules/*" \
  -not -path "*/.git/*" \
  -not -path "*/build/*" \
  -not -path "*/dist/*" \
  -not -path "*/.next/*" \
  -not -path "*/target/*" \
  -not -path "*/vendor/*" \
  -not -path "*/_legacy/*" \
  -not -name "*.lock" \
  -not -name "*.lockb" \
  -not -name "bun.lockb" \
  -not -name "package-lock.json" \
  -not -name "pnpm-lock.yaml" \
  -not -name "yarn.lock" \
  -not -name "*.png" -not -name "*.jpg" -not -name "*.jpeg" \
  -not -name "*.gif" -not -name "*.webp" -not -name "*.ico" \
  -not -name "*.svg" -not -name "*.pdf" -not -name "*.zip" \
  -not -name "*.tar" -not -name "*.gz" \
  -not -name "*.woff" -not -name "*.woff2" -not -name "*.ttf" -not -name "*.eot" \
  -not -name "*.mp4" -not -name "*.mov" -not -name "*.bin" \
  -not -name ".env" -not -name ".env.*" \
  -not -name "*.pem" -not -name "*.key" -not -name "*.p12" -not -name "*.pfx" -not -name "*.keystore" \
  -not -name "id_rsa*" -not -name "id_ed25519*" -not -name "id_dsa*" \
  -not -path "*/.ssh/*" -not -path "*/.aws/*" -not -path "*/.gnupg/*" \
  2>/dev/null | sort)

# Estimate total size
TOTAL=0
while IFS= read -r f; do
  [ -z "$f" ] && continue
  SIZE=$(wc -c < "$f" 2>/dev/null || echo 0)
  TOTAL=$((TOTAL + SIZE))
done <<< "$FILES"

if [ "$TOTAL" -gt "$LIMIT_BYTES" ]; then
  echo "❌ Repo too large for full-context: ~${TOTAL} bytes > ${LIMIT_BYTES} limit." >&2
  echo "   Use incremental exploration instead (don't load full context)." >&2
  echo "   Override with FULL_CONTEXT_LIMIT_BYTES if you really want to." >&2
  exit 2
fi

# Dump
echo "# Full repository context — $REPO_ROOT"
echo "# Generated $(date -u +%Y-%m-%dT%H:%M:%SZ) — ${TOTAL} bytes total"
echo ""
while IFS= read -r f; do
  [ -z "$f" ] && continue
  echo "=================================================================="
  echo "FILE: $f"
  echo "=================================================================="
  cat "$f"
  echo ""
done <<< "$FILES"
