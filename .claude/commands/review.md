---
description: 派遣 code-reviewer agent 审查当前改动，不建 session
argument-hint: [文件 / 范围；省略则审 git diff]
---

# /review

轻量入口：只派 `code-reviewer`，输出双阶段审查（Stage 1 规格符合性 + Stage 2 代码质量）。

## 使用

```
/review                 # 审 git diff（HEAD vs working）
/review src/auth/       # 审指定路径
/review HEAD~3..HEAD    # 审某个 commit 区间
```

## 流程

1. 主会话识别审查范围（`$ARGUMENTS` 或 `git diff --name-only HEAD`）
2. `Agent({ subagent_type: "code-reviewer", ... })` 派遣，传入：
   - 范围内变更文件清单
   - 计划/PRD（如有）作为 Stage 1 基准
3. code-reviewer 按 `.claude/agents/code-reviewer.md` 的输出格式产出 **Stage 1 + Stage 2** 报告
4. 主会话呈现报告；安全敏感（auth/支付/PII）发现时建议追加派 `security-reviewer`

## 与 `/workflow-start` 的区别

`/review` 是"审一下"——不写 handoff、不进 session。如果是工作流中的 phase 6（测试验证），用 `/workflow-start` 走完整流程，code-reviewer 的产物会写入 `.orchestration/<session>/code-reviewer/handoff.md`。
