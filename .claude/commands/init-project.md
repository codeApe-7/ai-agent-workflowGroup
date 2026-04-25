---
description: 初始化项目 AI 上下文 — 根 CLAUDE.md 只做导航，详细内容进 docs/
allowed-tools: Read(**), Write(CLAUDE.md, **/CLAUDE.md, docs/PROJECT_CONTEXT.md, docs/ARCHITECTURE.md)
argument-hint: <项目摘要或名称>
---

## 用法

`/init-project <项目摘要或名称>`

## 落盘策略（铁律）

**根 `CLAUDE.md` 永远只是导航**——一张索引表，记录每份详细文档的位置。≤100 行。**严禁**写入：项目愿景、架构图、模块清单、规范条目、Changelog 等任何"项目内容"。

详细内容按主题分散到 `docs/` 下：

| 主题 | 落盘文件 |
|------|----------|
| 项目愿景 / 模块索引 / Mermaid 结构图 / 运行与开发 / 测试策略 / 变更记录 | `docs/PROJECT_CONTEXT.md` |
| 架构总览（组件、数据流、跨切关注点、技术选型） | `docs/ARCHITECTURE.md` |
| 编码规范 / Git / 测试 / 安全 / 性能 / Hooks 强制规则 | `docs/rules/<topic>.md` |
| 模块级详细信息（入口、接口、依赖、数据模型、FAQ） | `<module>/CLAUDE.md` |

**根 CLAUDE.md 的唯一形态**（无论是否全新项目）：

```markdown
# CLAUDE.md

> 项目 AI 上下文导航。详情见 `docs/`。

## 项目快照
- 名称: <name>
- 主语言 / 栈: <...>
- 模块数: <n>

## 知识库地图

| 需要了解 | 查阅 |
|---------|------|
| 项目愿景与模块索引 | `docs/PROJECT_CONTEXT.md` |
| 架构总览 | `docs/ARCHITECTURE.md` |
| 强制规则 | `docs/rules/` |
| 派遣矩阵（若使用 aiGroup 框架）| `docs/rules/agents.md` |
| 各模块详细信息 | `<module>/CLAUDE.md` |

## 模块入口

| 模块 | 路径 | 一句话职责 |
|------|------|-----------|
| ... | ... | ... |
```

## Phases

### 1. 时间戳

派遣 `get-current-datetime` 获取当前 UTC 时间戳。

### 2. 调度 init-architect

```
Agent({
  subagent_type: "init-architect",
  project_summary: $ARGUMENTS,
  current_timestamp: <step 1>
})
```

`init-architect` 负责：

- 自适应三档扫描（全仓清点 → 模块优先 → 深度补捞），自决读取深度与断点续扫
- 写入 `docs/PROJECT_CONTEXT.md`（项目愿景、Mermaid 结构图、模块索引、运行/测试策略、Changelog）
- 写入 `docs/ARCHITECTURE.md`（架构总览：组件、数据流、跨切关注点）
- 写入各模块 `<module>/CLAUDE.md`（顶部带相对路径面包屑）
- 写入 / 更新根 `CLAUDE.md` 为**纯导航形态**——若已存在内容是项目内容（非导航）则保留不动，新内容并入 `docs/PROJECT_CONTEXT.md`
- 写入 `.claude/index.json`（扫描元数据 + 覆盖率 + 缺口清单）

### 3. 摘要回报

从 agent 返回体中提取并打印：

- 根 `CLAUDE.md` 状态：新建（导航模板）/ 已存在（保留不动）
- `docs/PROJECT_CONTEXT.md` 是否创建/更新（含主要章节）
- `docs/ARCHITECTURE.md` 是否创建/更新
- 识别的模块数量与路径
- 每个模块 `CLAUDE.md` 的生成/更新情况
- ✨ Mermaid 结构图与面包屑导航是否生成
- 覆盖率与主要缺口
- 若被上限截断：列出下一步推荐补扫路径

## 硬约束（由 init-architect 执行）

- 只读/写文档与 `.claude/index.json`，不改源代码
- 默认忽略 `node_modules/`、`.git/`、构建产物、二进制
- **根 `CLAUDE.md` 只能是导航形态**；若现有内容非导航（含项目愿景 / 架构 / 模块详情等），保留不动并把新内容追加到 `docs/PROJECT_CONTEXT.md`
- 时间戳来自 step 1，不由 agent 自行生成
