---
description: TDD 流程：派 tdd-guide 走 Red → Green → Refactor，不建 session
argument-hint: <功能描述>
---

# /tdd

轻量 TDD 流程：Red → Green → Refactor。**不建 session**，直接派 `tdd-guide` 端到端处理。

## 使用

`/tdd $ARGUMENTS`

## 流程

`Agent({ subagent_type: "tdd-guide", ... })` 派遣，传入：

- 功能描述（`$ARGUMENTS`）
- 项目栈与现有测试约定
- 任务：先写失败测试 → 写最小实现 → 测试变绿 → 必要时重构

`tdd-guide` 内部完成 Red-Green-Refactor 循环，主会话不需要再分阶段拆派。

主会话验证：让 `tdd-guide` 在最终响应中附 **测试全绿的证据**（命令 + 输出）。

## 后续审查

代码变更落定后，建议再派 `code-reviewer`（必要时加 `security-reviewer`）做双阶段审查。

## 与 `/workflow-start` 的区别

`/tdd` 适合**已知功能边界**的小到中型增量。如果还需要架构决策或跨模块协作，先 `/plan` 或 `/workflow-start`。
