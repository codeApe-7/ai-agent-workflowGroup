#!/bin/bash
# ================================================================
# Harness Linter: 文档交叉引用与新鲜度检查
#
# 验证：
# - AGENTS.md 中引用的文件实际存在
# - 技能文件中引用的路径有效
# - PERSONA 文件中的技能引用可达
# ================================================================

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PROJECT_ROOT"

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

ERRORS=0
WARNINGS=0
CHECKED=0

check_ref() {
    local source_file="$1"
    local ref_path="$2"

    clean_path=$(echo "$ref_path" | sed 's/`//g;s/^[[:space:]]*//;s/[[:space:]]*$//')

    if [ -z "$clean_path" ] || [ "$clean_path" = "none" ] || [ "$clean_path" = "N/A" ]; then
        return
    fi

    if echo "$clean_path" | grep -qE "^\{|NNN|\*"; then
        return
    fi

    CHECKED=$((CHECKED + 1))

    if [ ! -e "$clean_path" ]; then
        echo -e "${RED}BROKEN REF:${NC} $source_file -> $clean_path"
        ERRORS=$((ERRORS + 1))
    fi
}

echo "Checking AGENTS.md references..."
if [ -f "AGENTS.md" ]; then
    while IFS= read -r line; do
        refs=$(echo "$line" | grep -oE '`\.[^`]+`' | sed 's/`//g' || true)
        for ref in $refs; do
            if echo "$ref" | grep -qE "^\.(dev-agents|harness|codex|cursor|worktrees)/"; then
                check_ref "AGENTS.md" "$ref"
            fi
        done
    done < "AGENTS.md"
fi

echo "Checking PERSONA references..."
for persona in .dev-agents/*/PERSONA.md; do
    [ -f "$persona" ] || continue
    while IFS= read -r line; do
        refs=$(echo "$line" | grep -oE '`[^`]*\.md`' | sed 's/`//g' || true)
        for ref in $refs; do
            if echo "$ref" | grep -qE "^(skills/|\.dev-agents/)"; then
                check_ref "$persona" "$ref"
            fi
        done
    done < "$persona"
done

echo "Checking skill file existence..."
EXPECTED_SKILLS=(
    ".dev-agents/shared/skills/workflow-lifecycle.md"
    ".dev-agents/shared/skills/brainstorming.md"
    ".dev-agents/shared/skills/writing-plans.md"
    ".dev-agents/shared/skills/tdd.md"
    ".dev-agents/shared/skills/systematic-debugging.md"
    ".dev-agents/shared/skills/verification.md"
    ".dev-agents/shared/skills/code-review-dispatch.md"
    ".dev-agents/shared/skills/finishing-branch.md"
)

for skill in "${EXPECTED_SKILLS[@]}"; do
    CHECKED=$((CHECKED + 1))
    if [ ! -f "$skill" ]; then
        echo -e "${RED}MISSING SKILL:${NC} $skill"
        ERRORS=$((ERRORS + 1))
    fi
done

echo ""
echo "Checked $CHECKED reference(s)"

if [ $ERRORS -gt 0 ]; then
    echo -e "${RED}Doc freshness check FAILED: $ERRORS broken reference(s)${NC}"
    echo "FIX: Update or remove broken references. Keep docs in sync with actual files."
    exit 1
elif [ $WARNINGS -gt 0 ]; then
    echo -e "${YELLOW}Doc freshness passed with $WARNINGS warning(s)${NC}"
    exit 2
else
    echo -e "${GREEN}Doc freshness check passed — all references valid${NC}"
    exit 0
fi
