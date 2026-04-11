#!/bin/bash
# ================================================================
# Harness 传感器：工作流产物验证
# 检查 .dev-agents/shared/ 下的产物是否符合模板规范
#
# 输出格式对 Agent 友好：
#   [PASS] 通过的检查
#   [FAIL] 失败的检查 + [FIX] 修复指令
# ================================================================

ERRORS=0
WARNINGS=0

pass() { echo -e "  [PASS] $1"; }
fail() { echo -e "  [FAIL] $1"; ERRORS=$((ERRORS + 1)); }
warn() { echo -e "  [WARN] $1"; WARNINGS=$((WARNINGS + 1)); }
fix()  { echo -e "        [FIX] $1"; }

echo "======================================"
echo "  Harness 传感器：工作流产物检查"
echo "======================================"
echo ""

SHARED_DIR=".dev-agents/shared"

# ── 1. 实现计划检查 ──
echo "▸ 实现计划检查 ($SHARED_DIR/tasks/)"

if [ -d "$SHARED_DIR/tasks" ]; then
    TASK_COUNT=$(find "$SHARED_DIR/tasks" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
    if [ "$TASK_COUNT" -gt 0 ]; then
        pass "发现 $TASK_COUNT 个实现计划"
        for plan in "$SHARED_DIR/tasks/"*.md; do
            [ -f "$plan" ] || continue
            filename=$(basename "$plan")

            if grep -q "META" "$plan" 2>/dev/null || grep -q "## " "$plan" 2>/dev/null; then
                pass "$filename 有结构化标题"
            else
                warn "$filename 缺少结构化标题"
                fix "参考 .dev-agents/shared/templates/implementation-plan.md 模板重构 $plan"
            fi

            if grep -q -iE "(验收|acceptance|完成标准|done)" "$plan" 2>/dev/null; then
                pass "$filename 包含验收条件"
            else
                warn "$filename 缺少验收条件"
                fix "在 $plan 中添加验收条件（Acceptance Criteria），明确何时算完成"
            fi
        done
    else
        pass "tasks/ 为空（无活跃任务）"
    fi
else
    warn "$SHARED_DIR/tasks/ 目录不存在"
    fix "运行: mkdir -p $SHARED_DIR/tasks"
fi

# ── 2. 设计方案检查 ──
echo ""
echo "▸ 设计方案检查 ($SHARED_DIR/designs/)"

if [ -d "$SHARED_DIR/designs" ]; then
    DESIGN_COUNT=$(find "$SHARED_DIR/designs" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
    if [ "$DESIGN_COUNT" -gt 0 ]; then
        pass "发现 $DESIGN_COUNT 个设计方案"
        for design in "$SHARED_DIR/designs/"*.md; do
            [ -f "$design" ] || continue
            filename=$(basename "$design")

            if grep -q -iE "(方案|选型|对比|决策|architecture)" "$design" 2>/dev/null; then
                pass "$filename 包含方案决策内容"
            else
                warn "$filename 可能缺少方案决策"
                fix "设计文档应包含方案选择理由和对比分析"
            fi
        done
    else
        pass "designs/ 为空（无活跃设计）"
    fi
else
    warn "$SHARED_DIR/designs/ 目录不存在"
    fix "运行: mkdir -p $SHARED_DIR/designs"
fi

# ── 3. 审查报告检查 ──
echo ""
echo "▸ 审查报告检查 ($SHARED_DIR/reviews/)"

if [ -d "$SHARED_DIR/reviews" ]; then
    REVIEW_COUNT=$(find "$SHARED_DIR/reviews" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
    if [ "$REVIEW_COUNT" -gt 0 ]; then
        pass "发现 $REVIEW_COUNT 个审查报告"
        for review in "$SHARED_DIR/reviews/"*.md; do
            [ -f "$review" ] || continue
            filename=$(basename "$review")

            HAS_STAGE1=$(grep -c -iE "(stage.?1|规格符合|spec)" "$review" 2>/dev/null)
            HAS_STAGE2=$(grep -c -iE "(stage.?2|代码质量|quality)" "$review" 2>/dev/null)

            if [ "$HAS_STAGE1" -gt 0 ] && [ "$HAS_STAGE2" -gt 0 ]; then
                pass "$filename 包含两阶段审查"
            elif [ "$HAS_STAGE1" -gt 0 ]; then
                warn "$filename 只有 Stage 1，缺少 Stage 2"
                fix "补充 Stage 2 代码质量审查，参考 .dev-agents/shared/templates/code-review.md"
            else
                warn "$filename 审查结构不完整"
                fix "参考 .dev-agents/shared/templates/code-review.md 重构审查报告"
            fi
        done
    else
        pass "reviews/ 为空（无活跃审查）"
    fi
else
    warn "$SHARED_DIR/reviews/ 目录不存在"
    fix "运行: mkdir -p $SHARED_DIR/reviews"
fi

# ── 4. 模板完整性 ──
echo ""
echo "▸ 模板完整性检查"

REQUIRED_TEMPLATES=("prd.md" "implementation-plan.md" "code-review.md")
for tmpl in "${REQUIRED_TEMPLATES[@]}"; do
    if [ -f "$SHARED_DIR/templates/$tmpl" ]; then
        pass "模板 $tmpl 存在"
    else
        fail "模板 $tmpl 缺失"
        fix "创建 $SHARED_DIR/templates/$tmpl"
    fi
done

# ── 结果汇总 ──
echo ""
echo "======================================"
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo "  ✅ 全部通过"
elif [ $ERRORS -eq 0 ]; then
    echo "  ⚠️  通过（$WARNINGS 个警告）"
else
    echo "  ❌ 失败：$ERRORS 个错误，$WARNINGS 个警告"
fi
echo "======================================"

exit $ERRORS
