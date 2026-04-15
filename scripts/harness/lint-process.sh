#!/bin/bash
# ================================================================
# Harness 传感器：工作流过程合规检查
#
# 与 lint-structure.sh（检查文件存在）不同，本传感器检查的是
# 工作流是否被正确遵守：
#   - 有代码变更时，是否有对应的设计文档和实现计划
#   - 有实现计划时，是否有对应的设计文档
#   - 有审查报告时，是否覆盖了两阶段
#   - 工作流状态机是否一致
#
# 核心原则：从"文件存在"检查升级为"过程合规"检查
# ================================================================

ERRORS=0
WARNINGS=0

pass() { echo -e "  [PASS] $1"; }
fail() { echo -e "  [FAIL] $1"; ERRORS=$((ERRORS + 1)); }
warn() { echo -e "  [WARN] $1"; WARNINGS=$((WARNINGS + 1)); }
fix()  { echo -e "        [FIX] $1"; }

SHARED_DIR=".dev-agents/shared"
STATE_FILE="$SHARED_DIR/.workflow-state"

echo "======================================"
echo "  Harness 传感器：流程合规检查"
echo "======================================"
echo ""

# ── 1. 工作流状态一致性 ──
echo "▸ 工作流状态一致性"

if [ -f "$STATE_FILE" ]; then
    CURRENT_STAGE=$(grep "^stage=" "$STATE_FILE" | cut -d'=' -f2-)
    IS_EXEMPT=$(grep "^exempt=" "$STATE_FILE" | cut -d'=' -f2-)

    if [ "$IS_EXEMPT" = "true" ]; then
        pass "简单任务豁免模式（跳过流程检查）"
    elif [ -n "$CURRENT_STAGE" ] && [ "$CURRENT_STAGE" != "idle" ]; then
        pass "工作流活跃（阶段: $CURRENT_STAGE）"

        # 检查阶段与产物是否匹配
        case "$CURRENT_STAGE" in
            validation|design|planning|development|testing|documentation|finishing)
                DESIGN_COUNT=$(find "$SHARED_DIR/designs/" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
                if [ "$DESIGN_COUNT" -eq 0 ]; then
                    fail "当前阶段 $CURRENT_STAGE，但缺少需求/设计文档"
                    fix "工作流不应跳过 brainstorming 阶段。在 $SHARED_DIR/designs/ 中补充文档"
                else
                    pass "设计文档存在（$DESIGN_COUNT 个），符合阶段 $CURRENT_STAGE 的前置要求"
                fi
                ;;
        esac

        case "$CURRENT_STAGE" in
            development|testing|documentation|finishing)
                TASK_COUNT=$(find "$SHARED_DIR/tasks/" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
                if [ "$TASK_COUNT" -eq 0 ]; then
                    fail "当前阶段 $CURRENT_STAGE，但缺少实现计划"
                    fix "工作流不应跳过 planning 阶段。在 $SHARED_DIR/tasks/ 中补充实现计划"
                else
                    pass "实现计划存在（$TASK_COUNT 个），符合阶段 $CURRENT_STAGE 的前置要求"
                fi
                ;;
        esac

        case "$CURRENT_STAGE" in
            documentation|finishing)
                REVIEW_COUNT=$(find "$SHARED_DIR/reviews/" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
                if [ "$REVIEW_COUNT" -eq 0 ]; then
                    fail "当前阶段 $CURRENT_STAGE，但缺少审查报告"
                    fix "不应跳过 testing 阶段。派遣 Kyle 完成测试验证和两阶段审查"
                else
                    pass "审查报告存在（$REVIEW_COUNT 个），符合 finishing 的前置要求"
                fi
                ;;
        esac
    else
        pass "工作流空闲（idle）"
    fi
else
    pass "无工作流状态文件（首次使用或已重置）"
fi

# ── 2. 产物因果链完整性 ──
echo ""
echo "▸ 产物因果链检查"

DESIGN_COUNT=$(find "$SHARED_DIR/designs/" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
TASK_COUNT=$(find "$SHARED_DIR/tasks/" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
REVIEW_COUNT=$(find "$SHARED_DIR/reviews/" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')

# 有实现计划但没有设计文档 = 跳过了 brainstorming
if [ "$TASK_COUNT" -gt 0 ] && [ "$DESIGN_COUNT" -eq 0 ]; then
    fail "存在实现计划但无设计文档 → 可能跳过了 brainstorming"
    fix "补充设计文档到 $SHARED_DIR/designs/，或确认是否为简单任务豁免"
elif [ "$TASK_COUNT" -gt 0 ] && [ "$DESIGN_COUNT" -gt 0 ]; then
    pass "实现计划有对应的设计文档（因果链完整）"
elif [ "$TASK_COUNT" -eq 0 ] && [ "$DESIGN_COUNT" -eq 0 ]; then
    pass "无活跃产物（因果链不适用）"
elif [ "$DESIGN_COUNT" -gt 0 ] && [ "$TASK_COUNT" -eq 0 ]; then
    pass "有设计文档，尚无实现计划（正常的 brainstorming → planning 过渡）"
fi

# 有审查报告但没有实现计划 = 跳过了 planning
if [ "$REVIEW_COUNT" -gt 0 ] && [ "$TASK_COUNT" -eq 0 ]; then
    warn "存在审查报告但无实现计划 → 审查没有对照规格"
    fix "审查应基于实现计划中的规格进行，确认是否有计划遗漏"
elif [ "$REVIEW_COUNT" -gt 0 ] && [ "$TASK_COUNT" -gt 0 ]; then
    pass "审查报告有对应的实现计划（可对照规格）"
fi

# ── 3. 实现计划内容质量 ──
echo ""
echo "▸ 实现计划内容质量"

if [ "$TASK_COUNT" -gt 0 ]; then
    for plan in "$SHARED_DIR/tasks/"*.md; do
        [ -f "$plan" ] || continue
        filename=$(basename "$plan")

        # 检查验收条件
        if grep -q -iE "(验收|acceptance|完成标准|done.?criteria)" "$plan" 2>/dev/null; then
            pass "$filename 包含验收条件"
        else
            fail "$filename 缺少验收条件"
            fix "实现计划必须包含明确的验收条件，定义何时算完成"
        fi

        # 检查文件变更列表
        if grep -q -iE "(文件|file|变更|change|修改|modify)" "$plan" 2>/dev/null; then
            pass "$filename 包含变更范围描述"
        else
            warn "$filename 缺少变更范围描述"
            fix "实现计划应列出需要变更的文件清单"
        fi
    done
else
    pass "无实现计划（跳过内容质量检查）"
fi

# ── 4. 审查报告完整性 ──
echo ""
echo "▸ 审查报告两阶段完整性"

if [ "$REVIEW_COUNT" -gt 0 ]; then
    for review in "$SHARED_DIR/reviews/"*.md; do
        [ -f "$review" ] || continue
        filename=$(basename "$review")

        HAS_STAGE1=$(grep -c -iE "(stage.?1|阶段.?1|规格符合|spec.?compliance)" "$review" 2>/dev/null)
        HAS_STAGE2=$(grep -c -iE "(stage.?2|阶段.?2|代码质量|code.?quality)" "$review" 2>/dev/null)
        HAS_VERDICT=$(grep -c -iE "(通过|不通过|pass|fail|approved|rejected)" "$review" 2>/dev/null)

        if [ "$HAS_STAGE1" -gt 0 ] && [ "$HAS_STAGE2" -gt 0 ]; then
            pass "$filename 包含完整两阶段审查"
        elif [ "$HAS_STAGE1" -gt 0 ] && [ "$HAS_STAGE2" -eq 0 ]; then
            fail "$filename 只有 Stage 1，缺少 Stage 2（代码质量审查）"
            fix "必须完成两阶段审查：Stage 1 通过后，派遣 Kyle 执行 Stage 2"
        elif [ "$HAS_STAGE1" -eq 0 ] && [ "$HAS_STAGE2" -gt 0 ]; then
            fail "$filename 只有 Stage 2，缺少 Stage 1（规格符合性审查）"
            fix "Stage 2 不能在 Stage 1 之前执行。先派遣 Kyle 执行 Stage 1"
        else
            fail "$filename 审查结构不完整（缺少阶段标识）"
            fix "审查报告必须包含 Stage 1（规格符合性）和 Stage 2（代码质量）"
        fi

        if [ "$HAS_VERDICT" -eq 0 ]; then
            warn "$filename 缺少明确的审查结论"
            fix "审查报告必须包含明确结论（通过/不通过）"
        fi
    done
else
    pass "无审查报告（跳过完整性检查）"
fi

# ── 5. 设计文档内容质量 ──
echo ""
echo "▸ 设计文档内容质量"

if [ "$DESIGN_COUNT" -gt 0 ]; then
    for design in "$SHARED_DIR/designs/"*.md; do
        [ -f "$design" ] || continue
        filename=$(basename "$design")

        # 检查方案选择
        if grep -q -iE "(方案|选型|option|approach|alternative|trade.?off)" "$design" 2>/dev/null; then
            pass "$filename 包含方案分析"
        else
            warn "$filename 缺少方案对比分析"
            fix "设计文档应包含 2-3 种方案及取舍分析"
        fi

        # 检查是否有 TODO/待定
        if grep -q -iE "(TODO|待定|TBD|之后再说|暂不确定)" "$design" 2>/dev/null; then
            warn "$filename 包含未确定项（TODO/待定）"
            fix "设计文档不应有未确定项，请现在确定或标记为明确的开放问题"
        fi
    done
else
    pass "无设计文档（跳过内容质量检查）"
fi

# ── 结果汇总 ──
echo ""
echo "======================================"
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo "  ✅ 流程合规检查全部通过"
elif [ $ERRORS -eq 0 ]; then
    echo "  ⚠️  通过（$WARNINGS 个警告）"
else
    echo "  ❌ 流程不合规：$ERRORS 个错误，$WARNINGS 个警告"
fi
echo "======================================"

exit $ERRORS
