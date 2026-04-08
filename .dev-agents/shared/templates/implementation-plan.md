# [功能名] 实现计划

<!--
META:
  type: implementation-plan
  date: YYYY-MM-DD
  author: Max
  design: .dev-agents/shared/designs/xxx-design.md
-->

> **执行方式**：推荐使用 subagent-driven-development 技能按任务派遣子代理执行。
> 步骤使用 checkbox (`- [ ]`) 语法追踪进度。

**目标**：[一句话描述构建什么]

**架构**：[2-3 句话描述方案]

**技术栈**：[关键技术/库]

**设计文档**：[链接到 brainstorming 产出的设计文档]

---

## 文件结构

| 操作 | 文件路径 | 职责 |
|------|---------|------|
| 新建 | `path/to/new-file` | [说明] |
| 修改 | `path/to/existing-file` | [说明] |
| 测试 | `tests/path/to/test-file` | [说明] |

---

## 任务 1：[组件/功能名]

**文件：**
- 新建：`exact/path/to/file`
- 测试：`tests/exact/path/to/test`

- [ ] **步骤 1：编写失败测试**

```
[完整测试代码]
```

- [ ] **步骤 2：运行测试确认失败**

运行：`[精确测试命令]`
预期：失败，提示 "[预期错误信息]"

- [ ] **步骤 3：编写最小实现**

```
[完整实现代码]
```

- [ ] **步骤 4：运行测试确认通过**

运行：`[精确测试命令]`
预期：通过

- [ ] **步骤 5：提交**

```bash
git add [文件列表]
git commit -m "feat: [中文描述]"
```

---

## 任务 2：[组件/功能名]

[同上结构...]

---

## 验收标准

- [ ] 所有任务完成
- [ ] 全量测试通过
- [ ] Kyle Stage 1 审查通过（规格符合性）
- [ ] Kyle Stage 2 审查通过（代码质量）
