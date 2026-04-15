---
name: subagent-driven-development
description: 当有实现计划且任务相互独立时使用。使用 Agent 工具派遣独立子代理执行，每任务完成后进行两阶段审查。
---

# 子代理驱动开发

使用 **Agent 工具** 按实现计划逐任务派遣新的隔离子代理（Jarvis）执行，每个任务完成后由审查子代理（Kyle）进行两阶段审查。

## 关键概念：真正的子代理 vs 角色切换

```
❌ 错误方式（角色切换）：
   Max 在当前对话里"假装变成 Jarvis"，读 PERSONA.md 然后开始写代码
   → 共享上下文、无隔离、Max 的项目管理视角被污染

✅ 正确方式（Agent 工具派遣）：
   Max 调用 Agent 工具 → 创建独立子代理 → 子代理有自己的上下文
   → 子代理完成后返回结果给 Max → Max 继续协调
```

**铁律：Max 自己绝不写代码。所有开发/审查工作必须通过 Agent 工具委派给隔离的子代理。**

## 铁律

```
1. 使用 Agent 工具派遣，不是角色切换。Max 不写代码。
2. 每个任务一个全新子代理，禁止复用上下文
3. 两阶段审查顺序不可颠倒：先规格符合性，再代码质量
4. 审查不通过 = 修复 + 重新审查，不得跳过
5. 禁止并行派遣多个实现子代理（避免冲突）
6. 不让子代理自己读计划文件，由 Max 提取任务全文注入 prompt
```

## 流程

```
读取计划 → 提取所有任务全文 → 创建任务追踪

  ┌──────────── 每个任务循环 ────────────┐
  │                                       │
  │  Agent 工具派遣 Jarvis（含完整任务）   │
  │         ↓                             │
  │  Jarvis 实现、测试、提交、自检         │
  │         ↓                             │
  │  Agent 工具派遣 Kyle：规格符合性审查   │
  │    ├─ 不通过 → Agent 派遣 Jarvis 修复 │
  │    └─ 通过 ↓                          │
  │  Agent 工具派遣 Kyle：代码质量审查     │
  │    ├─ 不通过 → Agent 派遣 Jarvis 修复 │
  │    └─ 通过 ↓                          │
  │  标记任务完成                          │
  │                                       │
  └───────────────────────────────────────┘

所有任务完成 → 推进到 testing 阶段
```

## 派遣 Jarvis 实现子代理 — 具体操作

Max 必须使用 **Agent 工具** 派遣 Jarvis。以下是具体的调用方式：

### 步骤 1：准备 prompt

从实现计划中提取当前任务的全文，组装为子代理的 prompt：

```
prompt 模板：

先读取 `.dev-agents/jarvis/PERSONA.md` 了解你的角色。

你的技能资源在 `skills/jarvis/` 下，需要时读取对应的 SKILL.md。
工作流技能在 `skills/max/workflow/` 下，遇到 Bug 使用 systematic-debugging，
完成任务前使用 verification-before-completion。

## 前置门控
```bash
bash scripts/harness/workflow-state.sh gate development
```

## 任务
[此处粘贴从实现计划中提取的完整任务文本，包含：
- 要修改的文件和路径
- 完整代码
- 测试代码
- 验证命令和预期输出]

## 上下文
- 该任务在整体计划中的位置：第 N/M 个任务
- 设计文档路径：.dev-agents/shared/designs/YYYY-MM-DD-xxx-design.md
- 实现计划路径：.dev-agents/shared/tasks/YYYY-MM-DD-xxx-plan.md

## 工作规范
- 遵循 TDD：先写失败测试 → 确认失败 → 写最小实现 → 确认通过 → 提交
- 参照实现计划中的验收条件逐项确认

## 完成后报告
返回状态：DONE / DONE_WITH_CONCERNS / NEEDS_CONTEXT / BLOCKED
包含：变更文件列表、验证证据、验收条件对照、风险点
```

### 步骤 2：调用 Agent 工具

```
Agent({
  description: "Jarvis: [任务简述]",
  prompt: "[上面组装好的 prompt]"
})
```

### 步骤 3：处理返回结果

子代理完成后会返回结果给 Max。Max 根据状态处理：

| 状态 | Max 的处理方式 |
|------|-------------|
| **DONE** | 进入审查：Agent 工具派遣 Kyle |
| **DONE_WITH_CONCERNS** | 先评估疑虑，再决定是否审查 |
| **NEEDS_CONTEXT** | 补充上下文，重新 Agent 派遣 |
| **BLOCKED** | 评估阻塞原因（见下文） |

### BLOCKED 处理

1. 上下文问题 → 补充上下文，重新派遣
2. 任务太大 → 拆分为更小的任务
3. 计划有问题 → 上报给用户讨论
4. **永远不要**忽略阻塞或强制重试

## 派遣 Kyle 审查子代理 — 具体操作

### Stage 1：规格符合性审查

```
Agent({
  description: "Kyle: Stage 1 规格审查 - [功能名]",
  prompt: "
先读取 `.dev-agents/kyle/PERSONA.md` 了解你的角色。

## 前置门控
```bash
bash scripts/harness/workflow-state.sh gate testing
```

## Stage 1：规格符合性审查

审查基准（实现计划规格）：
[此处粘贴实现计划中该任务的完整规格]

Jarvis 修改的文件：
[此处列出 Jarvis 报告中的变更文件列表]

设计文档路径：.dev-agents/shared/designs/YYYY-MM-DD-xxx-design.md

### 检查要求
- 代码是否实现了计划的每条要求？
- 多做了什么？（未要求的功能 = 需要移除）
- 少做了什么？（遗漏的需求 = 需要补充）

## 输出
审查报告保存到 `.dev-agents/shared/reviews/YYYY-MM-DD-xxx-review.md`
结论：通过 / 不通过（附具体问题清单）
  "
})
```

### Stage 2：代码质量审查（Stage 1 通过后）

```
Agent({
  description: "Kyle: Stage 2 质量审查 - [功能名]",
  prompt: "
先读取 `.dev-agents/kyle/PERSONA.md` 了解你的角色。

## Stage 2：代码质量审查（Stage 1 已通过）

代码变更的 git diff：
```bash
git diff HEAD~1
```

### 检查要求
- 代码是否干净、可读、可维护？
- 有无安全隐患？
- 有无性能问题？
- 测试是否充分？
- 命名是否清晰？

## 输出
在 `.dev-agents/shared/reviews/` 的审查报告中追加 Stage 2 结论
结论：通过 / 不通过（附问题清单和修复建议）
  "
})
```

## 审查不通过的修复循环

```
Kyle Stage 1 不通过
  → Max 提取问题清单
  → Agent 派遣新的 Jarvis 子代理修复
  → Agent 派遣新的 Kyle 重审 Stage 1

Kyle Stage 2 不通过
  → Max 提取问题清单
  → Agent 派遣新的 Jarvis 子代理修复
  → Agent 派遣新的 Kyle 重审 Stage 2
```

**每次修复和重审都是新的 Agent 调用**，不复用之前的子代理。

## Red Flags — 停下来

| 信号 | 行动 |
|------|------|
| Max 自己开始写代码 | 停，使用 Agent 工具派遣 Jarvis |
| 在当前对话中"变成 Jarvis" | 停，这是角色切换不是子代理 |
| 在 Stage 1 通过前开始 Stage 2 | 停，先完成规格审查 |
| 审查发现问题但跳过了 | 停，Jarvis 修复后重审 |
| 同时派遣多个实现子代理 | 停，一次只能一个 |
| Jarvis 报告 BLOCKED 但继续强推 | 停，评估阻塞原因 |
| 没有实现计划就开始执行 | 停，先完成 writing-plans |

## 关联技能

- **writing-plans** — 产出实现计划（本技能的输入）
- **testing** — 测试验证阶段（本技能完成后的下一阶段）
- **verification-before-completion** — Jarvis 每个任务完成时必须验证
- **systematic-debugging** — Jarvis 遇到 Bug 时使用
