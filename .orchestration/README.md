# .orchestration — Agent 协作产物工作区

主会话是唯一的 orchestrator/writer；每个 subagent 都是只产文本的 worker。
**所有产物以 JSON 为唯一格式**，shape 由 `schemas/orchestration/*.schema.json` 约束。

## 目录结构

```
.orchestration/
├── .logs/                              # 全局事件日志（可选，主会话或 hooks 落盘）
│   └── events-YYYY-MM-DD.jsonl
└── <session>/                          # 一个任务一个 session（slug 化的任务名）
    ├── session.json                    # 元数据：name / label / createdAt / workers[]
    ├── plan.json                       # 聚合视图：workers + 依赖图 + 状态分桶（refresh 生成）
    └── <worker>/                       # 一个 worker 一个目录（通常 = agent 名）
        ├── task.json                   # 主→worker：objective / context / deliverables / dependsOn
        ├── handoff.json                # worker→主：summary / filesChanged / validation / followUps / notes[] / stages?
        └── status.json                 # worker→主：state / updatedAt / history[]
```

> 旧版 `.md` 三件套已废除。所有 hook 检查、CLI 工具、下游消费者都按 JSON 字段读取，不再 regex 解析 markdown。

## Schema 入口

| 产物 | Schema | 必填字段 |
|------|--------|----------|
| `session.json` | [`schemas/orchestration/session.schema.json`](../schemas/orchestration/session.schema.json) | schemaVersion · name · label · createdAt |
| `plan.json` | [`schemas/orchestration/plan.schema.json`](../schemas/orchestration/plan.schema.json) | schemaVersion · session · generatedAt · workers · buckets |
| `task.json` | [`schemas/orchestration/task.schema.json`](../schemas/orchestration/task.schema.json) | schemaVersion · session · worker · agent · objective · createdAt |
| `handoff.json` | [`schemas/orchestration/handoff.schema.json`](../schemas/orchestration/handoff.schema.json) | schemaVersion · session · worker |
| `status.json` | [`schemas/orchestration/status.schema.json`](../schemas/orchestration/status.schema.json) | schemaVersion · session · worker · state · updatedAt |

完整说明见 [`schemas/orchestration/README.md`](../schemas/orchestration/README.md)。

## 常用 worker 命名

| Worker | 对应 agent | 产物归属 |
|---|---|---|
| `planner` | `planner` | 实施计划、任务拆解 |
| `architect` | `architect` | 架构/方案设计 |
| `code-reviewer` | `code-reviewer` | 代码审查（必须填 `handoff.stages.spec` + `handoff.stages.quality`）|
| `security-reviewer` | `security-reviewer` | 安全审查 |
| `test-runner` | `test-runner` | 测试执行报告 |
| `frontend-engineer` | `frontend-engineer` | 前端实现 diff + 测试 |
| `backend-engineer` | `backend-engineer` | 后端实现 diff + 测试 |

## CLI

```bash
# 新建 session
node scripts/orchestration/session.cjs init <session>

# 创建 worker（task.json + handoff.json + status.json 一次创建）
node scripts/orchestration/session.cjs add-worker <session> <worker> \
  --agent <name> \
  --objective "<任务目标>" \
  --context "<context line>" \
  --deliverable "<deliverable line>" \
  --depends-on <other-worker>           # 可重复，声明前置 worker
# 轻量 worker（跳过 task.json）
  --lightweight

# 更新状态（追加到 history[]，覆盖当前 state）
node scripts/orchestration/session.cjs set-status <session> <worker> <state> \
  [--details "<text>"]
# state: not_started | running | blocked | completed | failed

# 追加 handoff.notes[]（过程记录，不替换最终四节）
node scripts/orchestration/session.cjs append <session> <worker> <section> \
  --content "<text>"

# 收尾 handoff（填充标准字段 + finalizedAt 时间戳）
node scripts/orchestration/session.cjs complete <session> <worker> \
  [--summary "<text>"] \
  [--files "path1,path2"]                 # 逗号或换行分隔
  [--validation "<text>"] \
  [--follow-ups "- item1\n- item2"] \
  [--stage-spec "<text>"]                 # 仅 code-reviewer
  [--stage-quality "<text>"]              # 仅 code-reviewer

# 聚合视图（写 plan.json，列出 ready/running/blocked/completed/failed/waiting 分桶）
node scripts/orchestration/session.cjs plan <session>

# 校验所有 JSON 产物 against schemas/orchestration/*.schema.json
node scripts/orchestration/session.cjs validate <session>

# 查询
node scripts/orchestration/session.cjs status <session>
node scripts/orchestration/session.cjs list
```

## 通信规则

1. worker prompt 中写明 **不再向下派遣 subagent**；worker 只产生最终响应文本。
2. worker **不自己写 handoff/status 文件**；主会话负责把 worker 响应写入 `handoff.json`、更新 `status.json`。
3. 每个 worker 目录三件套必须齐全（`task.json` + `handoff.json` + `status.json`），由 `session.cjs add-worker` 一次创建。
4. **phase 完结契约**：worker 进入 `completed` 前，主会话必须调用 `session.cjs complete` 至少回写 `--summary` 与 `--files`；`append` 仅用于过程记录，不能替代 `complete`。lightweight worker 同样适用。
5. **依赖图**：在 `add-worker` 时用 `--depends-on <worker>` 声明前置 worker。`session.cjs plan` 自动算出哪些 worker 在 `ready`（依赖全部 completed）vs `waiting`（仍有依赖未完成）。
6. **跨 session 知识持久化**分流到：
   - 项目级团队记忆（git-tracked）→ `docs/PROJECT_CONTEXT.md` / `docs/ARCHITECTURE.md` / `docs/rules/`
   - 用户级当前活跃状态（不入库）→ Claude Code 原生 memory（`~/.claude/projects/<slug>/memory/`，自动加载）

## Git 策略

- `.orchestration/<session>/**/*.json` 入库（计划、设计、审查记录是项目资产）
- `.orchestration/.logs/events-*.jsonl` 不入库（`.gitignore`）
