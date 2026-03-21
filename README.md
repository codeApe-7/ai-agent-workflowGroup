# aiGroup - AI 团队协作框架（Cursor 版）

> 单入口 AI 团队：在 Cursor IDE 中自动派遣设计、开发、测试专家协作完成任务

## 快速开始

1. 用 Cursor 打开本项目
2. 直接在 Cursor 的 Agent 模式中输入需求

就这样。麦克斯 (Max) 会自动就位，根据你的需求派遣对应的团队成员。

> 本分支为 **Cursor IDE 专用**，通过 `.cursor/rules/` 驱动多 Agent 协作。如需 Claude Code（CLI）版本，请切换到 `master` 分支。

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
├── .cursor/rules/             # Cursor 规则（多 Agent 调度入口）
│   ├── project-core.mdc       #   始终生效：核心约定（中文注释、编码规范）
│   ├── max-coordinator.mdc    #   始终生效：Max 角色 + 派遣规则
│   ├── git-conventions.mdc    #   始终生效：Git 安全与提交格式
│   ├── ella-designer.mdc      #   设计文件触发：艾拉角色
│   ├── jarvis-developer.mdc   #   代码文件触发：贾维斯角色
│   ├── kyle-qa.mdc            #   测试/审查触发：凯尔角色
│   └── shared-artifacts.mdc   #   共享目录触发：产物规范
├── .dev-agents/               # Agent 运行时数据
│   ├── ella/PERSONA.md        #   艾拉角色定义（派遣时读取）
│   ├── jarvis/PERSONA.md      #   贾维斯角色定义（派遣时读取）
│   ├── kyle/PERSONA.md        #   凯尔角色定义（派遣时读取）
│   └── shared/                #   协作产物（设计稿、审查报告、任务）
├── skills/                    # 技能资源
│   ├── ella/                  #   UI/UX Pro Max、前端参考
│   ├── jarvis/                #   Claude Simone、工程团队技能集
│   ├── kyle/                  #   QA 技能包、TDD 指南
│   └── max/                   #   CCPM 项目管理、PM 技能集
└── README.md
```

### 规则生效机制

| 规则文件 | 生效方式 | 说明 |
|---------|---------|------|
| `project-core.mdc` | 始终生效 | 中文注释、编码规范等基础约定 |
| `max-coordinator.mdc` | 始终生效 | Max 角色定义、Agent 派遣与上下文传递 |
| `git-conventions.mdc` | 始终生效 | Git 安全红线、提交格式 `<type>: <中文描述>` |
| `ella-designer.mdc` | `.dev-agents/ella/**`, `shared/designs/**` | 编辑设计文件时激活艾拉角色 |
| `jarvis-developer.mdc` | `src/**`, `app/**`, `components/**` 等 | 编辑代码文件时激活贾维斯角色 |
| `kyle-qa.mdc` | `*.test.*`, `*.spec.*`, `shared/reviews/**` 等 | 编辑测试/审查文件时激活凯尔角色 |
| `shared-artifacts.mdc` | `.dev-agents/shared/**` | 编辑共享产物时应用命名和格式规范 |

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
