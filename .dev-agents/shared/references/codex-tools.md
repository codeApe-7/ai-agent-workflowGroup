# Codex 工具映射参考

aiGroup 技能中使用的通用工具名称与 Codex CLI 实际工具的对应关系。

## 核心工具映射

| 通用名称 | Codex 工具 | 说明 |
|----------|-----------|------|
| 创建子代理 | `spawn_agent` | 创建角色子代理执行任务 |
| 发送输入 | `send_input` | 向运行中的子代理补充上下文 |
| 等待代理 | `wait_agent` | 等待子代理完成并获取结果 |
| 读取文件 | `read_file` | 读取项目文件内容 |
| 写入文件 | `write_file` | 创建或覆盖文件 |
| 编辑文件 | `edit_file` | 精确替换文件中的内容 |
| 执行命令 | `shell` | 执行 bash/powershell 命令 |
| 任务追踪 | `TodoWrite` | 创建和更新任务清单 |

## 与其他平台的对照

| 操作 | Codex | Cursor | Claude Code |
|------|-------|--------|-------------|
| 创建子代理 | `spawn_agent` | `Task` tool | subagent dispatch |
| 发送消息 | `send_input` | `resume` parameter | `send_input` |
| 等待结果 | `wait_agent` | `Await` tool | `wait_agent` |
| 读取文件 | `read_file` | `Read` tool | `Read` tool |
| 写入文件 | `write_file` | `Write` tool | `Write` tool |
| 编辑文件 | `edit_file` | `StrReplace` tool | `Edit` tool |
| 搜索代码 | `grep` / `glob` | `Grep` / `Glob` | `Grep` / `Glob` |
| 执行命令 | `shell` | `Shell` tool | `Bash` tool |
| 任务列表 | `TodoWrite` | `TodoWrite` | `TodoWrite` |

## Codex 特有注意事项

### 子代理隔离

Codex 子代理不继承主线程的对话历史。必须通过 `spawn_agent` 的提示参数提供完整上下文：

- 角色人格文件路径
- 适用技能文件路径
- 任务完整文本（不要让子代理自己读计划文件）
- WRITE_SCOPE 和 TEST_COMMAND

### 多代理特性

使用子代理驱动开发需要启用多代理特性：

```toml
[features]
multi_agent = true
```

### 文件操作

Codex 的 `edit_file` 使用精确匹配替换（类似 Cursor 的 `StrReplace`）。编辑时：

- 提供足够的上下文确保唯一匹配
- 保持原始缩进
- 一次只做一处修改

### 命令执行

Codex 的 `shell` 工具：

- 工作目录在调用间持久化
- 长时间命令会移到后台
- 使用 `&&` 链接依赖命令
- 避免需要交互式输入的命令

## Harness 自动化集成

Harness 检查在 Codex 中的自动化机制（按 Codex 原生 API 实现）：

### 机制 1: `[notify]` Post-Turn Hook（每个 turn 后自动触发）

Codex 原生支持的通知钩子。Agent 每完成一个 turn，自动执行指定脚本。

配置方式 — 在 `~/.codex/config.toml` 中添加：

```toml
[notify]
command = "/absolute/path/to/project/.codex/hooks/post-turn.sh"
```

`.codex/hooks/post-turn.sh` 会自动验证：
- 是否有保护文件被暂存修改
- 关键文件是否存在
- 新增任务文件是否符合命名规范

**这是 Codex 原生的、Agent 无法跳过的 Computational Sensor。**

### 机制 2: Git Pre-commit Hook（提交时自动触发）

安装后（`bash .harness/hooks/install.sh`），Agent 执行 `git commit` 会自动触发 `.harness/hooks/pre-commit.sh`：
- 检测保护文件修改
- 验证任务文件格式
- 扫描敏感信息泄漏

Agent 只能通过 `--no-verify` 跳过（可在 AGENTS.md 中明确禁止）。

### 机制 3: AGENTS.md + 模板指令（会话开始时读取）

Codex 启动时自动读取 `AGENTS.md`。其中"铁律"部分要求 Agent 在提交前运行 Harness 检查。
`implementer-prompt.md` 和 `codex-subtask.md` 中包含 "Harness 检查门" 清单。

这是 Inferential 层面的约束 — Agent 读到后应当执行，但理论上可以跳过。

### 机制 4: Plugin hooks.json（可选，插件体系）

如果将项目封装为 Codex Plugin，可在 `.codex-plugin/plugin.json` 中注册 `hooks.json`：

```json
{
  "name": "aigroup-harness",
  "hooks": "./hooks.json",
  "skills": "../.dev-agents/shared/skills/"
}
```

### 自动化强度排序

| 机制 | 类型 | 可被跳过？ | 触发点 | 配置方式 |
|------|------|-----------|--------|---------|
| `[notify]` hook | Computational | 否 | 每个 turn 结束 | `~/.codex/config.toml` |
| Git pre-commit | Computational | 仅 `--no-verify` | `git commit` | `bash .harness/hooks/install.sh` |
| AGENTS.md 铁律 | Inferential | Agent 可能遗漏 | 会话开始 | 项目根目录 |
| 模板 Harness 检查门 | Inferential | Agent 可能遗漏 | 任务执行中 | `.dev-agents/shared/templates/` |

**原则：尽量把检查推到 Computational 层。** 如果 Agent 反复跳过模板中的 Harness 检查，
应升级到 pre-commit hook 或 notify hook（记录到 `harness-log.mdc`，走 Steering Loop）。

### 首次安装

```bash
# 一键安装 Git hook + 验证结构 + 输出 notify 配置指引
bash .codex/sandbox-setup.sh
```
