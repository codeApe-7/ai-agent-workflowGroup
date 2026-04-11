#!/bin/bash
# ================================================================
# Harness Pre-commit Hook
#
# 提交前自动执行的 Computational Sensors。
# 快速检查（<5 秒），不阻塞正常开发流。
# ================================================================

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PROJECT_ROOT"

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

FAILED=0

echo -e "${BLUE}[HARNESS]${NC} Running pre-commit checks..."

# 1. Protected files check
STAGED=$(git diff --cached --name-only 2>/dev/null || echo "")

if [ -n "$STAGED" ]; then
    PROTECTED_PATTERNS="^AGENTS\.md$|^\.dev-agents/shared/skills/|^\.harness/|^\.dev-agents/.*/PERSONA\.md$"

    PROTECTED_HITS=$(echo "$STAGED" | grep -E "$PROTECTED_PATTERNS" || true)

    if [ -n "$PROTECTED_HITS" ]; then
        if [ -n "${HARNESS_ALLOW_PROTECTED:-}" ]; then
            echo -e "${BLUE}[HARNESS]${NC} Protected files modified (allowed by HARNESS_ALLOW_PROTECTED):"
            echo "$PROTECTED_HITS" | sed 's/^/  /'
        else
            echo -e "${RED}[HARNESS]${NC} BLOCKED: Protected files modified without authorization:"
            echo "$PROTECTED_HITS" | sed 's/^/  /'
            echo "  These files define the Harness itself. Modification requires:"
            echo "  - Max-level approval, OR"
            echo "  - Set HARNESS_ALLOW_PROTECTED=1 before commit"
            FAILED=$((FAILED + 1))
        fi
    fi
fi

# 2. Task format check (only if task files are staged)
TASK_FILES=$(echo "$STAGED" | grep -E "^\.dev-agents/shared/tasks/.*\.md$" || true)

if [ -n "$TASK_FILES" ]; then
    echo -e "${BLUE}[HARNESS]${NC} Checking staged task file format..."
    while IFS= read -r file; do
        [ -f "$file" ] || continue
        filename=$(basename "$file")
        if ! echo "$filename" | grep -qE "^T-[0-9]{3}-.*\.md$"; then
            echo -e "${RED}  BAD TASK FILENAME:${NC} $filename (expected T-NNN-slug.md)"
            FAILED=$((FAILED + 1))
        fi
    done <<< "$TASK_FILES"
fi

# 3. No secrets check
SECRET_PATTERNS="password|api_key|secret_key|private_key|AWS_SECRET|OPENAI_API_KEY"
SECRET_HITS=$(git diff --cached --diff-filter=ACM -p 2>/dev/null | grep -iE "$SECRET_PATTERNS" | grep "^+" | grep -v "^+++" || true)

if [ -n "$SECRET_HITS" ]; then
    echo -e "${RED}[HARNESS] POTENTIAL SECRETS DETECTED:${NC}"
    echo "$SECRET_HITS" | head -5 | sed 's/^/  /'
    echo "  Review carefully before committing."
    FAILED=$((FAILED + 1))
fi

if [ $FAILED -gt 0 ]; then
    echo -e "${RED}[HARNESS] Pre-commit: $FAILED issue(s) found${NC}"
    exit 1
else
    echo -e "${GREEN}[HARNESS] Pre-commit passed${NC}"
    exit 0
fi
