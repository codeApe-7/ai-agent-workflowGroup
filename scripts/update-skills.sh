#!/bin/bash
# ================================================================
# agentGroup - Skills 自动更新脚本
# 用法: bash scripts/update-skills.sh [target]
# 示例:
#   bash scripts/update-skills.sh all          # 更新所有 GitHub 来源
#   bash scripts/update-skills.sh ccpm         # 只更新 ccpm
#   bash scripts/update-skills.sh engineering  # 只更新 engineering-team
#   bash scripts/update-skills.sh manual       # 显示需手动更新的技能
# ================================================================

SKILLS_DIR="skills"
TEMP_DIR=$(mktemp -d)

trap "rm -rf '$TEMP_DIR'" EXIT

# GitHub 镜像列表（直连失败时依次尝试）
MIRRORS=(
    "https://github.com"
    "https://ghfast.top/https://github.com"
    "https://mirror.ghproxy.com/https://github.com"
)

# 颜色
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 带镜像回退的 git clone
clone_repo() {
    local repo=$1
    local dest=$2

    for mirror in "${MIRRORS[@]}"; do
        local url="$mirror/$repo.git"
        info "  尝试: $url"
        if git clone --depth 1 "$url" "$dest" 2>/dev/null; then
            return 0
        fi
        rm -rf "$dest"
    done
    return 1
}

# 从 GitHub 克隆并同步到本地目录
update_from_github() {
    local repo=$1
    local target=$2

    info "更新 $target ← github.com/$repo"

    local clone_dir="$TEMP_DIR/$(echo "$repo" | tr '/' '_')"

    if [ ! -d "$clone_dir" ]; then
        if ! clone_repo "$repo" "$clone_dir"; then
            error "所有镜像均克隆失败: $repo"
            return 1
        fi
    fi

    # 显示最新提交
    local commit date
    commit="$(cd "$clone_dir" && git rev-parse --short HEAD)"
    date="$(cd "$clone_dir" && git log -1 --format='%ci' | cut -d' ' -f1)"
    info "  最新提交: $commit ($date)"

    # 同步文件
    rm -rf "$SKILLS_DIR/$target"
    cp -r "$clone_dir" "$SKILLS_DIR/$target"
    rm -rf "$SKILLS_DIR/$target/.git"

    local count
    count="$(find "$SKILLS_DIR/$target" -type f | wc -l | tr -d ' ')"
    info "  ✓ 已同步 $count 个文件"
}

# ── 各源更新函数 ──

update_ccpm() {
    update_from_github "automazeio/ccpm" "max/ccpm"
}

update_pm() {
    update_from_github "mohitagw15856/pm-claude-skills" "max/pm-claude-skills"
}

update_simone() {
    update_from_github "Helmi/claude-simone" "jarvis/claude-simone"
}

update_engineering() {
    update_from_github "alirezarezvani/claude-skills" "jarvis/engineering-team"
}

show_manual() {
    warn "以下技能来自 SkillsMP 技能市场，需要手动更新："
    echo ""
    echo "  ui-ux-pro-max    → skills/ella/ui-ux-pro-max"
    echo "  senior-frontend  → skills/ella/senior-frontend"
    echo "  senior-qa        → skills/kyle/senior-qa"
    echo "  tdd-guide        → skills/kyle/tdd-guide"
    echo ""
    echo "  请前往 SkillsMP 技能市场下载最新版本后替换对应目录。"
}

# ── 主逻辑 ──

TARGET=${1:-""}

if [ -z "$TARGET" ]; then
    echo "用法: $0 <target>"
    echo ""
    echo "  all              更新所有 GitHub 来源"
    echo "  ccpm             更新 CCPM 项目管理"
    echo "  pm               更新 PM Claude Skills"
    echo "  simone           更新 Claude Simone"
    echo "  engineering      更新 Engineering Team"
    echo "  manual           显示需手动更新的技能"
    exit 0
fi

echo "======================================"
echo "  agentGroup Skills 更新工具"
echo "======================================"
echo ""

SUCCESS=0
FAIL=0

run_update() {
    if "$@"; then
        SUCCESS=$((SUCCESS + 1))
    else
        FAIL=$((FAIL + 1))
    fi
}

case $TARGET in
    all)
        run_update update_ccpm
        echo ""
        run_update update_pm
        echo ""
        run_update update_simone
        echo ""
        run_update update_engineering
        echo ""
        echo "--------------------------------------"
        echo -e "  结果: ${GREEN}成功 $SUCCESS${NC}  ${RED}失败 $FAIL${NC}"
        echo "--------------------------------------"
        echo ""
        show_manual
        ;;
    ccpm)
        run_update update_ccpm
        ;;
    pm|pm-claude-skills)
        run_update update_pm
        ;;
    simone|claude-simone)
        run_update update_simone
        ;;
    engineering|engineering-team|eng)
        run_update update_engineering
        ;;
    manual|skillsmp)
        show_manual
        ;;
    *)
        error "未知目标: $TARGET"
        echo ""
        echo "可用: all | ccpm | pm | simone | engineering | manual"
        exit 1
        ;;
esac

echo ""
if [ $FAIL -gt 0 ]; then
    warn "有 $FAIL 个源更新失败"
    exit 1
fi
info "完成！"
