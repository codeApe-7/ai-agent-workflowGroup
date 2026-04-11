# 强制工作流管道

## 管道总览

```
需求澄清 → 实现计划 → 开发执行 → 两阶段审查 → 分支收尾
(brainstorming)  (writing-plans)  (subagent-driven-dev)  (Kyle ×2)  (finishing-branch)
```

## 各环节详细规则

### 1. 需求澄清 + 方案设计 (brainstorming)

| 属性 | 值 |
|------|-----|
| 执行者 | Max |
| 技能路径 | `skills/max/workflow/brainstorming/` |
| 产出位置 | `.dev-agents/shared/designs/` |
| 触发条件 | 任何创造性工作之前（功能、组件、行为修改） |
| 完成标准 | 产出设计文档，包含方案选择理由 |

### 2. 实现计划 (writing-plans)

| 属性 | 值 |
|------|-----|
| 执行者 | Max |
| 技能路径 | `skills/max/workflow/writing-plans/` |
| 产出位置 | `.dev-agents/shared/tasks/` |
| 触发条件 | 有设计方案后、编码前 |
| 完成标准 | 产出实现计划，含文件变更列表和验收条件 |

### 3. UI 设计（可选）

| 属性 | 值 |
|------|-----|
| 执行者 | Ella |
| 触发命令 | `/ella` |
| 产出位置 | `.dev-agents/shared/designs/` |
| 触发条件 | 涉及 UI 变更时 |

### 4. 开发执行 (subagent-driven-development)

| 属性 | 值 |
|------|-----|
| 执行者 | Jarvis（子代理） |
| 技能路径 | `skills/max/workflow/subagent-driven-development/` |
| 产出 | 代码变更 |
| 关键规则 | 每任务一个新 Jarvis 子代理，不并行实施 |
| 状态报告 | DONE / DONE_WITH_CONCERNS / NEEDS_CONTEXT / BLOCKED |

### 5. 两阶段审查

Jarvis 完成开发后，Max **必须**按顺序驱动两轮 Kyle 审查：

**Stage 1：规格符合性**
- 代码是否实现了计划的每条要求？
- 多了什么？少了什么？
- 不通过 → Jarvis 修复 → Kyle 重审 Stage 1

**Stage 2：代码质量**（Stage 1 通过后才能进入）
- 实现是否干净、安全、可维护？
- 不通过 → Jarvis 修复 → Kyle 重审 Stage 2

### 6. 分支收尾 (finishing-a-development-branch)

| 属性 | 值 |
|------|-----|
| 执行者 | Max |
| 技能路径 | `skills/max/workflow/finishing-a-development-branch/` |
| 触发条件 | 所有任务完成并通过两阶段审查 |
| 产出 | 集成/PR/保留 |

## 横切技能

| 技能 | 触发时机 | 路径 |
|------|---------|------|
| systematic-debugging | Bug、测试失败、异常行为 | `skills/max/workflow/systematic-debugging/` |
| verification-before-completion | 声称完成/通过/修复之前 | `skills/max/workflow/verification-before-completion/` |
| entropy-management | 定期维护、漂移检测 | `skills/max/workflow/entropy-management/` |

## 简单任务豁免

以下情况可跳过完整管道，Max 直接回答或直接派遣：

- 纯知识问答
- 单行代码修改
- 配置项调整
- 文档笔误修复

**判断标准**：如果任务涉及 2 个以上文件或需要设计决策，走完整管道。
