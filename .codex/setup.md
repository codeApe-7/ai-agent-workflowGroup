# aiGroup Codex 安装与配置

在 Codex 中使用 aiGroup 多 Agent 协作框架。

## 前置条件

- OpenAI Codex CLI
- Git

## 安装步骤

### 1. 克隆项目

```bash
git clone <your-repo-url> ~/projects/work-group-improve
cd ~/projects/work-group-improve
```

### 2. 注册技能到 Codex（可选）

Codex 通过 `~/.agents/skills/` 目录自动发现技能。将本项目的双层技能链接过去：

```bash
mkdir -p ~/.agents/skills

# 第一层：工作流技能（强制流程）
ln -s ~/projects/work-group-improve/.dev-agents/shared/skills ~/.agents/skills/aigroup-workflow

# 第二层：领域技能（专业知识）
ln -s ~/projects/work-group-improve/skills ~/.agents/skills/aigroup-domain
```

**Windows (PowerShell):**

```powershell
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.agents\skills"

# 第一层：工作流技能
cmd /c mklink /J "$env:USERPROFILE\.agents\skills\aigroup-workflow" "$env:USERPROFILE\projects\work-group-improve\.dev-agents\shared\skills"

# 第二层：领域技能
cmd /c mklink /J "$env:USERPROFILE\.agents\skills\aigroup-domain" "$env:USERPROFILE\projects\work-group-improve\skills"
```

### 3. 启用子代理与嵌套 AGENTS.md 支持

在 `~/.codex/config.toml` 中启用：

```toml
[features]
multi_agent = true
child_agents_md = true
```

- `multi_agent` — 启用 `spawn_agent` 子代理功能
- `child_agents_md` — 启用嵌套 AGENTS.md 发现，子目录中的 AGENTS.md 会覆盖父级指令

### 4. 安装 Harness（一键）

```bash
bash .codex/sandbox-setup.sh
```

此脚本会：
- 安装 Git pre-commit hook → 每次 `git commit` 自动检查
- 验证项目结构完整性
- 输出 `[notify]` hook 配置指引

### 5. 重启 Codex

退出并重新启动 Codex CLI，使技能被自动发现。

## 工作原理

Codex 启动时自动读取项目根目录的 `AGENTS.md`，其中定义了：

- **Max（主线程）** 负责需求分析、任务拆解、进度协调
- **Ella / Jarvis / Kyle（子代理）** 通过 `spawn_agent` 创建，执行具体任务

### 双层技能系统

| 层级 | 目录 | 性质 | 内容 |
|------|------|------|------|
| 第一层 | `.dev-agents/shared/skills/` | 强制遵循 | 8 个工作流技能（brainstorming → tdd → verification → review → finish） |
| 第二层 | `skills/` | 按需激活 | 27 个领域技能（UI 设计、全栈开发、QA、项目管理等） |

**调用优先级：** 工作流技能 > 领域技能。工作流技能定义"怎么做"，领域技能提供"做什么的专业知识"。

### 标准工作流

```
用户提需求 → Max 澄清 → Max 设计（brainstorming）
  → Max 计划（writing-plans）
  → Jarvis 开发（tdd + 领域技能）→ Kyle 审查（code-review-dispatch）
  → Max 收尾（finishing-branch）
```

各角色可用的领域技能详见其 PERSONA.md（`.dev-agents/{ella|jarvis|kyle}/PERSONA.md`）。

## Codex 工具映射

| 通用名称 | Codex 工具 | 说明 |
|----------|-----------|------|
| 创建子代理 | `spawn_agent` | 创建角色子代理执行任务 |
| 发送消息 | `send_input` | 向子代理补充上下文 |
| 等待结果 | `wait_agent` | 等待子代理完成 |
| 任务追踪 | `TodoWrite` | 创建和更新任务清单 |
| 执行命令 | `shell` | 执行 bash/powershell 命令 |
| 读取文件 | `read_file` | 读取项目文件 |
| 写入文件 | `write_file` | 创建或覆盖文件 |
| 编辑文件 | `edit_file` | 精确替换文件内容 |

完整跨平台映射见 `.dev-agents/shared/references/codex-tools.md`。

## 验证

```bash
# 确认 AGENTS.md 存在
head -5 AGENTS.md

# 确认工作流技能（第一层）
ls .dev-agents/shared/skills/

# 确认领域技能（第二层）
ls skills/

# 确认子代理模板
ls .dev-agents/shared/templates/

# 确认 Harness 层
bash .harness/run-all.sh

# 确认 pre-commit hook 已安装
test -f .git/hooks/pre-commit && echo "Hook installed" || echo "Hook missing — run: bash .harness/hooks/install.sh"

# 确认 Codex 技能链接（可选步骤 2 完成后）
ls -la ~/.agents/skills/aigroup-workflow
ls -la ~/.agents/skills/aigroup-domain
```

## 更新

```bash
cd ~/projects/work-group-improve && git pull

# 更新外部领域技能
bash scripts/update-skills.sh all
```

两层技能通过符号链接即时生效。

## 卸载

```bash
rm ~/.agents/skills/aigroup-workflow
rm ~/.agents/skills/aigroup-domain
```

**Windows (PowerShell):**

```powershell
Remove-Item "$env:USERPROFILE\.agents\skills\aigroup-workflow"
Remove-Item "$env:USERPROFILE\.agents\skills\aigroup-domain"
```
