# 工作流 Phase 心智模型

> 8 个 phase 是**完整路径上限**，不是强制路径——主会话按任务复杂度和风险**裁剪**。
> 状态真相源：`.orchestration/<session>/<worker>/status.md`。

## 完整路径

```
需求收集 → 需求验证 → 方案设计 → 任务拆解 → 实施开发 → 测试验证 → 文档更新 → 分支收尾
```

按序推进、不可跳步的假设**已废弃**。实际：

- 大部分 bugfix 只需要 planning + development + testing
- 探索性调研不需要任何 phase（直接读文件）
- 架构性任务才需要完整 8 phase

## Phase 清单

| # | Phase | 负责者 | worker 目录（session 下） | 完成标志 |
|---|-------|--------|---------------------------|---------|
| 1 | 需求收集 | 主会话 | `architect/requirements.md` | 需求文档包含目标 / 用户场景 / 成功标准 |
| 2 | 需求验证 | 主会话 | 在 requirements.md 追加验证结论 | 无歧义、无矛盾、用户确认 |
| 3 | 方案设计 | `architect` | `architect/handoff.md`（ADR 格式） | 至少 2 个候选方案 + 推荐理由 |
| 4 | 任务拆解 | `planner` | `planner/handoff.md` | 3–7 个阶段，每个含 agent / 验证命令 |
| 5 | 实施开发 | `tdd-guide`（TDD 路径）/ 主对话直接实现 | `<agent>/handoff.md` 或直接改代码 | 改动文件清单 + 验证证据（typecheck / test） |
| 6 | 测试验证 | `code-reviewer`（安全敏感 + `security-reviewer`、关键路径 + `e2e-runner`） | `code-reviewer/handoff.md` 含 Stage 1 + Stage 2 | 规格符合性 ✓ 代码质量 ✓ |
| 7 | 文档更新 | `doc-updater` 或主会话直接改 | 直接改 `docs/`；session `README.md` 留笔记 | docs/ARCHITECTURE / docs/PROJECT_CONTEXT / API 文档已同步 |
| 8 | 分支收尾 | 主会话 | session `README.md` 总结 | 集成 / PR / 归档 |

> **派遣的具体 agent 选择**见 `docs/rules/agents.md`。
> **按语言栈的实施开发约束**见 `docs/rules/<lang>/`（cpp / golang / java / python / rust / typescript / web 等）。

## 横切关注点（任何 phase 可触发）

| 关注点 | 触发场景 |
|--------|---------|
| 系统化调试 | bug、测试失败、异常行为 |
| 完成前验证 | 任何"完成 / 通过 / 修复"声明前 |
| 熵管理 | 代码库漂移、规则模糊、文档与代码不一致 |

## 裁剪示例

| 任务类型 | 建议 phases | 入口 |
|---------|------------|------|
| 配置项调整 / 笔误修正 | 直接做 | 主对话 |
| 纯文档 | 7 | 主对话或 `doc-updater` |
| 纯 bugfix（单文件，已知根因） | 5 → 6 | `/tdd` + `/review` |
| 有根因待查的 bugfix | 4 → 5 → 6 | `/plan` 然后 `/tdd` |
| 小功能增补 | 3 → 4 → 5 → 6 | `/workflow-start` |
| 重构 | 3 → 4 → 5 → 6 | `/workflow-start` |
| 新模块 / 架构决策 | 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 | `/workflow-start` |

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
