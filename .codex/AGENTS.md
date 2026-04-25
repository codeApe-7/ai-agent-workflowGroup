# aiGroup for Codex CLI

> 本文件是根 `AGENTS.md` 的 Codex 专属补充。**agent 派遣规则与 Claude Code 端共享一份**——见 `docs/rules/agents.md`。
> 本文件只讲 Codex 端独有的：模型 / Skills 加载方式 / MCP / Codex 原生 persona / 无 hook 兜底。

## 模型推荐

| 任务类型 | 推荐模型 |
|----------|----------|
| 常规编码、测试、格式化 | GPT 5.4 |
| 复杂功能、架构 | GPT 5.4 |
| 代码审查、安全 | GPT 5.4（reasoning_effort = high） |
| 只读探索、文档研究 | GPT 5.4（reasoning_effort = medium） |

## Skills 加载

Skills 主源位于 `skills/<name>/SKILL.md`，跨平台共享。Codex 端**按任务意图加载文件路径**——不像 Claude Code 那样自动发现。

常用入口：

- `skills/writing-plans/SKILL.md` — 规划
- `skills/requirement-engineering/SKILL.md` — 需求收集与验证
- `skills/architecture-designer/SKILL.md` — 架构设计
- `skills/api-designer/SKILL.md` — API 契约
- `skills/code-reviewer/SKILL.md` — 代码审查
- `skills/security-reviewer/SKILL.md` — 安全审查
- `skills/tdd-guide/SKILL.md` / `skills/test-master/SKILL.md` — 测试
- `skills/systematic-debugging/SKILL.md` — 调试
- `skills/verification-before-completion/SKILL.md` — 完成前验证

完整分类见 `manifests/install-modules.json`。

## Codex 原生 Persona

`.codex/config.toml` 声明的 3 个 persona——**不是和 Claude agent 一一映射**，而是 Codex 自身需要"切换 sandbox / reasoning_effort"才生效的场景：

| Persona | 用途 |
|---------|------|
| `explorer` | 只读 sandbox，证据收集与执行路径追踪 |
| `reviewer` | 高 reasoning，代码 + 安全审查 |
| `docs_researcher` | API / 文档 / 版本行为查证（带网络访问） |

切换方式：

```bash
/agent explorer
/agent reviewer
/agent docs_researcher
```

**其他工作（planning / implementation / build-fixing）由 Codex 主对话直接做**——加载对应 skill 即可，无需切 persona。这也是与 ECC 一致的做法。

## MCP 服务器

项目级基线（`.codex/config.toml`）启用：GitHub、Context7、Memory、Sequential-Thinking。

预算规则见 `docs/rules/performance.md`：单项目启用 MCP 少于 10 个，活跃工具少于 80 个。Playwright / Exa 按需取消注释。重型服务器（Supabase、Firecrawl、Cloudflare）推荐放到用户级 `~/.codex/config.toml`，不要进入项目默认必启基线。

## 与 Claude Code 的关键差异

| 特性 | Claude Code | Codex CLI |
|------|-------------|-----------|
| Hooks | 自动触发 PostToolUse / Stop / SubagentStop | **不支持** —— 必须主动运行 dispatcher |
| Skill 发现 | 启动时自动加载 `skills/` | 按路径手动加载 |
| 命令 | `/slash` commands（`.claude/commands/`） | 主对话指令 + `/agent <persona>` |
| 子代理派遣 | `Agent({ subagent_type })` 工具调用 | 主对话直接对话；persona 通过 `/agent` 切换 |
| 安全强制 | Hook + 指令 | 指令 + sandbox 模式（`read-only` / `workspace-write`） |
| MCP | 完整支持 | `config.toml` 或 `codex mcp add` |

## 无 Hooks 的兜底强制

Codex 端必须**主动**执行以下动作（Claude Code 由 hooks 自动）：

1. 任何变更完成 → 跑 `node scripts/hooks/dispatcher.cjs stop`
2. 进入 reviewer persona 审完代码 → 跑 `node scripts/hooks/dispatcher.cjs subagent-stop`
3. 安全敏感代码（auth / 支付 / PII / 外部输入）→ 强制走 reviewer persona，不能跳过
4. 提交前跑 `npm audit` / `pip-audit` / `bundle audit`
5. `git diff` 人肉过一遍再推

## 常用命令

```bash
# 进入项目
codex

# 指定 profile（严格只读 / 放任修改）
codex -p strict
codex -p yolo

# 切换到 persona
/agent explorer
/agent reviewer
/agent docs_researcher

# MCP 检查
codex mcp list
```

## 完整 agent 派遣表

参见 `docs/rules/agents.md`——agent 体系**两端共享**，没有"对照映射表"。Codex 端要派"等价于 Claude `tdd-guide`"的工作时：

- 切回主对话（不需要 persona）
- 加载 `skills/tdd-guide/SKILL.md` + 对应框架 / 栈 skill（如 `skills/react-expert/SKILL.md`）
- 按 rules/agents.md 中 `tdd-guide` 的输出格式执行

审查工作走 `reviewer` persona，调研走 `explorer` persona，文档查证走 `docs_researcher` persona——这三个是 Codex 因 sandbox / reasoning 配置不同**才需要**切换的场景。
