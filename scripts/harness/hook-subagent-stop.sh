#!/bin/bash
# ================================================================
# Hook: SubagentStop（子代理完成后自动触发）
#
# 检查子代理是否：
#   1. 将产出写入正确的 shared/ 位置
#   2. 产出内容符合模板要求
#
# 策略：
#   exit 0 = 允许停止（有 warning 也不阻止）
#   exit 2 = 阻止停止，要求修复
# ================================================================

SHARED_DIR=".dev-agents/shared"
ERRORS=""
WARNINGS=""

# 检查 shared/ 子目录是否存在
for dir in "$SHARED_DIR/tasks" "$SHARED_DIR/designs" "$SHARED_DIR/reviews"; do
    if [ ! -d "$dir" ]; then
        WARNINGS="${WARNINGS}[WARN] $dir/ 目录不存在\n"
        WARNINGS="${WARNINGS}[FIX] 运行: mkdir -p $dir\n"
    fi
done

# 检查最近 5 分钟内是否有新的审查报告，如果有，验证两阶段完整性
if [ -d "$SHARED_DIR/reviews" ]; then
    for review in "$SHARED_DIR/reviews/"*.md; do
        [ -f "$review" ] || continue

        # 检查是否是近期修改的文件（5 分钟内）
        if [ "$(find "$review" -mmin -5 2>/dev/null)" ]; then
            filename=$(basename "$review")
            HAS_STAGE1=$(grep -c -iE "(stage.?1|阶段.?1|规格符合)" "$review" 2>/dev/null)
            HAS_STAGE2=$(grep -c -iE "(stage.?2|阶段.?2|代码质量)" "$review" 2>/dev/null)

            if [ "$HAS_STAGE1" -eq 0 ] && [ "$HAS_STAGE2" -eq 0 ]; then
                ERRORS="${ERRORS}[FAIL] 审查报告 $filename 缺少阶段标识（Stage 1/Stage 2）\n"
                ERRORS="${ERRORS}[FIX] 审查报告必须包含 'Stage 1：规格符合性审查' 和 'Stage 2：代码质量审查'\n"
            fi
        fi
    done
fi

# 输出警告（不阻止）
if [ -n "$WARNINGS" ]; then
    echo -e "$WARNINGS"
fi

# 错误则阻止
if [ -n "$ERRORS" ]; then
    echo -e "$ERRORS" >&2
    exit 2
fi
