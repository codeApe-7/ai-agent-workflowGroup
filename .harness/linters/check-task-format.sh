#!/bin/bash
# ================================================================
# Harness Linter: 任务文档格式验证
#
# 检查 .dev-agents/shared/tasks/ 中的任务文件是否符合规范：
# - 文件名符合 T-NNN-<slug>.md 格式
# - 包含必要的元信息字段（TASK_ID, OWNER, STATUS）
# ================================================================

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PROJECT_ROOT"

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

TASKS_DIR=".dev-agents/shared/tasks"
ERRORS=0
WARNINGS=0
CHECKED=0

if [ ! -d "$TASKS_DIR" ]; then
    echo -e "${GREEN}No tasks directory — nothing to check${NC}"
    exit 0
fi

TASK_FILES=$(find "$TASKS_DIR" -name "*.md" -not -name "README.md" 2>/dev/null || echo "")

if [ -z "$TASK_FILES" ]; then
    echo -e "${GREEN}No task files — nothing to check${NC}"
    exit 0
fi

while IFS= read -r file; do
    [ -f "$file" ] || continue
    CHECKED=$((CHECKED + 1))
    filename=$(basename "$file")

    if ! echo "$filename" | grep -qE "^T-[0-9]{3}-.*\.md$"; then
        echo -e "${RED}BAD FILENAME:${NC} $filename"
        echo "  Expected: T-NNN-<slug>.md (e.g., T-001-login-page.md)"
        ERRORS=$((ERRORS + 1))
    fi

    REQUIRED_FIELDS=("TASK_ID" "OWNER" "STATUS")
    for field in "${REQUIRED_FIELDS[@]}"; do
        if ! grep -q "$field" "$file" 2>/dev/null; then
            echo -e "${YELLOW}MISSING FIELD:${NC} $file — lacks '$field'"
            WARNINGS=$((WARNINGS + 1))
        fi
    done

    if grep -q "STATUS" "$file" 2>/dev/null; then
        STATUS=$(grep "STATUS" "$file" | head -1 | sed 's/.*STATUS[: ]*//;s/[[:space:]]*//')
        VALID_STATUSES="todo|in_progress|blocked|review|done"
        if [ -n "$STATUS" ] && ! echo "$STATUS" | grep -qE "^($VALID_STATUSES)" 2>/dev/null; then
            echo -e "${RED}INVALID STATUS:${NC} $file — '$STATUS'"
            echo "  Allowed: $VALID_STATUSES"
            ERRORS=$((ERRORS + 1))
        fi
    fi
done <<< "$TASK_FILES"

echo "Checked $CHECKED task file(s)"

if [ $ERRORS -gt 0 ]; then
    echo -e "${RED}Task format check FAILED: $ERRORS error(s), $WARNINGS warning(s)${NC}"
    exit 1
elif [ $WARNINGS -gt 0 ]; then
    echo -e "${YELLOW}Task format check passed with $WARNINGS warning(s)${NC}"
    exit 2
else
    echo -e "${GREEN}Task format check passed${NC}"
    exit 0
fi
