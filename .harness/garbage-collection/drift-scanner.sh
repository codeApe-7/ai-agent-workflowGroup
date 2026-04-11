#!/bin/bash
# ================================================================
# Harness Garbage Collection: 漂移扫描器
#
# 定期运行（建议每周），检测架构漂移和熵增信号：
# - 超大文件（>500 行的 Markdown 文档）
# - 孤立的任务文件（已完成但未归档）
# - 过期的设计文档
# - 技能文件与 AGENTS.md 的不一致
#
# 输出格式适合 Agent 消费，可直接用于生成修复 PR。
# ================================================================

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PROJECT_ROOT"

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

DRIFT_COUNT=0

echo "================================================================"
echo "  Harness Garbage Collection — Drift Scanner"
echo "  $(date '+%Y-%m-%d %H:%M')"
echo "================================================================"
echo ""

# 1. Oversized documents
echo -e "${BLUE}[SCAN]${NC} Checking for oversized documents..."
while IFS= read -r file; do
    [ -f "$file" ] || continue
    lines=$(wc -l < "$file")
    if [ "$lines" -gt 500 ]; then
        echo -e "${YELLOW}  OVERSIZED:${NC} $file ($lines lines)"
        echo "  ACTION: Consider splitting into smaller focused documents."
        DRIFT_COUNT=$((DRIFT_COUNT + 1))
    fi
done < <(find .dev-agents -name "*.md" 2>/dev/null)

# 2. Stale task files (status=done but still in tasks/)
echo -e "${BLUE}[SCAN]${NC} Checking for completed but unarchived tasks..."
for task_file in .dev-agents/shared/tasks/T-*.md; do
    [ -f "$task_file" ] || continue
    if grep -qi "STATUS.*done" "$task_file" 2>/dev/null; then
        echo -e "${YELLOW}  STALE TASK:${NC} $task_file (status=done, should be archived)"
        echo "  ACTION: Move to .dev-agents/shared/tasks/archived/"
        DRIFT_COUNT=$((DRIFT_COUNT + 1))
    fi
done

# 3. Orphaned design docs (no corresponding task)
echo -e "${BLUE}[SCAN]${NC} Checking for orphaned design documents..."
for design_file in .dev-agents/shared/designs/T-*.md; do
    [ -f "$design_file" ] || continue
    task_id=$(basename "$design_file" | grep -oE "T-[0-9]{3}" || echo "")
    if [ -n "$task_id" ]; then
        matching_task=$(find .dev-agents/shared/tasks -name "${task_id}*" 2>/dev/null | head -1 || echo "")
        if [ -z "$matching_task" ]; then
            echo -e "${YELLOW}  ORPHANED DESIGN:${NC} $design_file (no matching task)"
            echo "  ACTION: Link to a task or archive."
            DRIFT_COUNT=$((DRIFT_COUNT + 1))
        fi
    fi
done

# 4. Empty directories
echo -e "${BLUE}[SCAN]${NC} Checking for empty directories..."
while IFS= read -r dir; do
    if [ -d "$dir" ] && [ -z "$(ls -A "$dir" 2>/dev/null)" ]; then
        echo -e "${YELLOW}  EMPTY DIR:${NC} $dir"
        DRIFT_COUNT=$((DRIFT_COUNT + 1))
    fi
done < <(find .dev-agents -type d 2>/dev/null)

# 5. AGENTS.md size check
echo -e "${BLUE}[SCAN]${NC} Checking AGENTS.md size..."
if [ -f "AGENTS.md" ]; then
    AGENTS_LINES=$(wc -l < "AGENTS.md")
    if [ "$AGENTS_LINES" -gt 200 ]; then
        echo -e "${YELLOW}  AGENTS.md BLOAT:${NC} $AGENTS_LINES lines (recommended: ~100)"
        echo "  ACTION: Move detailed rules into sub-documents. Keep AGENTS.md as table of contents."
        DRIFT_COUNT=$((DRIFT_COUNT + 1))
    fi
fi

echo ""
echo "================================================================"
echo "  Drift Scanner Results"
echo "================================================================"
echo ""

if [ $DRIFT_COUNT -gt 0 ]; then
    echo -e "${YELLOW}Found $DRIFT_COUNT drift signal(s)${NC}"
    echo "Run 'bash .harness/garbage-collection/drift-scanner.sh > drift-report.md' to capture for Agent consumption."
    exit 2
else
    echo -e "${GREEN}No drift detected — codebase is clean${NC}"
    exit 0
fi
