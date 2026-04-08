# 领域技能索引

外部技能资源库，按角色分组，提供专业知识和自动化工具。

## 架构定位

本目录是技能系统的**第二层（领域技能）**，在第一层工作流技能（`.dev-agents/shared/skills/`）的框架内按需激活。

```
技能系统
├── 第一层：工作流技能（强制）  → .dev-agents/shared/skills/
│   brainstorming / writing-plans / tdd / debugging / verification / review / finish
└── 第二层：领域技能（按需）  → skills/（本目录）
    ├── max/      PM 与项目管理
    ├── ella/     UI/UX 设计
    ├── jarvis/   工程开发
    └── kyle/     质量保障
```

## Max（项目管理）

| 技能包 | 路径 | 来源 | 核心能力 |
|--------|------|------|----------|
| CCPM | `max/ccpm/` | [automazeio/ccpm](https://github.com/automazeio/ccpm) | 项目管理、子代理编排（code-analyzer / file-analyzer / test-runner / parallel-worker） |
| PM Claude Skills | `max/pm-claude-skills/` | [mohitagw15856/pm-claude-skills](https://github.com/mohitagw15856/pm-claude-skills) | PRD 模板、会议纪要、用户研究、竞品分析、干系人更新 |

## Ella（UI/UX 设计）

| 技能包 | 路径 | 来源 | 核心能力 |
|--------|------|------|----------|
| UI/UX Pro Max | `ella/ui-ux-pro-max/` | SkillsMP 技能市场 | 50+ 设计风格、97 色板、57 字体配对、25 图表类型、9 技术栈 |
| Senior Frontend | `ella/senior-frontend/` | SkillsMP 技能市场 | 前端实现模式、组件架构 |

## Jarvis（工程开发）

| 技能包 | 路径 | 来源 | 核心能力 |
|--------|------|------|----------|
| Engineering Team | `jarvis/engineering-team/` | [alirezarezvani/claude-skills](https://github.com/alirezarezvani/claude-skills) | 15+ 工程技能 + 30+ Python 工具 |
| Claude Simone | `jarvis/claude-simone/` | [Helmi/claude-simone](https://github.com/Helmi/claude-simone) | 工程化工作流、MCP 服务器、文档系统 |

### Engineering Team 技能清单

**核心工程（13 个）：**

| 技能 | SKILL.md 路径 |
|------|---------------|
| Senior Fullstack | `jarvis/engineering-team/senior-fullstack/SKILL.md` |
| Senior Backend | `jarvis/engineering-team/senior-backend/SKILL.md` |
| Senior Frontend | `jarvis/engineering-team/senior-frontend/SKILL.md` |
| Senior Architect | `jarvis/engineering-team/senior-architect/SKILL.md` |
| Senior DevOps | `jarvis/engineering-team/senior-devops/SKILL.md` |
| Senior SecOps | `jarvis/engineering-team/senior-secops/SKILL.md` |
| Senior Security | `jarvis/engineering-team/senior-security/SKILL.md` |
| Senior QA | `jarvis/engineering-team/senior-qa/SKILL.md` |
| Code Reviewer | `jarvis/engineering-team/code-reviewer/SKILL.md` |
| AWS Solution Architect | `jarvis/engineering-team/aws-solution-architect/SKILL.md` |
| MS365 Tenant Manager | `jarvis/engineering-team/ms365-tenant-manager/SKILL.md` |
| TDD Guide | `jarvis/engineering-team/tdd-guide/SKILL.md` |
| Tech Stack Evaluator | `jarvis/engineering-team/tech-stack-evaluator/SKILL.md` |

**AI/ML/数据（5 个）：**

| 技能 | SKILL.md 路径 |
|------|---------------|
| Senior Data Scientist | `jarvis/engineering-team/senior-data-scientist/SKILL.md` |
| Senior Data Engineer | `jarvis/engineering-team/senior-data-engineer/SKILL.md` |
| Senior ML Engineer | `jarvis/engineering-team/senior-ml-engineer/SKILL.md` |
| Senior Prompt Engineer | `jarvis/engineering-team/senior-prompt-engineer/SKILL.md` |
| Senior Computer Vision | `jarvis/engineering-team/senior-computer-vision/SKILL.md` |

## Kyle（质量保障）

| 技能包 | 路径 | 来源 | 核心能力 |
|--------|------|------|----------|
| Senior QA | `kyle/senior-qa/` | SkillsMP 技能市场 | React/Next.js 测试自动化、覆盖率分析、E2E 测试 |
| TDD Guide | `kyle/tdd-guide/` | SkillsMP 技能市场 | 多框架 TDD 工作流（Jest/Pytest/JUnit/Vitest） |

## 更新

### GitHub 来源（自动）

```bash
bash scripts/update-skills.sh all
```

### SkillsMP 来源（手动）

以下技能需要从 SkillsMP 技能市场手动下载更新：

- `ella/ui-ux-pro-max`
- `ella/senior-frontend`
- `kyle/senior-qa`
- `kyle/tdd-guide`

## 使用方式

1. 确认当前任务需要哪个领域的专业知识
2. 读取对应的 `SKILL.md` 文件
3. 按 SKILL.md 中的指引执行（触发条件、工具、工作流等）
4. 始终在工作流技能（第一层）的框架内使用领域技能
