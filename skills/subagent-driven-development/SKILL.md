---
name: subagent-driven-development
description: 当有实现计划且任务相互独立时使用。使用 Agent 工具派遣独立子代理执行，每任务完成后进行两阶段审查。
---

# 子代理驱动开发

按实现计划逐任务派遣独立子代理执行（实现 + 测试），每任务完成后由 `code-reviewer` 执行两阶段审查。

## 关键概念：真正的子代理 vs 角色切换

```
❌ 错误方式（角色切换）：
   主会话在当前对话里"假装变成实现 agent"然后开始写代码
   → 共享上下文、无隔离、协调视角被污染

✅ 正确方式（Agent 工具派遣）：
   主会话调用 Agent({ subagent_type: "tdd-guide", ... }) → 创建独立子代理
   → 子代理有自己的上下文与工具权限
   → 子代理完成后返回结果 → 主会话继续协调
```

**铁律：主会话不亲自写代码 / 做审查 / 跑测试。所有这些工作通过 Agent 工具委派给隔离的子代理（详见 `.claude/agents/`）。**

## 铁律

1. 使用 Agent 工具派遣，不是角色切换
2. 每个任务一个全新子代理，禁止复用上下文
3. 两阶段审查顺序不可颠倒：先规格符合性（Stage 1），再代码质量（Stage 2）
4. 审查不通过 = 修复 + 重审，不得跳过
5. 禁止并行派遣多个实现子代理（避免冲突）
6. 不让子代理自己读计划文件，由主会话提取任务全文注入 prompt

## 流程

```
读取计划 → 提取所有任务全文 → 创建任务追踪

  ┌──────────── 每个任务循环 ────────────┐
  │                                       │
  │  Agent 派遣实现 agent（含完整任务）   │
  │         ↓                             │
  │  实现 agent：实现 + 测试 + 自检       │
  │         ↓                             │
  │  Agent 派遣 code-reviewer             │
  │  （单次响应输出 Stage 1 + Stage 2）   │
  │    ├─ Stage 1 不通过 → 派遣实现修复  │
  │    └─ Stage 1 通过 ↓                  │
  │    ├─ Stage 2 不通过 → 派遣实现修复  │
  │    └─ Stage 2 通过 ↓                  │
  │  标记任务完成                          │
  │                                       │
  └───────────────────────────────────────┘

所有任务完成 → 进入测试 / 文档更新 phase
```

## 派遣实现子代理

按任务类型选择 agent：

| 任务类型 | 派遣 |
|---------|------|
| TDD 流程（先写失败测试）| `tdd-guide` |
| 构建 / 类型 / 依赖错误 | `build-error-resolver` |
| 死代码清理 / 重构 | `refactor-cleaner` |
| 文档更新 | `doc-updater` |
| 关键浏览器路径 | `e2e-runner` |
| 其他实现工作 | 主对话直接做（不需要切 agent） |

### Prompt 模板

agent 身份 / 工具 / 输出格式已在 `.claude/agents/<name>.md` frontmatter 注入，prompt 只写**任务**和**上下文**：

```
## 任务
[从实现计划中粘贴该任务全文：要改的文件 / 完整代码 / 测试 / 验证命令]

## 上下文
- 该任务在整体计划中的位置：第 N/M 个任务
- session：<session 名>
- 设计文档路径：.orchestration/<session>/architect/handoff.md
- 实现计划路径：.orchestration/<session>/planner/handoff.md

## 验收
- 测试全绿（命令 + 输出）
- 改动文件在 handoff 中列出
```

### 处理返回

| 状态 | 主会话动作 |
|------|-----------|
| **DONE** | 派 `code-reviewer` 审查 |
| **DONE_WITH_CONCERNS** | 先评估疑虑再决定 |
| **NEEDS_CONTEXT** | 补上下文，重新派遣 |
| **BLOCKED** | 评估阻塞原因（见下） |

**BLOCKED 处理**：

1. 上下文不足 → 补 + 重派
2. 任务太大 → 拆小再派
3. 计划本身错 → 回到 `planner` 修计划
4. **永远不要**忽略阻塞或强推

## 派遣审查子代理

### `code-reviewer`（双阶段一次完成）

agent 在 `.claude/agents/code-reviewer.md` 已规定输出格式包含 Stage 1 + Stage 2，prompt 只写**审查基准**和**对象**：

```
Agent({
  subagent_type: "code-reviewer",
  description: "Code review: [功能名]",
  prompt: `
## 审查基准（Stage 1 用）
[粘贴实现计划中该任务的完整规格]

## 审查对象
- 实现 agent 报告的变更文件清单
- session：<session 名>
- 设计文档：.orchestration/<session>/architect/handoff.md

主会话会把你的响应抄进 .orchestration/<session>/code-reviewer/handoff.md。
按 agent frontmatter 规定的格式输出 Stage 1 + Stage 2 + Verdict。
  `
})
```

### 安全敏感时追加 `security-reviewer`

涉及 auth / 支付 / PII / 外部输入 / 加密时，追加：

```
Agent({
  subagent_type: "security-reviewer",
  description: "Security review: [功能名]",
  prompt: "[审查范围 + git diff 引用]"
})
```

## 审查不通过的修复循环

```
Stage 1 不通过
  → 主会话提取问题清单
  → Agent 派遣实现 agent 修复
  → Agent 派遣新 code-reviewer 重审

Stage 2 不通过
  → 同上
```

**每次修复和重审都是新的 Agent 调用**——不复用之前的子代理。

## Red Flags — 停下来

| 信号 | 行动 |
|------|------|
| 主会话自己开始写代码 | 停，派遣实现 agent |
| "在当前对话中变成 X agent" | 停，这是角色切换不是子代理 |
| Stage 1 通过前开始 Stage 2 | 停，按 agent 输出格式顺序 |
| 审查发现问题但跳过 | 停，修复后重审 |
| 同时派遣多个实现子代理 | 停，一次只能一个 |
| 实现 agent 报告 BLOCKED 但继续强推 | 停，评估阻塞原因 |
| 没有实现计划就开始执行 | 停，先 `planner` 出计划 |

## 关联

- 输入：`writing-plans` / `planner` 产出的实现计划
- 之后：测试验证 / 文档更新 phase
- 横切：`verification-before-completion` / `systematic-debugging`
