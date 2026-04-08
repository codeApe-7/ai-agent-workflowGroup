# aiGroup — 多 Agent 协作框架

一套为 AI 编码代理设计的团队协作框架，通过角色分工和结构化技能驱动高质量软件开发。

## 工作原理

项目定义了一个 4 人虚拟团队，每个成员有明确角色和专属技能：

| 成员 | 角色 | 核心技能 |
|------|------|----------|
| **Max** | 项目经理（主线程） | 需求澄清、方案设计、计划编写、分支收尾 |
| **Ella** | UI/UX 设计师 | 页面设计、交互原型、设计规范 |
| **Jarvis** | 全栈开发 | TDD 开发、系统化调试、Bug 修复 |
| **Kyle** | 质量保障 | 规格合规审查、代码质量审查 |

当你启动编码代理时，Max 不会直接写代码，而是先理解需求、设计方案、编写计划，然后协调 Jarvis 实施、Kyle 审查，形成完整闭环。

## 标准工作流

```
用户提需求 → Max 澄清 → Max 设计 → Max 计划
    → Jarvis 开发（TDD）→ Kyle 审查（两阶段）
    → Max 收尾
```

## 快速开始

### Codex

```bash
git clone <repo-url> ~/projects/work-group-improve
cd ~/projects/work-group-improve
```

详细配置见 `.codex/setup.md`。

### Cursor

在项目根目录打开 Cursor，`AGENTS.md` 会自动生效。

### Claude Code

在项目根目录运行 Claude Code，协议自动加载。

## 项目结构

```
.
├── AGENTS.md                    # 多 Agent 协议（入口）
├── .codex/setup.md              # Codex 安装配置
├── .dev-agents/
│   ├── ella/PERSONA.md          # Ella 角色定义
│   ├── jarvis/PERSONA.md        # Jarvis 角色定义
│   ├── kyle/PERSONA.md          # Kyle 角色定义
│   └── shared/
│       ├── skills/              # 工作流技能（7 个）
│       ├── templates/           # 结构化模板（12 个）
│       ├── references/          # 参考文档
│       ├── tasks/               # 任务产物
│       ├── designs/             # 设计产物
│       └── reviews/             # 审查产物
├── skills/                      # 外部技能资源库
└── scripts/update-skills.sh     # 技能更新脚本
```

## 双层技能体系

### 第一层：工作流技能（`.dev-agents/shared/skills/`）

定义过程纪律，强制遵循。

| 技能 | 所有者 | 说明 |
|------|--------|------|
| workflow-lifecycle | Max | 工作流总览和技能调用纪律 |
| brainstorming | Max | 将模糊想法转化为可执行设计 |
| writing-plans | Max | 将设计拆解为细粒度实施计划 |
| finishing-branch | Max | 分支收尾的结构化选项 |
| tdd | Jarvis | 红-绿-重构测试驱动开发 |
| systematic-debugging | Jarvis | 4 阶段根因分析调试 |
| verification | 全员 | 证据优先的完成验证 |
| code-review-dispatch | Kyle | 两阶段代码审查流程 |

### 第二层：领域技能（`skills/`）

提供专业知识和工具，按需激活。

| 角色 | 技能包数 | 核心能力 |
|------|---------|----------|
| Max | 2 | CCPM 项目管理、PRD/竞品分析 |
| Ella | 2 | 50+ 设计风格、前端模式 |
| Jarvis | 2 (含 15+ 子技能) | 全栈/后端/前端/安全/DevOps/AI-ML |
| Kyle | 2 | 测试自动化、多框架 TDD |

详见 `skills/README.md`。

## 更新外部技能

```bash
bash scripts/update-skills.sh all
```

## 设计理念

受 [superpowers](https://github.com/obra/superpowers) 启发，融合其核心优势并适配多角色团队架构：

- **技能驱动** — 不是建议，是强制流程
- **测试先行** — 没有失败测试就不写代码
- **系统化调试** — 根因优先，禁止盲修
- **证据优先** — 运行命令后才能声称结果
- **角色分工** — 设计、开发、审查严格分离
