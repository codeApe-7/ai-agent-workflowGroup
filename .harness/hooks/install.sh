#!/bin/bash
# ================================================================
# 安装 Harness Git Hooks
# ================================================================

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
HOOKS_DIR="$PROJECT_ROOT/.git/hooks"
HARNESS_HOOKS="$PROJECT_ROOT/.harness/hooks"

echo "Installing harness git hooks..."

if [ -f "$HOOKS_DIR/pre-commit" ]; then
    echo "Backing up existing pre-commit hook..."
    cp "$HOOKS_DIR/pre-commit" "$HOOKS_DIR/pre-commit.backup"
fi

cat > "$HOOKS_DIR/pre-commit" << 'HOOK'
#!/bin/bash
# Harness pre-commit hook (auto-installed)
REPO_ROOT="$(git rev-parse --show-toplevel)"
if [ -f "$REPO_ROOT/.harness/hooks/pre-commit.sh" ]; then
    bash "$REPO_ROOT/.harness/hooks/pre-commit.sh"
fi
HOOK

chmod +x "$HOOKS_DIR/pre-commit"

echo "Harness pre-commit hook installed."
echo "To uninstall: rm $HOOKS_DIR/pre-commit"
