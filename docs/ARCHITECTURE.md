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
│   ├── workflow-pipeline.md   # 工作流管道详细规则
│   ├── dispatch-rules.md      # 派遣规则与上下文传递
│   ├── coding-standards.md    # 编码与 Git 规范
│   ├── red-flags.md           # 危险信号检测
│   ├── QUALITY_SCORE.md       # 质量评分追踪
│   ├── tech-debt-tracker.md   # 技术债追踪
│   └── steering-loop.md       # 转向循环机制
├── .dev-agents/shared/        # Agent 间协作产物工作区
│   ├── tasks/                 # 实现计划
│   ├── designs/               # 设计方案与设计稿
│   ├── reviews/               # 审查报告
│   └── templates/             # 文档模板
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
