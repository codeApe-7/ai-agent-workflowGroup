#!/bin/bash
# 单元测试：log-event.sh
# 运行：bash scripts/harness/tests/test-log-event.sh

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
LOG_EVENT="$ROOT/scripts/harness/log-event.sh"

TMP=$(mktemp -d)
trap "rm -rf $TMP" EXIT

cd "$TMP"
mkdir -p .orchestration

PASS=0
FAIL=0

assert() {
    local msg="$1"
    local cond="$2"
    if eval "$cond"; then
        echo "  [PASS] $msg"
        PASS=$((PASS + 1))
    else
        echo "  [FAIL] $msg"
        echo "         条件: $cond"
        FAIL=$((FAIL + 1))
    fi
}

echo "▸ 测试 1：基础事件写入（带 workflow-id/stage 参数）"
bash "$LOG_EVENT" worker_completed --workflow-id test-session --stage development --actor planner
LOG_FILE=".orchestration/.logs/events-$(date +%Y-%m-%d).jsonl"
assert "日志文件已创建" "[ -f '$LOG_FILE' ]"
assert "事件类型正确" "grep -q '\"event_type\":\"worker_completed\"' '$LOG_FILE'"
assert "workflow_id 来自参数" "grep -q '\"workflow_id\":\"test-session\"' '$LOG_FILE'"
assert "stage 来自参数" "grep -q '\"stage\":\"development\"' '$LOG_FILE'"
assert "actor 正确" "grep -q '\"actor\":\"planner\"' '$LOG_FILE'"

echo ""
echo "▸ 测试 2：payload 解析"
bash "$LOG_EVENT" dispatch --workflow-id test-session --actor main --payload "target=backend-engineer,task_id=T5"
assert "payload 包含 target" "grep -q '\"target\":\"backend-engineer\"' '$LOG_FILE'"
assert "payload 包含 task_id" "grep -q '\"task_id\":\"T5\"' '$LOG_FILE'"

echo ""
echo "▸ 测试 3：duration_ms 字段"
bash "$LOG_EVENT" phase_skipped --workflow-id test-session --duration-ms 12345
assert "duration_ms 存在且为数字" "grep -q '\"duration_ms\":12345' '$LOG_FILE'"

echo ""
echo "▸ 测试 4：省略参数时 fallback 为 idle"
bash "$LOG_EVENT" red_flag --actor main
assert "省略 workflow-id 时为 idle" "tail -1 '$LOG_FILE' | grep -q '\"workflow_id\":\"idle\"'"
assert "省略 stage 时为 idle" "tail -1 '$LOG_FILE' | grep -q '\"stage\":\"idle\"'"

echo ""
echo "▸ 测试 5：特殊字符转义"
bash "$LOG_EVENT" red_flag --actor main --payload 'msg=has "quotes" and \ backslash'
assert "双引号被转义" "tail -1 '$LOG_FILE' | grep -q '\\\\\"quotes\\\\\"'"

echo ""
echo "▸ 测试 6：ts 字段 ISO-8601 格式"
assert "ts 字段格式合法" "tail -1 '$LOG_FILE' | grep -qE '\"ts\":\"[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}[+-][0-9]{4}\"'"

echo ""
echo "======================================"
echo "  结果: $PASS 通过 / $FAIL 失败"
echo "======================================"
[ "$FAIL" -eq 0 ]
