#!/bin/bash
# ================================================================
# Harness Structural Test: 角色引用一致性
#
# 验证 AGENTS.md 中定义的角色与 PERSONA 文件的一致性：
# - AGENTS.md 中提到的角色都有对应的 PERSONA.md
# - PERSONA 路径正确
# - 角色名称在文档间一致
# ================================================================

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PROJECT_ROOT"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

ERRORS=0
CHECKED=0

EXPECTED_ROLES=("ella" "jarvis" "kyle")
EXPECTED_ROLE_NAMES=("Ella:ella" "Jarvis:jarvis" "Kyle:kyle")

echo "Testing role-persona mapping..."

for role in "${EXPECTED_ROLES[@]}"; do
    CHECKED=$((CHECKED + 1))
    persona_file=".dev-agents/$role/PERSONA.md"

    if [ ! -f "$persona_file" ]; then
        echo -e "${RED}MISSING PERSONA:${NC} $persona_file"
        ERRORS=$((ERRORS + 1))
        continue
    fi

    if ! grep -qi "role\|角色\|职责" "$persona_file" 2>/dev/null; then
        echo -e "${RED}INCOMPLETE PERSONA:${NC} $persona_file — missing role definition"
        ERRORS=$((ERRORS + 1))
    fi
done

echo "Testing AGENTS.md role references..."

if [ -f "AGENTS.md" ]; then
    CHECKED=$((CHECKED + 1))
    for pair in "${EXPECTED_ROLE_NAMES[@]}"; do
        display_name="${pair%%:*}"
        dir_name="${pair##*:}"

        if ! grep -q "$display_name" "AGENTS.md" 2>/dev/null; then
            echo -e "${RED}MISSING ROLE IN AGENTS.md:${NC} $display_name"
            ERRORS=$((ERRORS + 1))
        fi

        if ! grep -q ".dev-agents/$dir_name/PERSONA.md" "AGENTS.md" 2>/dev/null; then
            echo -e "${RED}MISSING PERSONA PATH IN AGENTS.md:${NC} .dev-agents/$dir_name/PERSONA.md"
            ERRORS=$((ERRORS + 1))
        fi
    done
fi

echo ""
echo "Checked $CHECKED item(s)"

if [ $ERRORS -gt 0 ]; then
    echo -e "${RED}Persona refs FAILED: $ERRORS error(s)${NC}"
    exit 1
else
    echo -e "${GREEN}Persona refs passed — all roles consistent${NC}"
    exit 0
fi
