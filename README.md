# aiGroup - AI 团队协作框架

> 单入口 AI 团队：一个命令启动，按需自动派遣设计、开发、测试专家

## 快速开始

```bash
git clone https://github.com/yezannnnn/agentGroup.git
cd agentGroup
claude
```

就这样。麦克斯 (Max) 会自动就位，根据你的需求派遣对应的团队成员。

## 团队成员

| 成员 | 角色 | 负责什么 | 不负责什么 |
|------|------|----------|-----------|
| 麦克斯 (Max) | 项目经理 | 需求分析、任务拆解、进度协调 | 写代码、做设计、做测试 |
| 艾拉 (Ella) | UI/UX 设计师 | 界面设计、交互原型、设计规范 | 写代码、做测试 |
| 贾维斯 (Jarvis) | 全栈开发 | 前后端编码、API、技术方案 | 做设计、做测试验收 |
| 凯尔 (Kyle) | 质量保障 | 代码审查、功能验收、安全审计 | 写代码、做设计 |

## 工作流程

```
你的需求 → Max 分析 → 自动派遣对应 AI → 执行 → Max 汇总
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
agentGroup/
├── CLAUDE.md              # Max 配置 + 调度规则（唯一入口）
├── .dev-agents/           # 角色定义
│   ├── ella/PERSONA.md    # 艾拉
│   ├── jarvis/PERSONA.md  # 贾维斯
│   ├── kyle/PERSONA.md    # 凯尔
│   └── shared/            # 协作产物（设计稿、审查报告、任务）
├── skills/                # 技能资源
│   ├── ella/              # UI/UX Pro Max、前端参考
│   ├── jarvis/            # Claude Simone、工程团队技能集
│   ├── kyle/              # QA 技能包、TDD 指南
│   └── max/               # CCPM 项目管理、PM 技能集
└── README.md
```

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
