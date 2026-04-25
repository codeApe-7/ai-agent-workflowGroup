# Hooks

> Claude Code 与 Codex 在 hook 支持上的差异是**最大的运行时不对称**，本文记录两端如何应对。

## 平台支持

| Harness | Hook 支持 | 配置位置 |
|---------|-----------|---------|
| Claude Code | ✅ 原生（`PostToolUse` / `Stop` / `SessionStart` / `PreToolUse` 等 8+ 事件） | `.claude/hooks.json` |
| Codex CLI | ❌ 不支持任何 hook | — |

## Claude Code Hook 事件

| 事件 | 触发时机 | 当前脚本 | exit 行为 |
|------|---------|---------|----------|
| `PostToolUse` | Agent 编辑文件后 | `hook-post-edit.sh` | 0 静默 / 2 错误回注 |
| `Stop` | Agent 准备停止时 | `hook-stop.sh` | 0 允许 / 2 阻止 |
| `SubagentStop` | 子 agent 完成时 | `hook-subagent-stop.sh` | — |

详细配置见 `.claude/hooks.json`。

## Codex 兜底方案

Codex 无 hook 支持，所有自动化必须**主动调用**：

| Claude 自动事件 | Codex 手动替代 |
|----------------|----------------|
| 编辑后传感器检查 | 主动跑 `node scripts/hooks/dispatcher.cjs stop` |
| Stop 完整性校验 | Agent prompt 内自检；或派 `reviewer` |
| 工具调用前权限校验 | 用 `sandbox_mode = "read-only"` profile |
| 会话开始注入上下文 | `persistent_instructions` + 自动加载 `AGENTS.md` |

## Hook 编写约束

### 阻塞型（PreToolUse / Stop）
- **必须快**（< 200ms）
- **不做网络调用**
- **不阻塞**正常工具执行
- 解析失败时 `exit 0`（不阻塞）

### 异步型（PostToolUse 长任务）
- 在 `settings.json` 标记 `"async": true`
- 超时 ≤ 30s
- 失败仅打印警告，不阻塞流程

### 通用规则
- 所有 hook 脚本错误日志加 `[HookName]` 前缀写到 stderr
- 解析错误一律 `exit 0`，不影响主流程
- 不要直接调用其他 hook（避免循环）

## 用户可绕过吗？

- **Claude Code**：无法绕过 hook（除非禁用整个 hooks.json）
- **Codex**：完全靠 agent 自觉调用，因此 reviewer / build_fixer 的 prompt 都明确要求"主动跑 run-all.sh"

## 不应该用 hook 做的事

- ❌ 复杂业务逻辑（hook 不适合，应放在 agent 或 skill）
- ❌ 长时间运算（除非异步）
- ❌ 用户交互（hook 是无人值守的）
- ❌ 修改 git 状态（除非用户明确授权）
