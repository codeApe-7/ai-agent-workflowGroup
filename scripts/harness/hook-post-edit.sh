#!/bin/bash
# ================================================================
# Hook: PostToolUse — Write|Edit（文件修改后自动触发）
#
# 触发方式：
#   Claude Code CLI → hooks.json 自动触发（强制）
#   Cursor → 不会自动触发（需在 CLAUDE.md 中指令引导）
#
# 策略：静默成功，仅在失败时输出 + exit 2
#   exit 0 = 静默通过，stdout 显示在 transcript
#   exit 2 = 错误回注到 Agent 上下文，Agent 必须修复
# ================================================================

ERRORS=""

# 检查 CLAUDE.md 行数是否膨胀
if [ -f "CLAUDE.md" ]; then
    LINE_COUNT=$(wc -l < "CLAUDE.md" | tr -d ' ')
    if [ "$LINE_COUNT" -gt 100 ]; then
        ERRORS="${ERRORS}[FAIL] CLAUDE.md 超过 100 行（当前 ${LINE_COUNT} 行）\n"
        ERRORS="${ERRORS}[FIX] CLAUDE.md 应保持为目录式入口，详细内容移至 docs/ 目录\n\n"
    fi
fi

# 检查 docs/ 下是否有空壳文档
for doc in docs/*.md; do
    if [ -f "$doc" ]; then
        SIZE=$(wc -c < "$doc" 2>/dev/null | tr -d ' ')
        if [ -n "$SIZE" ] && [ "$SIZE" -lt 50 ]; then
            ERRORS="${ERRORS}[FAIL] $doc 内容过少（${SIZE} bytes）\n"
            ERRORS="${ERRORS}[FIX] 文档不应为空壳，请补充实质内容\n\n"
        fi
    fi
done

# 静默成功，失败时 exit 2 回注上下文
if [ -n "$ERRORS" ]; then
    echo -e "$ERRORS" >&2
    exit 2
fi
