#!/bin/bash
# ================================================================
# aiGroup 项目 - Skills 更新脚本
# 用法: bash scripts/update-skills.sh [skill名称|all]
# 示例:
#   bash scripts/update-skills.sh all          # 更新所有 GitHub 来源的 skill
#   bash scripts/update-skills.sh ccpm         # 只更新 ccpm
#   bash scripts/update-skills.sh engineering  # 只更新 engineering-team 系列
# ================================================================

set -e

SKILLS_DIR=".cursor/skills"
TEMP_DIR=$(mktemp -d)

trap "rm -rf $TEMP_DIR" EXIT

# 颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 从 GitHub 仓库更新单个 skill
update_from_github() {
    local repo=$1
    local target=$2
    local subpath=${3:-""}

    info "正在从 github.com/$repo 更新 $target ..."

    local clone_dir="$TEMP_DIR/$(basename $repo)"

    if [ ! -d "$clone_dir" ]; then
        git clone --depth 1 "https://github.com/$repo.git" "$clone_dir" 2>/dev/null
        if [ $? -ne 0 ]; then
            error "克隆 $repo 失败，跳过"
            return 1
        fi
    fi

    if [ -n "$subpath" ]; then
        if [ -d "$clone_dir/$subpath" ]; then
            rm -rf "$SKILLS_DIR/$target"
            cp -r "$clone_dir/$subpath" "$SKILLS_DIR/$target"
            info "✓ $target 已更新（来自 $repo/$subpath）"
        else
            error "$repo 中未找到 $subpath，跳过"
            return 1
        fi
    else
        rm -rf "$SKILLS_DIR/$target"
        cp -r "$clone_dir" "$SKILLS_DIR/$target"
        # 清理 .git 目录
        rm -rf "$SKILLS_DIR/$target/.git"
        info "✓ $target 已更新"
    fi
}

# 更新 CCPM
update_ccpm() {
    update_from_github "automazeio/ccpm" "ccpm"
}

# 更新 PM Claude Skills
update_pm_claude_skills() {
    update_from_github "mohitagw15856/pm-claude-skills" "pm-claude-skills"
}

# 更新 Claude Simone
update_claude_simone() {
    update_from_github "Helmi/claude-simone" "claude-simone"
}

# 更新 Engineering Team（18 个子 skill）
update_engineering_team() {
    local repo="alirezarezvani/claude-skills"
    local clone_dir="$TEMP_DIR/claude-skills"

    info "正在从 github.com/$repo 更新 Engineering Team 技能集 ..."

    if [ ! -d "$clone_dir" ]; then
        git clone --depth 1 "https://github.com/$repo.git" "$clone_dir" 2>/dev/null
        if [ $? -ne 0 ]; then
            error "克隆 $repo 失败"
            return 1
        fi
    fi

    # Engineering Team 子 skill 列表
    local skills=(
        aws-solution-architect
        code-reviewer
        ms365-tenant-manager
        senior-architect
        senior-backend
        senior-computer-vision
        senior-data-engineer
        senior-data-scientist
        senior-devops
        senior-fullstack
        senior-ml-engineer
        senior-prompt-engineer
        senior-secops
        senior-security
        tech-stack-evaluator
    )

    local found_dir=""
    # 自动探测仓库中的 skill 目录结构
    for candidate in "skills" "." "claude-skills"; do
        if [ -d "$clone_dir/$candidate" ]; then
            found_dir="$candidate"
            break
        fi
    done

    local updated=0
    for skill in "${skills[@]}"; do
        local src=""
        # 在仓库中搜索该 skill 目录
        src=$(find "$clone_dir" -maxdepth 3 -type d -name "$skill" | head -1)
        if [ -n "$src" ] && [ -f "$src/SKILL.md" ]; then
            rm -rf "$SKILLS_DIR/$skill"
            cp -r "$src" "$SKILLS_DIR/$skill"
            info "  ✓ $skill"
            ((updated++))
        else
            warn "  ✗ $skill 未在仓库中找到，保留现有版本"
        fi
    done

    info "Engineering Team: $updated/${#skills[@]} 个 skill 已更新"
}

# 显示 SkillsMP 来源的 skill（需要手动更新）
show_manual_skills() {
    warn "以下 skill 来自 SkillsMP 技能市场，需要手动更新："
    echo "  - ui-ux-pro-max (Ella: UI/UX 设计工具)"
    echo "  - senior-qa (Kyle: QA 技能包)"
    echo "  - tdd-guide (Kyle: TDD 指南)"
    echo "  - senior-frontend (Ella: 前端技能包)"
    echo ""
    echo "  请访问 SkillsMP 技能市场下载最新版本后替换对应目录。"
}

# 主逻辑
TARGET=${1:-"all"}

echo "======================================"
echo "  aiGroup Skills 更新工具"
echo "======================================"
echo ""

case $TARGET in
    all)
        update_ccpm
        update_pm_claude_skills
        update_claude_simone
        update_engineering_team
        echo ""
        show_manual_skills
        ;;
    ccpm)
        update_ccpm
        ;;
    pm-claude-skills|pm)
        update_pm_claude_skills
        ;;
    claude-simone|simone)
        update_claude_simone
        ;;
    engineering|engineering-team|eng)
        update_engineering_team
        ;;
    manual|skillsmp)
        show_manual_skills
        ;;
    *)
        error "未知的 skill: $TARGET"
        echo ""
        echo "可用选项："
        echo "  all              更新所有 GitHub 来源的 skill"
        echo "  ccpm             更新 CCPM 项目管理"
        echo "  pm-claude-skills 更新 PM Claude Skills"
        echo "  claude-simone    更新 Claude Simone"
        echo "  engineering      更新 Engineering Team (18 个子 skill)"
        echo "  manual           显示需要手动更新的 skill"
        exit 1
        ;;
esac

echo ""
info "更新完成！"
# 更新 manifest 时间戳
if command -v python3 &>/dev/null; then
    python3 -c "
import json, datetime
f = '$SKILLS_DIR/skills-manifest.json'
with open(f) as fp: d = json.load(fp)
d['_updated'] = datetime.date.today().isoformat()
with open(f, 'w') as fp: json.dump(d, fp, ensure_ascii=False, indent=2)
" 2>/dev/null && info "manifest 时间戳已更新"
fi
