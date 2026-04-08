---
name: writing-plans
owner: Max
description: 有需求规格后、动代码前使用 - 将设计拆解为可执行的细粒度实施计划
---

# 编写实施计划

Max 主导编写实施计划。假设执行工程师（Jarvis）对代码库零上下文、品味存疑。文档化一切：哪些文件需要改、具体代码、测试、如何验证。DRY、YAGNI、TDD、频繁提交。

## 触发条件

- 设计方案经 brainstorming 确认后
- 有明确的需求规格需要拆解实施

## 计划文档头部

每个计划必须以此头部开始：

```markdown
# [功能名] 实施计划

> **子代理执行指引：** 使用 codex-subtask.md 模板为每个任务创建派发文档，由 Max 协调 Jarvis 逐任务实现，Kyle 逐任务验收。

**目标：** [一句话描述要构建什么]

**架构：** [2-3 句话描述方案]

**技术栈：** [关键技术/库]

---
```

## 文件结构

在定义任务前，先映射出要创建或修改的文件以及各自的职责：

- 设计边界清晰、接口明确的单元，每个文件有一个清晰职责
- 优先使用更小、更聚焦的文件，而非臃肿的大文件
- 一起变更的文件应放在一起，按职责拆分而非技术层
- 在现有代码库中遵循已有模式

## 细粒度任务拆分

**每一步是一个动作（2-5 分钟）：**

- "编写失败测试" — 一步
- "运行确认测试失败" — 一步
- "实现最小代码使测试通过" — 一步
- "运行测试确认全部通过" — 一步
- "提交" — 一步

## 任务结构模板

````markdown
### 任务 N: [组件名]

**文件：**
- 创建: `exact/path/to/file.py`
- 修改: `exact/path/to/existing.py:123-145`
- 测试: `tests/exact/path/to/test.py`

**OWNER:** Jarvis
**WRITE_SCOPE:** `exact/path/to/file.py`, `tests/exact/path/to/test.py`

- [ ] **步骤 1: 编写失败测试**

```python
def test_specific_behavior():
    result = function(input)
    assert result == expected
```

- [ ] **步骤 2: 运行测试确认失败**

运行: `pytest tests/path/test.py::test_name -v`
预期: FAIL — "function not defined"

- [ ] **步骤 3: 编写最小实现**

```python
def function(input):
    return expected
```

- [ ] **步骤 4: 运行测试确认通过**

运行: `pytest tests/path/test.py::test_name -v`
预期: PASS

- [ ] **步骤 5: 提交**

```bash
git add tests/path/test.py src/path/file.py
git commit -m "feat: 添加特定功能"
```
````

## 禁止占位符

每一步都必须包含工程师需要的实际内容。以下是**计划失败**——禁止出现：

- "TBD"、"TODO"、"稍后实现"、"填充细节"
- "添加合适的错误处理" / "添加验证" / "处理边界情况"
- "为上述代码写测试"（不附实际测试代码）
- "类似任务 N"（重复代码——执行者可能不按顺序阅读）
- 描述做什么但不展示怎么做的步骤（代码步骤必须有代码块）

## 计划自审

写完计划后，以新鲜眼光对照设计规格检查：

1. **规格覆盖** — 浏览设计文档的每个需求，能否指向一个实现它的任务？列出空白
2. **占位符扫描** — 搜索上述禁止模式，修掉
3. **类型一致性** — 后续任务中的类型、方法签名、属性名是否与早期任务一致？

发现问题就地修复，不需要重新审阅。

## 执行交接

计划保存后，向用户提供执行选择：

**"计划已保存至 `.dev-agents/shared/tasks/T-{NNN}-plan.md`。两种执行方式：**

**1. 子代理驱动（推荐）** — 每个任务派发给 Jarvis 的新子代理，Kyle 逐任务审查

**2. 串行执行** — 在当前会话中由 Jarvis 逐任务执行，批次间设检查点

**选择哪种？"**
