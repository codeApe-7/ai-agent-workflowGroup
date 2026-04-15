#!/bin/bash
# ================================================================
# 工作流状态机 — Harness 行为强制执行的核心
#
# 通过状态文件追踪当前工作流阶段，强制管道顺序：
#   idle → brainstorming → validation → design → planning
#        → development → testing → documentation → finishing → idle
#
# 阶段对照：
#   brainstorming  = 需求收集（收集和分析功能需求）
#   validation     = 需求验证（验证需求的完整性和可行性）
#   design         = 方案设计（设计技术方案和架构）
#   planning       = 任务拆解（将需求拆解为可执行任务）
#   development    = 实施开发（按照任务进行开发）
#   testing        = 测试验证（编写和执行测试用例）
#   documentation  = 文档更新（更新相关文档）
#   finishing      = 分支收尾（集成/PR/归档）
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

# 管道阶段定义（有序，8 阶段 + idle）
STAGES=("idle" "brainstorming" "validation" "design" "planning" "development" "testing" "documentation" "finishing")

# 阶段中文名映射
stage_label() {
    case "$1" in
        idle)            echo "空闲" ;;
        brainstorming)   echo "需求收集" ;;
        validation)      echo "需求验证" ;;
        design)          echo "方案设计" ;;
        planning)        echo "任务拆解" ;;
        development)     echo "实施开发" ;;
        testing)         echo "测试验证" ;;
        documentation)   echo "文档更新" ;;
        finishing)       echo "分支收尾" ;;
        *)               echo "$1" ;;
    esac
}

# ── 工具函数 ──

ensure_state_dir() {
    mkdir -p "$STATE_DIR" 2>/dev/null
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
        echo "[STATE] 阶段: $stage（$(stage_label "$stage")）"
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
    echo "[STATE] 当前阶段: brainstorming（需求收集）"
    echo "[NEXT] 收集和分析功能需求，记录到 .dev-agents/shared/designs/ 后运行 advance"
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
            # 需求收集阶段：必须有需求文档
            local design_count
            design_count=$(find .dev-agents/shared/designs/ -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
            if [ "$design_count" -eq 0 ]; then
                echo "[FAIL] 需求收集阶段完成前必须产出需求文档" >&2
                echo "[FIX] 将需求分析保存到 .dev-agents/shared/designs/ 后再推进" >&2
                return 1
            fi
            ;;
        validation)
            # 需求验证阶段：需求文档中应有验证标记
            local design_count
            design_count=$(find .dev-agents/shared/designs/ -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
            if [ "$design_count" -eq 0 ]; then
                echo "[FAIL] 需求验证阶段但无需求文档" >&2
                echo "[FIX] 需求文档应在 brainstorming 阶段产出" >&2
                return 1
            fi
            ;;
        design)
            # 方案设计阶段：设计文档中应有方案决策
            local has_design=0
            for f in .dev-agents/shared/designs/*.md; do
                [ -f "$f" ] || continue
                if grep -q -iE "(方案|架构|技术栈|architecture|approach)" "$f" 2>/dev/null; then
                    has_design=1
                    break
                fi
            done
            if [ "$has_design" -eq 0 ]; then
                echo "[FAIL] 方案设计阶段完成前必须有技术方案" >&2
                echo "[FIX] 在设计文档中补充方案选择、架构决策和技术栈" >&2
                return 1
            fi
            ;;
        planning)
            # 任务拆解阶段：必须有实现计划
            local task_count
            task_count=$(find .dev-agents/shared/tasks/ -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
            if [ "$task_count" -eq 0 ]; then
                echo "[FAIL] 任务拆解阶段完成前必须产出实现计划" >&2
                echo "[FIX] 将实现计划保存到 .dev-agents/shared/tasks/ 后再推进" >&2
                return 1
            fi
            ;;
        development)
            # 实施开发阶段：检查是否有代码变更
            ;;
        testing)
            # 测试验证阶段：必须有审查/测试报告
            local review_count
            review_count=$(find .dev-agents/shared/reviews/ -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
            if [ "$review_count" -eq 0 ]; then
                echo "[FAIL] 测试验证阶段完成前必须有测试/审查报告" >&2
                echo "[FIX] 派遣 Kyle 完成测试验证和代码审查，报告保存到 .dev-agents/shared/reviews/" >&2
                return 1
            fi
            ;;
        documentation)
            # 文档更新阶段：不做强制检查，由 Agent 自行判断
            ;;
        finishing)
            # 分支收尾：无额外检查
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
        echo "[OK] 阶段推进: $current_stage（$(stage_label "$current_stage")） → $next（$(stage_label "$next")）"
        echo "[STATE] 当前阶段: $next（$(stage_label "$next")）"

        case "$next" in
            validation)
                echo "[NEXT] 验证需求的完整性和可行性，确认无歧义后 advance" ;;
            design)
                echo "[NEXT] 设计技术方案和架构，产出方案决策文档后 advance" ;;
            planning)
                echo "[NEXT] 将需求拆解为可执行任务，保存到 .dev-agents/shared/tasks/" ;;
            development)
                echo "[NEXT] 派遣 Jarvis 子代理按任务执行开发" ;;
            testing)
                echo "[NEXT] 派遣 Kyle 编写和执行测试用例，进行两阶段审查" ;;
            documentation)
                echo "[NEXT] 更新相关文档（API 文档、README、ARCHITECTURE 等）" ;;
            finishing)
                echo "[NEXT] 执行分支收尾流程（集成/PR/归档）" ;;
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

    # idle 状态下不允许任何操作
    if [ "$current_stage" = "idle" ] && [ "$required_stage" != "idle" ]; then
        echo "[GATE-FAIL] 当前无活跃工作流，不能执行 $required_stage（$(stage_label "$required_stage")）" >&2
        echo "[FIX] 先运行 workflow-state.sh init <任务名> 启动工作流" >&2
        return 1
    fi

    # 检查当前阶段是否匹配要求
    if [ "$current_stage" = "$required_stage" ]; then
        echo "[GATE] 门控通过: 当前阶段 $current_stage（$(stage_label "$current_stage")）允许执行"
        return 0
    fi

    # 阶段不匹配
    local current_idx
    current_idx=$(stage_index "$current_stage")
    local required_idx
    required_idx=$(stage_index "$required_stage")

    if [ "$required_idx" -gt "$current_idx" ]; then
        echo "[GATE-FAIL] 当前阶段 $current_stage（$(stage_label "$current_stage")），不能跳到 $required_stage（$(stage_label "$required_stage")）" >&2
        echo "[FIX] 必须先完成当前阶段，逐步推进到 $required_stage" >&2
    else
        echo "[GATE-FAIL] 当前阶段 $current_stage（$(stage_label "$current_stage")），已超过 $required_stage（$(stage_label "$required_stage")）" >&2
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
        echo "  init <名称>     启动新工作流（进入 brainstorming/需求收集）"
        echo "  advance         推进到下一阶段（含产物检查）"
        echo "  gate <阶段>     门控检查：当前是否允许该操作"
        echo "  reset           重置工作流状态"
        echo "  exempt <原因>   标记简单任务豁免"
        echo ""
        echo "  阶段: brainstorming → validation → design → planning → development → testing → documentation → finishing"
        exit 1
        ;;
esac
