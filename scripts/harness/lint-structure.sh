#!/bin/bash
# ================================================================
# Harness 传感器：项目结构验证
# 检查项目目录结构、必要文件是否存在且符合规范
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
echo "  Harness 传感器：结构检查"
echo "======================================"
echo ""

# ── 1. 核心文件存在性 ──
echo "▸ 核心文件检查"

for f in "CLAUDE.md" "docs/README.md" "docs/ARCHITECTURE.md"; do
    if [ -f "$f" ]; then
        pass "$f 存在"
    else
        fail "$f 缺失"
        fix "创建 $f，参考 docs/README.md 中的知识库索引"
    fi
done

# ── 2. Agent Persona 文件 ──
echo ""
echo "▸ Agent Persona 检查"

for agent in ella jarvis kyle; do
    persona=".dev-agents/$agent/PERSONA.md"
    if [ -f "$persona" ]; then
        pass "$persona 存在"
    else
        fail "$persona 缺失"
        fix "创建 $persona，定义 $agent 的角色、能力和约束"
    fi
done

# ── 3. 协作产物目录 ──
echo ""
echo "▸ 协作产物目录检查"

for dir in ".dev-agents/shared/tasks" ".dev-agents/shared/designs" ".dev-agents/shared/reviews" ".dev-agents/shared/templates"; do
    if [ -d "$dir" ]; then
        pass "$dir/ 存在"
    else
        warn "$dir/ 不存在"
        fix "运行: mkdir -p $dir"
    fi
done

# ── 4. 工作流技能完整性 ──
echo ""
echo "▸ 工作流技能检查"

WORKFLOW_DIR="skills/max/workflow"
REQUIRED_SKILLS=(
    "brainstorming"
    "requirement-validation"
    "solution-design"
    "writing-plans"
    "subagent-driven-development"
    "testing"
    "documentation"
    "systematic-debugging"
    "verification-before-completion"
    "finishing-a-development-branch"
    "entropy-management"
)

for skill in "${REQUIRED_SKILLS[@]}"; do
    skill_file="$WORKFLOW_DIR/$skill/SKILL.md"
    if [ -f "$skill_file" ]; then
        pass "$skill 技能存在"
    else
        fail "$skill 技能缺失"
        fix "创建 $skill_file，参考其他 SKILL.md 的格式"
    fi
done

# ── 5. docs/ 知识库完整性 ──
echo ""
echo "▸ 知识库文档检查"

REQUIRED_DOCS=(
    "docs/ARCHITECTURE.md"
    "docs/workflow-pipeline.md"
    "docs/dispatch-rules.md"
    "docs/coding-standards.md"
    "docs/red-flags.md"
    "docs/QUALITY_SCORE.md"
    "docs/tech-debt-tracker.md"
    "docs/steering-loop.md"
)

for doc in "${REQUIRED_DOCS[@]}"; do
    if [ -f "$doc" ]; then
        pass "$doc 存在"
    else
        fail "$doc 缺失"
        fix "创建 $doc，参考 docs/README.md 中的文档地图"
    fi
done

# ── 6. Harness 脚本自身完整性 ──
echo ""
echo "▸ Harness 传感器套件检查"

for script in "scripts/harness/lint-structure.sh" "scripts/harness/lint-docs.sh" "scripts/harness/lint-workflow-artifacts.sh" "scripts/harness/lint-process.sh" "scripts/harness/workflow-state.sh" "scripts/harness/run-all.sh"; do
    if [ -f "$script" ]; then
        pass "$script 存在"
    else
        warn "$script 缺失"
        fix "创建 $script 以完善传感器覆盖"
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
