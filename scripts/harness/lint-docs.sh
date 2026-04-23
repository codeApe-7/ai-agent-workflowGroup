#!/bin/bash
# ================================================================
# Harness 传感器：文档新鲜度与一致性检查
# 检测文档是否过期、交叉引用是否有效、内容是否一致
#
# 输出格式对 Agent 友好：
#   [PASS] 通过的检查
#   [FAIL] 失败的检查 + [FIX] 修复指令
# ================================================================

ERRORS=0
WARNINGS=0

pass() { echo -e "  [PASS] $1"; }
fail() {
    echo -e "  [FAIL] $1"
    ERRORS=$((ERRORS + 1))
    bash "$(dirname "${BASH_SOURCE[0]}")/log-event.sh" lint_fail --actor harness --payload "lint=docs" 2>/dev/null || true
}
warn() { echo -e "  [WARN] $1"; WARNINGS=$((WARNINGS + 1)); }
fix()  { echo -e "        [FIX] $1"; }

echo "======================================"
echo "  Harness 传感器：文档检查"
echo "======================================"
echo ""

# ── 1. CLAUDE.md 行数检查（应保持精简） ──
echo "▸ CLAUDE.md 精简度检查"

if [ -f "CLAUDE.md" ]; then
    LINE_COUNT=$(wc -l < "CLAUDE.md" | tr -d ' ')
    if [ "$LINE_COUNT" -le 100 ]; then
        pass "CLAUDE.md 保持精简（${LINE_COUNT} 行 ≤ 100）"
    else
        warn "CLAUDE.md 过长（${LINE_COUNT} 行 > 100）"
        fix "CLAUDE.md 应作为目录/地图，详细内容移至 docs/ 目录。参考 Harness Engineering 的渐进式披露原则"
    fi
else
    fail "CLAUDE.md 不存在"
    fix "创建 CLAUDE.md 作为 Agent 入口文件"
fi

# ── 2. 交叉引用有效性 ──
echo ""
echo "▸ CLAUDE.md 交叉引用检查"

if [ -f "CLAUDE.md" ]; then
    while IFS= read -r ref; do
        [ -z "$ref" ] && continue
        if [ -f "$ref" ] || [ -d "$ref" ]; then
            pass "引用有效: $ref"
        else
            fail "引用无效: $ref"
            fix "文件 $ref 不存在，请创建或更新 CLAUDE.md 中的引用路径"
        fi
    done < <(grep -oE '`(docs/[^`]+|skills/[^`]+|\.dev-agents/[^`]+|scripts/[^`]+)`' CLAUDE.md | tr -d '`' | sort -u)
fi

# ── 3. 知识库索引一致性 ──
echo ""
echo "▸ 知识库索引一致性"

if [ -f "docs/README.md" ]; then
    while IFS= read -r ref; do
        [ -z "$ref" ] && continue
        if [ -f "docs/$ref" ]; then
            pass "索引引用有效: docs/$ref"
        else
            fail "索引引用无效: docs/$ref"
            fix "docs/README.md 引用了不存在的 docs/$ref，请创建该文档或删除引用"
        fi
    done < <(grep -oE '\[.*\]\(([^)]+\.md)\)' docs/README.md | grep -oE '\([^)]+\)' | tr -d '()' | grep -v '^http')
fi

# ── 4. 文档非空检查 ──
echo ""
echo "▸ 文档非空检查"

for doc in docs/*.md; do
    if [ -f "$doc" ]; then
        size=$(wc -c < "$doc" | tr -d ' ')
        if [ "$size" -gt 50 ]; then
            pass "$doc 有内容（${size} bytes）"
        else
            warn "$doc 内容过少（${size} bytes）"
            fix "$doc 可能是空壳文档，请补充实质内容"
        fi
    fi
done

# ── 5. QUALITY_SCORE.md 更新检查 ──
echo ""
echo "▸ 质量评分更新检查"

if [ -f "docs/QUALITY_SCORE.md" ]; then
    LAST_UPDATE=$(grep -oE '最后更新：[0-9]{4}-[0-9]{2}-[0-9]{2}' docs/QUALITY_SCORE.md | head -1 | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}')
    if [ -n "$LAST_UPDATE" ]; then
        DAYS_AGO=$(( ($(date +%s) - $(date -d "$LAST_UPDATE" +%s 2>/dev/null || echo 0)) / 86400 ))
        if [ "$DAYS_AGO" -le 30 ] 2>/dev/null; then
            pass "质量评分最近更新于 $LAST_UPDATE"
        else
            warn "质量评分上次更新于 $LAST_UPDATE（超过 30 天）"
            fix "运行熵管理流程，更新 docs/QUALITY_SCORE.md 中的评分"
        fi
    fi
fi

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
