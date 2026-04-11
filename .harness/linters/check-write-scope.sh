#!/bin/bash
# ================================================================
# Harness Linter: WRITE_SCOPE 越权检查
#
# 检查最近一次提交是否修改了 WRITE_SCOPE 之外的文件。
# 在子代理提交后运行，防止越权写入。
#
# 用法:
#   bash .harness/linters/check-write-scope.sh [WRITE_SCOPE_PATTERN]
#
# 如果未提供参数，检查是否有子代理越权修改了核心配置文件。
# ================================================================

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PROJECT_ROOT"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

ERRORS=0

PROTECTED_PATTERNS=(
    "^AGENTS\.md$"
    "^\.dev-agents/shared/skills/"
    "^\.dev-agents/.*/PERSONA\.md$"
    "^\.harness/"
    "^\.cursor/rules/"
    "^\.gitignore$"
)

if [ -n "${1:-}" ]; then
    SCOPE_PATTERN="$1"
    CHANGED_FILES=$(git diff --name-only HEAD~1 HEAD 2>/dev/null || echo "")

    if [ -z "$CHANGED_FILES" ]; then
        echo -e "${GREEN}No commits to check${NC}"
        exit 0
    fi

    while IFS= read -r file; do
        if ! echo "$file" | grep -qE "$SCOPE_PATTERN"; then
            echo -e "${RED}OUT OF SCOPE:${NC} $file (allowed: $SCOPE_PATTERN)"
            ERRORS=$((ERRORS + 1))
        fi
    done <<< "$CHANGED_FILES"
else
    STAGED_FILES=$(git diff --cached --name-only 2>/dev/null || echo "")

    if [ -z "$STAGED_FILES" ]; then
        echo -e "${GREEN}No staged files to check${NC}"
        exit 0
    fi

    while IFS= read -r file; do
        for pattern in "${PROTECTED_PATTERNS[@]}"; do
            if echo "$file" | grep -qE "$pattern"; then
                echo -e "${RED}PROTECTED FILE MODIFIED:${NC} $file"
                echo "  This file requires Max-level approval to modify."
                ERRORS=$((ERRORS + 1))
            fi
        done
    done <<< "$STAGED_FILES"
fi

if [ $ERRORS -gt 0 ]; then
    echo ""
    echo -e "${RED}WRITE_SCOPE violation: $ERRORS file(s) outside allowed scope${NC}"
    echo "FIX: Revert unauthorized changes or request scope expansion from Max."
    exit 1
else
    echo -e "${GREEN}WRITE_SCOPE check passed${NC}"
    exit 0
fi
