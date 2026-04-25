# aiGroup — AI 团队协作框架

[![npm version](https://img.shields.io/npm/v/aigroup-workflow?style=flat&colorA=080f12&colorB=1fa669)](https://npmjs.com/package/aigroup-workflow)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg?style=flat&colorA=080f12&colorB=1fa669)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude-Code-purple.svg?style=flat&colorA=080f12&colorB=1fa669)](https://claude.ai/code)
[![Codex](https://img.shields.io/badge/Codex-CLI-blue.svg?style=flat&colorA=080f12&colorB=1fa669)](https://developers.openai.com/codex)

> **双端 AI 团队协作框架**：主会话接收需求，按任务类型派遣**专项子代理**执行。
> Claude Code 与 Codex 共享同一份 agent / skill / docs 主源，各自薄适配层接入。
> 重场景走 phase 心智模型（按需裁剪）；轻量任务走 `/plan`、`/review`、`/fix-build`、`/tdd` 单 agent 流程。

## 双端兼容

| Harness | 入口 | Agent 启用位置 | 启动 |
|---------|------|----------------|------|
| Claude Code | `CLAUDE.md` | `.claude/agents/<name>.md`（init 时按需选） | `claude` |
| Codex CLI | `AGENTS.md` | `.codex/agents/<persona>.toml`（3 个原生 persona） | `codex` |

两端共享 `agents/`（源池）/ `skills/` / `docs/` / `scripts/` / `.orchestration/<session>/`。派遣规则单一事实源：`docs/rules/agents.md`。

## 快速开始

### 环境

| 依赖 | 用途 |
|------|------|
| [Claude Code](https://docs.anthropic.com/en/docs/claude-code) 或 [Codex CLI](https://developers.openai.com/codex) | AI Agent 运行时 |
| Node.js 18+ | CLI 工具 |
| Git 2.x | 版本控制 |
| Bash 4+ | 协调脚本（Windows 用 Git Bash） |

### 安装

```bash
# 推荐：全局安装
npm install -g aigroup-workflow
aig init                  # 交互式选择：harness / skill 模块 / agent 模块

# 或：npx 一次性
npx aigroup-workflow init

# 或：克隆开发
git clone https://github.com/codeApe-7/ai-agent-workflowGroup.git
```

`aig init` 会让你选：

1. 启用哪些 harness（Claude Code / Codex CLI）
2. 装哪些 skill 模块（workflow / engineering-core / quality 默认装；其他按项目栈选）
3. 装哪些 agent 模块（agents-core 默认装 12 个；语言专项 / 质量分析 / 运维 / 特殊领域按需选）

### CLI

```bash
aig init              # 初始化（交互式）
aig init --yes        # 跳过确认，用默认配置
aig update            # 增量更新（保留自定义）
aig check             # Harness 健康检查
aig status            # 查看活跃 session
aig help              # 帮助
```

> `aig` 是 `aigroup` 的短别名。npx 用户用 `npx aigroup-workflow <命令>`。

## Agent 派遣

agent 体系**两端共享一份**——单一 manifest 驱动的源池 + 选装机制。

### 默认装的 12 个 agent（agents-core）

| Agent | 用途 |
|-------|------|
| `planner` | 实现规划 — 复杂功能、重构 |
| `architect` | 系统设计 — 架构决策 |
| `tdd-guide` | 测试驱动开发 — 新功能、bug 修复 |
| `code-reviewer` | 代码审查 — 编写代码后 |
| `security-reviewer` | 安全分析 — 提交前 |
| `build-error-resolver` | 修复构建 / 类型 / 依赖错误 |
| `e2e-runner` | E2E 测试 — 关键用户流程 |
| `refactor-cleaner` | 死代码清理 — 代码维护 |
| `doc-updater` | 文档更新 |
| `rust-reviewer` | Rust 代码审查 |
| `init-architect` | 项目专属（`/init-project` 用） |
| `get-current-datetime` | 工具 agent |

> 派遣规则采用 ECC 风格 `docs/rules/agents.md`。详细 handoff 内容、并行场景、反模式见 `docs/rules/agents.md`。

### 可选扩展模块（按需装）

| 模块 | agent 数 | 内容 |
|------|---------|------|
| `agents-quality` | 8 | code-explorer / code-architect / refactor / 静默失败 / 性能 等 |
| `agents-language` | 15 | cpp / go / java / kotlin / python / rust / typescript / ... 各语言 reviewer 与 build-resolver |
| `agents-ops` | 6 | chief-of-staff / database-reviewer / docs-lookup / harness-optimizer / loop-operator / pr-test-analyzer |
| `agents-domain` | 9 | a11y / healthcare / opensource / gan-* / seo |

源池 `agents/` 共 50 个 agent，覆盖完整 agent 模块清单。

### 三种使用方式

**方式一：自然语言（推荐）**

```
你: 帮我审一下登录模块
→ Claude Code：派遣 code-reviewer + security-reviewer 并行
→ Codex：/agent reviewer，加载 skills/security-reviewer/SKILL.md

你: build 挂了
→ Claude Code：派遣 build-error-resolver
→ Codex：主对话 + 加载 skills/systematic-debugging/SKILL.md

你: 帮我规划用户认证系统
→ Claude Code：planner → architect → tdd-guide → code-reviewer
→ Codex：主对话规划，必要时 /agent reviewer 审查
```

**方式二：显式点名**

```
你: 让 tdd-guide 把用户模块按 TDD 实现
你: 请 security-reviewer 审一下 auth 流程
你: 让 doc-updater 把 README 同步一下
```

**方式三：斜杠命令（Claude Code 专享）**

```bash
# 重场景（建 session、按 phase 裁剪）
/workflow-start <任务名>      # ≥2 worker 协作的完整流程
/init-project <名称>          # 项目 AI 上下文初始化

# 轻量场景（单 agent，不建 session）
/plan <任务>                  # 派 planner
/review                       # 派 code-reviewer（双阶段）
/fix-build                    # 派 build-error-resolver
/tdd <功能>                   # 派 tdd-guide 走 Red→Green→Refactor

# 工具
/git-commit                   # 智能 Git 提交（Conventional Commits）
```

> Codex 端无 slash command，对应操作通过自然语言或 `/agent` 完成。

## Codex 原生 Persona

`.codex/agents/` 下 3 个 TOML——**仅在需要切换 sandbox / reasoning_effort 时**使用：

| Persona | sandbox | reasoning | 用途 |
|---------|---------|-----------|------|
| `explorer` | read-only | medium | 证据收集、执行路径追踪 |
| `reviewer` | read-only | high | 代码 + 安全审查 |
| `docs_researcher` | read-only | medium | API / 文档查证（带网络） |

不存在"Claude agent ↔ Codex role 对照表"——agent 体系本就单一。详见 `.codex/AGENTS.md`。

## 工作流 Phase 心智模型

8 phase 是**完整路径**，不是强制路径——每个任务由主会话按复杂度和风险**裁剪**。

```
需求收集 → 需求验证 → 方案设计 → 任务拆解 → 实施开发 → 测试验证 → 文档更新 → 分支收尾
```

| 任务类型 | 建议 phases |
|---------|------------|
| 纯 bugfix | 5 → 6（直接 `/tdd` + `/review`）|
| 小功能增补 | 3 → 4 → 5 → 6 |
| 新模块 / 架构决策 | 完整 1 → 8（`/workflow-start`）|
| 重构 | 3 → 4 → 5 → 6 |
| 纯文档 / 笔误 | 直接做，不建 session |

状态真相源：`.orchestration/<session>/<worker>/status.md`，由 `node scripts/orchestration/session.cjs set-status` 维护。详见 `docs/workflow-pipeline.md`。

### 多视角审查（高风险变更）

- **正确性** — `code-reviewer`
- **安全** — `security-reviewer`
- **测试覆盖** — `tdd-guide`（审"该有但没有"）
- **一致性** — `architect`（审是否破坏架构约束）

可并行：`code-reviewer` + `security-reviewer`、`doc-updater` + `tdd-guide`、多个 `code-explorer` 跑不同模块。

## Skill 体系

Skill 是共享能力层，**不属于任何 agent**。Claude Code 启动时**自动加载** `skills/<name>/SKILL.md`，按 skill `description` frontmatter 自动触发。

```
skills/<name>/SKILL.md       # 扁平结构，命名小写 + 短横线
```

按 manifest 模块分类（`manifests/install-modules.json`）：

| 模块 | 默认 | 数量 | 内容 |
|------|------|------|------|
| `workflow` | ✅ | 8 | 需求工程 / 规划 / 调试 / 文档 / 验证 / 收尾 |
| `engineering-core` | ✅ | 12 | API / 架构 / 数据库 / 调试 |
| `quality` | ✅ | 8 | 审查 / 测试 / 安全 |
| `product` | ⏤ | 5 | PRD / 用户研究 / 干系人 |
| `design` | ⏤ | 10 | UI/UX + 前端框架 |
| `engineering-languages` | ⏤ | 19 | TypeScript / Python / Go / Rust / Java / ... |
| `engineering-infra` | ⏤ | 13 | DevOps / 云 / Kubernetes / CLI / AI/ML |

> agent 文件**不写"必读 skill"段**——硬编码 skill 路径会绑死归属、稀释 prompt、skill 重命名后造成漂移。靠 skill description 自动触发即可。

## 协调协议（`.orchestration/`）

主会话是唯一的 orchestrator/writer；每个 subagent 都是只产文本的 worker。

```
.orchestration/
├── .logs/                       # 全局事件日志（可选，不入库）
└── <session>/                   # 一任务一 session
    ├── session.json             # 元数据
    └── <worker>/                # = agent 名
        ├── task.md              # 主→worker
        ├── handoff.md           # worker→主（Summary / Files / Validation / Follow-ups）
        └── status.md            # state: not_started / running / completed / failed / blocked
```

CLI：

```bash
node scripts/orchestration/session.cjs init <session-name>
node scripts/orchestration/session.cjs add-worker <session> <worker> --agent <name> --objective "<目标>" [--lightweight]
node scripts/orchestration/session.cjs set-status <session> <worker> <state> [--details "<md>"]
node scripts/orchestration/session.cjs append <session> <worker> <section> --content "<md>"
node scripts/orchestration/session.cjs status <session>
node scripts/orchestration/session.cjs list
```

`--lightweight` 模式跳过 `task.md`，适合一次性临时 worker。

## 项目结构

```
aiGroup/
├── CLAUDE.md                    # Claude Code 入口（导航）
├── AGENTS.md                    # Codex / 通用入口
├── package.json                 # npm 包
├── bin/aigroup.mjs              # CLI 入口
├── cli/                         # CLI 实现
├── agents/                      # agent 源池（50 个，分发态）
├── skills/                      # skill 源池（扁平，自动加载）
├── docs/                        # 知识库（唯一事实源）
│   ├── rules/agents.md        #   Agent 派遣矩阵
│   ├── workflow-pipeline.md     #   Phase 心智模型
│   ├── red-flags.md             #   危险信号清单
│   ├── rules/                   #   强制规则集
│   └── PROJECT_CONTEXT.md       #   /init-project 生成
├── manifests/install-modules.json   # 安装清单（agent / skill 分组）
├── scripts/
│   ├── hooks/dispatcher.cjs     # hook dispatcher（PreToolUse / Stop / SubagentStop）
│   ├── orchestration/session.cjs  # 协调 CLI
│   ├── harness/                 # 日志写入与查询（可选）
│   └── update-skills.sh         # 上游 skill 同步
├── .orchestration/<session>/    # 协作产物工作区
├── .claude/                     # Claude 适配（init 时填充）
│   ├── agents/                  #   按选择从 agents/ 复制
│   ├── commands/                #   /workflow-start /plan /review /fix-build /tdd /init-project /git-commit
│   ├── hooks.json
│   └── settings.json
├── .codex/                      # Codex 适配
│   ├── AGENTS.md
│   ├── config.toml              #   Runtime + MCP + 3 个 persona
│   └── agents/                  #   explorer / reviewer / docs-researcher
├── .claude-plugin/plugin.json
└── .codex-plugin/plugin.json
```

## Harness Engineering

```
Agent = Model + Harness
```

| 层级 | 机制 | 实现 |
|------|------|------|
| **前馈引导** | 行动前提示 | CLAUDE.md / AGENTS.md / Skills（按 description 自动触发）/ docs/rules/ |
| **计算型反馈** | 确定性检查 | `scripts/hooks/dispatcher.cjs` 路由 6 个 check |
| **推理型反馈** | AI 审查 | `code-reviewer` / `security-reviewer` / `tdd-guide` / `architect` 多视角 |
| **熵管理** | 防退化 | `skills/entropy-management` |

### Hook 检查（`scripts/hooks/dispatcher.cjs`）

| 事件 | 触发 | 检查 |
|------|------|------|
| `post-edit` | `Write` / `Edit` 后 | CLAUDE.md 体积、docs 空壳 |
| `subagent-stop` | subagent 结束 | 基础结构、orchestration 三件套完整性 |
| `stop` | 主会话停止 | 上述 + 派遣反模式、worker 状态门控 |

```bash
node scripts/hooks/dispatcher.cjs stop          # 全量检查
echo '{}' | node scripts/hooks/dispatcher.cjs <event>
```

| Harness | Hook 支持 | 兜底 |
|---------|-----------|------|
| Claude Code | ✅ 自动触发 | `.claude/hooks.json` 已配置 |
| Codex CLI | ❌ 不支持 | 主动运行 `node scripts/hooks/dispatcher.cjs stop` |

## Memory（跨会话持久化）

按所有权分流到 3 个位置——**不再有项目内 `memory/` 目录**：

| 内容 | 落盘 | git-tracked |
|------|------|-------------|
| 项目愿景 / 架构决策 | `docs/PROJECT_CONTEXT.md` + `docs/ARCHITECTURE.md` | ✅ |
| 团队约定 / 危险信号 / 代码模式 | `docs/rules/<topic>.md` + `docs/red-flags.md` | ✅ |
| 用户活跃任务 / 个人偏好 | `~/.claude/projects/<slug>/memory/`（Claude 原生自动加载） | ⏤ |

## Skill 来源

| 类别 | 来源 | License |
|------|------|---------|
| 工作流技能 | 原创，受 [obra/superpowers](https://github.com/obra/superpowers) 与 [Harness Engineering](https://martinfowler.com/articles/harness-engineering.html) 启发 | MIT |
| 开发 / QA / 前端技能（62 个） | [Jeffallan/claude-skills](https://github.com/Jeffallan/claude-skills) | MIT |
| PM 辅助技能（5 个） | [mohitagw15856/pm-claude-skills](https://github.com/mohitagw15856/pm-claude-skills) | MIT |

## 致谢

本项目基于 [yezannnnn/agentGroup](https://github.com/yezannnnn/agentGroup) 开发扩展。感谢 [@yezannnnn](https://github.com/yezannnnn) 提出的 AI 专业分工协作框架理念。

## 社区

<div align="center">

[![LINUX DO](https://img.shields.io/badge/LINUX%20DO-社区-gray?style=flat-square)](https://linux.do/) [![社区支持](https://img.shields.io/badge/社区支持-交流-blue?style=flat-square)](https://linux.do/)

本项目在 [LINUX DO](https://linux.do/) 社区发布与交流。

</div>

## 许可证

MIT License
