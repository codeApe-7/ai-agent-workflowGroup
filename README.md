# aiGroup - AI 团队协作框架（Cursor 版）

> 单入口 AI 团队：在 Cursor IDE 中自动派遣设计、开发、测试专家协作完成任务

## 快速开始

1. 用 Cursor 打开本项目
2. 直接在 Cursor 的 Agent 模式中输入需求

就这样。麦克斯 (Max) 会自动就位，根据你的需求派遣对应的团队成员。

> 本分支为 **Cursor IDE 专用**，通过 `.cursor/rules/`（规则）+ `.cursor/agents/`（子 Agent）+ `.cursor/skills/`（技能）驱动多 Agent 协作。如需 Claude Code（CLI）版本，请切换到 `master` 分支。

## 团队成员

| 成员 | 角色 | 负责什么 | 不负责什么 |
|------|------|----------|-----------|
| 麦克斯 (Max) | 项目经理 | 需求分析、任务拆解、进度协调 | 写代码、做设计、做测试 |
| 艾拉 (Ella) | UI/UX 设计师 | 界面设计、交互原型、设计规范 | 写代码、做测试 |
| 贾维斯 (Jarvis) | 全栈开发 | 前后端编码、API、技术方案 | 做设计、做测试验收 |
| 凯尔 (Kyle) | 质量保障 | 代码审查、功能验收、安全审计 | 写代码、做设计 |

## 工作流程

```
你的需求 → Max 分析 → 自动派遣对应 Agent → 执行 → Max 汇总
```

- 设计类需求 → 派遣艾拉
- 开发类需求 → 派遣贾维斯
- 测试/审查需求 → 派遣凯尔
- 简单问题 → Max 直接回答

## 使用示例

```
你: 帮我设计一个登录页面
Max: [分析需求，派遣艾拉] → 艾拉输出设计稿

你: 根据设计稿开发登录功能
Max: [派遣贾维斯] → 贾维斯实现代码

你: 验收一下登录功能
Max: [派遣凯尔] → 凯尔输出审查报告
```

## 项目结构

```
ai-agent-workflowGroup/
├── .cursor/
│   ├── rules/                 # Rules — 主 Agent (Max) 的行为规则
│   │   ├── project-core.mdc   #   始终生效：核心约定（中文注释、编码规范）
│   │   ├── max-coordinator.mdc#   始终生效：Max 角色 + 团队调度
│   │   ├── git-conventions.mdc#   始终生效：Git 安全与提交格式
│   │   └── shared-artifacts.mdc#  共享目录触发：产物规范
│   ├── agents/                # Subagents — 可委派的子 Agent
│   │   ├── ella.md            #   艾拉：UI/UX 设计师
│   │   ├── jarvis.md          #   贾维斯：全栈开发工程师
│   │   └── kyle.md            #   凯尔：质量保证工程师（只读模式）
│   └── skills/                # Skills — 技能资源（Cursor 自动发现）
│       ├── ui-ux-pro-max/     #   UI/UX 设计工具（艾拉）
│       ├── senior-frontend/   #   前端开发（艾拉/贾维斯）
│       ├── claude-simone/     #   开发框架（贾维斯）
│       ├── senior-backend/    #   后端开发（贾维斯）
│       ├── senior-fullstack/  #   全栈开发（贾维斯）
│       ├── senior-architect/  #   架构设计（贾维斯）
│       ├── senior-qa/         #   QA 测试（凯尔）
│       ├── tdd-guide/         #   TDD 指南（凯尔）
│       ├── ccpm/              #   项目管理（麦克斯）
│       ├── pm-claude-skills/  #   PM 技能（麦克斯）
│       └── ...                #   更多专业技能（共 23 个）
├── .dev-agents/
│   └── shared/                # Agent 协作产物
│       ├── tasks/             #   任务文档
│       ├── designs/           #   设计稿
│       ├── reviews/           #   审查报告
│       └── templates/         #   文档模板
└── README.md
```

### Cursor 三层架构

本项目完全遵循 [Cursor 官方规范](https://cursor.com/docs)，利用三层原生机制实现多 Agent 协作：

| 层级 | 位置 | 作用 | 详情 |
|------|------|------|------|
| **Rules** | `.cursor/rules/` | 注入主 Agent 上下文 | Max 角色、项目约定、Git 规范始终生效 |
| **Subagents** | `.cursor/agents/` | 独立子 Agent，被 Max 委派 | 艾拉/贾维斯/凯尔各自有独立上下文窗口 |
| **Skills** | `.cursor/skills/` | 可复用的专业知识包 | 23 个技能包，Cursor 自动发现并按需加载 |

### 子 Agent 调用方式

| 子 Agent | 显式调用 | 自动委派 | 模式 |
|----------|---------|---------|------|
| 艾拉 (Ella) | `/ella` | 涉及设计需求时 Max 自动委派 | 默认（可读写） |
| 贾维斯 (Jarvis) | `/jarvis` | 涉及开发需求时 Max 自动委派 | 默认（可读写） |
| 凯尔 (Kyle) | `/kyle` | 涉及审查/测试需求时 Max 自动委派 | 只读（readonly） |

## 技能来源

| 技能 | 来源 | 许可证 |
|------|------|--------|
| CCPM 项目管理 | [automazeio/ccpm](https://github.com/automazeio/ccpm) | MIT |
| PM Claude Skills | [mohitagw15856/pm-claude-skills](https://github.com/mohitagw15856/pm-claude-skills) | MIT |
| Claude Simone | [Helmi/claude-simone](https://github.com/Helmi/claude-simone) | 见原仓库 |
| Engineering Team | [alirezarezvani/claude-skills](https://github.com/alirezarezvani/claude-skills) | 见原仓库 |
| UI/UX Pro Max | SkillsMP 技能市场 | MIT |
| Senior QA / TDD | SkillsMP 技能市场 | MIT |

## 许可证

MIT License
