# 工作流 Phase 心智模型

> 8 个 phase 是**完整路径上限**，不是强制路径——主会话按任务复杂度和风险**裁剪**。
> 状态真相源：`.orchestration/<session>/<worker>/status.md`。

## 完整路径

```
需求收集 → 需求验证 → 方案设计 → 任务拆解 → [隔离工作区] → 实施开发
       → 审查发起 → 审查反馈处理 → 文档更新 → 分支收尾
```

按序推进、不可跳步的假设**已废弃**。实际：

- 大部分 bugfix 只需要 planning + development + testing
- 探索性调研不需要任何 phase（直接读文件）
- 架构性任务才需要完整路径

## Phase 清单

| # | Phase | 主导 skill | 负责者 | worker 目录（session 下） | 完成标志 |
|---|-------|-----------|--------|---------------------------|---------|
| 1 | 需求收集 | `brainstorming`（前段） | 主会话 | `architect/requirements.md` | 需求文档包含目标 / 用户场景 / 成功标准 |
| 2 | 需求验证 | `brainstorming`（中段：challenge） | 主会话 | 在 requirements.md 追加验证结论 | 无歧义、无矛盾、用户确认 |
| 3 | 方案设计 | `brainstorming`（终段：spec 锁定） | `architect` | `architect/handoff.md`（ADR 格式） | 至少 2 个候选方案 + 推荐理由 |
| 4 | 任务拆解 | `writing-plans` | `planner` | `planner/handoff.md` | 3–7 个阶段，每个含 agent / 验证命令 |
| 4→5 桥 | 隔离工作区 | `using-git-worktrees` | 主会话执行 git | session `README.md` 记录 worktree 路径 | worktree 创建、依赖装好、测试基线通过 |
| 5 | 实施开发 | subagent 派遣（推荐）/ `executing-plans` | `tdd-guide`（TDD 路径）/ 语言专项 reviewer | `<agent>/handoff.md` 或直接改代码 | 改动文件清单 + 验证证据（typecheck / test） |
| 6a | 审查发起 | `requesting-code-review` | 主会话向 `code-reviewer` 派遣（敏感场景加 `security-reviewer`、关键路径加 `e2e-runner`、按栈加语言专项 reviewer） | `code-reviewer/request.md` | 审查范围 / 验收点 / 关注项清单完整 |
| 6b | 审查反馈处理 | `receiving-code-review` | 主会话逐条决议 | `code-reviewer/handoff.md`（含决议） | 每条反馈有"采纳/反驳/记录"决议且证据闭环（Stage 1 规格 ✓ Stage 2 代码质量 ✓） |
| 7 | 文档更新 | （无强制 skill） | `doc-updater` 或主会话直接改 | 直接改 `docs/`；session `README.md` 留笔记 | docs/ARCHITECTURE / docs/PROJECT_CONTEXT / API 文档已同步 |
| 8 | 分支收尾 | `finishing-a-development-branch` | 主会话 | session `README.md` 总结 | 集成 / PR / 归档 |

> **派遣的具体 agent 选择**见 `docs/rules/agents.md`。
> **按语言栈的实施开发约束**见 `docs/rules/<lang>/`（cpp / golang / java / python / rust / typescript / web 等）。

## 横切关注点（任何 phase 可触发）

| 关注点 | 主导 skill | 触发场景 |
|--------|-----------|---------|
| 系统化调试 | `systematic-debugging` | bug、测试失败、异常行为 |
| 完成前验证 | `verification-before-completion` | **强制触发点**：phase 5 末（声称实现完成前）、phase 6b 末（声称审查处理完前）、phase 8 进入前 |
| 熵管理 | `entropy-management` | 代码库漂移、规则模糊、文档与代码不一致 |

## 裁剪示例

| 任务类型 | 建议 phases | 入口 |
|---------|------------|------|
| 配置项调整 / 笔误修正 | 直接做 | 主对话 |
| 纯文档 | 7 | 主对话或 `doc-updater` |
| 纯 bugfix（单文件，已知根因） | 5 → 6a → 6b | `/tdd` + `/review` |
| 有根因待查的 bugfix | 4 → 5 → 6a → 6b | `/plan` 然后 `/tdd` |
| 小功能增补 | 3 → 4 → (4→5 桥) → 5 → 6a → 6b | `/workflow-start` |
| 重构 | 3 → 4 → (4→5 桥) → 5 → 6a → 6b | `/workflow-start` |
| 新模块 / 架构决策 | 1 → 2 → 3 → 4 → (4→5 桥) → 5 → 6a → 6b → 7 → 8 | `/workflow-start` |

> 跳过"4→5 桥"= 在主仓库 working tree 直接改。仅在改动 ≤ 单文件且无并行任务风险时可省。

## 人工 checkpoint（orchestrator 不替用户做的决定）

`/workflow-start` 是命令驱动的自动 orchestrator，但以下决策点**必须保留人工**——这些位置涉及不可逆操作或契约错误向后传播，自动跳过会丢失安全网。

| Checkpoint | 触发位置 | 暂停原因 | orchestrator 行为 |
|-----------|---------|---------|-----------------|
| 计划批准 | phase 4 末（`writing-plans` 产出后） | 计划是后续所有 phase 的契约，错误会扩散到实施和审查 | 暂停，向用户展示 plan 摘要，等待"批准 / 修订"回应 |
| 实施模式选择 | phase 5 起点 | subagent 派遣 vs `executing-plans` 影响代价、速度、上下文清洁度 | 暂停 1 次询问；用户未指定时默认 subagent 派遣并明确告知 |
| 集成方式选择 | phase 8（`finishing-a-development-branch` Step 3） | merge / PR / keep / discard 是不可逆的对外操作 | 暂停展示 4 选项，不替用户选 |
| Discard 确认 | phase 8 选项 4 | 删除分支 + worktree 不可恢复 | 必须用户键入 `discard` 字面量；其他输入一律视为放弃 |
| 审查反馈分歧 | phase 6b（`receiving-code-review` 中） | reviewer 与实施 agent 对同一问题给出冲突结论时 | 暂停，把分歧摘要呈给用户决议 |

**自动决策**（不打断用户）：phase 间流转、handoff 文件生成、`status.md` 推进、worktree 路径分配、`session.cjs` 状态写入、phase 内的子 agent 派遣。

## Session 存在条件

建 session 的判断标准：

- 涉及 2+ 文件变更
- 需要架构决策或跨模块协作
- 有明确验收标准、需追溯证据链
- ≥2 个 worker 产生 handoff

不满足以上条件 → 不建 session。直接走主对话或单 agent 轻量命令（`/plan` / `/review` / `/fix-build` / `/tdd`）。

主会话识别出复杂任务时，应**建议**启动 session 而非强制。

## 与其他文档的关系

| 文档 | 关系 |
|------|------|
| `docs/rules/agents.md` | 派遣规则（什么时候派谁） |
| `docs/rules/<lang>/` | 实施开发 phase 的语言专项约束 |
| `docs/red-flags.md` | 任何 phase 都需监测的危险信号 |
| `docs/PROJECT_CONTEXT.md` | phase 8 文档更新的产物归属 |
| `docs/ARCHITECTURE.md` | phase 3 方案设计 / phase 7 文档更新的产物归属 |
| `.orchestration/README.md` | session/worker 三件套协议 |
