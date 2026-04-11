#!/bin/bash
# ================================================================
# Harness Structural Test: 模板格式规范
#
# 验证 .dev-agents/shared/templates/ 中的核心模板包含必要的结构化字段：
# - implementer-prompt: TASK_ID, WRITE_SCOPE, TEST_COMMAND
# - codex-subtask: TASK_ID, OWNER, STATUS, WRITE_SCOPE
# - reviewer prompts: 验收标准
# ================================================================

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PROJECT_ROOT"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

ERRORS=0
CHECKED=0

check_fields() {
    local file="$1"
    shift
    local fields=("$@")

    if [ ! -f "$file" ]; then
        echo -e "${RED}MISSING:${NC} $file"
        ERRORS=$((ERRORS + 1))
        return
    fi

    CHECKED=$((CHECKED + 1))

    for field in "${fields[@]}"; do
        if ! grep -q "$field" "$file" 2>/dev/null; then
            echo -e "${RED}MISSING FIELD:${NC} $file — lacks '$field'"
            ERRORS=$((ERRORS + 1))
        fi
    done
}

echo "Testing implementer-prompt.md..."
check_fields ".dev-agents/shared/templates/implementer-prompt.md" \
    "TASK_ID" "WRITE_SCOPE" "TEST_COMMAND" "PERSONA" "tdd.md" "verification.md"

echo "Testing codex-subtask.md..."
check_fields ".dev-agents/shared/templates/codex-subtask.md" \
    "TASK_ID" "OWNER" "STATUS" "WRITE_SCOPE"

echo "Testing spec-reviewer-prompt.md..."
check_fields ".dev-agents/shared/templates/spec-reviewer-prompt.md" \
    "PERSONA" "kyle"

echo "Testing code-quality-reviewer-prompt.md..."
check_fields ".dev-agents/shared/templates/code-quality-reviewer-prompt.md" \
    "PERSONA" "kyle"

echo ""
echo "Checked $CHECKED template(s)"

if [ $ERRORS -gt 0 ]; then
    echo -e "${RED}Template schema FAILED: $ERRORS error(s)${NC}"
    exit 1
else
    echo -e "${GREEN}Template schema passed — all templates valid${NC}"
    exit 0
fi
