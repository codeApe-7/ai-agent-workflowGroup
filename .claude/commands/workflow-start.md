---
description: 启动一个分阶段工作流会话，按需裁剪 phase 并派遣专项 agent
argument-hint: <任务名>
---

## 用法

`/workflow-start <任务名>`

主会话作为唯一的 orchestrator，按以下 phase 推进任务；**每个 phase 按需裁剪**——不是所有任务都要跑完 8 phase（bugfix 可能只需要 planning + development + testing）。

## 启动步骤

1. **确认任务名**——若 `$ARGUMENTS` 为空，向用户询问 slug 化的短名（如 `refactor-auth`、`add-payment`）。
2. **创建 session**：

   ```bash
   node scripts/orchestration/session.cjs init <任务名>
   ```

3. **评估裁剪**：读完需求后明确告诉用户"这个任务会跑哪些 phase，为什么"。

## Phases（按需裁剪）

每个 phase 都按这个格式执行：

- **目标**一句话说明
- **负责 agent**（用 `Agent({ subagent_type: "..." })` 派遣；主会话不亲自实现）
- **worker 目录**：`.orchestration/<session>/<worker>/`
- **产物**：主会话把 agent 响应写入 `handoff.md`，然后 `session.cjs set-status <session> <worker> completed`

| # | Phase | 主导 skill | 负责 agent | worker 目录 |
|---|-------|-----------|-----------|-------------|
| 1 | 需求收集 | `brainstorming`（前段） | 主会话 | `.orchestration/<session>/architect/requirements.md` |
| 2 | 需求验证 | `brainstorming`（中段） | 主会话 | 同上，追加验证结论 |
| 3 | 方案设计 | `brainstorming`（终段） | `architect` | `.orchestration/<session>/architect/handoff.md` |
| 4 | 任务拆解 | `writing-plans` | `planner` | `.orchestration/<session>/planner/handoff.md` |
| 4→5 桥 | 隔离工作区 | `using-git-worktrees` | 主会话执行 git | session `README.md` 记录 worktree 路径 |
| 5 | 实施开发 | subagent 派遣（推荐）/ `executing-plans` | `tdd-guide` 或语言专项 reviewer | `.orchestration/<session>/<agent>/handoff.md` |
| 6a | 审查发起 | `requesting-code-review` | `code-reviewer`（敏感场景加 `security-reviewer` / `e2e-runner` / 语言专项 reviewer） | `.orchestration/<session>/code-reviewer/request.md` |
| 6b | 审查反馈处理 | `receiving-code-review` | 主会话逐条决议 | `.orchestration/<session>/code-reviewer/handoff.md` |
| 7 | 文档更新 | （无强制 skill） | `doc-updater` 或主会话 | 直接改 docs/；在 session README 留笔记 |
| 8 | 分支收尾 | `finishing-a-development-branch` | 主会话 | 在 session README 总结 |

> **人工 checkpoint**：phase 4 末（计划批准）、phase 5 起点（实施模式选择）、phase 8（集成方式 4 选 1 / discard 确认）、phase 6b 审查分歧——orchestrator 暂停等用户决策。详见 `docs/workflow-pipeline.md`。

## 裁剪示例

| 任务类型 | 建议 phases |
|---------|------------|
| 纯 bugfix | 4 → 5 → 6a → 6b |
| 小功能增补 | 3 → 4 → (4→5 桥) → 5 → 6a → 6b |
| 新模块 / 架构决策 | 1 → 2 → 3 → 4 → (4→5 桥) → 5 → 6a → 6b → 7 → 8 |
| 重构 | 3 → 4 → (4→5 桥) → 5 → 6a → 6b |
| 纯文档 | 7（直接做，不用走 session） |

## 状态真相源

唯一真相源是 `.orchestration/<session>/<worker>/status.md`（由 `session.cjs set-status` 维护）。不要引入第二个状态机。

## 横切 skill（任何 phase 可触发）

- `skills/systematic-debugging`（调试时）
- `skills/verification-before-completion`（强制触发：phase 5 末 / 6b 末 / 8 入前）
- `skills/entropy-management`（感知到漂移时）

## 不启动 session 的情况

- 单行修改、配置项调整、文档笔误 —— 直接做
- 纯知识问答、方案讨论 —— 直接答
- 探索性代码调研 —— 直接读文件即可

判断标准：如果**没有 ≥2 个 worker 产物**、也**没有需要事后追溯的证据链**，就不要建 session。

## 命令矩阵（按任务规模选）

| 命令 | 是否建 session | 适用任务 |
|------|---------------|---------|
| 直接对话 | 否 | 笔误、单行修改、知识问答 |
| `/plan <任务>` | 否 | 已知需求，需要拆步骤 |
| `/review` | 否 | 审一下 git diff |
| `/fix-build` | 否 | 修构建/类型错误 |
| `/tdd <功能>` | 否 | TDD 增量开发 |
| `/workflow-start <任务名>` | **是** | 需要 ≥2 个 worker 协作、需追溯证据链 |
| `/init-project <名称>` | 否 | 项目初始化（生成 CLAUDE.md 索引） |

## 参考

- 派遣规则：`docs/rules/agents.md`
- 危险信号：`docs/red-flags.md`
- Phase 心智模型：`docs/workflow-pipeline.md`
