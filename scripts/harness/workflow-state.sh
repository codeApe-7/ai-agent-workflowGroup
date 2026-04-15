#!/bin/bash
# ================================================================
# 工作流状态机 — Harness 行为强制执行的核心
#
# 通过状态文件追踪当前工作流阶段，强制管道顺序：
#   idle → brainstorming → planning → development → review → finishing → idle
#
# 用法：
#   workflow-state.sh status          # 查看当前状态
#   workflow-state.sh init <名称>     # 开始新工作流（进入 brainstorming）
#   workflow-state.sh advance         # 推进到下一阶段
#   workflow-state.sh gate <阶段>     # 门控检查：当前是否可以执行该阶段
#   workflow-state.sh reset           # 重置状态（完成或放弃）
#   workflow-state.sh exempt <原因>   # 标记为简单任务豁免
#
# 状态文件：.dev-agents/shared/.workflow-state
# ================================================================

STATE_FILE=".dev-agents/shared/.workflow-state"
STATE_DIR="$(dirname "$STATE_FILE")"

# 管道阶段定义（有序）
STAGES=("idle" "brainstorming" "planning" "development" "review" "finishing")

# ── 工具函数 ──

ensure_state_dir() {
    mkdir -p "$STATE_DIR" 2>/dev/null
}

read_state() {
    if [ -f "$STATE_FILE" ]; then
        cat "$STATE_FILE"
    else
        echo "stage=idle"
        echo "task="
        echo "started="
        echo "exempt=false"
    fi
}

get_field() {
    local field="$1"
    if [ -f "$STATE_FILE" ]; then
        grep "^${field}=" "$STATE_FILE" 2>/dev/null | cut -d'=' -f2-
    fi
}

get_stage() {
    local stage
    stage=$(get_field "stage")
    echo "${stage:-idle}"
}

write_state() {
    local stage="$1"
    local task="$2"
    local started="$3"
    local exempt="${4:-false}"
    ensure_state_dir
    cat > "$STATE_FILE" << EOF
stage=$stage
task=$task
started=$started
exempt=$exempt
updated=$(date '+%Y-%m-%d %H:%M:%S')
EOF
}

stage_index() {
    local target="$1"
    for i in "${!STAGES[@]}"; do
        if [ "${STAGES[$i]}" = "$target" ]; then
            echo "$i"
            return
        fi
    done
    echo "-1"
}

next_stage() {
    local current="$1"
    local idx
    idx=$(stage_index "$current")
    local next_idx=$((idx + 1))
    if [ "$next_idx" -lt "${#STAGES[@]}" ]; then
        echo "${STAGES[$next_idx]}"
    else
        echo "idle"
    fi
}

# ── 命令实现 ──

cmd_status() {
    local stage
    stage=$(get_stage)
    local task
    task=$(get_field "task")
    local started
    started=$(get_field "started")
    local exempt
    exempt=$(get_field "exempt")

    if [ "$stage" = "idle" ]; then
        echo "[STATE] 当前无活跃工作流"
        echo "[INFO] 使用 'workflow-state.sh init <任务名>' 开始新工作流"
    else
        echo "[STATE] 阶段: $stage"
        echo "[STATE] 任务: ${task:-未命名}"
        echo "[STATE] 开始时间: ${started:-未知}"
        [ "$exempt" = "true" ] && echo "[STATE] 标记: 简单任务豁免"
    fi
}

cmd_init() {
    local task_name="$1"
    local current_stage
    current_stage=$(get_stage)

    if [ "$current_stage" != "idle" ]; then
        echo "[FAIL] 已有活跃工作流（阶段: $current_stage，任务: $(get_field 'task')）" >&2
        echo "[FIX] 先完成或重置当前工作流: workflow-state.sh reset" >&2
        return 1
    fi

    if [ -z "$task_name" ]; then
        echo "[FAIL] 必须提供任务名称: workflow-state.sh init <任务名>" >&2
        return 1
    fi

    write_state "brainstorming" "$task_name" "$(date '+%Y-%m-%d %H:%M:%S')"
    echo "[OK] 工作流已启动: $task_name"
    echo "[STATE] 当前阶段: brainstorming"
    echo "[NEXT] 完成需求澄清和方案设计后，运行 workflow-state.sh advance 进入下一阶段"
}

cmd_advance() {
    local current_stage
    current_stage=$(get_stage)
    local task
    task=$(get_field "task")

    if [ "$current_stage" = "idle" ]; then
        echo "[FAIL] 无活跃工作流，无法推进" >&2
        echo "[FIX] 使用 workflow-state.sh init <任务名> 开始新工作流" >&2
        return 1
    fi

    # 阶段推进前的产物检查
    case "$current_stage" in
        brainstorming)
            # 必须有设计文档
            local design_count
            design_count=$(find .dev-agents/shared/designs/ -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
            if [ "$design_count" -eq 0 ]; then
                echo "[FAIL] brainstorming 阶段完成前必须产出设计文档" >&2
                echo "[FIX] 将设计方案保存到 .dev-agents/shared/designs/ 后再推进" >&2
                return 1
            fi
            ;;
        planning)
            # 必须有实现计划
            local task_count
            task_count=$(find .dev-agents/shared/tasks/ -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
            if [ "$task_count" -eq 0 ]; then
                echo "[FAIL] planning 阶段完成前必须产出实现计划" >&2
                echo "[FIX] 将实现计划保存到 .dev-agents/shared/tasks/ 后再推进" >&2
                return 1
            fi
            ;;
        development)
            # 开发完成，应有代码变更（这里不做强制检查，由 review 阶段验证）
            ;;
        review)
            # 必须有审查报告
            local review_count
            review_count=$(find .dev-agents/shared/reviews/ -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
            if [ "$review_count" -eq 0 ]; then
                echo "[FAIL] review 阶段完成前必须有审查报告" >&2
                echo "[FIX] 派遣 Kyle 完成两阶段审查，报告保存到 .dev-agents/shared/reviews/" >&2
                return 1
            fi
            ;;
    esac

    local next
    next=$(next_stage "$current_stage")

    if [ "$next" = "idle" ]; then
        write_state "idle" "" "" "false"
        echo "[OK] 工作流已完成: $task"
        echo "[STATE] 状态已重置为 idle"
    else
        write_state "$next" "$task" "$(get_field 'started')"
        echo "[OK] 阶段推进: $current_stage → $next"
        echo "[STATE] 当前阶段: $next"

        case "$next" in
            planning)
                echo "[NEXT] 创建实现计划，保存到 .dev-agents/shared/tasks/" ;;
            development)
                echo "[NEXT] 派遣 Jarvis 子代理执行开发任务" ;;
            review)
                echo "[NEXT] 派遣 Kyle 子代理进行两阶段审查" ;;
            finishing)
                echo "[NEXT] 执行分支收尾流程" ;;
        esac
    fi
}

cmd_gate() {
    local required_stage="$1"
    local current_stage
    current_stage=$(get_stage)
    local exempt
    exempt=$(get_field "exempt")

    # 简单任务豁免
    if [ "$exempt" = "true" ]; then
        echo "[GATE] 简单任务豁免，跳过门控检查"
        return 0
    fi

    # idle 状态下不允许任何操作（除了 brainstorming）
    if [ "$current_stage" = "idle" ] && [ "$required_stage" != "idle" ]; then
        echo "[GATE-FAIL] 当前无活跃工作流，不能执行 $required_stage" >&2
        echo "[FIX] 先运行 workflow-state.sh init <任务名> 启动工作流" >&2
        return 1
    fi

    # 检查当前阶段是否匹配要求
    if [ "$current_stage" = "$required_stage" ]; then
        echo "[GATE] 门控通过: 当前阶段 $current_stage 允许执行 $required_stage"
        return 0
    fi

    # 阶段不匹配
    local current_idx
    current_idx=$(stage_index "$current_stage")
    local required_idx
    required_idx=$(stage_index "$required_stage")

    if [ "$required_idx" -gt "$current_idx" ]; then
        echo "[GATE-FAIL] 当前阶段 $current_stage，不能跳到 $required_stage" >&2
        echo "[FIX] 必须先完成 $current_stage 阶段，逐步推进到 $required_stage" >&2
    else
        echo "[GATE-FAIL] 当前阶段 $current_stage，已超过 $required_stage" >&2
        echo "[INFO] $required_stage 阶段已完成，当前处于 $current_stage" >&2
    fi
    return 1
}

cmd_reset() {
    local current_stage
    current_stage=$(get_stage)
    local task
    task=$(get_field "task")

    if [ "$current_stage" = "idle" ]; then
        echo "[INFO] 当前已是 idle 状态，无需重置"
        return 0
    fi

    write_state "idle" "" "" "false"
    echo "[OK] 工作流已重置（原任务: ${task:-未命名}，原阶段: $current_stage）"
}

cmd_exempt() {
    local reason="$1"

    if [ -z "$reason" ]; then
        echo "[FAIL] 必须提供豁免原因: workflow-state.sh exempt <原因>" >&2
        return 1
    fi

    write_state "idle" "exempt: $reason" "$(date '+%Y-%m-%d %H:%M:%S')" "true"
    echo "[OK] 已标记为简单任务豁免: $reason"
    echo "[INFO] 豁免任务完成后请运行 workflow-state.sh reset 恢复正常模式"
}

# ── 入口 ──

case "${1:-status}" in
    status)   cmd_status ;;
    init)     cmd_init "$2" ;;
    advance)  cmd_advance ;;
    gate)     cmd_gate "$2" ;;
    reset)    cmd_reset ;;
    exempt)   cmd_exempt "$2" ;;
    *)
        echo "用法: workflow-state.sh {status|init|advance|gate|reset|exempt}" >&2
        echo ""
        echo "  status          查看当前工作流状态"
        echo "  init <名称>     启动新工作流（进入 brainstorming）"
        echo "  advance         推进到下一阶段（含产物检查）"
        echo "  gate <阶段>     门控检查：当前是否允许该操作"
        echo "  reset           重置工作流状态"
        echo "  exempt <原因>   标记简单任务豁免"
        exit 1
        ;;
esac
