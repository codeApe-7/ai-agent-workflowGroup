# aiGroup — 多 Agent 协作框架

一套为 AI 编码代理设计的团队协作框架，通过角色分工、结构化技能和 [Harness Engineering](https://openai.com/index/harness-engineering/) 驱动高质量软件开发。

**核心公式：** `Agent = Model + Harness`

## 工作原理

项目定义了一个 4 人虚拟团队，每个成员有明确角色和专属技能：

| 成员 | 角色 | 核心技能 |
|------|------|----------|
| **Max** | 项目经理（主线程） | 需求澄清、方案设计、计划编写、分支收尾 |
| **Ella** | UI/UX 设计师 | 页面设计、交互原型、设计规范 |
| **Jarvis** | 全栈开发 | TDD 开发、系统化调试、Bug 修复 |
| **Kyle** | 质量保障 | 规格合规审查、代码质量审查 |

当你启动编码代理时，Max 不会直接写代码，而是先理解需求、设计方案、编写计划，然后协调 Jarvis 实施、Kyle 审查，形成完整闭环。整个过程由 Harness 层（自动化 Linter、结构测试、Git Hook）约束质量。

## 标准工作流

```
用户提需求 → Max 澄清 → Max 设计 → Max 计划
    → Jarvis 开发（TDD）→ Harness 自动检查 → Kyle 审查（两阶段）
    → Max 收尾
```

## 快速开始

### 方式一：Codex CLI

```bash
# 1. 克隆
git clone <repo-url> ~/projects/ai-agent-workflowGroup
cd ~/projects/ai-agent-workflowGroup

# 2. 一键安装 Harness（Git hook + notify hook + 结构验证）
bash .codex/sandbox-setup.sh

# 3. 在 ~/.codex/config.toml 中启用子代理
# [features]
# multi_agent = true
# child_agents_md = true

# 4. 启动 Codex — AGENTS.md 自动生效，Max 接管会话
codex
```

完整 Codex 配置见 `.codex/setup.md`。

### 方式二：Cursor

```
1. 在项目根目录打开 Cursor
2. AGENTS.md 自动生效，Max 接管会话
3. 安装 Harness hook（可选但推荐）：
   在 Terminal 中运行 bash .harness/hooks/install.sh
```

### 方式三：Claude Code

```bash
# 在项目根目录启动
cd ~/projects/ai-agent-workflowGroup
claude

# 协议通过 AGENTS.md 自动加载
# 安装 Harness hook（可选但推荐）
bash .harness/hooks/install.sh
```

## 使用方法

### 日常使用

启动任何平台的 Agent 后，直接用自然语言描述需求即可：

```
你: "给用户管理模块添加批量导入功能"

Max 会自动：
  1. 澄清需求（缺什么信息会追问你）
  2. 设计方案（brainstorming 技能）
  3. 拆解计划（writing-plans 技能）
  4. 派发 Jarvis 开发（TDD 驱动）
  5. 派发 Kyle 审查（两阶段）
  6. 汇总结果
```

### 简单请求

不是所有需求都需要走完整流程。以下情况 Max 直接回答：

```
"这个函数是做什么的？"        → Max 直接回答
"把变量名 foo 改成 bar"      → Max 直接处理
"怎么配置 ESLint？"          → Max 直接回答
```

### 复杂任务（自动多代理协作）

```
"重构数据库访问层，从 Prisma 迁移到 Drizzle"

Max: 需求澄清 → 识别风险 → 设计迁移方案
  → 拆分为 5 个子任务
  → Jarvis-1: 新建 Drizzle schema（TDD）
  → Jarvis-2: 迁移查询层（TDD）
  → Jarvis-3: 更新测试（TDD）
  → Kyle: 规格合规 + 代码质量审查
  → Max: 收尾、汇总、分支合并
```

### Bug 修复

```
"用户登录后 token 过期没有自动刷新"

Max → Jarvis:
  1. systematic-debugging 技能（4 阶段根因分析）
  2. tdd 技能（先写失败测试复现 Bug）
  3. 最小修复 → 验证 → Harness 检查
  → Kyle 审查 → Max 收尾
```

### Harness 检查

Agent 提交代码前会自动运行 Harness 检查（通过 Git hook），你也可以手动运行：

```bash
# 运行所有检查
bash .harness/run-all.sh

# 单项检查
bash .harness/linters/check-write-scope.sh      # 子代理是否越权修改
bash .harness/linters/check-task-format.sh       # 任务文件格式
bash .harness/linters/check-doc-freshness.sh     # 文档引用是否有效
bash .harness/structural-tests/test-skill-integrity.sh  # 技能系统完整性

# 熵治理扫描（定期运行，检测架构漂移）
bash .harness/garbage-collection/drift-scanner.sh
```

### 自定义与扩展

**添加新的工作流技能：**

在 `.dev-agents/shared/skills/` 下新建 Markdown 文件，包含 YAML frontmatter：

```yaml
---
name: my-new-skill
owner: Jarvis
description: 何时使用这个技能
---
```

然后在 `workflow-lifecycle.md` 中注册触发条件。

**添加新的 Harness 检查：**

在 `.harness/linters/` 或 `.harness/structural-tests/` 下新建 shell 脚本，遵循退出码约定：
- `exit 0` = 通过
- `exit 1` = 失败（阻止）
- `exit 2` = 警告（不阻止）

`run-all.sh` 会自动发现并执行。

**修改角色行为：**

编辑对应的 `.dev-agents/{ella|jarvis|kyle}/PERSONA.md`。修改后 Harness 会阻止子代理直接修改这些文件（需要 Max 级别授权或 `HARNESS_ALLOW_PROTECTED=1`）。

## 集成到你的项目

### 场景一：用框架从零开始一个新项目

```bash
# 1. 克隆框架
git clone <repo-url> my-new-project
cd my-new-project

# 2. 清理框架自身的 git 历史，重新初始化
rm -rf .git
git init
git add .
git commit -m "feat: 初始化项目，基于 aiGroup 多 Agent 框架"

# 3. 安装 Harness
bash .codex/sandbox-setup.sh    # Codex 用户
bash .harness/hooks/install.sh  # Cursor / Claude Code 用户

# 4. 编写你的项目架构文档（替换模板内容）
#    → 编辑 ARCHITECTURE.md，描述你的技术栈和模块结构
#    → 编辑 AGENTS.md 铁律部分，调整提交格式等项目规范

# 5. 启动 Agent，开始开发
codex                # 或打开 Cursor / 运行 claude
```

然后直接告诉 Max 你要做什么：

```
你: "我要开发一个基于 Next.js + Prisma 的博客系统，支持 Markdown 编辑和标签分类"

Max 会自动启动完整工作流：澄清 → 设计 → 计划 → 派发开发 → 审查 → 收尾
```

### 场景二：将框架引入已有项目

**第 1 步：复制框架核心文件到你的项目**

```bash
# 设 FRAMEWORK 为框架目录，PROJECT 为你的项目目录
FRAMEWORK=~/projects/ai-agent-workflowGroup
PROJECT=~/projects/your-project

# 必须复制（协议层 + Harness 层）
cp $FRAMEWORK/AGENTS.md $PROJECT/
cp $FRAMEWORK/ARCHITECTURE.md $PROJECT/
cp -r $FRAMEWORK/.dev-agents $PROJECT/
cp -r $FRAMEWORK/.harness $PROJECT/

# Codex 用户额外复制
cp -r $FRAMEWORK/.codex $PROJECT/

# 不需要复制 skills/（通过符号链接引用）
# 不需要复制 scripts/、README.md
```

**第 2 步：链接领域技能（避免重复文件）**

```bash
cd $PROJECT

# 符号链接领域技能库（所有项目共享同一份）
ln -s $FRAMEWORK/skills skills

# Windows (PowerShell)
# cmd /c mklink /J skills $FRAMEWORK\skills
```

**第 3 步：定制项目专属内容**

你需要根据自己的项目修改以下文件：

**`ARCHITECTURE.md`** — 用你自己的项目架构替换模板内容：

```markdown
## 技术栈
- 框架: Next.js 15 (App Router)
- 数据库: PostgreSQL + Prisma
- 样式: Tailwind CSS
- 测试: Vitest + Playwright

## 目录结构
src/
├── app/           # 路由和页面
├── components/    # UI 组件
├── lib/           # 业务逻辑
├── server/        # Server Actions
└── prisma/        # 数据库 Schema

## 模块边界
- components/ 不能导入 server/
- lib/ 不能直接访问数据库，必须通过 server/
```

**`AGENTS.md`** 铁律部分 — 调整为你的项目规范：

```markdown
## 铁律
...
6. **提交格式** — `<type>(scope): <英文描述>`  ← 改成你的格式
7. ...
```

**`.harness/linters/`** — 添加你项目实际的检查脚本：

```bash
# .harness/linters/check-lint.sh — 包装你的 Linter
#!/bin/bash
set -euo pipefail
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
npm run lint 2>&1 || { echo "Lint check failed"; exit 1; }

# .harness/linters/check-types.sh — TypeScript 类型检查
#!/bin/bash
set -euo pipefail
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
npx tsc --noEmit 2>&1 || { echo "Type check failed"; exit 1; }
```

新增的脚本会被 `run-all.sh` 自动发现和执行。

**第 4 步：安装 Harness 并验证**

```bash
cd $PROJECT

# 安装 Git hook
bash .harness/hooks/install.sh

# Codex 用户：一键安装（含 notify hook）
bash .codex/sandbox-setup.sh

# 验证一切正常
bash .harness/run-all.sh
```

**第 5 步：添加 .gitignore 条目**

在你项目的 `.gitignore` 中追加：

```gitignore
# aiGroup 运行时产物
.dev-agents/shared/tasks/*.md
!.dev-agents/shared/tasks/.gitkeep
.dev-agents/shared/designs/*.md
!.dev-agents/shared/designs/.gitkeep
.dev-agents/shared/reviews/*.md
!.dev-agents/shared/reviews/.gitkeep
.harness/notify.log
.worktrees/
```

### 不需要所有角色？

框架支持按需裁剪：

| 项目类型 | 推荐角色 | 省略 |
|---------|---------|------|
| 全栈 Web 应用 | Max + Ella + Jarvis + Kyle | 无 |
| 纯后端 / API | Max + Jarvis + Kyle | Ella |
| 个人小项目 | Max + Jarvis | Ella + Kyle |
| 纯文档 / 规划 | Max | Ella + Jarvis + Kyle |

省略角色时，只需在 `AGENTS.md` 的团队角色表中移除对应行即可，`.dev-agents/` 下的文件保留不影响。

### 多个项目共享同一套框架

如果你有多个项目都想用同一套框架，推荐的方式是：

```
~/frameworks/ai-agent-workflowGroup/   ← 框架仓库（只维护一份）
  ├── .dev-agents/
  ├── .harness/
  ├── skills/
  └── ...

~/projects/project-a/                  ← 项目 A
  ├── AGENTS.md                        ← 复制后定制
  ├── ARCHITECTURE.md                  ← 项目专属
  ├── .dev-agents/ → 符号链接          ← 共享
  ├── .harness/ → 符号链接 + 本地扩展   ← 共享基础 + 项目专属检查
  └── skills → 符号链接                ← 共享

~/projects/project-b/                  ← 项目 B（同理）
```

```bash
# 为项目 A 创建符号链接
cd ~/projects/project-a
ln -s ~/frameworks/ai-agent-workflowGroup/.dev-agents .dev-agents
ln -s ~/frameworks/ai-agent-workflowGroup/skills skills

# AGENTS.md 和 ARCHITECTURE.md 不要链接，每个项目需要独立定制
cp ~/frameworks/ai-agent-workflowGroup/AGENTS.md .
cp ~/frameworks/ai-agent-workflowGroup/ARCHITECTURE.md .
```

如果项目需要额外的 Harness 检查（如特定框架的 Linter），在项目本地的 `.harness/linters/` 中添加即可。

## 项目结构

```
.
├── AGENTS.md                    # 多 Agent 协议（索引式入口）
├── ARCHITECTURE.md              # 架构地图（Harness 层级全貌）
├── .codex/setup.md              # Codex 安装配置
├── .dev-agents/                 # Feedforward Guides
│   ├── ella/PERSONA.md          # Ella 角色定义
│   ├── jarvis/PERSONA.md        # Jarvis 角色定义
│   ├── kyle/PERSONA.md          # Kyle 角色定义
│   └── shared/
│       ├── skills/              # 工作流技能（8 个）
│       ├── templates/           # 结构化模板（12 个）
│       ├── references/          # 参考文档 + 详细协议规则
│       ├── tasks/               # 任务产物
│       ├── designs/             # 设计产物
│       └── reviews/             # 审查产物
├── .harness/                    # Feedback Sensors（Computational）
│   ├── run-all.sh               # 一键执行所有检查
│   ├── linters/                 # 自定义 Linter（3 个）
│   ├── structural-tests/        # 架构结构测试（3 个）
│   ├── hooks/                   # Git pre-commit hook
│   ├── quality/                 # 模块质量评分
│   └── garbage-collection/      # 熵治理扫描
├── skills/                      # 领域技能资源库
└── scripts/                     # 维护脚本
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

## 更新与维护

```bash
# 更新外部领域技能
bash scripts/update-skills.sh all

# 更新后验证完整性
bash .harness/run-all.sh
```

## Harness Engineering

基于 [OpenAI Harness Engineering](https://openai.com/index/harness-engineering/) 和 [Martin Fowler 的分析框架](https://martinfowler.com/articles/harness-engineering.html) 构建。

**核心公式：** `Agent = Model + Harness`

| 层 | 类型 | 内容 |
|----|------|------|
| Feedforward Guides | Inferential | AGENTS.md、技能、模板、PERSONA |
| Feedback Sensors | Computational | `.harness/` Linter、结构测试、Hook |
| Steering Loop | Both | harness-log + 约束升级阶梯 |
| Garbage Collection | Computational | 定期漂移扫描 + 质量评分 |

```bash
# 首次安装（安装 Git hook + 输出 notify 配置指引）
bash .codex/sandbox-setup.sh

# 手动运行所有 Harness 检查
bash .harness/run-all.sh

# 熵治理扫描（建议每周）
bash .harness/garbage-collection/drift-scanner.sh
```

**Codex 自动化（两层 Computational Sensor）：**
1. `[notify]` hook — 配置到 `~/.codex/config.toml`，Agent 每个 turn 结束后自动执行验证
2. Git pre-commit hook — 安装后每次 `git commit` 自动触发检查，Agent 无法绕过

## 设计理念

受 [superpowers](https://github.com/obra/superpowers) 启发，融合 Harness Engineering 范式：

- **Harness 优先** — 能用代码强制执行的约束，不靠提示词
- **技能驱动** — 不是建议，是强制流程
- **测试先行** — 没有失败测试就不写代码
- **系统化调试** — 根因优先，禁止盲修
- **证据优先** — 运行命令后才能声称结果
- **角色分工** — 设计、开发、审查严格分离
- **Steering Loop** — Agent 犯错 → 改进环境，而非换模型
