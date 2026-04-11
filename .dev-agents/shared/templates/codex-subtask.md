# Codex 子任务派发表

## 元信息

- TASK_ID: T-{NNN}
- PARENT: {父任务 ID 或 none}
- DEPENDS_ON: {依赖任务 ID 列表，无依赖写 none}
- OWNER: {Ella | Jarvis | Kyle}
- STATUS: {todo | in_progress | blocked | review | done}
- DUE: {YYYY-MM-DD HH:mm | N/A}
- WRITE_SCOPE: {可修改的文件/目录范围}

## 目标

{一句话描述这个子任务要达成的最终效果}

## 上下文

- PERSONA: `.dev-agents/{角色名}/PERSONA.md`
- 前序产物: {列出必须先读取的文件路径}
- 相关技能: {列出需要遵循的 `.dev-agents/shared/skills/*.md`}

## 具体步骤

### 步骤 1: {动作描述}

- 操作: {具体文件操作或命令}
- 预期: {执行后的预期结果}

### 步骤 2: {动作描述}

- 操作: {具体文件操作或命令}
- 预期: {执行后的预期结果}

## 验证标准

- [ ] {验收条件 1}
- [ ] {验收条件 2}
- [ ] {验收条件 3}

## Harness 检查门

提交前必须通过的 Computational Sensors（不可跳过）：

- [ ] WRITE_SCOPE 检查：所有修改文件均在声明范围内
- [ ] Linter/TypeCheck 通过：0 errors
- [ ] 测试通过：全部绿色，无回归
- [ ] 文档格式：新增任务/设计文件符合命名规范

```bash
# 一键检查（如 .harness/ 可用）
bash .harness/run-all.sh
```

## 交付物

| 产物 | 路径 | 说明 |
|------|------|------|
| {类型} | {文件路径} | {简要说明} |

## 风险与约束

- ⚠️ {需要注意的风险点}
- 🚫 {明确的禁止事项}
