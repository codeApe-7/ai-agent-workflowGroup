---
description: 派遣 planner agent 输出实施计划，不建 session
argument-hint: <任务描述>
---

# /plan

轻量入口：只派 `planner`，不创建 orchestration session。适合**已知需求、需要拆解步骤**的中小型任务。

## 使用

`/plan $ARGUMENTS`

## 流程

1. 主会话用 `Agent({ subagent_type: "planner", ... })` 派遣 planner，传入：
   - 任务描述（`$ARGUMENTS`）
   - 当前 git 状态摘要（`git status` + `git log --oneline -10`）
2. planner 按 `.claude/agents/planner.md` 的输出格式产出实施计划
3. 主会话把计划呈现给用户，等待 CONFIRM 后再实施
4. **不要**自动开始实施——计划是讨论稿，不是执行令

## 与 `/workflow-start` 的区别

| 维度 | `/plan` | `/workflow-start` |
|------|---------|-------------------|
| 是否建 session | 否 | 是 |
| 适用规模 | 单 agent 输出即够 | 涉及 ≥2 个 worker 协作 |
| 后续流程 | 用户自决，不强制 phase 链 | 8 phase 心智模型 |
| 产物归属 | 直接呈现给用户 | `.orchestration/<session>/<worker>/handoff.md` |

何时升级到 `/workflow-start`：planner 输出后用户判断需要多 worker 协作（如同时要架构决策 + 测试规划），可手动 `node scripts/orchestration/session.cjs init <name>` 升级。
