# 项目架构

## 一句话描述

aiGroup 是一个基于 Harness Engineering 理念的 AI 团队协作框架，通过角色分工、强制工作流管道和机械化约束，让 AI Agent 可靠地完成软件开发任务。

## 目录结构

```
ai-agent-workflowGroup/
├── CLAUDE.md                  # Agent 入口：全局地图（< 100 行）
├── docs/                      # 知识库：详细规范与标准
│   ├── README.md              # 知识库索引
│   ├── ARCHITECTURE.md        # 本文件
│   ├── templates/             # 静态文档模板（prd/implementation-plan/code-review 等）
│   ├── workflow-pipeline.md   # 工作流管道详细规则
│   ├── dispatch-rules.md      # 派遣规则与上下文传递
│   ├── coding-standards.md    # 编码与 Git 规范
│   ├── red-flags.md           # 危险信号检测
│   ├── QUALITY_SCORE.md       # 质量评分追踪
│   ├── tech-debt-tracker.md   # 技术债追踪
│   └── steering-loop.md       # 转向循环机制
├── .dev-agents/shared/        # Agent 间协作产物工作区（运行时动态）
│   ├── tasks/                 # 实现计划
│   ├── designs/               # 设计方案与设计稿
│   ├── reviews/               # 审查报告
│   ├── memory/                # 长期记忆（projectContext/activeContext/systemPatterns）
│   └── logs/                  # 运行时事件日志（JSONL 按日滚动）
├── skills/                    # 技能库
│   ├── max/                   # PM 技能
│   │   ├── workflow/          # 工作流技能（8 阶段管道 + 横切技能）
│   │   ├── competitive-analysis/  # 竞品分析
│   │   ├── meeting-notes/         # 会议纪要
│   │   ├── prd-template/          # PRD 撰写
│   │   ├── stakeholder-update/    # 干系人汇报
│   │   └── user-research-synthesis/ # 用户研究综合
│   ├── ella/                  # 设计技能（UI/UX + 前端框架 x7）
│   ├── jarvis/                # 开发技能（45 Skills：架构/后端/语言/数据库/DevOps/安全）
│   └── kyle/                  # QA 技能（审查/测试/安全审计/混沌工程）
├── scripts/                   # 自动化脚本
│   ├── harness/               # Harness 传感器（计算型反馈）
│   └── *.sh                   # 维护脚本
└── .claude/                   # Claude Code 配置
    ├── settings.json          # 权限配置
    ├── hooks.json             # Hook 配置
    ├── commands/              # 通用斜杠命令（/init-project /git-commit）
    └── agents/                # 原生子代理定义
        ├── ella.md            # 艾拉（UI/UX 设计师）
        ├── jarvis.md          # 贾维斯（全栈开发）
        ├── kyle.md            # 凯尔（质量保障）
        ├── init-architect.md  # 项目初始化架构师
        └── get-current-datetime.md
```

## 核心设计决策

### 1. Agent = Model + Harness

本项目不优化模型本身，而是优化模型运行的环境：
- **前馈引导 (Feedforward)** — CLAUDE.md、Skills、工作流管道在 Agent 行动前引导方向
- **反馈传感 (Feedback)** — 计算型 Linter、两阶段审查在 Agent 行动后检测并纠正
- **熵管理** — 定期垃圾回收，防止技术债积累

### 2. 文件驱动的 Agent 协作

Agent 之间不能直接通信，所有协作通过 `.dev-agents/shared/` 目录下的文件进行：
- 设计文档 → `shared/designs/`
- 实现计划 → `shared/tasks/`
- 审查报告 → `shared/reviews/`
- Max 负责在派遣时注入上下文路径

### 3. 约束换取自主性

架构规则不仅写在文档中，还通过 `scripts/harness/` 下的计算型传感器机械化执行。
Agent 的自由度在约束边界内最大化。

### 4. Hooks 自动化反馈（Claude Code CLI 专属）

`.claude/hooks.json` 配置了生命周期 Hooks，**由 Claude Code 运行时自动触发**：

| Hook 事件 | 触发时机 | 脚本 | exit 行为 |
|-----------|---------|------|----------|
| PostToolUse | Agent 编辑文件后 | `hook-post-edit.sh` | exit 0 静默通过；exit 2 错误回注 |
| Stop | Agent 准备停止时 | `hook-stop.sh` | exit 0 允许停止；exit 2 阻止停止 |

**重要区别**：
- **Claude Code CLI**：Hooks 自动执行，如同 git hook，Agent 无法跳过
- **Cursor / 其他 IDE**：不支持 hooks.json，传感器需要 Agent 根据 CLAUDE.md 指令主动运行

## 六层架构实现映射

本项目完整实现 Harness Engineering 定义的六层架构：

| 层 | 职责 | 本项目实现 |
|----|------|-----------|
| ① 上下文边界层 | 角色定义、信息裁剪、分层管理 | `CLAUDE.md`（< 100 行入口）+ `.claude/agents/*.md`（角色） + `docs/`（按需加载） + `skills/`（渐进式披露） |
| ② 工具系统层 | 连接模型与现实 | `Agent(subagent_type)` 派遣 + `.dev-agents/shared/` 文件邮箱 + CLI 工具（Gemini/Qwen/Codex） |
| ③ 执行编排层 | 任务分解为可执行步骤 | `scripts/harness/workflow-state.sh` 8 阶段状态机 + `docs/workflow-pipeline.md` + `skills/max/workflow/*` |
| ④ 记忆与状态层 | 解决 Agent 失忆 | `.dev-agents/shared/.workflow-state`（会话状态） + `.dev-agents/shared/memory/`（长期记忆 3 件套） |
| ⑤ 评估与观测层 | 建立质量反馈 | `scripts/harness/lint-*.sh`（5 个静态传感器） + Kyle 两阶段审查 + `.dev-agents/shared/logs/`（JSONL 事件日志） + `scripts/harness/logs-query.sh`（查询工具） |
| ⑥ 约束校验与恢复层 | 保障鲁棒性 | `.claude/hooks.json`（运行时约束） + `docs/red-flags.md`（10 条危险信号） + `docs/steering-loop.md`（转向循环将重复错误编码为规则） |

### 记忆系统详解（L4）

- `memory/projectContext.md` — 项目级记忆：产品愿景、架构决策、技术栈
- `memory/activeContext.md` — 会话级记忆：当前焦点、上次做到哪、下一步（不入 git）
- `memory/systemPatterns.md` — 模式级记忆：代码模式、重构手法、团队约定

Max 每次会话启动必读 `activeContext.md`（见 CLAUDE.md 会话启动协议）。

### 观测系统详解（L5）

- JSONL 按日滚动：`.dev-agents/shared/logs/events-YYYY-MM-DD.jsonl`
- 10 种 event_type：`workflow_start/reset/exempt/complete`、`stage_enter/exit`、`dispatch`、`loop_iter`、`lint_fail`、`red_flag`
- 写入工具：`scripts/harness/log-event.sh`（fail-silent，不阻塞主流程）
- 查询工具：`scripts/harness/logs-query.sh`（`--stats` / `--hotspots` / `--export`）
- Schema 详见 `.dev-agents/shared/logs/README.md`
