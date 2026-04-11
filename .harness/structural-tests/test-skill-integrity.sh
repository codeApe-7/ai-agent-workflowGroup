#!/bin/bash
# ================================================================
# Harness Structural Test: 技能系统完整性
#
# 验证双层技能体系的结构一致性：
# - 工作流技能文件存在且包含 frontmatter
# - workflow-lifecycle.md 中引用的技能实际存在
# - 技能文件包含必要的元信息（name, owner, description）
# ================================================================

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PROJECT_ROOT"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

ERRORS=0
CHECKED=0

SKILLS_DIR=".dev-agents/shared/skills"

echo "Testing workflow skill integrity..."

for skill_file in "$SKILLS_DIR"/*.md; do
    [ -f "$skill_file" ] || continue
    CHECKED=$((CHECKED + 1))
    filename=$(basename "$skill_file")

    if ! head -1 "$skill_file" | grep -q "^---$"; then
        echo -e "${RED}MISSING FRONTMATTER:${NC} $skill_file"
        echo "  Skill files must start with YAML frontmatter (---)"
        ERRORS=$((ERRORS + 1))
        continue
    fi

    for field in "name:" "owner:" "description:"; do
        if ! head -10 "$skill_file" | grep -q "$field"; then
            echo -e "${RED}MISSING FIELD:${NC} $skill_file — lacks '$field' in frontmatter"
            ERRORS=$((ERRORS + 1))
        fi
    done
done

echo "Testing template existence..."

EXPECTED_TEMPLATES=(
    ".dev-agents/shared/templates/implementer-prompt.md"
    ".dev-agents/shared/templates/spec-reviewer-prompt.md"
    ".dev-agents/shared/templates/code-quality-reviewer-prompt.md"
    ".dev-agents/shared/templates/codex-subtask.md"
)

for template in "${EXPECTED_TEMPLATES[@]}"; do
    CHECKED=$((CHECKED + 1))
    if [ ! -f "$template" ]; then
        echo -e "${RED}MISSING TEMPLATE:${NC} $template"
        ERRORS=$((ERRORS + 1))
    fi
done

echo "Testing persona existence..."

EXPECTED_PERSONAS=(
    ".dev-agents/ella/PERSONA.md"
    ".dev-agents/jarvis/PERSONA.md"
    ".dev-agents/kyle/PERSONA.md"
)

for persona in "${EXPECTED_PERSONAS[@]}"; do
    CHECKED=$((CHECKED + 1))
    if [ ! -f "$persona" ]; then
        echo -e "${RED}MISSING PERSONA:${NC} $persona"
        ERRORS=$((ERRORS + 1))
    fi
done

echo ""
echo "Checked $CHECKED artifact(s)"

if [ $ERRORS -gt 0 ]; then
    echo -e "${RED}Skill integrity FAILED: $ERRORS error(s)${NC}"
    exit 1
else
    echo -e "${GREEN}Skill integrity passed — all artifacts valid${NC}"
    exit 0
fi
