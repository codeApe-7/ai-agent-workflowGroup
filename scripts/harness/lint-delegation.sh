#!/bin/bash
# ================================================================
# Harness 传感器：派遣契约检查（delegation-check）
#
# 目的：防止 dispatch prompt、文档、skill 重复定义 .claude/agents/*.md
#       里已经声明的内容（角色身份、门控、技能加载、旧路径）。
#
# 参考：Claude-Code-Workflow 项目的 delegation-check skill
#
# 检查维度：
#   A. 角色再定义  — "读取 <persona>.md 了解你的角色" 类指令
#   B. 角色扮演    — "你是<角色中文名>" 出现在非规范位置
#   C. 旧路径残留  — 遗留的 .dev-agents/<role>/ 路径引用
#   D. 旧命令残留  — 遗留的 .claude/commands/{ella,jarvis,kyle}*.md 引用
#   E. frontmatter — .claude/agents/*.md 缺失必需字段
# ================================================================

ERRORS=0
WARNINGS=0

pass() { echo -e "  [PASS] $1"; }
fail() { echo -e "  [FAIL] $1"; ERRORS=$((ERRORS + 1)); }
warn() { echo -e "  [WARN] $1"; WARNINGS=$((WARNINGS + 1)); }
fix()  { echo -e "        [FIX] $1"; }

echo "======================================"
echo "  Harness 传感器：派遣契约检查"
echo "======================================"
echo ""

# ─────────────────────────────────────────
# 扫描目标：CLAUDE.md + docs/ + skills/
# 排除目标：.claude/agents/（规范定义自身）
#          .dev-agents/shared/templates/（模板允许示例）
#          .git/、node_modules/、.idea/
# ─────────────────────────────────────────
SCAN_INCLUDE=("CLAUDE.md" "docs" "skills")

scan_files() {
    local pattern="$1"
    grep -rnE "$pattern" "${SCAN_INCLUDE[@]}" 2>/dev/null \
        | grep -v "^\.git/" \
        | grep -v "node_modules/" \
        | grep -v "\.idea/" \
        | grep -v "/shared/templates/" \
        || true
}

# ── A. 角色再定义检查 ──
echo "▸ A. 角色再定义检查"
echo "   （原生子代理已自动加载身份，无需在 prompt 里指示读取）"

# 匹配：读取 .claude/agents/xxx.md 了解你的角色
# 匹配：先读取 .dev-agents/xxx/PERSONA.md
role_redef=$(scan_files '(读取|加载|load|read).*\.(claude/agents/(ella|jarvis|kyle)\.md|dev-agents/(ella|jarvis|kyle)/PERSONA\.md).*(你的角色|角色|persona|role)')

if [ -z "$role_redef" ]; then
    pass "未发现角色再定义的 dispatch prompt 片段"
else
    while IFS= read -r line; do
        fail "角色再定义: $line"
    done <<< "$role_redef"
    fix "改用 Agent({subagent_type: \"<role>\", ...})，子代理身份由 frontmatter 自动加载"
fi

# ── B. 角色扮演检查 ──
echo ""
echo "▸ B. 角色扮演（role-switching）检查"
echo "   （禁止在当前对话中'变成' Ella/Jarvis/Kyle，必须用 Agent 工具派遣）"

# "你是艾拉/贾维斯/凯尔" 在非 .claude/agents/ 位置
role_switch=$(scan_files '你是.{0,3}(艾拉|贾维斯|凯尔)')

if [ -z "$role_switch" ]; then
    pass "未发现角色扮演指令"
else
    found_switch=0
    while IFS= read -r line; do
        # 过滤：文档里解释"角色切换 vs Agent 派遣"的反例引用是合法的
        if echo "$line" | grep -qE '(禁止|错误|反例|不要|✗|❌|假装)'; then
            continue
        fi
        fail "疑似角色扮演: $line"
        found_switch=1
    done <<< "$role_switch"
    if [ $found_switch -eq 1 ]; then
        fix "删除'你是<角色>'指令，改用 Agent({subagent_type: \"<role>\"})"
    else
        pass "仅命中文档里的反例引用（合法）"
    fi
fi

# ── C. 旧路径残留检查 ──
echo ""
echo "▸ C. 旧 .dev-agents/<role>/ 路径残留检查"

legacy_path=$(scan_files '\.dev-agents/(ella|jarvis|kyle)/')

if [ -z "$legacy_path" ]; then
    pass "无旧路径残留"
else
    while IFS= read -r line; do
        fail "旧路径: $line"
    done <<< "$legacy_path"
    fix "替换为 .claude/agents/<role>.md，或删除整段引用"
fi

# ── D. 旧命令残留检查 ──
echo ""
echo "▸ D. 旧 /ella /jarvis /kyle 命令残留检查"

legacy_cmd=$(scan_files '\.claude/commands/(ella|jarvis|kyle)(-[a-z]+)?\.md|/(ella|jarvis|kyle)(-[a-z]+)?(\s|$|`)')

if [ -z "$legacy_cmd" ]; then
    pass "无旧命令路径残留"
else
    while IFS= read -r line; do
        fail "旧命令引用: $line"
    done <<< "$legacy_cmd"
    fix "角色派遣改用 Agent({subagent_type: \"<role>\"})；只保留 .claude/commands/{init-project,git-commit}.md"
fi

# ── E. Agent frontmatter 完整性检查 ──
echo ""
echo "▸ E. 子代理 frontmatter 完整性检查"

for agent in ella jarvis kyle; do
    file=".claude/agents/$agent.md"
    if [ ! -f "$file" ]; then
        fail "$file 不存在"
        fix "创建 $file 并填入 YAML frontmatter（name/description/tools）"
        continue
    fi

    # 检查前 20 行内是否有 name/description/tools 三个字段
    header=$(head -20 "$file")
    missing=""
    for field in "name:" "description:" "tools:"; do
        if ! echo "$header" | grep -q "^$field"; then
            missing="$missing $field"
        fi
    done

    if [ -z "$missing" ]; then
        pass "$file frontmatter 完整"
    else
        fail "$file frontmatter 缺失:$missing"
        fix "在 $file 顶部的 YAML frontmatter 中补齐上述字段"
    fi
done

# ─────────────────────────────────────────
echo ""
echo "======================================"
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo "  ✅ 派遣契约检查全部通过"
elif [ $ERRORS -eq 0 ]; then
    echo "  ⚠️  通过（$WARNINGS 个警告）"
else
    echo "  ❌ 失败：$ERRORS 个错误，$WARNINGS 个警告"
fi
echo "======================================"

exit $ERRORS
