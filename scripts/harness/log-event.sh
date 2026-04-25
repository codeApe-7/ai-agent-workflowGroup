#!/bin/bash
# ================================================================
# Harness 事件写入工具
#
# 职责：将 harness 事件以 JSONL 格式追加到日志文件
# 调用者：主会话或 hooks/checks（主动调用）
# 设计原则：fail-silent — 写入失败不得中断调用方主流程
#
# 用法：
#   log-event.sh <event_type> [--workflow-id W] [--stage S] [--actor A] [--duration-ms D] [--payload k=v,k=v,...]
#
# 示例：
#   log-event.sh dispatch --workflow-id refactor-auth --actor main --payload "target=planner"
#   log-event.sh worker_completed --workflow-id refactor-auth --actor planner
#   log-event.sh lint_fail --payload "rule=empty-docs,file=docs/x.md"
#
# 输出：.orchestration/.logs/events-YYYY-MM-DD.jsonl（追加一行）
# ================================================================

EVENT_TYPE="${1:-}"

if [ -z "$EVENT_TYPE" ]; then
    echo "[log-event] ERROR: 必须提供 event_type" >&2
    exit 1
fi

shift

# ── 解析参数 ──
WORKFLOW_ID_ARG=""
STAGE_ARG=""
ACTOR_ARG=""
DURATION_ARG=""
PAYLOAD_ARG=""

while [ $# -gt 0 ]; do
    case "$1" in
        --workflow-id) WORKFLOW_ID_ARG="$2"; shift 2 ;;
        --stage) STAGE_ARG="$2"; shift 2 ;;
        --actor) ACTOR_ARG="$2"; shift 2 ;;
        --duration-ms) DURATION_ARG="$2"; shift 2 ;;
        --payload) PAYLOAD_ARG="$2"; shift 2 ;;
        *) shift ;;
    esac
done

WORKFLOW_ID="${WORKFLOW_ID_ARG:-idle}"
STAGE="${STAGE_ARG:-idle}"
ACTOR="${ACTOR_ARG:-harness}"

# ── 时间戳（ISO-8601 带时区）──
TS=$(date +%Y-%m-%dT%H:%M:%S%z)

# ── JSON 字符串转义函数 ──
json_escape() {
    # 转义顺序：\ 先转，再转 "
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    # 换行/制表符转义
    s="${s//$'\n'/\\n}"
    s="${s//$'\t'/\\t}"
    echo "$s"
}

# ── 拼接 payload ──
PAYLOAD_JSON="{}"
if [ -n "$PAYLOAD_ARG" ]; then
    PAYLOAD_JSON="{"
    FIRST=1
    # payload 用 "," 分隔 k=v 对；v 内含 "," 需用户调用方避免（本轮不支持复杂 payload）
    IFS=',' read -ra PAIRS <<< "$PAYLOAD_ARG"
    for pair in "${PAIRS[@]}"; do
        K="${pair%%=*}"
        V="${pair#*=}"
        K_ESC=$(json_escape "$K")
        V_ESC=$(json_escape "$V")
        if [ "$FIRST" -eq 1 ]; then
            PAYLOAD_JSON="${PAYLOAD_JSON}\"${K_ESC}\":\"${V_ESC}\""
            FIRST=0
        else
            PAYLOAD_JSON="${PAYLOAD_JSON},\"${K_ESC}\":\"${V_ESC}\""
        fi
    done
    PAYLOAD_JSON="${PAYLOAD_JSON}}"
fi

# ── duration_ms 字段（可选）──
DURATION_FIELD=""
if [ -n "$DURATION_ARG" ]; then
    # 仅接受数字
    if echo "$DURATION_ARG" | grep -qE '^[0-9]+$'; then
        DURATION_FIELD=",\"duration_ms\":${DURATION_ARG}"
    fi
fi

# ── 拼接最终 JSON（字段顺序固定）──
JSON="{\"ts\":\"${TS}\",\"workflow_id\":\"$(json_escape "$WORKFLOW_ID")\",\"stage\":\"$(json_escape "$STAGE")\",\"event_type\":\"$(json_escape "$EVENT_TYPE")\",\"actor\":\"$(json_escape "$ACTOR")\"${DURATION_FIELD},\"payload\":${PAYLOAD_JSON}}"

# ── 写入（fail-silent）──
LOG_DIR=".orchestration/.logs"
LOG_FILE="${LOG_DIR}/events-$(date +%Y-%m-%d).jsonl"

{
    mkdir -p "$LOG_DIR" 2>/dev/null
    echo "$JSON" >> "$LOG_FILE" 2>/dev/null
} || true

# 永远返回 0，即使写入失败
exit 0
