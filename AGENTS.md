# AGENTS.md

> 平台中立的 agent 协作入口。Codex CLI 与其他 harness 读本文件；Claude Code 读 `CLAUDE.md`。
> 两端共享主源：`agents/` / `skills/` / `docs/` / `scripts/`。

## Project Overview

aiGroup is a **dual-harness AI team collaboration framework**. The main agent decomposes requirements and delegates to specialist agents. It does NOT directly write code, design UI, or run tests.

## Architecture

| 目录 | 内容 |
|------|------|
| `agents/` | **agent 源池**（52 个，开发态分发位置） |
| `skills/` | **skill 源池**（扁平 `skills/<name>/SKILL.md`） |
| `commands/` | 斜杠命令源 |
| `.claude/agents/` | Claude Code 实际启用的 agent（由 `aigroup init` 按需复制） |
| `.codex/agents/` | Codex 原生 persona TOML（3 个：explorer / reviewer / docs_researcher） |
| `.codex/config.toml` | Runtime + MCP + persona 配置 |
| `docs/` | 知识库主源（架构、规则、流程） |
| `docs/rules/` | 强制规则集（agents / coding-style / git-workflow / testing / security / performance / hooks） |
| `manifests/` | 安装清单（agent / skill 分组） |
| `.orchestration/<session>/` | Agent 协作产物工作区 |
| `scripts/orchestration/` | 协调 CLI（session.cjs） |
| `scripts/hooks/` | hook dispatcher + checks（Codex 端需手动调用） |

## Available Agents

源池 `agents/<name>.md` 共 52 个，由 `aigroup init` 按 manifest 模块选择安装：

| 模块 | 默认 | 数量 | 说明 |
|------|------|------|------|
| `agents-core` | ✅ | 12 | 派遣规则定义的 10 个 + init-architect / get-current-datetime |
| `agents-quality` | ⏤ | 9 | 代码质量分析 |
| `agents-language` | ⏤ | 16 | 各语言 reviewer / build-resolver |
| `agents-ops` | ⏤ | 8 | 运维与工作流操作 |
| `agents-domain` | ⏤ | 9 | 特殊领域（a11y / healthcare / opensource / gan-* / seo） |

详细派遣矩阵见 `docs/rules/agents.md`。

> **agent 体系两端共享一份**——不存在"Claude 专项 agent vs Codex role adapter"对照表。Codex 端在主对话中加载对应 skill 即可达成同样效果。

## Codex 端独有

`.codex/agents/` 下的 3 个 persona TOML 是 **Codex 原生 multi-agent 机制**，仅在需要切换 sandbox / reasoning_effort 时使用：

| Persona | 用途 |
|---------|------|
| `explorer` | 只读 sandbox，证据收集 |
| `reviewer` | 高 reasoning，代码 + 安全审查 |
| `docs_researcher` | 带网络访问，API / 文档查证 |

切换：`/agent <persona>`。完整 Codex 端说明见 `.codex/AGENTS.md`。

## 知识库地图

| 需要了解 | 查阅 |
|---------|------|
| Agent 派遣矩阵 | `docs/rules/agents.md` |
| 强制规则（铁律 / 编码 / Git / 测试 / 安全 / 性能 / Hooks） | `docs/rules/` |
| Codex 端差异（模型 / MCP / persona / 无 hook 兜底） | `.codex/AGENTS.md` |
| 工作流 phase 心智模型 | `docs/workflow-pipeline.md` |
| 危险信号 | `docs/red-flags.md` |
| 项目实例上下文 | `docs/PROJECT_CONTEXT.md` |

## Codex 限制（必须知道）

- **No hooks** — Codex 不支持 hook 事件；必须主动运行 `node scripts/hooks/dispatcher.cjs stop`
- **No slash commands** — 用主对话 + `/agent <persona>`，不识别 `.claude/commands/`
- **No `Agent({ subagent_type })` 语法** — 派遣 = 主对话加载对应 skill；persona 切换 = `/agent`

详见 `.codex/AGENTS.md`。

## Claude Code 兼容

Claude Code 用户使用 `CLAUDE.md` 作为入口，通过 `Agent({ subagent_type })` 派遣安装在 `.claude/agents/` 下的 agent。两端的派遣规则都以 `docs/rules/agents.md` 为唯一事实源。
