# Architecture

> Agent 的架构地图。优先阅读本文件理解系统全貌，再深入具体模块。

## 系统公式

```
Agent = Model + Harness
Harness = Feedforward (Guides) + Feedback (Sensors)
```

## 层级架构

```
┌─────────────────────────────────────────────────┐
│                  用户 / 人类                      │
├─────────────────────────────────────────────────┤
│              Max（协调层）                        │
│  需求澄清 → 方案设计 → 计划编写 → 任务派发       │
├────────┬────────┬────────┬──────────────────────┤
│  Ella  │ Jarvis │  Kyle  │    角色执行层         │
│  设计  │  开发  │  审查  │                       │
├────────┴────────┴────────┴──────────────────────┤
│           Harness（约束与反馈层）                  │
│  ┌──────────────┐  ┌──────────────┐             │
│  │ Feedforward  │  │   Feedback   │             │
│  │ (Guides)     │  │  (Sensors)   │             │
│  │              │  │              │             │
│  │ AGENTS.md    │  │ .harness/    │             │
│  │ Skills       │  │  linters/    │             │
│  │ Templates    │  │  struct-     │             │
│  │ PERSONAs     │  │   tests/     │             │
│  │              │  │  hooks/      │             │
│  └──────────────┘  └──────────────┘             │
├─────────────────────────────────────────────────┤
│              协作产物层                           │
│  tasks/ → designs/ → reviews/ → commits         │
└─────────────────────────────────────────────────┘
```

## 目录拓扑

| 路径 | 类型 | 用途 |
|------|------|------|
| `AGENTS.md` | 索引 | 团队协议入口（目录，非百科全书） |
| `ARCHITECTURE.md` | 地图 | 本文件 — 系统架构全貌 |
| `.dev-agents/` | Feedforward | 角色人格、工作流技能、模板、参考文档 |
| `.harness/` | Feedback | Computational Sensors — Linter、结构测试、Git Hook |
| `.codex/` | Both | Codex 平台配置 — setup、notify hook、初始化 |
| `skills/` | Feedforward | 领域技能库（按角色分组） |
| `.cursor/rules/` | Both | Cursor 平台规则（含 harness-log） |
| `scripts/` | 工具 | 维护脚本 |

## 信息流

```
用户需求
  ↓ feedforward: AGENTS.md → workflow-lifecycle.md
Max 澄清 & 设计
  ↓ feedforward: brainstorming.md → writing-plans.md
Max 派发任务
  ↓ feedforward: implementer-prompt.md + PERSONA + skills
Jarvis 执行
  ↓ feedback: tdd.md (红-绿-重构) + verification.md
  ↓ feedback: .harness/run-all.sh (Computational Sensors)
Jarvis 提交
  ↓ feedback: .harness/hooks/pre-commit.sh (git commit 自动触发)
  ↓ feedback: .codex/hooks/post-turn.sh (Codex [notify] 每 turn 自动触发)
Kyle 审查
  ↓ feedback: code-review-dispatch.md (两阶段)
Max 收尾
  ↓ feedback: finishing-branch.md
  ↓ meta-feedback: harness-log.mdc (Steering Loop)
```

## Harness 分类

| 类别 | Feedforward (Guide) | Feedback (Sensor) |
|------|--------------------|--------------------|
| **Computational** | 模板强制字段、命名规范脚本 | Linter、结构测试、pre-commit hook、`[notify]` post-turn hook |
| **Inferential** | AGENTS.md、Skills、PERSONA | Kyle 审查、verification 技能 |

**优先级：Computational > Inferential**（能用代码强制执行的，不靠提示词）

## 约束边界

| 规则 | 强制方式 | 位置 |
|------|---------|------|
| 角色单一职责 | Inferential | AGENTS.md |
| WRITE_SCOPE 隔离 | Computational | .harness/linters/check-write-scope.sh |
| 任务文件命名 | Computational | .harness/linters/check-task-format.sh |
| 文档引用完整 | Computational | .harness/linters/check-doc-freshness.sh |
| 技能系统一致性 | Computational | .harness/structural-tests/ |
| TDD 纪律 | Inferential | .dev-agents/shared/skills/tdd.md |
| 验证门 | Both | verification.md + .harness/run-all.sh |
| 保护文件 | Computational | .harness/hooks/pre-commit.sh |

## 平台适配

| 平台 | 子代理调度 | Harness 自动执行 | Harness 手动执行 |
|------|-----------|-----------------|-----------------|
| Codex | `spawn_agent` / `wait_agent` | `[notify]` hook + pre-commit | `shell` → `bash .harness/run-all.sh` |
| Cursor | Task tool / subagent | pre-commit hook | Shell tool → `bash .harness/run-all.sh` |
| Claude Code | subagent | pre-commit hook | Bash tool → `bash .harness/run-all.sh` |
