#!/bin/bash
# ================================================================
# Hook: SubagentStop（子代理完成后自动触发）
# 检查子代理是否将产出写入了正确的 shared/ 位置
# 策略：静默成功，失败时提醒
# ================================================================

SHARED_DIR=".dev-agents/shared"
WARNINGS=""

# 检查 shared/ 子目录是否存在
for dir in "$SHARED_DIR/tasks" "$SHARED_DIR/designs" "$SHARED_DIR/reviews"; do
    if [ ! -d "$dir" ]; then
        WARNINGS="${WARNINGS}[WARN] $dir/ 目录不存在\n"
        WARNINGS="${WARNINGS}[FIX] 运行: mkdir -p $dir\n"
    fi
done

if [ -n "$WARNINGS" ]; then
    echo -e "$WARNINGS"
fi
