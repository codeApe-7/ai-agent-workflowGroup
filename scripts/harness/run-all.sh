#!/bin/bash
# ================================================================
# Harness 传感器：主运行器
# 依次运行所有传感器脚本，汇总结果
#
# 用法: bash scripts/harness/run-all.sh
#
# Agent 集成说明：
#   开发完成后运行此脚本进行自检。
#   如果有 [FAIL]，根据 [FIX] 指令修正后重新运行，直至全部通过。
# ================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOTAL_ERRORS=0
TOTAL_WARNINGS=0
SENSORS_RUN=0
SENSORS_FAILED=0

echo "╔════════════════════════════════════════╗"
echo "║    aiGroup Harness 传感器 - 全量检查    ║"
echo "╚════════════════════════════════════════╝"
echo ""

run_sensor() {
    local name=$1
    local script=$2

    if [ ! -f "$script" ]; then
        echo "  [SKIP] $name — 脚本不存在: $script"
        return
    fi

    SENSORS_RUN=$((SENSORS_RUN + 1))
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  运行: $name"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    bash "$script"
    local exit_code=$?

    if [ $exit_code -ne 0 ]; then
        SENSORS_FAILED=$((SENSORS_FAILED + 1))
        TOTAL_ERRORS=$((TOTAL_ERRORS + exit_code))
    fi

    echo ""
}

run_sensor "结构检查" "$SCRIPT_DIR/lint-structure.sh"
run_sensor "文档检查" "$SCRIPT_DIR/lint-docs.sh"
run_sensor "工作流产物检查" "$SCRIPT_DIR/lint-workflow-artifacts.sh"
run_sensor "流程合规检查" "$SCRIPT_DIR/lint-process.sh"
run_sensor "派遣契约检查" "$SCRIPT_DIR/lint-delegation.sh"

echo "╔════════════════════════════════════════╗"
echo "║            总体检查结果                ║"
echo "╠════════════════════════════════════════╣"
echo "║  运行传感器: $SENSORS_RUN"
echo "║  失败传感器: $SENSORS_FAILED"
echo "║  累计错误数: $TOTAL_ERRORS"

if [ $TOTAL_ERRORS -eq 0 ]; then
    echo "║  状态: ✅ 全部通过"
else
    echo "║  状态: ❌ 存在问题需修复"
    echo "║"
    echo "║  Agent 操作指引："
    echo "║  1. 查看上方 [FAIL] 标记的检查项"
    echo "║  2. 按 [FIX] 指令逐一修复"
    echo "║  3. 重新运行: bash scripts/harness/run-all.sh"
    echo "║  4. 重复直至全部通过"
fi

echo "╚════════════════════════════════════════╝"

exit $TOTAL_ERRORS
