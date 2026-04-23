#!/bin/bash
# 单元测试：logs-query.sh
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
QUERY="$ROOT/scripts/harness/logs-query.sh"

TMP=$(mktemp -d)
trap "rm -rf $TMP" EXIT
cd "$TMP"

# 构造 mock 日志
mkdir -p .dev-agents/shared/logs
TODAY=$(date +%Y-%m-%d)
LOG="$TMP/.dev-agents/shared/logs/events-$TODAY.jsonl"

cat > "$LOG" <<EOF
{"ts":"2026-04-23T10:00:00+0800","workflow_id":"wf1","stage":"brainstorming","event_type":"stage_enter","actor":"harness","payload":{}}
{"ts":"2026-04-23T10:15:00+0800","workflow_id":"wf1","stage":"brainstorming","event_type":"stage_exit","actor":"harness","duration_ms":900000,"payload":{"next_stage":"design"}}
{"ts":"2026-04-23T10:15:01+0800","workflow_id":"wf1","stage":"design","event_type":"stage_enter","actor":"harness","payload":{}}
{"ts":"2026-04-23T10:45:00+0800","workflow_id":"wf1","stage":"design","event_type":"stage_exit","actor":"harness","duration_ms":1800000,"payload":{"next_stage":"planning"}}
{"ts":"2026-04-23T11:00:00+0800","workflow_id":"wf1","stage":"testing","event_type":"lint_fail","actor":"harness","payload":{"rule":"template-missing"}}
{"ts":"2026-04-23T11:05:00+0800","workflow_id":"wf1","stage":"testing","event_type":"lint_fail","actor":"harness","payload":{"rule":"template-missing"}}
{"ts":"2026-04-23T11:10:00+0800","workflow_id":"wf1","stage":"testing","event_type":"lint_fail","actor":"harness","payload":{"rule":"empty-doc"}}
{"ts":"2026-04-23T11:15:00+0800","workflow_id":"wf1","stage":"testing","event_type":"red_flag","actor":"max","payload":{"flag_id":"3"}}
EOF

PASS=0; FAIL=0
assert() {
    if eval "$2"; then echo "  [PASS] $1"; PASS=$((PASS+1))
    else echo "  [FAIL] $1 — cond: $2"; FAIL=$((FAIL+1)); fi
}

echo "▸ 测试 1：--stats 输出包含阶段耗时"
OUT=$(bash "$QUERY" --stats wf1)
assert "含 brainstorming 900000 ms" "echo '$OUT' | grep -q 'brainstorming.*900000'"
assert "含 design 1800000 ms" "echo '$OUT' | grep -q 'design.*1800000'"

echo ""
echo "▸ 测试 2：--hotspots 输出按次数降序"
OUT=$(bash "$QUERY" --hotspots --days 30)
assert "template-missing 出现 2 次排第一" "echo '$OUT' | grep -E 'template-missing.*2|2.*template-missing'"
assert "empty-doc 出现 1 次" "echo '$OUT' | grep -E 'empty-doc.*1|1.*empty-doc'"

echo ""
echo "▸ 测试 3：--export 生成 CSV"
bash "$QUERY" --export --out "$TMP/out.csv"
assert "CSV 文件生成" "[ -f '$TMP/out.csv' ]"
assert "CSV 含表头" "head -1 '$TMP/out.csv' | grep -q 'ts,workflow_id,stage,event_type'"
assert "CSV 行数 >= 8" "[ \$(wc -l < '$TMP/out.csv') -ge 8 ]"

echo ""
echo "▸ 测试 4：空日志不报错"
rm "$LOG"
OUT=$(bash "$QUERY" --stats 2>&1)
assert "空日志返回码 0" "bash '$QUERY' --stats >/dev/null 2>&1"
assert "含 '无匹配事件' 提示" "echo '$OUT' | grep -qE '无匹配|无事件|no events'"

echo ""
echo "结果: $PASS 通过 / $FAIL 失败"
[ "$FAIL" -eq 0 ]
