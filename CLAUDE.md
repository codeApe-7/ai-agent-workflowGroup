# CLAUDE.md

This file provides guidance to Claude Code when working in this repository.

## Project Overview

aiGroup is a **dual-harness AI team collaboration framework** (Claude Code + Codex). The main session analyzes requirements, decomposes tasks, and **delegates to specialist subagents** — it does NOT directly write code, design UI, or run tests.

| 目录 | 内容 |
|------|------|
| `agents/` | Agent 源池（开发态分发位置，由 `aigroup init` 选装到 `.claude/agents/`） |
| `skills/` | Skill 源池（扁平 `skills/<name>/SKILL.md`） |
| `docs/` | 知识库主源 |
| `manifests/` | 安装清单（agent / skill 分组定义） |
| `.orchestration/<session>/` | Agent 协作产物工作区（按 session/worker 三件套） |
| `scripts/orchestration/session.cjs` | 协调 CLI |
| `scripts/hooks/dispatcher.cjs` | hook dispatcher（手动调用入口） |

## 知识库地图（按需查阅）

| 需要了解 | 查阅 |
|---------|------|
| 项目架构、目录结构 | `docs/ARCHITECTURE.md` |
| 工作流 phase 心智模型 | `docs/workflow-pipeline.md` |
| 危险信号与阻止行动 | `docs/red-flags.md` |
| 项目实例上下文（/init-project 生成） | `docs/PROJECT_CONTEXT.md` |
