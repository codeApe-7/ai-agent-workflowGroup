# Rules

> 短小、强制、可勾选的规则集。Skills 告诉你"怎么做"，Rules 告诉你"必须做什么"。
> 通用规则按领域切分（agents / coding-style / git / testing / security / performance / hooks），语言专项按栈分目录（采用 ECC 规则原版）。

## 通用规则（所有项目）

| 文件 | 主题 |
|------|------|
| [agents.md](agents.md) | Agent 派遣规则（采用 ECC zh） |
| [coding-style.md](coding-style.md) | 编码风格、命名、错误处理、中文注释 |
| [git-workflow.md](git-workflow.md) | Conventional Commits、Git 安全 |
| [testing.md](testing.md) | TDD、覆盖率、测试结构 |
| [security.md](security.md) | 安全清单、密钥管理、应急响应 |
| [performance.md](performance.md) | MCP / tool 预算、上下文卫生、长任务拆分 |
| [hooks.md](hooks.md) | Hooks 使用规则（Claude 自动 / Codex 手动） |

## 语言专项（按栈加载，采用 ECC 规则原版）

每个语言目录含 5 个标准维度：`coding-style.md` / `patterns.md` / `testing.md` / `security.md` / `hooks.md`。`web` 额外含 `design-quality.md` / `performance.md`。

| 目录 | 适用 |
|------|------|
| [cpp/](cpp/) | C / C++ |
| [csharp/](csharp/) | C# / .NET |
| [dart/](dart/) | Dart / Flutter |
| [golang/](golang/) | Go |
| [java/](java/) | Java / Spring Boot / Kotlin (JVM) |
| [kotlin/](kotlin/) | Kotlin / Android / KMP |
| [perl/](perl/) | Perl |
| [php/](php/) | PHP / Laravel |
| [python/](python/) | Python / Django / FastAPI / PyTorch |
| [rust/](rust/) | Rust |
| [swift/](swift/) | Swift / iOS |
| [typescript/](typescript/) | TypeScript / JavaScript / React / Next.js |
| [web/](web/) | HTML / CSS / 前端通用（额外含 design-quality / performance） |

## Rules vs Skills

- **Rules** — 始终遵守的标准（"测试覆盖率 ≥ 80%"、"密钥不入代码"、"派遣不可跳过"）
- **Skills** — 完成具体任务的方法论与示例（`writing-plans/SKILL.md`、`code-reviewer/SKILL.md`）

Rules 决定**必须做什么**；Skills 决定**怎么做**。

## 与现有文档的关系

| 现有文档 | 作用 | 与 rules/ 的关系 |
|----------|------|------------------|
| `docs/red-flags.md` | 危险信号检测 | rules/agents.md + rules/security.md 的反向版本 |
| `docs/workflow-pipeline.md` | 工作流 phase 心智模型 | rules/agents.md 的"何时使用"展开 |
| `.codex/config.toml` | Codex MCP 与 persona 基线 | rules/performance.md 约束默认启用范围 |
