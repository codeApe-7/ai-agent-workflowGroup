# agentGroup - 面向 Codex 的多 Agent 协作框架

> 一个主协调器，按需派生多个 Codex 子代理，在同一仓库内完成设计、实现、测试和审查。

## 核心变化

这个仓库原本偏向 Claude 单入口调度。现在的主入口改为根级 `AGENTS.md`，并把多 agent 协作方式调整为更适合 Codex 的模式：

- 主线程负责拆解、集成、对用户沟通
- 子代理只做边界清晰的并行任务
- 通过 `spawn_agent`、`send_input`、`wait_agent` 协调，而不是让代理彼此直接通信
- 用 `.dev-agents/shared/` 传递设计稿、任务单、审查结果等中间产物
- 只在写入范围互不重叠时并行实现

## 架构角色

| 协作层 | Codex 实际形态 | 负责内容 | 典型产物 |
|------|---------------|---------|---------|
| 主协调器 | 主线程 | 需求分析、分解、集成、汇总 | 执行计划、最终回复 |
| 设计探索 | `explorer` 子代理 | 设计分析、信息提炼、方案草稿 | `.dev-agents/shared/designs/*.md` |
| 实现执行 | `worker` 子代理 | 限定文件范围内的实现与测试 | 代码改动、测试结果 |
| 审查验证 | `explorer` 或 `worker` 子代理 | 代码审查、测试复现、验收报告 | `.dev-agents/shared/reviews/*.md` |

## 目录结构

```text
agentGroup/
├── AGENTS.md                     # Codex 主入口，定义多 agent 协议
├── .dev-agents/
│   ├── ella/PERSONA.md           # 设计探索子代理规范
│   ├── jarvis/PERSONA.md         # 实现执行子代理规范
│   ├── kyle/PERSONA.md           # 审查验证子代理规范
│   └── shared/
│       ├── designs/              # 设计输出
│       ├── reviews/              # 审查报告
│       ├── tasks/                # 任务单
│       └── templates/            # 结构化模板
├── .claude/settings.local.json   # 历史兼容配置
├── skills/                       # 参考技能与外部资料
└── README.md
```

## Codex 协作原则

1. 主线程先判断当前阻塞点，阻塞路径上的工作优先本地处理。
2. 只把可独立完成、可明确交付物的任务派给子代理。
3. 子代理不能互相假设上下文，所有依赖由主线程注入。
4. 并行实现必须先声明写入范围，避免冲突。
5. 测试和验证要跟随改动走，不能把所有验证堆到最后。

## 推荐用法

1. 在 Codex 中打开仓库。
2. 让主线程读取根级 `AGENTS.md`。
3. 用自然语言提出需求，例如：

```text
把登录流程拆成 UI、接口、测试三个并行子任务来做
```

4. 主线程会按 `AGENTS.md` 中的规则判断是否需要派生 `explorer` 或 `worker`。

## 兼容说明

- `skills/` 下的大量资料依然可复用，只是其中部分内容保留了 Claude 术语，现阶段作为参考资产使用。
- 如果后续要继续 Codex 化，可再逐步把 `skills/max`、`skills/jarvis` 里的 Claude 专属命令体系抽离成模型无关的模板。

## 许可证

MIT License
