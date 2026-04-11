#!/bin/bash
# ================================================================
# Hook: Stop（Agent 停止前自动触发）
# 策略：静默成功，失败时输出错误 + exit 2 让 Agent 继续工作
#
# 这是 back-pressure 的核心：确保 Agent 不会在留下问题时停止
# ================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ERRORS=""

# 运行结构检查（静默模式）
STRUCT_OUTPUT=$(bash "$SCRIPT_DIR/lint-structure.sh" 2>&1)
STRUCT_EXIT=$?
if [ $STRUCT_EXIT -ne 0 ]; then
    FAIL_LINES=$(echo "$STRUCT_OUTPUT" | grep -E "\[FAIL\]|\[FIX\]")
    if [ -n "$FAIL_LINES" ]; then
        ERRORS="${ERRORS}--- 结构检查失败 ---\n${FAIL_LINES}\n\n"
    fi
fi

# 运行文档检查（静默模式）
DOCS_OUTPUT=$(bash "$SCRIPT_DIR/lint-docs.sh" 2>&1)
DOCS_EXIT=$?
if [ $DOCS_EXIT -ne 0 ]; then
    FAIL_LINES=$(echo "$DOCS_OUTPUT" | grep -E "\[FAIL\]|\[FIX\]")
    if [ -n "$FAIL_LINES" ]; then
        ERRORS="${ERRORS}--- 文档检查失败 ---\n${FAIL_LINES}\n\n"
    fi
fi

# 运行工作流产物检查（静默模式）
ARTIFACT_OUTPUT=$(bash "$SCRIPT_DIR/lint-workflow-artifacts.sh" 2>&1)
ARTIFACT_EXIT=$?
if [ $ARTIFACT_EXIT -ne 0 ]; then
    FAIL_LINES=$(echo "$ARTIFACT_OUTPUT" | grep -E "\[FAIL\]|\[FIX\]")
    if [ -n "$FAIL_LINES" ]; then
        ERRORS="${ERRORS}--- 工作流产物检查失败 ---\n${FAIL_LINES}\n\n"
    fi
fi

# 静默成功，失败时输出并 exit 2 让 Agent 继续修复
if [ -n "$ERRORS" ]; then
    echo "Harness 传感器检测到问题，请修复后再停止："
    echo ""
    echo -e "$ERRORS"
    echo "修复上述 [FAIL] 项后，Agent 可以正常停止。"
    exit 2
fi
