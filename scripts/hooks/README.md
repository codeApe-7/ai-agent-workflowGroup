# scripts/hooks — Hook Dispatcher

**单一入口**：`dispatcher.cjs <event>` 读 stdin JSON、路由到对应 checks、失败 `exit 2`（错误回注 Claude 上下文）。

## 事件 → Checks 映射

| 事件 | 触发时机 | 执行的 checks |
|------|----------|---------------|
| `post-edit` | `PostToolUse: Write\|Edit` | `claude-md-size`, `empty-docs` |
| `subagent-stop` | `SubagentStop` | `structure`, `orchestration-artifacts` |
| `stop` | `Stop` | `structure`, `claude-md-size`, `empty-docs`, `delegation-antipatterns`, `workflow-state`, `orchestration-artifacts` |

## 添加新检查

1. 在 `checks/` 下新建 `<name>.cjs`，导出 `{ run(): Report, section: string }`。
2. 在 `dispatcher.cjs` 的 `DISPATCH` 中把它加入对应事件。

Report API：

```js
const { createReport } = require('../lib/runner.cjs');
function run() {
  const report = createReport();
  if (badCondition) {
    report.fail('说人话的问题描述', '说人话的修复提示');
  }
  return report;
}
```

## 直接调用（调试）

```bash
echo '{}' | node scripts/hooks/dispatcher.cjs stop
echo '{}' | node scripts/hooks/dispatcher.cjs post-edit
echo '{}' | node scripts/hooks/dispatcher.cjs subagent-stop
```

## 退出码

- `0`：无问题 或 仅 WARN
- `1`：未知事件（调用错误）
- `2`：有 FAIL，错误信息回注 Claude 上下文以便修复

## 与 harness/ 的分工

- `scripts/hooks/` — 由 `.claude/hooks.json` 自动触发的 check 集合（只读，快速）
- `scripts/orchestration/session.cjs` — 协调会话 / worker 三件套管理（状态真相源）
- `scripts/harness/log-event.sh` / `logs-query.sh` — 事件日志落盘与查询（CLI，可选）
