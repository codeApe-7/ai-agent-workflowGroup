# aiGroup 知识库索引

本目录是项目的**唯一事实源 (Single Source of Truth)**，所有架构决策、规范、质量标准均版本化存储于此。

Agent 应按需检索本目录下的文档，而非依赖 CLAUDE.md 中的简短描述。

## 文档地图

| 文档 | 用途 | 更新频率 |
|------|------|---------|
| [ARCHITECTURE.md](ARCHITECTURE.md) | 项目架构总览、目录结构、模块职责 | 架构变更时 |
| [workflow-pipeline.md](workflow-pipeline.md) | 强制工作流管道详细规则 | 流程调整时 |
| [dispatch-rules.md](dispatch-rules.md) | 团队成员派遣规则与上下文传递 | 角色变更时 |
| [coding-standards.md](coding-standards.md) | Git 规范、代码规范、注释规则 | 标准更新时 |
| [red-flags.md](red-flags.md) | Max 必须阻止的危险信号与对应行动 | 发现新模式时 |
| [QUALITY_SCORE.md](QUALITY_SCORE.md) | 各模块质量评分与健康度追踪 | 每次审查后 |
| [tech-debt-tracker.md](tech-debt-tracker.md) | 已知技术债与偿还计划 | 持续更新 |
| [steering-loop.md](steering-loop.md) | Harness 转向循环：问题→编码为规则→自动执行 | 发现重复问题时 |

## 子目录

- `templates/` — 静态文档模板（PRD / 实现计划 / 代码审查等）

## 使用原则

1. **渐进式披露** — Agent 先读 CLAUDE.md 获取全局地图，按需深入本目录
2. **仓库即事实** — 所有约束、决策、规范必须存在于仓库文件中，不依赖口头约定
3. **文档即代码** — 文档与代码同步更新，过期文档由熵管理流程清理
