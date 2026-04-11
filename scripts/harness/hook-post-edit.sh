#!/bin/bash
# ================================================================
# Hook: PostToolUse（代码修改后自动触发）
# 策略：静默成功，仅在失败时输出（back-pressure 模式）
#
# 只运行快速检查，不运行全量传感器（那是 Stop hook 的职责）
# ================================================================

FILE_PATH="${1:-}"
ERRORS=""

# 检查 1：如果修改的是 CLAUDE.md，检查行数
if [ "$FILE_PATH" = "CLAUDE.md" ] || echo "$FILE_PATH" | grep -q "CLAUDE.md$"; then
    LINE_COUNT=$(wc -l < "CLAUDE.md" 2>/dev/null | tr -d ' ')
    if [ -n "$LINE_COUNT" ] && [ "$LINE_COUNT" -gt 100 ]; then
        ERRORS="${ERRORS}[FAIL] CLAUDE.md 超过 100 行（当前 ${LINE_COUNT} 行）\n"
        ERRORS="${ERRORS}[FIX] CLAUDE.md 应保持为目录式入口，详细内容移至 docs/ 目录\n"
    fi
fi

# 检查 2：如果修改的是 docs/ 下的文件，检查非空
if echo "$FILE_PATH" | grep -q "^docs/"; then
    if [ -f "$FILE_PATH" ]; then
        SIZE=$(wc -c < "$FILE_PATH" 2>/dev/null | tr -d ' ')
        if [ -n "$SIZE" ] && [ "$SIZE" -lt 50 ]; then
            ERRORS="${ERRORS}[FAIL] $FILE_PATH 内容过少（${SIZE} bytes）\n"
            ERRORS="${ERRORS}[FIX] 文档不应为空壳，请补充实质内容\n"
        fi
    fi
fi

# 检查 3：如果修改的是 SKILL.md，检查基本格式
if echo "$FILE_PATH" | grep -q "SKILL.md$"; then
    if [ -f "$FILE_PATH" ]; then
        if ! grep -q "^---" "$FILE_PATH" 2>/dev/null; then
            ERRORS="${ERRORS}[FAIL] $FILE_PATH 缺少 YAML frontmatter\n"
            ERRORS="${ERRORS}[FIX] SKILL.md 必须以 --- 开始的 YAML frontmatter（含 name 和 description）\n"
        fi
    fi
fi

# 静默成功，仅失败时输出
if [ -n "$ERRORS" ]; then
    echo -e "$ERRORS"
    exit 2
fi
