# 强制工作流管道

## 管道总览

```
需求收集 → 需求验证 → 方案设计 → 任务拆解 → 实施开发 → 测试验证 → 文档更新 → 分支收尾
(brainstorming) (validation) (design) (planning) (development) (testing) (documentation) (finishing)
```

状态机命令：`bash scripts/harness/workflow-state.sh {init|advance|gate|status|reset|exempt}`

## 各环节详细规则

### 1. 需求收集 (brainstorming)

| 属性 | 值 |
|------|-----|
| 执行者 | Max |
| 技能路径 | `skills/max/workflow/brainstorming/` |
| 产出位置 | `.dev-agents/shared/designs/` |
| 触发条件 | 任何创造性工作之前（功能、组件、行为修改） |
| 完成标准 | 产出需求文档，包含功能需求、用户场景、约束条件 |
| 推进门控 | `.dev-agents/shared/designs/` 中有需求文档 |

**聚焦**：收集和分析功能需求。通过协作对话理解用户意图，明确需要做什么、为谁做、成功标准是什么。此阶段**不做**方案设计。

### 2. 需求验证 (validation)

| 属性 | 值 |
|------|-----|
| 执行者 | Max |
| 技能路径 | `skills/max/workflow/requirement-validation/` |
| 产出位置 | 在需求文档上追加验证结论 |
| 触发条件 | 需求收集完成后 |
| 完成标准 | 需求无歧义、完整、可行，用户确认 |
| 推进门控 | 需求文档存在且通过验证 |

**聚焦**：验证需求的完整性和可行性。逐条审视需求，检查歧义、矛盾、遗漏、技术可行性。

### 3. 方案设计 (design)

| 属性 | 值 |
|------|-----|
| 执行者 | Max（UI 相关可派遣 Ella） |
| 技能路径 | `skills/max/workflow/solution-design/` |
| 产出位置 | `.dev-agents/shared/designs/` |
| 触发条件 | 需求验证通过后 |
| 完成标准 | 产出技术方案文档，包含架构、方案对比、技术选型 |
| 推进门控 | 设计文档包含方案/架构/技术栈关键词 |

**聚焦**：设计技术方案和架构。提出 2-3 种方案及取舍，选定方案，定义架构、数据流、接口。

### 4. 任务拆解 (planning)

| 属性 | 值 |
|------|-----|
| 执行者 | Max |
| 技能路径 | `skills/max/workflow/writing-plans/` |
| 产出位置 | `.dev-agents/shared/tasks/` |
| 触发条件 | 有设计方案后、编码前 |
| 完成标准 | 产出实现计划，含文件变更列表、TDD 步骤、验收条件 |
| 推进门控 | `.dev-agents/shared/tasks/` 中有实现计划 |

**聚焦**：将需求拆解为可执行任务。每个任务 2-5 分钟粒度，包含精确文件路径、完整代码、验证命令。

### 5. 实施开发 (development)

| 属性 | 值 |
|------|-----|
| 执行者 | Jarvis（子代理） |
| 技能路径 | `skills/max/workflow/subagent-driven-development/` |
| 产出 | 代码变更 |
| 关键规则 | 每任务一个新 Jarvis 子代理，不并行实施 |
| 状态报告 | DONE / DONE_WITH_CONCERNS / NEEDS_CONTEXT / BLOCKED |
| 推进门控 | 无强制检查（由测试验证阶段覆盖） |

**聚焦**：按照任务进行开发。严格遵循 TDD，先写失败测试再写实现。

### 6. 测试验证 (testing)

| 属性 | 值 |
|------|-----|
| 执行者 | Kyle（子代理） |
| 技能路径 | `skills/max/workflow/testing/` |
| 产出位置 | `.dev-agents/shared/reviews/` |
| 触发条件 | 开发完成后 |
| 完成标准 | 测试计划编写、测试用例执行、两阶段审查通过 |
| 推进门控 | `.dev-agents/shared/reviews/` 中有审查报告 |

**聚焦**：编写和执行测试用例。包含三个子步骤：

1. **测试计划**：基于实现计划编写测试用例（功能测试、边界测试、异常测试）
2. **Stage 1 审查（规格符合性）**：代码是否实现了计划的每条要求
3. **Stage 2 审查（代码质量）**：代码是否干净、安全、可维护

Stage 1 不通过 → Jarvis 修复 → 重审。Stage 2 不通过 → Jarvis 修复 → 重审。

### 7. 文档更新 (documentation)

| 属性 | 值 |
|------|-----|
| 执行者 | Max（可派遣 Jarvis 协助） |
| 技能路径 | `skills/max/workflow/documentation/` |
| 产出 | 更新后的文档 |
| 触发条件 | 测试验证通过后 |
| 完成标准 | 相关文档已更新，无文档与代码不一致 |
| 推进门控 | 无强制检查（由 Agent 自行判断） |

**聚焦**：更新相关文档。包括 API 文档、README、ARCHITECTURE、模块文档、注释等。

### 8. 分支收尾 (finishing)

| 属性 | 值 |
|------|-----|
| 执行者 | Max |
| 技能路径 | `skills/max/workflow/finishing-a-development-branch/` |
| 触发条件 | 文档更新完成后 |
| 产出 | 集成/PR/归档 |

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

豁免时运行：`bash scripts/harness/workflow-state.sh exempt <原因>`
