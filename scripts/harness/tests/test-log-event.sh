#!/bin/bash
# 单元测试：log-event.sh
# 运行：bash scripts/harness/tests/test-log-event.sh

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
LOG_EVENT="$ROOT/scripts/harness/log-event.sh"

# 用临时目录做隔离测试
TMP=$(mktemp -d)
trap "rm -rf $TMP" EXIT

cd "$TMP"
mkdir -p .dev-agents/shared
cat > .dev-agents/shared/.workflow-state <<EOF
stage=testing
task=test-task
started=2026-04-23 00:00:00
exempt=false
updated=2026-04-23 00:00:00
EOF

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

echo "▸ 测试 1：基础事件写入"
bash "$LOG_EVENT" stage_enter --actor harness
LOG_FILE=".dev-agents/shared/logs/events-$(date +%Y-%m-%d).jsonl"
assert "日志文件已创建" "[ -f '$LOG_FILE' ]"
assert "事件类型正确" "grep -q '\"event_type\":\"stage_enter\"' '$LOG_FILE'"
assert "workflow_id 从 state 读取" "grep -q '\"workflow_id\":\"test-task\"' '$LOG_FILE'"
assert "stage 从 state 读取" "grep -q '\"stage\":\"testing\"' '$LOG_FILE'"
assert "actor 正确" "grep -q '\"actor\":\"harness\"' '$LOG_FILE'"

echo ""
echo "▸ 测试 2：payload 解析"
bash "$LOG_EVENT" dispatch --actor max --payload "target=jarvis,task_id=T5"
assert "payload 包含 target" "grep -q '\"target\":\"jarvis\"' '$LOG_FILE'"
assert "payload 包含 task_id" "grep -q '\"task_id\":\"T5\"' '$LOG_FILE'"

echo ""
echo "▸ 测试 3：duration_ms 字段"
bash "$LOG_EVENT" stage_exit --duration-ms 12345
assert "duration_ms 存在且为数字" "grep -q '\"duration_ms\":12345' '$LOG_FILE'"

echo ""
echo "▸ 测试 4：state 文件缺失时 fallback 为 idle"
rm .dev-agents/shared/.workflow-state
bash "$LOG_EVENT" workflow_reset
assert "无 state 时 workflow_id 为 idle" "grep -q '\"workflow_id\":\"idle\"' '$LOG_FILE'"
assert "无 state 时 stage 为 idle" "tail -1 '$LOG_FILE' | grep -q '\"stage\":\"idle\"'"

echo ""
echo "▸ 测试 5：特殊字符转义"
cat > .dev-agents/shared/.workflow-state <<EOF
stage=design
task=test-task
started=2026-04-23 00:00:00
exempt=false
EOF
bash "$LOG_EVENT" red_flag --actor max --payload 'msg=has "quotes" and \ backslash'
assert "双引号被转义" "tail -1 '$LOG_FILE' | grep -q '\\\\\"quotes\\\\\"'"

echo ""
echo "▸ 测试 6：ts 字段 ISO-8601 格式"
assert "ts 字段格式合法" "tail -1 '$LOG_FILE' | grep -qE '\"ts\":\"[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}[+-][0-9]{4}\"'"

echo ""
echo "======================================"
echo "  结果: $PASS 通过 / $FAIL 失败"
echo "======================================"
[ "$FAIL" -eq 0 ]
