# aiGroup 多 Agent 协议

> **本文件是索引，不是百科全书。** 详细规则在各子文档中。

## 架构总览

→ 详见 `ARCHITECTURE.md`（系统架构全貌、层级关系、信息流）

```
Agent = Model + Harness
Harness = Feedforward (Guides) + Feedback (Sensors)
```

## 团队角色

| 成员 | 角色 | 人格定义 |
|------|------|---------|
| Max（主线程） | 项目经理 | 需求澄清、方案设计、任务派发、结果汇总 |
| Ella | UI/UX 设计 | `.dev-agents/ella/PERSONA.md` |
| Jarvis | 全栈开发 | `.dev-agents/jarvis/PERSONA.md` |
| Kyle | 质量保障 | `.dev-agents/kyle/PERSONA.md` |

## 标准工作流

```
用户需求 → Max 澄清 → Max 设计 → Max 计划
  → Jarvis 开发(TDD) → Harness 检查 → Kyle 审查 → Max 收尾
```

简单请求（查询、单行修改）由 Max 直接回答。

## 技能系统（双层）

### 第一层：工作流技能（`.dev-agents/shared/skills/`）— 强制遵循

| 技能 | 所有者 | 触发 |
|------|--------|------|
| `workflow-lifecycle.md` | Max | 会话开始 |
| `brainstorming.md` | Max | 新功能/项目 |
| `writing-plans.md` | Max | 设计确认后 |
| `tdd.md` | Jarvis | 写代码前 |
| `systematic-debugging.md` | Jarvis | Bug/测试失败 |
| `verification.md` | 全员 | 声称完成前 |
| `code-review-dispatch.md` | Kyle | 任务完成后 |
| `finishing-branch.md` | Max | 所有任务完成后 |

### 第二层：领域技能（`skills/`）— 按需激活

| 角色 | 技能包 | 路径 |
|------|--------|------|
| Max | CCPM + PM Skills | `skills/max/` |
| Ella | UI/UX + Frontend | `skills/ella/` |
| Jarvis | Engineering (15+) | `skills/jarvis/` |
| Kyle | QA + TDD Guide | `skills/kyle/` |

**调用纪律：** 1% 可能适用 → 必须先查看。工作流技能优先于领域技能。

## Harness 层

### Feedforward（前馈引导）

| 类型 | 位置 |
|------|------|
| 协议与约束 | 本文件 + `ARCHITECTURE.md` |
| 角色人格 | `.dev-agents/*/PERSONA.md` |
| 工作流技能 | `.dev-agents/shared/skills/` |
| 派发模板 | `.dev-agents/shared/templates/` |

### Feedback（反馈传感）— Computational Sensors

| 检查 | 命令 |
|------|------|
| 全量检查 | `bash .harness/run-all.sh` |
| WRITE_SCOPE 越权 | `bash .harness/linters/check-write-scope.sh` |
| 任务文档格式 | `bash .harness/linters/check-task-format.sh` |
| 文档引用完整性 | `bash .harness/linters/check-doc-freshness.sh` |
| 技能系统一致性 | `bash .harness/structural-tests/test-skill-integrity.sh` |
| 角色引用一致性 | `bash .harness/structural-tests/test-persona-refs.sh` |
| 模板格式规范 | `bash .harness/structural-tests/test-template-schema.sh` |

### Steering Loop（失败驱动改进）

→ 详见 `.cursor/rules/harness-log.mdc`

```
Agent 犯错 → 记录 → 能机械化? → .harness/ 新增检查
                              → 不能? → 更新技能/文档
           → 验证新规则有效 → 更新 QUALITY_SCORE
```

### Garbage Collection（熵治理）

```bash
bash .harness/garbage-collection/drift-scanner.sh
```

→ 详见 `.harness/quality/QUALITY_SCORE.md`

## Codex 调度

| 操作 | Codex | Cursor | Claude Code |
|------|-------|--------|-------------|
| 子代理 | `spawn_agent` | Task tool | subagent |
| 补充上下文 | `send_input` | `resume` | `send_input` |
| 等待结果 | `wait_agent` | `Await` | `wait_agent` |
| Harness 检查 | `shell` | Shell tool | Bash tool |

→ 工具映射详见 `.dev-agents/shared/references/codex-tools.md`

**子代理流程：** Max 读计划 → `spawn_agent` Jarvis（附模板+任务文本）→ Jarvis 实现+Harness检查+提交 → `spawn_agent` Kyle 审查 → 通过则继续，不通过则返回 Jarvis。

→ 派发模板详见 `.dev-agents/shared/templates/`
→ 详细派发规则见 `.dev-agents/shared/references/detailed-protocol.md`

### Codex Harness 自动化

Harness 在 Codex 中通过原生 API 实现自动执行（按可靠度排序）：

| 层级 | 机制 | 触发点 | 可跳过？ | 配置 |
|------|------|--------|---------|------|
| L1 | `[notify]` post-turn hook | 每个 turn 结束 | 否 | `~/.codex/config.toml` |
| L2 | Git pre-commit hook | `git commit` | 仅 `--no-verify` | `bash .harness/hooks/install.sh` |
| L3 | AGENTS.md 铁律 + 模板检查门 | 会话开始 / 任务中 | Agent 可能遗漏 | 本文件 + 模板 |

**首次使用：** `bash .codex/sandbox-setup.sh`（安装 hook + 输出 notify 配置指引）
→ 详见 `.codex/setup.md`

## 协作产物

```
.dev-agents/shared/
├── tasks/       # 任务文档 (T-NNN-slug.md)
├── designs/     # 设计产物
└── reviews/     # 审查产物
```

→ 命名与状态机规范见 `.dev-agents/shared/references/detailed-protocol.md`

## 铁律

1. **验证优先** — 运行命令、阅读输出、然后声称结果
2. **技能先查** — 执行前检查是否有适用技能
3. **WRITE_SCOPE** — 不越界修改
4. **Harness 检查** — 提交前运行 `bash .harness/run-all.sh`
5. **Git 安全** — 禁止自动 commit/push/merge，除非用户授权
6. **禁止 `--no-verify`** — 不得跳过 pre-commit hook，它是 Harness 的最后防线
7. **提交格式** — `<type>: <中文描述>`（feat|fix|refactor|docs|style|test|chore|ci）
