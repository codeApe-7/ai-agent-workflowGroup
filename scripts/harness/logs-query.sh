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

LOG_DIR=".orchestration/.logs"

# ── 辅助：返回近 N 天内的日志文件路径（一行一个）──
# 基于文件名 events-YYYY-MM-DD.jsonl 解析日期并与 (today - N 天) 比较。
# date -d 不可用时（非 GNU date 环境）兜底为返回全部文件。
get_log_files_within_days() {
    local days="$1"
    local cutoff_ts
    cutoff_ts=$(date -d "$days days ago" +%s 2>/dev/null || echo "0")
    if [ "$cutoff_ts" -eq 0 ]; then
        ls -1 "$LOG_DIR"/events-*.jsonl 2>/dev/null
        return
    fi
    for f in "$LOG_DIR"/events-*.jsonl; do
        [ -f "$f" ] || continue
        local fname
        fname=$(basename "$f")
        local fdate
        fdate=$(echo "$fname" | sed -n 's/^events-\([0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}\)\.jsonl$/\1/p')
        [ -z "$fdate" ] && continue
        local fts
        fts=$(date -d "$fdate" +%s 2>/dev/null || echo "0")
        if [ "$fts" -ge "$cutoff_ts" ]; then
            echo "$f"
        fi
    done
}

cmd_stats() {
    local wf_id="${1:-unknown}"

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
    echo "  reviewer 审查-修复循环: $loop_count 次"
}

cmd_hotspots() {
    local days="${1:-30}"
    if [ ! -d "$LOG_DIR" ]; then
        echo "[INFO] 无匹配事件"
        return 0
    fi

    local files
    files=$(get_log_files_within_days "$days")
    if [ -z "$files" ]; then
        echo "[INFO] 无匹配事件"
        return 0
    fi

    echo "======================================"
    echo "  失败热点（近 $days 天 top 10）"
    echo "======================================"
    echo ""
    echo "▸ lint_fail 规则 top 10"

    # 字段契约：lint_fail 事件 payload 使用 lint=<name>（任务 8.1 修正后）；
    # red_flag 事件 payload 使用 flag_id=<id>。两种事件按各自字段聚合。
    grep -h -E '"event_type":"(lint_fail|red_flag)"' $files 2>/dev/null \
        | while IFS= read -r line; do
            lint=$(echo "$line" | sed -n 's/.*"lint":"\([^"]*\)".*/\1/p')
            flag=$(echo "$line" | sed -n 's/.*"flag_id":"\([^"]*\)".*/\1/p')
            type=$(echo "$line" | sed -n 's/.*"event_type":"\([^"]*\)".*/\1/p')
            key="${lint}${flag}"
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

    # --days N 真实过滤：只导出近 N 天内的日志文件
    while IFS= read -r f; do
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
    done <<< "$(get_log_files_within_days "$days")"

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
