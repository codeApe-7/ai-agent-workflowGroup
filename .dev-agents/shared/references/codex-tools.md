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
