# Entropy Rules

> 防止 AI 反复复制不良模式造成的代码漂移。三条 Golden Rule + 沉淀义务。

## Golden Rule 1：共享 utility 优先于手写 helper

**强制**：实现新功能前，必须搜索现有 utility 包；只有在确认无可复用项后才允许手写。

| 场景 | 必须做 |
|------|-------|
| 需要工具函数（格式化、校验、转换） | 先 grep `utils/` `shared/` `common/` 现有实现；存在即复用 |
| 现有实现接近但不完全匹配 | 扩展现有函数而不是新写一个并行版本 |
| 真的需要新函数 | 放进项目约定的共享目录，不放业务模块内 |

**违规信号**：同名/近似名函数在多个文件出现、业务模块内出现纯工具函数、`copy from X` 注释。

**自动检测**：`refactor-cleaner` agent 跑 `knip` / `ts-prune` 检测重复导出与未使用导出；同名函数检测应纳入未来 `scripts/hooks/checks/duplicate-utility.cjs`（待补）。

## Golden Rule 2：边界处必须做数据验证

**强制**：跨信任边界的数据进入系统时，必须经过类型/Schema 验证。"内部代码可信"的假设仅在边界之内成立。

| 边界 | 必须做 |
|------|-------|
| 用户输入（HTTP / CLI / 表单） | Schema 校验后再进业务层 |
| 外部 API 返回 | 类型化 SDK 或显式 Schema 解析 |
| 数据库读取（无强类型 ORM 时） | 出库即校验或类型断言 |
| 进程间消息（队列、IPC） | 反序列化后立刻 Schema 校验 |

**禁止**：
- `as any` / `as unknown as T` 跨边界使用
- `JSON.parse` 后直接当业务对象用
- 把外部数据直接作为内部函数参数传入

**自动检测**：各语言 rules 文件应给出该栈的强制写法（参考 `docs/rules/typescript/` 等）。

## Golden Rule 3：关键子系统自实现 + 全覆盖

**强制**：业务关键路径（鉴权、计费、数据持久化、安全）不外包给"看起来能用"的第三方包；要么用业界标准（且锁版本 + 监控 CVE），要么自实现并保证测试覆盖。

| 子系统类型 | 选择策略 |
|-----------|---------|
| 鉴权 / 加密 / 签名 | 用经过审计的标准库（如 OpenSSL、libsodium、JWT 标准实现），不允许"自己写一个" |
| 计费 / 限流 / 配额 | 自实现 + 100% 行覆盖 + 边界测试齐全 |
| 数据序列化 / 持久化关键字段 | 自实现 + Schema 版本兼容测试 |
| 通用 utility / UI 组件 | 可用社区包，按 Golden Rule 1 复用 |

**禁止**：关键路径依赖未审计的小众包；关键路径测试覆盖率 < 100%。

## 沉淀义务（与本规则配套）

**铁律**：发现的违规不能只修一次。每次熵管理或 code review 发现的反复模式必须在以下位置编码为约束：

| 类型 | 沉淀位置 |
|------|---------|
| 自动可检测的代码模式 | 加 `scripts/hooks/checks/<name>.cjs` 让 dispatcher 报 [FAIL] |
| 跨任务的架构约定 | 写入 `docs/PROJECT_CONTEXT.md` 或 `docs/ARCHITECTURE.md` |
| 强制规则（语言无关） | 加入本文件或 `docs/rules/<topic>.md` |
| 强制规则（语言专项） | 加入 `docs/rules/<lang>/<topic>.md` |
| 高频踩坑信号 | 加入 `docs/red-flags.md` |

未沉淀的修复 = **没修**。

## 触发与执行

- **何时检视本规则**：`entropy-management` skill 第二阶段、code-reviewer 审查、refactor-cleaner 任务前
- **谁负责**：主会话编排，`refactor-cleaner` / `code-reviewer` agent 执行
- **频率**：完成 5 个任务后 / 怀疑漂移时 / 用户主动要求

## 关联

- `skills/entropy-management/SKILL.md` — 执行流程
- `agents/refactor-cleaner.md` — 死代码与重复清理
- `docs/red-flags.md` 信号 #8 / #9 — 反复问题与文档漂移
- `scripts/hooks/checks/` — 自动化传感器套件
