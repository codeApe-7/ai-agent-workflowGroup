#!/bin/bash
# ================================================================
# Harness 日志查询工具
#
# 用法：
#   logs-query.sh --stats [workflow_id]
#   logs-query.sh --hotspots [--days N]
#   logs-query.sh --export [--days N] [--out PATH]
#
# 实现：纯 bash + grep + sed，无 jq 依赖
# ================================================================

LOG_DIR=".dev-agents/shared/logs"

cmd_stats() {
    local wf_id="$1"
    local state_file=".dev-agents/shared/.workflow-state"
    if [ -z "$wf_id" ] && [ -f "$state_file" ]; then
        wf_id=$(grep '^task=' "$state_file" 2>/dev/null | cut -d'=' -f2-)
    fi
    wf_id="${wf_id:-unknown}"

    if [ ! -d "$LOG_DIR" ]; then
        echo "[INFO] 无匹配事件（logs 目录不存在）"
        return 0
    fi

    local files
    files=$(ls -1 "$LOG_DIR"/events-*.jsonl 2>/dev/null)
    if [ -z "$files" ]; then
        echo "[INFO] 无匹配事件"
        return 0
    fi

    echo "======================================"
    echo "  工作流统计: $wf_id"
    echo "======================================"
    echo ""
    echo "▸ 阶段耗时（ms）"

    # 提取 stage_exit 事件，按 stage 聚合 duration_ms
    grep -h "\"workflow_id\":\"${wf_id}\"" $files 2>/dev/null \
        | grep "\"event_type\":\"stage_exit\"" \
        | while IFS= read -r line; do
            stage=$(echo "$line" | sed -n 's/.*"stage":"\([^"]*\)".*/\1/p')
            dur=$(echo "$line" | sed -n 's/.*"duration_ms":\([0-9]*\).*/\1/p')
            [ -n "$stage" ] && [ -n "$dur" ] && echo "$stage $dur"
        done \
        | sort \
        | awk '
            {
                sum[$1] += $2
                cnt[$1] += 1
            }
            END {
                for (s in sum) printf "  %-16s %10d ms (× %d)\n", s, sum[s], cnt[s]
            }
        '

    echo ""
    echo "▸ 循环次数"
    local loop_count
    loop_count=$(grep -h "\"workflow_id\":\"${wf_id}\"" $files 2>/dev/null \
        | grep -c "\"event_type\":\"loop_iter\"")
    echo "  Kyle 审查-修复循环: $loop_count 次"
}

cmd_hotspots() {
    local days="${1:-30}"
    if [ ! -d "$LOG_DIR" ]; then
        echo "[INFO] 无匹配事件"
        return 0
    fi

    local files
    files=$(ls -1 "$LOG_DIR"/events-*.jsonl 2>/dev/null)
    if [ -z "$files" ]; then
        echo "[INFO] 无匹配事件"
        return 0
    fi

    echo "======================================"
    echo "  失败热点（近 $days 天 top 10）"
    echo "======================================"
    echo ""
    echo "▸ lint_fail 规则 top 10"

    grep -h -E '"event_type":"(lint_fail|red_flag)"' $files 2>/dev/null \
        | while IFS= read -r line; do
            rule=$(echo "$line" | sed -n 's/.*"rule":"\([^"]*\)".*/\1/p')
            flag=$(echo "$line" | sed -n 's/.*"flag_id":"\([^"]*\)".*/\1/p')
            type=$(echo "$line" | sed -n 's/.*"event_type":"\([^"]*\)".*/\1/p')
            key="${rule}${flag}"
            [ -n "$key" ] && echo "${type}:${key}"
        done \
        | sort | uniq -c | sort -rn | head -10 \
        | awk '{printf "  %-40s %d 次\n", $2, $1}'
}

cmd_export() {
    local days=30
    local out="events-export.csv"
    while [ $# -gt 0 ]; do
        case "$1" in
            --days) days="$2"; shift 2 ;;
            --out) out="$2"; shift 2 ;;
            *) shift ;;
        esac
    done

    if [ ! -d "$LOG_DIR" ]; then
        echo "ts,workflow_id,stage,event_type,actor,duration_ms" > "$out"
        echo "[INFO] 无事件数据，已生成空 CSV: $out"
        return 0
    fi

    echo "ts,workflow_id,stage,event_type,actor,duration_ms" > "$out"

    for f in "$LOG_DIR"/events-*.jsonl; do
        [ -f "$f" ] || continue
        while IFS= read -r line; do
            ts=$(echo "$line" | sed -n 's/.*"ts":"\([^"]*\)".*/\1/p')
            wf=$(echo "$line" | sed -n 's/.*"workflow_id":"\([^"]*\)".*/\1/p')
            stg=$(echo "$line" | sed -n 's/.*"stage":"\([^"]*\)".*/\1/p')
            et=$(echo "$line" | sed -n 's/.*"event_type":"\([^"]*\)".*/\1/p')
            ac=$(echo "$line" | sed -n 's/.*"actor":"\([^"]*\)".*/\1/p')
            dur=$(echo "$line" | sed -n 's/.*"duration_ms":\([0-9]*\).*/\1/p')
            echo "$ts,$wf,$stg,$et,$ac,$dur" >> "$out"
        done < "$f"
    done

    echo "[OK] 已导出到 $out（$(wc -l < "$out") 行）"
}

# ── 入口 ──
case "${1:-}" in
    --stats)
        shift
        cmd_stats "$@"
        ;;
    --hotspots)
        shift
        DAYS=30
        while [ $# -gt 0 ]; do
            case "$1" in
                --days) DAYS="$2"; shift 2 ;;
                *) shift ;;
            esac
        done
        cmd_hotspots "$DAYS"
        ;;
    --export)
        shift
        cmd_export "$@"
        ;;
    *)
        echo "用法: logs-query.sh {--stats [workflow_id]|--hotspots [--days N]|--export [--days N] [--out PATH]}" >&2
        exit 1
        ;;
esac
