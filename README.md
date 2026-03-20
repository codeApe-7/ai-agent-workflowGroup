# agentGroup - 角色化多 Agent 协作框架（Codex）

> 主线程扮演 Max，子 agent 分别扮演 Ella、Jarvis、Kyle，按角色协作完成设计、开发、验收闭环。

## 核心变化

这个仓库采用单入口协议：

- `AGENTS.md`：同时定义主线程角色（Max）与子角色派发规则
- `.dev-agents/*/PERSONA.md`：定义每个子角色的执行规范

## 架构角色

| 人物角色 | 在 Codex 中的形态 | 负责内容 | 典型产物 |
|------|------------------|---------|---------|
| Max（主线程） | 当前会话 | 需求分析、任务拆解、调度和汇总 | 任务计划、最终结论 |
| Ella | 子 agent | UI/UX 设计与交互方案 | `.dev-agents/shared/designs/*.md` |
| Jarvis | 子 agent | 前后端实现和问题修复 | 代码改动与验证结果 |
| Kyle | 子 agent | 审查、验收、安全检查 | `.dev-agents/shared/reviews/*.md` |

## 目录结构

```text
agentGroup/
├── AGENTS.md                     # Max 主角色 + Codex 角色派发协议
├── .dev-agents/
│   ├── ella/PERSONA.md           # Ella 角色规范
│   ├── jarvis/PERSONA.md         # Jarvis 角色规范
│   ├── kyle/PERSONA.md           # Kyle 角色规范
│   └── shared/
│       ├── designs/              # 设计输出
│       ├── reviews/              # 审查报告
│       ├── tasks/                # 任务单
│       └── templates/            # 结构化模板
├── skills/                       # 参考技能与外部资料
└── README.md
```

## Codex 协作原则

1. 主线程始终是 Max，不切换为子角色。
2. 每个子 agent 只扮演一个人物角色，不混角。
3. 子 agent 之间不直接通信，统一由 Max 传递上下文。
4. 并行开发前必须声明 `WRITE_SCOPE`，避免冲突。
5. 设计、开发、验收尽量形成闭环，不跳过 Kyle 验收。

## 推荐用法

1. 在 Codex 中打开仓库。
2. 让主线程先读取 `AGENTS.md`，确认 Max 角色与派发规则。
3. 用自然语言提出需求，例如：

```text
把登录流程拆成 UI、接口、测试三个并行子任务来做
```

3. 主线程会按 `AGENTS.md` 中的规则判断是否需要派生 Ella、Jarvis、Kyle 对应的子 agent。

## 兼容说明

- `skills/` 下资料可继续复用；其中历史术语内容仅作为参考，不影响当前角色化主流程。
- 如需进一步统一，可把 `skills/max` 与 `skills/jarvis` 的术语逐步映射到 Codex 工具语义。

## 许可证

MIT License
