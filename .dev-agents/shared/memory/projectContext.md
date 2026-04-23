---
last_updated: 2026-04-23
updated_by: initial-bootstrap
version: 1
---

# 项目上下文

> Max 在 design 阶段完成后应更新此文件，记录本次的架构决策。

## 产品愿景

aiGroup 是一个基于 Harness Engineering 理念的 AI 团队协作框架，通过角色分工、强制工作流管道和机械化约束，让 AI Agent 可靠地完成软件开发任务。

## 核心架构决策

| 决策 | 时间 | 上下文 | 放弃的替代方案 |
|------|------|--------|---------------|
| 采用 8 阶段工作流管道 | 初期 | 将"Agent 想到哪做到哪"的无序执行改为状态机驱动 | 自由编排 |
| 文件驱动的 Agent 协作 | 初期 | Agent 间不能直接通信，需中间介质 | 直接 prompt 传递 |
| Harness 传感器机械化检查 | 初期 | 约束换自主性，规则写进 lint 脚本 | 纯文档约定 |
| 采用 Cline Memory Bank 3 件套 | 2026-04-23 | 补强 L4 记忆层，单人场景下足够 | Cline 完整 6 件套；Aider repo-map（需 tree-sitter） |
| 采用扁平 JSONL 观测 | 2026-04-23 | 零依赖 + 单人场景 | OpenTelemetry span 树；LangFuse self-hosted |

## 技术栈

- **运行时**：Claude Code CLI（主）/ Cursor（兼容）
- **语言**：bash（harness 脚本）+ Markdown（文档）+ JSONL（日志）
- **依赖**：coreutils（date/grep/sed/cut/mkdir/wc/find）
- **版本控制**：git

## 关键约束

- CLAUDE.md ≤ 100 行（渐进式披露原则）
- harness 脚本零外部依赖（无 jq / bats）
- Windows Git Bash 兼容
- 向后兼容：现有 5 个 lint 脚本检测逻辑不破坏

## 团队惯例

- 不直接角色扮演，必须用 `Agent(subagent_type)` 派遣子代理
- 设计 → 计划 → 实施 → 测试 严格分离
- 铁律：证据优于断言；流程不可跳过；不确定时先问；门控先行
