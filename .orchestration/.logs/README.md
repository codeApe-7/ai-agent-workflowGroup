# Harness 运行时日志

此目录存储主会话或 hooks/checks 主动落盘的结构化事件日志（可选）。

## 文件命名

- `events-YYYY-MM-DD.jsonl` — 按日滚动
- 每行一个完整 JSON 对象

## 事件 Schema

```json
{
  "ts": "ISO-8601 带时区",
  "workflow_id": "session 名；空闲时为 idle",
  "stage": "phase 名；空闲时为 idle",
  "event_type": "见下方枚举",
  "actor": "main|<agent-name>|harness",
  "duration_ms": 123456,
  "payload": { "自由字段": "..." }
}
```

### 建议 event_type

| event_type | 典型触发 | 典型 payload |
|-----------|---------|-------------|
| `session_init` | 主会话创建 session | `task_name` |
| `worker_created` | 新建 worker 三件套 | `worker` |
| `worker_completed` | worker state→completed | `worker`, `duration_ms` |
| `worker_failed` | worker state→failed | `worker`, `reason` |
| `phase_skipped` | 主会话按裁剪跳过某 phase | `phase`, `reason` |
| `dispatch` | 主会话派遣 subagent | `target`, `session`, `worker` |
| `lint_fail` | hooks/checks 报 FAIL | `check`, `file` |
| `red_flag` | 主会话检测到 red-flag 信号 | `flag_id`, `severity` |

## 写入

```bash
bash scripts/harness/log-event.sh <event_type> \
  --workflow-id <session> \
  --stage <phase> \
  --actor <agent|main|harness> \
  --payload "k=v,k=v"
```

## 查询

```bash
bash scripts/harness/logs-query.sh --stats <workflow-id>
bash scripts/harness/logs-query.sh --hotspots [--days N]
bash scripts/harness/logs-query.sh --export --out report.csv
```

## Git 策略

- **不追踪**：`events-*.jsonl`（个人运行时状态）
- **追踪**：本 README.md（schema 说明）
