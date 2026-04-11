# aiGroup 详细协议规则

> 本文件包含从 AGENTS.md 下沉的详细规则。AGENTS.md 作为索引指向此处。

## 任务状态机

所有角色任务统一使用以下状态：

- `todo`：已创建，未开始
- `in_progress`：子 agent 正在执行
- `blocked`：因依赖、权限、冲突或上下文缺失而暂停
- `review`：实现完成，等待 Kyle 验收
- `done`：验收通过并已由 Max 汇总

状态转移规则：

1. `todo -> in_progress`：Max 明确派发并附带上下文。
2. `in_progress -> blocked`：子 agent 缺少必要信息或命中冲突规则。
3. `in_progress -> review`：Jarvis 完成实现并提交验证结果。
4. `review -> done`：Kyle 验收通过，Max 完成收口。
5. `blocked -> in_progress`：Max 补齐上下文并重新派发。

## 派发规则

1. 单一职责：设计给 Ella，开发给 Jarvis，审查给 Kyle。
2. 可并行则并行，但并行写入必须拆分 `WRITE_SCOPE`。
3. 默认顺序：Max 分析 → Ella 设计（按需）→ Jarvis 开发 → Kyle 验收 → Max 汇总。
4. 简单问题由 Max 直接回答，不强制派发。
5. 需求模糊时先澄清，不做隐式假设。

## 需求澄清门禁

在进入派发前，Max 必须先判断需求是否可执行：

1. 若目标、范围、验收标准任一项不清晰，必须先向用户提澄清问题。
2. 澄清完成前不得派发给 Ella/Jarvis/Kyle。
3. 澄清结论需写入任务上下文后再进入 `todo -> in_progress`。

## 任务标识与命名规范

任务文档使用统一命名：

- `.dev-agents/shared/tasks/T-001-<slug>.md`
- 设计文档建议引用对应任务 ID，例如：`.dev-agents/shared/designs/T-001-login-ui.md`
- 验收文档建议引用对应任务 ID，例如：`.dev-agents/shared/reviews/T-001-review.md`

每次派发必须包含以下字段：

- `TASK_ID`：任务唯一标识（如 `T-001`）
- `DEPENDS_ON`：依赖任务列表，无依赖写 `none`
- `OWNER`：当前执行角色（Ella/Jarvis/Kyle）
- `DUE`：目标完成时间或 `N/A`

## 上下文传递规则

子 agent 之间不直接通信，全部通过 Max 传递依赖。

- 给 Jarvis 派发时，如已有设计稿，必须附上 `.dev-agents/shared/designs/*.md` 路径。
- 给 Kyle 派发时，必须附上要验收的代码路径和需求依据。
- 并行派发时，每个子 agent 都要获得完整且独立的上下文。

## 角色派发模板

### 通用派发模板

```text
先读取 .dev-agents/{name}/PERSONA.md，严格按该角色执行。
先读取 .dev-agents/shared/skills/{applicable-skill}.md，严格按技能流程执行。

PURPOSE: [最终目标]
TASK: [当前子任务]
TASK_ID: [T-001]
DEPENDS_ON: [none | T-000]
OWNER: [Ella|Jarvis|Kyle]
DUE: [YYYY-MM-DD HH:mm | N/A]
MODE: [auto|write]
CONTEXT: [必须读取的文件和前序产物]
SKILLS: [必须遵循的技能文件路径]
EXPECTED: [交付物与完成标准]
RULES: WRITE_SCOPE=[可修改范围]; TEST_COMMAND=[命令或N/A]; 不能修改范围外文件
```

### 专用子代理提示模板

| 场景 | 模板 | 使用者 |
|------|------|--------|
| Jarvis 执行实施任务 | `.dev-agents/shared/templates/implementer-prompt.md` | Max → Jarvis |
| Kyle 规格合规审查 | `.dev-agents/shared/templates/spec-reviewer-prompt.md` | Max → Kyle |
| Kyle 代码质量审查 | `.dev-agents/shared/templates/code-quality-reviewer-prompt.md` | Max → Kyle |
| 通用子任务 | `.dev-agents/shared/templates/codex-subtask.md` | Max → 任意角色 |

## 并行冲突协议

1. 两个并行任务如果 `WRITE_SCOPE` 重叠，必须立即降级为串行执行。
2. 子 agent 发现潜在写冲突时，不得继续修改，必须上报 Max 并标记 `blocked`。
3. Max 负责重排顺序、拆分范围或合并任务后再继续执行。
4. 未声明 `WRITE_SCOPE` 的任务默认不允许进入并行执行。

## 质量与安全约束

- 需求不清先问清楚再执行
- 禁止自动 git commit/push/merge，除非用户明确授权
- 允许直接执行 `git status`、`git diff`、`git add`
- 提交格式：`<type>: <中文描述>`，type 为 `feat|fix|refactor|docs|style|test|chore|ci`

## 验证纪律

所有角色在声称工作完成前必须遵循 `verification.md` 技能：

1. 确定什么命令能证明声明
2. 运行完整命令
3. 阅读完整输出
4. 核实输出确认声明
5. 此时才能做出声明

禁止使用"应该没问题"、"大概通过了"等未经验证的表述。
