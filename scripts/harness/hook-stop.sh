#!/bin/bash
# ================================================================
# Hook: Stop（Agent 准备停止时自动触发）
#
# 触发方式：
#   Claude Code CLI → hooks.json 自动触发（强制）
#   Cursor → 不会自动触发（需在 CLAUDE.md 中指令引导）
#
# 策略：静默成功，失败时 exit 2 阻止 Agent 停止
#   exit 0 = 允许停止
#   exit 2 = 阻止停止，错误信息回注让 Agent 继续修复
#
# 检查范围：
#   1. 结构检查（lint-structure.sh）
#   2. 文档检查（lint-docs.sh）
#   3. 工作流产物检查（lint-workflow-artifacts.sh）
#   4. 流程合规检查（lint-process.sh）— 新增
# ================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ERRORS=""

collect_failures() {
    local output="$1"
    local exit_code=$2
    local section_name="$3"

    if [ $exit_code -ne 0 ]; then
        local fail_lines
        fail_lines=$(echo "$output" | grep -E "\[FAIL\]|\[FIX\]")
        if [ -n "$fail_lines" ]; then
            ERRORS="${ERRORS}--- ${section_name} ---\n${fail_lines}\n\n"
        fi
    fi
}

# 运行各传感器（静默模式，只收集失败项）
STRUCT_OUTPUT=$(bash "$SCRIPT_DIR/lint-structure.sh" 2>&1)
collect_failures "$STRUCT_OUTPUT" $? "结构检查"

DOCS_OUTPUT=$(bash "$SCRIPT_DIR/lint-docs.sh" 2>&1)
collect_failures "$DOCS_OUTPUT" $? "文档检查"

ARTIFACT_OUTPUT=$(bash "$SCRIPT_DIR/lint-workflow-artifacts.sh" 2>&1)
collect_failures "$ARTIFACT_OUTPUT" $? "工作流产物检查"

PROCESS_OUTPUT=$(bash "$SCRIPT_DIR/lint-process.sh" 2>&1)
collect_failures "$PROCESS_OUTPUT" $? "流程合规检查"

# 检查工作流状态：如果有活跃工作流且未完成，警告
if [ -f ".dev-agents/shared/.workflow-state" ]; then
    CURRENT_STAGE=$(grep "^stage=" ".dev-agents/shared/.workflow-state" | cut -d'=' -f2-)
    EXEMPT=$(grep "^exempt=" ".dev-agents/shared/.workflow-state" | cut -d'=' -f2-)
    TASK_NAME=$(grep "^task=" ".dev-agents/shared/.workflow-state" | cut -d'=' -f2-)

    if [ "$CURRENT_STAGE" != "idle" ] && [ "$EXEMPT" != "true" ]; then
        ERRORS="${ERRORS}--- 工作流状态检查 ---\n"
        ERRORS="${ERRORS}[FAIL] 工作流未完成就停止（阶段: $CURRENT_STAGE，任务: $TASK_NAME）\n"
        ERRORS="${ERRORS}[FIX] 完成当前工作流阶段后再停止，或运行 bash scripts/harness/workflow-state.sh reset 重置\n\n"
    fi
fi

# 静默成功，失败时 exit 2 阻止停止
if [ -n "$ERRORS" ]; then
    echo "Harness 传感器检测到问题，请修复后再停止：" >&2
    echo "" >&2
    echo -e "$ERRORS" >&2
    echo "修复上述 [FAIL] 项后重试。" >&2
    exit 2
fi
