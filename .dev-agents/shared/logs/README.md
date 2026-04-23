# Harness 运行时日志

此目录存储 Harness 各组件产生的结构化事件日志。

## 文件命名

- `events-YYYY-MM-DD.jsonl` — 按日滚动
- 每行一个完整 JSON 对象

## 事件 Schema

```json
{
  "ts": "ISO-8601 带时区",
  "workflow_id": "workflow-state.sh 的 task 名；空闲时为 idle",
  "stage": "brainstorming|validation|design|planning|development|testing|documentation|finishing|idle",
  "event_type": "见下方枚举",
  "actor": "max|jarvis|ella|kyle|harness",
  "duration_ms": 123456,
  "payload": { "自由字段": "..." }
}
```

### event_type 枚举

| event_type | 触发者 | 典型 payload |
|-----------|--------|-------------|
| `workflow_start` | workflow-state.sh init | `task_name` |
| `workflow_reset` | workflow-state.sh reset | `prev_task` |
| `workflow_exempt` | workflow-state.sh exempt | `reason` |
| `workflow_complete` | workflow-state.sh advance（finishing 后） | `prev_stage` |
| `stage_enter` | workflow-state.sh advance | `prev_stage` |
| `stage_exit` | workflow-state.sh advance（新阶段前） | `next_stage` + duration_ms |
| `dispatch` | Max 派遣子代理时 | `target`, `task_id` |
| `loop_iter` | Max 在 Kyle 循环中 | `iteration`, `result` |
| `lint_fail` | lint-*.sh 失败路径 | `lint` |
| `red_flag` | Max 检测到 red-flag | `flag_id`, `severity` |

## 查询

```bash
bash scripts/harness/logs-query.sh --stats [workflow_id]
bash scripts/harness/logs-query.sh --hotspots [--days N]
bash scripts/harness/logs-query.sh --export --out report.csv
```

## Git 策略

- **不追踪**：`events-*.jsonl`（个人运行时状态）
- **追踪**：本 README.md（schema 说明）
