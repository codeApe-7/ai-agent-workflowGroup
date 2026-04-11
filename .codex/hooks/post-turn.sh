#!/bin/bash
# ================================================================
# Codex Post-Turn Notify Hook
#
# 通过 config.toml 的 [notify] 配置，Agent 每完成一个 turn 自动执行。
#
# 时机：turn 结束后（Agent 已执行完工具调用，但可能还没 commit）。
# 因此检查的是工作树的实际状态，不仅是 staged files。
#
# 配置方式：在 ~/.codex/config.toml 中添加：
#   [notify]
#   command = "/path/to/project/.codex/hooks/post-turn.sh"
# ================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$PROJECT_ROOT" 2>/dev/null || exit 0

LOG_FILE="$PROJECT_ROOT/.harness/notify.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE" 2>/dev/null || true
}

log "--- Post-turn hook triggered ---"

ISSUES=0

# 1. Check working tree for protected file modifications (unstaged + staged)
MODIFIED=$(git diff --name-only HEAD 2>/dev/null || git diff --name-only 2>/dev/null || echo "")
STAGED=$(git diff --cached --name-only 2>/dev/null || echo "")
ALL_CHANGED=$(printf "%s\n%s" "$MODIFIED" "$STAGED" | sort -u | grep -v '^$' || true)

if [ -n "$ALL_CHANGED" ]; then
    PROTECTED="^AGENTS\.md$|^\.dev-agents/shared/skills/|^\.harness/|^\.dev-agents/.*/PERSONA\.md$|^ARCHITECTURE\.md$"
    VIOLATIONS=$(echo "$ALL_CHANGED" | grep -E "$PROTECTED" || true)
    if [ -n "$VIOLATIONS" ]; then
        log "WARN: Protected files changed in working tree:"
        echo "$VIOLATIONS" | while IFS= read -r v; do log "  - $v"; done
        ISSUES=$((ISSUES + 1))
    fi

    log "Files changed this turn: $(echo "$ALL_CHANGED" | wc -l | tr -d ' ')"
fi

# 2. Critical file existence check
for f in "AGENTS.md" "ARCHITECTURE.md" ".dev-agents/shared/skills/verification.md" ".harness/run-all.sh"; do
    if [ ! -f "$PROJECT_ROOT/$f" ]; then
        log "ERROR: Critical file missing: $f"
        ISSUES=$((ISSUES + 1))
    fi
done

# 3. Check for new task files with bad naming in working tree
NEW_TASKS=$(git ls-files --others --exclude-standard 2>/dev/null | grep "\.dev-agents/shared/tasks/.*\.md$" || true)
if [ -n "$NEW_TASKS" ]; then
    while IFS= read -r task; do
        filename=$(basename "$task")
        if ! echo "$filename" | grep -qE "^T-[0-9]{3}-" 2>/dev/null; then
            log "WARN: Bad task filename in working tree: $filename (expected T-NNN-slug.md)"
            ISSUES=$((ISSUES + 1))
        fi
    done <<< "$NEW_TASKS"
fi

# 4. Check if agent left uncommitted changes (drift signal)
UNCOMMITTED=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
if [ "$UNCOMMITTED" -gt 20 ]; then
    log "WARN: $UNCOMMITTED uncommitted changes — possible drift accumulation"
    ISSUES=$((ISSUES + 1))
fi

if [ $ISSUES -eq 0 ]; then
    log "Post-turn: all checks passed"
else
    log "Post-turn: $ISSUES issue(s) detected"
fi

exit 0
