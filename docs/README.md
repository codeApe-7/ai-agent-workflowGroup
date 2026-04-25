# aiGroup 知识库索引

本目录是项目的**唯一事实源 (Single Source of Truth)**，所有架构决策、规范均版本化存储于此。

Agent 应按需检索本目录下的文档，而非依赖 CLAUDE.md / AGENTS.md 中的简短描述。

## 文档地图

### 强制规则（必读）

| 文档 | 主题 |
|------|------|
| [rules/README.md](rules/README.md) | Rules 总入口（Rules vs Skills 边界） |
| [rules/agents.md](rules/agents.md) | Agent 派遣铁律 + 启动协议 + 反模式 |
| [rules/coding-style.md](rules/coding-style.md) | 编码风格、命名、错误处理、中文注释 |
| [rules/git-workflow.md](rules/git-workflow.md) | Conventional Commits、Git 安全 |
| [rules/testing.md](rules/testing.md) | TDD、覆盖率、AAA 模式 |
| [rules/security.md](rules/security.md) | 安全清单、密钥管理、OWASP |
| [rules/performance.md](rules/performance.md) | MCP / tool 预算、上下文卫生 |
| [rules/hooks.md](rules/hooks.md) | Hooks 使用（Claude 自动 / Codex 手动） |

### 派遣与流程

| 文档 | 用途 |
|------|------|
| [rules/agents.md](rules/agents.md) | **Agent 派遣完整矩阵**（agent 模块分组、handoff 内容、反模式） |
| [workflow-pipeline.md](workflow-pipeline.md) | 工作流 phase 心智模型（按需裁剪） |

### 治理

| 文档 | 用途 |
|------|------|
| [red-flags.md](red-flags.md) | 主会话必须阻止的危险信号与对应行动 |
| [PROJECT_CONTEXT.md](PROJECT_CONTEXT.md) | 项目实例上下文（/init-project 生成） |

## 子目录

- `rules/` — 强制规则集（按领域切分）
- `templates/` — 静态文档模板（PRD / 实现计划 / 代码审查等）

## 使用原则

1. **渐进式披露** — Agent 先读 CLAUDE.md / AGENTS.md 获取全局地图，按需深入本目录
2. **仓库即事实** — 所有约束、决策、规范必须存在于仓库文件中，不依赖口头约定
3. **Rules vs Skills** — Rules 决定**必须做什么**；Skills 决定**怎么做**
4. **文档即代码** — 文档与代码同步更新
