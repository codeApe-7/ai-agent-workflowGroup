# .orchestration — Agent 协作产物工作区

主会话是唯一的 orchestrator/writer；每个 subagent 都是只产文本的 worker。

## 目录结构

```
.orchestration/
├── .logs/                              # 全局事件日志（可选，主会话或 hooks 落盘）
│   └── events-YYYY-MM-DD.jsonl
└── <session>/                          # 一个任务一个 session（slug 化的任务名）
    ├── session.json                    # 元数据：name / label / createdAt
    └── <worker>/                       # 一个 worker 一个目录（通常 = agent 名）
        ├── task.md                     # 主→worker：任务描述、Objective、Context、Deliverables
        ├── handoff.md                  # worker→主：Summary / Files Changed / Validation / Follow-ups
        └── status.md                   # worker→主：State + 时间戳
```

## 常用 worker 命名

| Worker   | 对应 agent         | 产物归属                         |
|----------|--------------------|----------------------------------|
| `planner`       | `planner`          | 实施计划、任务拆解               |
| `architect`     | `architect`        | 架构/方案设计                    |
| `code-reviewer` | `code-reviewer`    | 代码审查                         |
| `security-reviewer` | `security-reviewer` | 安全审查                    |
| `test-runner`   | `test-runner`      | 测试执行报告                     |
| `frontend-engineer` | `frontend-engineer` | 前端实现 diff + 测试       |
| `backend-engineer`  | `backend-engineer`  | 后端实现 diff + 测试       |

## CLI

```bash
# 新建 session
node scripts/orchestration/session.cjs init <session-name>

# 创建 worker 任务
node scripts/orchestration/session.cjs add-worker <session> <worker> \
  --agent <name> \
  --objective "<任务目标>" \
  --context "<context line>" \
  --deliverable "<deliverable line>"

# 更新状态
node scripts/orchestration/session.cjs set-status <session> <worker> <state> \
  [--details "<markdown>"]
# state: not_started | running | blocked | completed | failed

# 追加 handoff 段（记录中间过程，不替换标准四节）
node scripts/orchestration/session.cjs append <session> <worker> <section-title> \
  --content "<markdown>"

# 收尾 handoff（回写标准四节：Summary / Files Changed / Validation / Follow-ups）
# phase 末必须调用一次，否则四节永远停留在 "Pending"
node scripts/orchestration/session.cjs complete <session> <worker> \
  [--summary "<md>"] [--files "<md>"] \
  [--validation "<md>"] [--follow-ups "<md>"]

# 查询
node scripts/orchestration/session.cjs status <session>
node scripts/orchestration/session.cjs list
```

## 通信规则

1. worker prompt 中写明 **不再向下派遣 subagent**；worker 只产生最终响应文本。
2. worker **不自己写 handoff / status 文件**；主会话负责把 worker 响应抄进 `handoff.md`、更新 `status.md`。
3. 每个 worker 目录三件套必须齐全（`task.md` + `handoff.md` + `status.md`），由 `session.cjs add-worker` 一次创建。
4. **phase 完结契约**：worker 进入 `completed` 前，主会话必须调用 `session.cjs complete` 至少回写 `--summary` 与 `--files`；`append` 仅用于过程记录（设计草稿、调研、需求笔记），不能替代 `complete`。lightweight worker 同样适用。
4. 跨 session 的知识持久化分流到：
   - **项目级团队记忆**（git-tracked）→ `docs/PROJECT_CONTEXT.md` / `docs/ARCHITECTURE.md` / `docs/rules/`
   - **用户级当前活跃状态**（不入库）→ Claude Code 原生 memory（`~/.claude/projects/<slug>/memory/`，自动加载）

## Git 策略

- `.orchestration/<session>/**/*.md` 入库（计划、设计、审查记录是项目资产）
- `.orchestration/<session>/**/session.json` 入库（session 元数据）
- `.orchestration/.logs/events-*.jsonl` 不入库（`.gitignore`）
