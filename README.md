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

### 强制工作流管道

非简单需求必须经过完整管道，不可跳过或合并环节：

```
需求澄清 → 方案设计 → 用户批准 → 实现计划 → 开发(TDD) → 两阶段审查 → 完成
```

```mermaid
flowchart TD
    UserReq["用户需求"] --> MaxAnalyze["Max 分析需求"]
    MaxAnalyze --> Simple{"简单问题?"}
    Simple -->|"是"| MaxDirect["Max 直接回答"]
    Simple -->|"否"| Brainstorm["需求澄清 + 方案设计\n(brainstorming skill)"]
    Brainstorm --> SpecApproval{"用户批准设计?"}
    SpecApproval -->|"否"| Brainstorm
    SpecApproval -->|"是"| WritePlan["写实现计划\n(writing-plans skill)"]
    WritePlan --> NeedDesign{"需要 UI 设计?"}
    NeedDesign -->|"是"| Ella["/ella 设计"]
    NeedDesign -->|"否"| Jarvis["/jarvis 开发 (TDD)"]
    Ella --> Jarvis
    Jarvis --> SpecReview["/kyle Stage 1: 规格符合性"]
    SpecReview --> SpecPass{"符合计划?"}
    SpecPass -->|"否"| JarvisFix["Jarvis 修复"]
    JarvisFix --> SpecReview
    SpecPass -->|"是"| QualityReview["/kyle Stage 2: 代码质量"]
    QualityReview --> QualityPass{"质量达标?"}
    QualityPass -->|"否"| JarvisFix2["Jarvis 修复"]
    JarvisFix2 --> QualityReview
    QualityPass -->|"是"| Done["完成"]
```

### 三条铁律

| 铁律 | 说明 |
|------|------|
| 证据优于断言 | 任何完成声明必须附带验证证据，禁止"应该没问题" |
| 流程不可跳过 | 工作流管道的每个环节必须走完 |
| 不确定时先问 | 宁可多问一句，不要假设 |

### 任务派遣决策流程

```mermaid
flowchart TD
    Input([用户输入需求]) --> Parse[Max 解析需求]
    Parse --> Classify{需求分类}

    Classify -->|界面/交互/视觉/原型| Design[设计需求]
    Classify -->|编码/功能/API/修复| Dev[开发需求]
    Classify -->|审查/验收/测试/安全| QA[质量需求]
    Classify -->|咨询/解释/简单问答| Simple[简单问题]

    Design --> NeedClarify1{需求是否清晰?}
    NeedClarify1 -->|否| Ask1[追问用户澄清]
    Ask1 --> NeedClarify1
    NeedClarify1 -->|是| DispatchElla["派遣艾拉<br/>注入: 需求描述 + 项目上下文"]

    Dev --> NeedClarify2{需求是否清晰?}
    NeedClarify2 -->|否| Ask2[追问用户澄清]
    Ask2 --> NeedClarify2
    NeedClarify2 -->|是| HasDesign{有设计稿?}
    HasDesign -->|是| DispatchJarvisWithDesign["派遣贾维斯<br/>注入: 需求 + 设计稿路径"]
    HasDesign -->|否| DispatchJarvis["派遣贾维斯<br/>注入: 需求 + 技术上下文"]

    QA --> HasCode{有待审查代码?}
    HasCode -->|是| DispatchKyle["派遣凯尔<br/>注入: 代码路径 + 需求说明"]
    HasCode -->|否| AskCode[提示用户指定审查范围]

    Simple --> MaxAnswer[Max 直接回答]
```

### 完整流水线（设计 → 开发 → 验收）

```mermaid
sequenceDiagram
    participant User as User
    participant Max as Max
    participant Ella as Ella
    participant Jarvis as Jarvis
    participant Kyle as Kyle
    participant Shared as Shared

    User->>Max: 提出需求
    Max->>Max: 分析并拆解任务

    Note over Max,Ella: 阶段一 设计
    Max->>Ella: 派遣设计任务
    Ella->>Shared: 输出设计稿
    Ella-->>Max: 设计完成
    Max-->>User: 需要开发吗

    User->>Max: 确认开发

    Note over Max,Jarvis: 阶段二 开发
    Max->>Jarvis: 派遣开发任务+设计稿路径
    Jarvis->>Shared: 读取设计稿
    Jarvis->>Jarvis: 实现代码
    Jarvis-->>Max: 开发完成
    Max-->>User: 需要验收吗

    User->>Max: 确认验收

    Note over Max,Kyle: 阶段三 验收
    Max->>Kyle: 派遣验收任务+代码路径
    Kyle->>Kyle: 代码审查+功能验收
    Kyle->>Shared: 输出审查报告
    Kyle-->>Max: 验收完成

    Max-->>User: 汇总全流程结果
```

### 上下文传递机制

```mermaid
flowchart LR
    subgraph CTX["独立上下文窗口"]
        MaxCtx["Max 上下文\nRules 自动注入"]
        EllaCtx["Ella 上下文\n独立窗口"]
        JarvisCtx["Jarvis 上下文\n独立窗口"]
        KyleCtx["Kyle 上下文\n独立窗口"]
    end

    subgraph SHARED["共享产物目录"]
        Tasks[("tasks/")]
        Designs[("designs/")]
        Reviews[("reviews/")]
    end

    MaxCtx -->|"派遣时注入\n需求+产物路径"| EllaCtx
    MaxCtx -->|"派遣时注入\n需求+设计稿路径"| JarvisCtx
    MaxCtx -->|"派遣时注入\n代码路径+需求"| KyleCtx

    EllaCtx -->|写入设计稿| Designs
    JarvisCtx -->|读取设计稿| Designs
    KyleCtx -->|写入审查报告| Reviews
    MaxCtx -->|写入任务文档| Tasks

    style MaxCtx fill:#4A90D9,color:#fff
    style EllaCtx fill:#E91E63,color:#fff
    style JarvisCtx fill:#4CAF50,color:#fff
    style KyleCtx fill:#FF9800,color:#fff
```

> **关键规则**：子 Agent 之间不能直接通信，所有上下文由 Max 在派遣时注入，跨 Agent 协作通过 `.dev-agents/shared/` 目录下的文件实现。

### 并行执行场景

```mermaid
flowchart TD
    User([用户: 设计登录页 + 开发后端 API]) --> Max[Max 分析]
    Max --> Check{任务间有依赖?}

    Check -->|无依赖| Parallel["并行派遣<br/>(各自注入完整独立上下文)"]
    Parallel --> Ella2[艾拉: 设计登录页]
    Parallel --> Jarvis2[贾维斯: 开发后端 API]
    Ella2 --> Done1[设计完成]
    Jarvis2 --> Done2[开发完成]
    Done1 --> Merge[Max 汇总两个任务结果]
    Done2 --> Merge

    Check -->|有依赖| Sequential[顺序执行]
    Sequential --> First[先完成前置任务]
    First --> Then[再派遣依赖任务<br/>注入前置产物路径]
    Then --> Merge2[Max 汇总]
```

### Cursor 五层 Harness 架构与 Agent 关系

```mermaid
flowchart TB
    subgraph Layer1["Rules 层 — 上下文注入"]
        R1["project-core.mdc\n核心约定"]
        R2["max-coordinator.mdc\n调度规则 + Harness 反馈"]
        R3["git-conventions.mdc\nGit 安全"]
        R4["shared-artifacts.mdc\n产物规范"]
        R5["harness-log.mdc\n失败案例日志"]
    end

    subgraph Layer2["Subagents 层 — 角色隔离"]
        A1["ella.md\nUI/UX 设计师"]
        A2["jarvis.md\n全栈开发"]
        A3["kyle.md\n质量保障 只读"]
    end

    subgraph Layer4["Hooks 层 — 硬约束"]
        H1["verify-completion.ts\n完成前验证守卫"]
        H2["pre-commit-check.ts\n提交前安全检查"]
    end

    subgraph Layer5["Commands 层 — 工作流复用"]
        C1["/pr"]
        C2["/fix-issue"]
        C3["/review"]
    end

    subgraph Layer3["Skills 层 — 动态知识"]
        S1["ccpm\n项目管理"]
        S2["ui-ux-pro-max\n设计工具"]
        S3["claude-simone\n开发技能"]
        S4["senior-qa\n测试技能"]
    end

    Layer1 -->|注入上下文| Max(("Max\n主 Agent"))
    Layer4 -->|生命周期守卫| Max
    Layer5 -->|一键触发| Max
    Max -->|委派| A1
    Max -->|委派| A2
    Max -->|委派| A3

    S1 -.->|按需加载| Max
    S2 -.->|按需加载| A1
    S3 -.->|按需加载| A2
    S4 -.->|按需加载| A3
```

## 使用示例

```
你: 帮我设计一个登录页面
Max: [分析需求，派遣艾拉] → 艾拉输出设计稿 → .dev-agents/shared/designs/

你: 根据设计稿开发登录功能
Max: [派遣贾维斯，注入设计稿路径] → 贾维斯实现代码

你: 验收一下登录功能
Max: [派遣凯尔，注入代码路径 + 需求] → 凯尔输出审查报告 → .dev-agents/shared/reviews/

你: /pr
Agent: [自动执行] git diff → 撰写 commit message → 推送 → 创建 PR → 返回链接

你: /fix-issue 42
Agent: [自动执行] 获取 Issue 详情 → 定位代码 → TDD 修复 → 验证 → 询问是否创建 PR
```

## 项目结构

```
ai-agent-workflowGroup/
├── .cursor/
│   ├── rules/                     # Rules — 主 Agent (Max) 的行为规则
│   │   ├── project-core.mdc       #   始终生效：核心约定（中文注释、编码规范）
│   │   ├── max-coordinator.mdc    #   始终生效：Max 角色 + 团队调度 + Harness 反馈循环
│   │   ├── git-conventions.mdc    #   始终生效：Git 安全与提交格式
│   │   ├── shared-artifacts.mdc   #   共享目录触发：产物规范
│   │   └── harness-log.mdc        #   Harness 失败案例日志（活文档）
│   ├── agents/                    # Subagents — 可委派的子 Agent
│   │   ├── ella.md                #   艾拉：UI/UX 设计师
│   │   ├── jarvis.md              #   贾维斯：全栈开发工程师
│   │   └── kyle.md                #   凯尔：质量保证工程师（只读模式）
│   ├── hooks/                     # Hooks — Agent 生命周期硬约束
│   │   ├── verify-completion.ts   #   stop hook：完成前验证守卫
│   │   └── pre-commit-check.ts    #   stop hook：提交前安全检查
│   ├── hooks.json                 # Hooks 配置入口
│   ├── commands/                  # Commands — 可复用的工作流命令
│   │   ├── pr.md                  #   /pr：提交并创建 Pull Request
│   │   ├── fix-issue.md           #   /fix-issue：从 Issue 出发修复
│   │   └── review.md              #   /review：代码审查
│   └── skills/                    # Skills — 技能资源（Cursor 自动发现）
│       ├── brainstorming/         #   工作流：需求澄清与方案设计
│       ├── writing-plans/         #   工作流：实现计划编写
│       ├── systematic-debugging/  #   工作流：系统化调试
│       ├── verification-before-completion/ # 工作流：完成前验证
│       ├── ui-ux-pro-max/         #   UI/UX 设计工具（艾拉）
│       ├── senior-frontend/       #   前端开发（艾拉/贾维斯）
│       ├── claude-simone/         #   开发框架（贾维斯）
│       ├── senior-backend/        #   后端开发（贾维斯）
│       ├── senior-qa/             #   QA 测试（凯尔）
│       ├── ccpm/                  #   项目管理（麦克斯）
│       ├── skills-manifest.json   #   技能来源清单（版本追踪）
│       └── ...                    #   更多专业技能（共 27 个）
├── .dev-agents/
│   └── shared/                    # Agent 协作产物
│       ├── tasks/                 #   任务文档
│       ├── designs/               #   设计稿
│       ├── reviews/               #   审查报告
│       └── templates/             #   文档模板
├── scripts/
│   ├── update-skills.ps1          # Skills 更新脚本（Windows）
│   ├── update-skills.sh           # Skills 更新脚本（Linux/Mac）
│   ├── check-gitignore.sh         # .gitignore 检查脚本
│   └── clean-system-files.sh      # 系统文件清理脚本
└── README.md
```

### Cursor 五层 Harness 架构

本项目遵循 [Cursor 官方规范](https://cursor.com/docs) 与 [Harness Engineering](https://martinfowler.com/articles/harness-engineering.html) 范式，通过五层机制实现多 Agent 可靠协作：

| 层级 | 位置 | 作用 | 详情 |
|------|------|------|------|
| **Rules** | `.cursor/rules/` | 注入主 Agent 上下文 | Max 角色、项目约定、Git 规范、Harness 日志始终生效 |
| **Subagents** | `.cursor/agents/` | 独立子 Agent，被 Max 委派 | 艾拉/贾维斯/凯尔各自有独立上下文窗口 |
| **Hooks** | `.cursor/hooks/` | 硬约束 — Agent 生命周期守卫 | 完成前验证、提交前安全检查，系统强制执行 |
| **Commands** | `.cursor/commands/` | 可复用的工作流命令 | `/pr`、`/fix-issue`、`/review` 一键触发 |
| **Skills** | `.cursor/skills/` | 可复用的专业知识包 | 27 个技能包，Cursor 自动发现并按需加载 |

### 子 Agent 调用方式

| 子 Agent | 显式调用 | 自动委派 | 模式 |
|----------|---------|---------|------|
| 艾拉 (Ella) | `/ella` | 涉及设计需求时 Max 自动委派 | 默认（可读写） |
| 贾维斯 (Jarvis) | `/jarvis` | 涉及开发需求时 Max 自动委派 | 默认（可读写） |
| 凯尔 (Kyle) | `/kyle` | 涉及审查/测试需求时 Max 自动委派 | 只读（readonly） |

## 技能来源与更新

| 技能 | 来源 | 许可证 | 更新方式 |
|------|------|--------|---------|
| CCPM 项目管理 | [automazeio/ccpm](https://github.com/automazeio/ccpm) | MIT | 脚本自动 |
| PM Claude Skills | [mohitagw15856/pm-claude-skills](https://github.com/mohitagw15856/pm-claude-skills) | MIT | 脚本自动 |
| Claude Simone | [Helmi/claude-simone](https://github.com/Helmi/claude-simone) | 见原仓库 | 脚本自动 |
| Engineering Team (15个) | [alirezarezvani/claude-skills](https://github.com/alirezarezvani/claude-skills) | 见原仓库 | 脚本自动 |
| UI/UX Pro Max | SkillsMP 技能市场 | MIT | 手动下载 |
| Senior Frontend | SkillsMP 技能市场 | MIT | 手动下载 |
| Senior QA / TDD | SkillsMP 技能市场 | MIT | 手动下载 |

### 更新 Skills

```powershell
# Windows — 更新所有 GitHub 来源的 skill
.\scripts\update-skills.ps1 -Target all

# 只更新某个来源
.\scripts\update-skills.ps1 -Target ccpm
.\scripts\update-skills.ps1 -Target simone
.\scripts\update-skills.ps1 -Target engineering

# 查看需要手动更新的 skill
.\scripts\update-skills.ps1 -Target manual
```

```bash
# Linux/Mac
bash scripts/update-skills.sh all
```

技能来源和版本信息记录在 `.cursor/skills/skills-manifest.json` 中。

## 致谢

本项目的工作流驱动理念、铁律机制和质量门禁设计受到 [Superpowers](https://github.com/obra/superpowers) 项目的启发。Superpowers 是一个优秀的 agentic 开发方法论框架，aiGroup 在保留自身角色体系的基础上融合了其核心思想。

## 许可证

MIT License
