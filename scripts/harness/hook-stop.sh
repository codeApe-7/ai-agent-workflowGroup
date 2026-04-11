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
# 这是 back-pressure 的核心：
#   确保 Agent 不会在留下问题时停止
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

# 静默成功，失败时 exit 2 阻止停止
if [ -n "$ERRORS" ]; then
    echo "Harness 传感器检测到问题，请修复后再停止：" >&2
    echo "" >&2
    echo -e "$ERRORS" >&2
    echo "修复上述 [FAIL] 项后重试。" >&2
    exit 2
fi
