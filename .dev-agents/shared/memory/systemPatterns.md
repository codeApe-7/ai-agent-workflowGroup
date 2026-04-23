---
last_updated: 2026-04-23
updated_by: initial-bootstrap
version: 1
---

# 系统模式

> Kyle 审查通过后，Max 应将反复出现的好模式/反模式沉淀至此。

## 代码模式

| 模式名 | 类型 | 场景 | 示例位置 | 首次发现 |
|--------|------|------|---------|---------|
| fail-silent-log | 推荐 | harness 观测写入失败不得中断主流程 | `scripts/harness/log-event.sh` | 2026-04-23 |
| frontmatter-timestamp | 推荐 | 记忆文件必须含 last_updated/version | `.dev-agents/shared/memory/*.md` | 2026-04-23 |
| flat-jsonl | 推荐 | 日志用扁平结构 + workflow_id 关联而非 span 嵌套 | `.dev-agents/shared/logs/events-*.jsonl` | 2026-04-23 |

## 常用重构手法

| 场景 | 重构方法 |
|------|---------|
| 避免重复插桩多个脚本 | 在共享 `fail()` 函数内部统一调用 log-event.sh |

## 已沉淀的团队约定

- **零依赖铁律**：不引入 jq / bats / python，纯 bash + coreutils
  - *为什么*：Git Bash Windows 环境下外部依赖难保证；降低用户环境要求
- **观测不阻塞主流程**：log-event.sh 内部 `2>/dev/null || true`
  - *为什么*：观测是辅助手段，失败不能拖垮业务流程
