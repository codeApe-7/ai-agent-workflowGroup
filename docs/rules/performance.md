# Performance And Context Budget

> 基线规则：上下文窗口是运行预算，不是无限缓存。

## MCP / Tool Budget

- 项目级默认只启用轻量 MCP：GitHub、Context7、Memory、Sequential-Thinking。
- 单项目启用 MCP 数量保持在 10 个以内。
- 活跃工具总量保持在 80 个以内。
- Supabase、Vercel、Railway、Cloudflare、Playwright、Exa 等重型 MCP 按任务临时启用，不写入默认必启基线。
- 新增 MCP 前必须说明：用途、触发场景、关闭方式、是否需要密钥。

## Context Hygiene

- 根 `CLAUDE.md` / `AGENTS.md` 只做导航，不复制长篇规则。
- 完整规则放在 `docs/rules/`，执行方法放在 `skills/<name>/SKILL.md`。
- Agent prompt 只注入任务目标、文件路径、skill 路径、验收条件和验证命令。
- 不在 prompt 中重复 agent 身份、人格、长背景；这些属于 agent 定义文件。

## Long-Running Work

- 长任务优先拆成阶段产物，写入 `.orchestration/<session>/`。
- 失败日志只保留关键错误、命令、文件路径和下一步，不粘贴整段无关输出。
- 进入最后 20% 上下文窗口时，不启动大重构；先 compact 或落盘当前状态。

## Verification Cost

- 默认先跑最小相关测试，再跑 harness 全量检查。
- 构建失败交给 `build-error-resolver` / `build_fixer` 做最小修复，不顺手重构。
- 文档查证优先 `docs_researcher` / Context7 / web_search，不把过期外部信息写进规则。
