# Jarvis 实现子代理提示模板

先读取 `.dev-agents/jarvis/PERSONA.md`，严格按 Jarvis 角色执行。

## 任务信息

- TASK_ID: {T-NNN}
- TASK_TITLE: {任务标题}
- DEPENDS_ON: {依赖任务 | none}

## 要求

{粘贴计划中该任务的完整文本，包括所有步骤和代码块}

## 上下文

- 项目根目录: {路径}
- 设计文档: {`.dev-agents/shared/designs/T-NNN-xxx.md` 路径}
- 实施计划: {`.dev-agents/shared/tasks/T-NNN-plan.md` 路径}
- 前序任务产物: {列出前序任务修改的文件}

## 必读技能

- `.dev-agents/shared/skills/tdd.md` — 严格遵循红-绿-重构循环
- `.dev-agents/shared/skills/verification.md` — 声称完成前必须运行验证

## WRITE_SCOPE

仅可修改以下文件：
{列出文件路径}

## TEST_COMMAND

```bash
{测试命令}
```

## 执行规则

1. 先读现有代码，理解模式
2. 严格遵循 TDD：先写失败测试 → 验证失败 → 最小实现 → 验证通过 → 重构
3. 每步完成后运行 TEST_COMMAND 验证
4. 不越界修改 WRITE_SCOPE 之外的文件
5. 完成后提交简要变更说明

## 完成后报告

以下列格式之一结束：

### DONE
```
STATUS: DONE
SUMMARY: {实现了什么}
FILES_CHANGED: {修改的文件列表}
TEST_RESULT: {测试通过数/总数}
COMMIT: {提交 SHA}
```

### DONE_WITH_CONCERNS
```
STATUS: DONE_WITH_CONCERNS
SUMMARY: {实现了什么}
CONCERNS: {需要注意的问题}
FILES_CHANGED: {文件列表}
TEST_RESULT: {测试结果}
COMMIT: {提交 SHA}
```

### NEEDS_CONTEXT
```
STATUS: NEEDS_CONTEXT
QUESTION: {需要什么信息}
REASON: {为什么需要}
```

### BLOCKED
```
STATUS: BLOCKED
BLOCKER: {阻塞原因}
ATTEMPTED: {已尝试的方案}
```
