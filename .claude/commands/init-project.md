---
description: 初始化项目 AI 上下文，生成/更新根级与模块级 CLAUDE.md 索引
allowed-tools: Read(**), Write(CLAUDE.md, **/CLAUDE.md)
argument-hint: <项目摘要或名称>
---

## 用法

`/init-project <项目摘要或名称>`

## 目标

以"根级简明 + 模块级详尽"的混合策略初始化项目 AI 上下文：

- 在仓库根生成/更新 `CLAUDE.md`（高层愿景、架构总览、模块索引、全局规范）。
- 在识别的各模块目录生成/更新本地 `CLAUDE.md`（接口、依赖、入口、测试、关键文件等）。
- ✨ **为了提升可读性，会在根 `CLAUDE.md` 中自动生成 Mermaid 结构图，并为每个模块 `CLAUDE.md` 添加导航面包屑**。

## ⚠️ aiGroup 框架保护（铁律）

根 `CLAUDE.md` 是 aiGroup 框架的导航入口（≤ 100 行），**绝对禁止**追加项目上下文内容。

### 检测方法

读取现有根 `CLAUDE.md`，检查以下任一特征标记：

- `## 角色：麦克斯 (Max)`
- `## 全局铁律`
- `## 行为门控`
- `## 团队派遣`

### 保护策略

**检测到框架内容**：设置 `preserve_framework=true` 调用 `init-architect`。该代理会把项目上下文写入 `docs/PROJECT_CONTEXT.md`，**不碰**根 `CLAUDE.md`。

**未检测到框架内容**（全新项目）：设置 `preserve_framework=false`，按常规方式在根 `CLAUDE.md` 生成完整项目上下文。

### 模块级 CLAUDE.md

模块级 `<module>/CLAUDE.md` 不受此保护限制，正常生成/更新。

## 编排说明

**步骤 1**：调用 `get-current-datetime` 子智能体获取当前时间戳。

**步骤 2**：调用一次 `init-architect` 子智能体，输入：

- `project_summary`: $ARGUMENTS
- `current_timestamp`: (来自步骤1的时间戳)
- `preserve_framework`: true/false（基于上述检测结果）

## 执行策略（由 Agent 自适应决定，不需要用户传参）

- **阶段 A：全仓清点（轻量）**
  快速统计文件与目录，识别模块根（package.json、pyproject.toml、go.mod、apps/_、packages/_、services/\* 等）。
- **阶段 B：模块优先扫描（中等）**
  对每个模块做"入口/接口/依赖/测试/数据模型/质量工具"的定点读取与样本抽取。
- **阶段 C：深度补捞（按需）**
  若仓库较小或模块规模较小，则扩大读取面；若较大，则对高风险/高价值路径分批追加扫描。
- **覆盖率度量与可续跑**
  输出"已扫描文件数 / 估算总文件数、已覆盖模块占比、被忽略/跳过原因"，并列出"建议下一步深挖的子路径"。重复运行 `/init-project` 时按上次索引做**增量更新**与**断点续扫**。

## 安全与边界

- 只读/写文档与索引，不改源代码。
- 默认忽略常见生成物与二进制大文件。
- 结果在主对话打印"摘要"，全文写入仓库。
- **绝不覆盖 aiGroup 框架内容**（角色定义、工作流管道、派遣规则等）。

## 输出要求

- 在主对话中打印"初始化结果摘要"，包含：
  - 根级 CLAUDE.md 保护状态（preserve_framework 值；是否已检测并跳过写入）。
  - `docs/PROJECT_CONTEXT.md` 是否创建/更新、主要栏目概览。
  - ✨ **是否检测到 aiGroup 框架并已保护**（明确说明）。
  - 识别的模块数量及其路径列表。
  - 每个模块 `CLAUDE.md` 的生成/更新情况。
  - ✨ **明确提及"已生成 Mermaid 结构图"和"已为 N 个模块添加导航面包屑"**。
  - 覆盖率与主要缺口。
  - 若未读全：说明"为何到此为止"，并列出**推荐的下一步**（例如"建议优先补扫：packages/auth/src/controllers"）。
