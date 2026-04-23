# Harness L4/L5 层补强 实现计划

> **执行方式**：推荐使用 subagent-driven-development 技能按任务派遣子代理执行。
> 步骤使用 checkbox (`- [ ]`) 语法追踪进度。

**目标**：落地 A（templates 迁移）+ B（长期记忆）+ C（运行时观测）三项改造，补强 Harness 六层架构的 L4/L5 层。

**架构**：纯 bash 实现，零外部依赖。记忆系统采用 Cline 3 件套（projectContext/activeContext/systemPatterns），观测系统采用扁平 JSONL 按日滚动，通过 `log-event.sh` 统一写入。

**技术栈**：bash (Git Bash Windows 兼容) / Markdown / JSONL；coreutils：date/grep/sed/cut/mkdir/wc/find

**设计文档**：`.dev-agents/shared/designs/2026-04-23-harness-l4-l5-enhancement-design.md`
**需求文档**：`.dev-agents/shared/designs/2026-04-23-harness-l4-l5-enhancement-requirements.md`

---

## 文件结构变更清单

| 变更类型 | 路径 | 职责 |
|---------|------|------|
| 迁移 | `.dev-agents/shared/templates/` → `docs/templates/` | 静态模板归入知识库 |
| 新建 | `.dev-agents/shared/memory/projectContext.md` | 项目级记忆（追踪） |
| 新建 | `.dev-agents/shared/memory/activeContext.md` | 会话级记忆（不追踪） |
| 新建 | `.dev-agents/shared/memory/systemPatterns.md` | 模式级记忆（追踪） |
| 新建 | `.dev-agents/shared/logs/README.md` | 日志 schema 说明 |
| 新建 | `scripts/harness/log-event.sh` | 唯一事件写入工具 |
| 新建 | `scripts/harness/logs-query.sh` | 日志查询聚合工具 |
| 新建 | `scripts/harness/tests/test-log-event.sh` | log-event.sh 单元测试 |
| 新建 | `scripts/harness/tests/test-logs-query.sh` | logs-query.sh 单元测试 |
| 修改 | `scripts/harness/workflow-state.sh` | init/advance/reset/exempt 埋点 + 记忆提示 |
| 修改 | `scripts/harness/lint-structure.sh` | templates 路径 + 新增 memory/logs 检查 |
| 修改 | `scripts/harness/lint-workflow-artifacts.sh` | 模板完整性检查路径 + fail() 插桩 |
| 修改 | `scripts/harness/lint-delegation.sh` | 排除路径 + fail() 插桩 |
| 修改 | `scripts/harness/lint-docs.sh` | fail() 插桩 |
| 修改 | `scripts/harness/lint-process.sh` | fail() 插桩 |
| 修改 | `cli/utils/scaffold.mjs` | 脚手架目录列表 |
| 修改 | `CLAUDE.md` | 会话启动协议 |
| 修改 | `docs/ARCHITECTURE.md` | 目录图 + L4/L5 章节 |
| 修改 | `.gitignore` | 日志和 activeContext 忽略 |

---

## 任务 1：templates 目录迁移（A 项）

**文件：**
- 迁移：`.dev-agents/shared/templates/` → `docs/templates/`

- [x] **步骤 1.1：执行 git 迁移保留历史**

```bash
cd /d/www/ai-agent-workflowGroup
git mv .dev-agents/shared/templates docs/templates
```

- [x] **步骤 1.2：验证迁移结果**

```bash
ls docs/templates/ | wc -l
```
预期：输出 `10`（README.md + 9 个模板文件）

```bash
ls .dev-agents/shared/templates 2>&1
```
预期：`ls: cannot access '.dev-agents/shared/templates': No such file or directory`

- [x] **步骤 1.3：git 状态确认**

```bash
git status --short | grep templates | head -15
```
预期：显示 `R  .dev-agents/shared/templates/*.md -> docs/templates/*.md`（R 表示 rename）

---

## 任务 2：更新 6 处路径引用（A 项）

**文件：**
- 修改：`cli/utils/scaffold.mjs:31`
- 修改：`scripts/harness/lint-structure.sh:54`
- 修改：`scripts/harness/lint-delegation.sh:34,45`
- 修改：`scripts/harness/lint-workflow-artifacts.sh:41,105,108,123,125`

- [x] **步骤 2.1：修改 `cli/utils/scaffold.mjs`**

使用 Edit 工具：
- old_string: `  '.dev-agents/shared/templates',`
- new_string: `  'docs/templates',`

- [x] **步骤 2.2：修改 `scripts/harness/lint-structure.sh`**

使用 Edit 工具：
- old_string: `for dir in ".dev-agents/shared/tasks" ".dev-agents/shared/designs" ".dev-agents/shared/reviews" ".dev-agents/shared/templates"; do`
- new_string: `for dir in ".dev-agents/shared/tasks" ".dev-agents/shared/designs" ".dev-agents/shared/reviews" ".dev-agents/shared/memory" ".dev-agents/shared/logs" "docs/templates"; do`

（注意同时追加了新增的 `memory/` 和 `logs/` 目录检查，属于任务 11 的前置。）

- [x] **步骤 2.3：修改 `scripts/harness/lint-delegation.sh`（注释）**

使用 Edit 工具：
- old_string: `#          .dev-agents/shared/templates/（模板允许示例）`
- new_string: `#          docs/templates/（模板允许示例）`

- [x] **步骤 2.4：修改 `scripts/harness/lint-delegation.sh`（排除规则）**

使用 Edit 工具：
- old_string: `        | grep -v "/shared/templates/" \`
- new_string: `        | grep -v "docs/templates/" \`

- [x] **步骤 2.5：修改 `scripts/harness/lint-workflow-artifacts.sh` 第 41 行**

使用 Edit 工具：
- old_string: `                fix "参考 .dev-agents/shared/templates/implementation-plan.md 模板重构 $plan"`
- new_string: `                fix "参考 docs/templates/implementation-plan.md 模板重构 $plan"`

- [x] **步骤 2.6：修改 `scripts/harness/lint-workflow-artifacts.sh` 第 105 行**

使用 Edit 工具：
- old_string: `                fix "补充 Stage 2 代码质量审查，参考 .dev-agents/shared/templates/code-review.md"`
- new_string: `                fix "补充 Stage 2 代码质量审查，参考 docs/templates/code-review.md"`

- [x] **步骤 2.7：修改 `scripts/harness/lint-workflow-artifacts.sh` 第 108 行**

使用 Edit 工具：
- old_string: `                fix "参考 .dev-agents/shared/templates/code-review.md 重构审查报告"`
- new_string: `                fix "参考 docs/templates/code-review.md 重构审查报告"`

- [x] **步骤 2.8：修改 `scripts/harness/lint-workflow-artifacts.sh` 模板完整性段（第 119-131 行）**

使用 Edit 工具：
- old_string:
```
# ── 4. 模板完整性 ──
echo ""
echo "▸ 模板完整性检查"

REQUIRED_TEMPLATES=("prd.md" "implementation-plan.md" "code-review.md")
for tmpl in "${REQUIRED_TEMPLATES[@]}"; do
    if [ -f "$SHARED_DIR/templates/$tmpl" ]; then
        pass "模板 $tmpl 存在"
    else
        fail "模板 $tmpl 缺失"
        fix "创建 $SHARED_DIR/templates/$tmpl"
    fi
done
```
- new_string:
```
# ── 4. 模板完整性 ──
echo ""
echo "▸ 模板完整性检查"

TEMPLATES_DIR="docs/templates"
REQUIRED_TEMPLATES=("prd.md" "implementation-plan.md" "code-review.md")
for tmpl in "${REQUIRED_TEMPLATES[@]}"; do
    if [ -f "$TEMPLATES_DIR/$tmpl" ]; then
        pass "模板 $tmpl 存在"
    else
        fail "模板 $tmpl 缺失"
        fix "创建 $TEMPLATES_DIR/$tmpl"
    fi
done
```

- [x] **步骤 2.9：验证所有引用已更新**

```bash
grep -rn "dev-agents/shared/templates" --include="*.sh" --include="*.mjs" --include="*.md" . 2>/dev/null | grep -v "\.dev-agents/shared/designs" | grep -v "\.dev-agents/shared/tasks"
```
预期：无输出（旧引用已清除；designs/ 和 tasks/ 中的历史文档引用保留，因为它们是本次工作流本身的产物）

---

## 任务 3：更新 docs/ARCHITECTURE.md 目录图（A 项）

**文件：**
- 修改：`docs/ARCHITECTURE.md:22-26`

- [x] **步骤 3.1：修改目录图中的 .dev-agents 段**

使用 Edit 工具：
- old_string:
```
├── .dev-agents/shared/        # Agent 间协作产物工作区
│   ├── tasks/                 # 实现计划
│   ├── designs/               # 设计方案与设计稿
│   ├── reviews/               # 审查报告
│   └── templates/             # 文档模板
```
- new_string:
```
├── .dev-agents/shared/        # Agent 间协作产物工作区（运行时动态）
│   ├── tasks/                 # 实现计划
│   ├── designs/               # 设计方案与设计稿
│   ├── reviews/               # 审查报告
│   ├── memory/                # 长期记忆（projectContext/activeContext/systemPatterns）
│   └── logs/                  # 运行时事件日志（JSONL 按日滚动）
```

- [x] **步骤 3.2：在 docs/ 段补充 templates/**

使用 Edit 工具：
- old_string:
```
├── docs/                      # 知识库：详细规范与标准
│   ├── README.md              # 知识库索引
│   ├── ARCHITECTURE.md        # 本文件
```
- new_string:
```
├── docs/                      # 知识库：详细规范与标准
│   ├── README.md              # 知识库索引
│   ├── ARCHITECTURE.md        # 本文件
│   ├── templates/             # 静态文档模板（prd/implementation-plan/code-review 等）
```

- [x] **步骤 3.3：验证变更**

```bash
sed -n '20,35p' docs/ARCHITECTURE.md
```
预期：能看到更新后的目录图，包含 `memory/` `logs/` `templates/`。

---

## 任务 4：创建记忆系统 3 个模板（B 项）

**文件：**
- 新建：`.dev-agents/shared/memory/projectContext.md`
- 新建：`.dev-agents/shared/memory/activeContext.md`
- 新建：`.dev-agents/shared/memory/systemPatterns.md`

- [x] **步骤 4.1：创建 memory 目录**

```bash
mkdir -p .dev-agents/shared/memory
```

- [x] **步骤 4.2：创建 `projectContext.md`**

写入文件 `.dev-agents/shared/memory/projectContext.md`，完整内容：

```markdown
---
last_updated: 2026-04-23
updated_by: initial-bootstrap
version: 1
---

# 项目上下文

> Max 在 design 阶段完成后应更新此文件，记录本次的架构决策。

## 产品愿景

aiGroup 是一个基于 Harness Engineering 理念的 AI 团队协作框架，通过角色分工、强制工作流管道和机械化约束，让 AI Agent 可靠地完成软件开发任务。

## 核心架构决策

| 决策 | 时间 | 上下文 | 放弃的替代方案 |
|------|------|--------|---------------|
| 采用 8 阶段工作流管道 | 初期 | 将"Agent 想到哪做到哪"的无序执行改为状态机驱动 | 自由编排 |
| 文件驱动的 Agent 协作 | 初期 | Agent 间不能直接通信，需中间介质 | 直接 prompt 传递 |
| Harness 传感器机械化检查 | 初期 | 约束换自主性，规则写进 lint 脚本 | 纯文档约定 |
| 采用 Cline Memory Bank 3 件套 | 2026-04-23 | 补强 L4 记忆层，单人场景下足够 | Cline 完整 6 件套；Aider repo-map（需 tree-sitter） |
| 采用扁平 JSONL 观测 | 2026-04-23 | 零依赖 + 单人场景 | OpenTelemetry span 树；LangFuse self-hosted |

## 技术栈

- **运行时**：Claude Code CLI（主）/ Cursor（兼容）
- **语言**：bash（harness 脚本）+ Markdown（文档）+ JSONL（日志）
- **依赖**：coreutils（date/grep/sed/cut/mkdir/wc/find）
- **版本控制**：git

## 关键约束

- CLAUDE.md ≤ 100 行（渐进式披露原则）
- harness 脚本零外部依赖（无 jq / bats）
- Windows Git Bash 兼容
- 向后兼容：现有 5 个 lint 脚本检测逻辑不破坏

## 团队惯例

- 不直接角色扮演，必须用 `Agent(subagent_type)` 派遣子代理
- 设计 → 计划 → 实施 → 测试 严格分离
- 铁律：证据优于断言；流程不可跳过；不确定时先问；门控先行
```

- [x] **步骤 4.3：创建 `activeContext.md`**

写入文件 `.dev-agents/shared/memory/activeContext.md`，完整内容：

```markdown
---
last_updated: 2026-04-23
updated_by: initial-bootstrap
workflow_id: harness-l4-l5-enhancement
version: 1
---

# 当前工作上下文

> Max 每次 advance 后应更新此文件。下次会话启动时会被优先读取。

## 当前焦点

工作流：`harness-l4-l5-enhancement`
当前阶段：development（实施开发）
正在做：按照 `docs/templates` 迁移 + 3 件套记忆 + JSONL 观测三项改造

## 上次做到哪

- 需求文档已确认：`.dev-agents/shared/designs/2026-04-23-harness-l4-l5-enhancement-requirements.md`
- 设计文档已确认：`.dev-agents/shared/designs/2026-04-23-harness-l4-l5-enhancement-design.md`
- 实现计划已生成：`.dev-agents/shared/tasks/2026-04-23-harness-l4-l5-enhancement-plan.md`

## 下一步动作

派遣 Jarvis 按实现计划逐任务执行，预计 12 个任务。

## 开放的阻塞问题

无。

## 近期学到的

- 本项目 Git Bash 环境 jq 不可用，事件日志必须纯 bash 拼 JSON
- Cline 6 件套对单人项目可简化为 3 件套（合并 projectbrief+productContext+techContext，省略 progress）
```

- [x] **步骤 4.4：创建 `systemPatterns.md`**

写入文件 `.dev-agents/shared/memory/systemPatterns.md`，完整内容：

```markdown
---
last_updated: 2026-04-23
updated_by: initial-bootstrap
version: 1
---

# 系统模式

> Kyle 审查通过后，Max 应将反复出现的好模式/反模式沉淀至此。

## 代码模式

| 模式名 | 类型 | 场景 | 示例位置 | 首次发现 |
|--------|------|------|---------|---------|
| fail-silent-log | 推荐 | harness 观测写入失败不得中断主流程 | `scripts/harness/log-event.sh` | 2026-04-23 |
| frontmatter-timestamp | 推荐 | 记忆文件必须含 last_updated/version | `.dev-agents/shared/memory/*.md` | 2026-04-23 |
| flat-jsonl | 推荐 | 日志用扁平结构 + workflow_id 关联而非 span 嵌套 | `.dev-agents/shared/logs/events-*.jsonl` | 2026-04-23 |

## 常用重构手法

| 场景 | 重构方法 |
|------|---------|
| 避免重复插桩多个脚本 | 在共享 `fail()` 函数内部统一调用 log-event.sh |

## 已沉淀的团队约定

- **零依赖铁律**：不引入 jq / bats / python，纯 bash + coreutils
  - *为什么*：Git Bash Windows 环境下外部依赖难保证；降低用户环境要求
- **观测不阻塞主流程**：log-event.sh 内部 `2>/dev/null || true`
  - *为什么*：观测是辅助手段，失败不能拖垮业务流程
```

- [x] **步骤 4.5：验证 3 个文件已创建**

```bash
ls -la .dev-agents/shared/memory/ && wc -l .dev-agents/shared/memory/*.md
```
预期：3 个 .md 文件，projectContext/activeContext/systemPatterns 每个都有几十行内容。

---

## 任务 5：实现 `scripts/harness/log-event.sh`（C 项核心）

**文件：**
- 新建：`scripts/harness/log-event.sh`
- 测试：`scripts/harness/tests/test-log-event.sh`

- [x] **步骤 5.1：先写测试（TDD）**

创建目录并写入测试脚本 `scripts/harness/tests/test-log-event.sh`：

```bash
#!/bin/bash
# 单元测试：log-event.sh
# 运行：bash scripts/harness/tests/test-log-event.sh

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
LOG_EVENT="$ROOT/scripts/harness/log-event.sh"

# 用临时目录做隔离测试
TMP=$(mktemp -d)
trap "rm -rf $TMP" EXIT

cd "$TMP"
mkdir -p .dev-agents/shared
cat > .dev-agents/shared/.workflow-state <<EOF
stage=testing
task=test-task
started=2026-04-23 00:00:00
exempt=false
updated=2026-04-23 00:00:00
EOF

PASS=0
FAIL=0

assert() {
    local msg="$1"
    local cond="$2"
    if eval "$cond"; then
        echo "  [PASS] $msg"
        PASS=$((PASS + 1))
    else
        echo "  [FAIL] $msg"
        echo "         条件: $cond"
        FAIL=$((FAIL + 1))
    fi
}

echo "▸ 测试 1：基础事件写入"
bash "$LOG_EVENT" stage_enter --actor harness
LOG_FILE=".dev-agents/shared/logs/events-$(date +%Y-%m-%d).jsonl"
assert "日志文件已创建" "[ -f '$LOG_FILE' ]"
assert "事件类型正确" "grep -q '\"event_type\":\"stage_enter\"' '$LOG_FILE'"
assert "workflow_id 从 state 读取" "grep -q '\"workflow_id\":\"test-task\"' '$LOG_FILE'"
assert "stage 从 state 读取" "grep -q '\"stage\":\"testing\"' '$LOG_FILE'"
assert "actor 正确" "grep -q '\"actor\":\"harness\"' '$LOG_FILE'"

echo ""
echo "▸ 测试 2：payload 解析"
bash "$LOG_EVENT" dispatch --actor max --payload "target=jarvis,task_id=T5"
assert "payload 包含 target" "grep -q '\"target\":\"jarvis\"' '$LOG_FILE'"
assert "payload 包含 task_id" "grep -q '\"task_id\":\"T5\"' '$LOG_FILE'"

echo ""
echo "▸ 测试 3：duration_ms 字段"
bash "$LOG_EVENT" stage_exit --duration-ms 12345
assert "duration_ms 存在且为数字" "grep -q '\"duration_ms\":12345' '$LOG_FILE'"

echo ""
echo "▸ 测试 4：state 文件缺失时 fallback 为 idle"
rm .dev-agents/shared/.workflow-state
bash "$LOG_EVENT" workflow_reset
assert "无 state 时 workflow_id 为 idle" "grep -q '\"workflow_id\":\"idle\"' '$LOG_FILE'"
assert "无 state 时 stage 为 idle" "tail -1 '$LOG_FILE' | grep -q '\"stage\":\"idle\"'"

echo ""
echo "▸ 测试 5：特殊字符转义"
cat > .dev-agents/shared/.workflow-state <<EOF
stage=design
task=test-task
started=2026-04-23 00:00:00
exempt=false
EOF
bash "$LOG_EVENT" red_flag --actor max --payload 'msg=has "quotes" and \ backslash'
assert "双引号被转义" "tail -1 '$LOG_FILE' | grep -q '\\\\\"quotes\\\\\"'"

echo ""
echo "▸ 测试 6：ts 字段 ISO-8601 格式"
assert "ts 字段格式合法" "tail -1 '$LOG_FILE' | grep -qE '\"ts\":\"[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}[+-][0-9]{4}\"'"

echo ""
echo "======================================"
echo "  结果: $PASS 通过 / $FAIL 失败"
echo "======================================"
[ "$FAIL" -eq 0 ]
```

- [x] **步骤 5.2：运行测试确认失败**

```bash
bash scripts/harness/tests/test-log-event.sh
```
预期：失败（因为 log-event.sh 尚未实现）。

- [x] **步骤 5.3：实现 `scripts/harness/log-event.sh`**

写入文件 `scripts/harness/log-event.sh`，完整内容：

```bash
#!/bin/bash
# ================================================================
# Harness 事件写入工具
#
# 职责：将 harness 事件以 JSONL 格式追加到日志文件
# 调用者：workflow-state.sh / lint-*.sh / Max（主动调用）
# 设计原则：fail-silent — 写入失败不得中断调用方主流程
#
# 用法：
#   log-event.sh <event_type> [--stage S] [--actor A] [--duration-ms D] [--payload k=v,k=v,...]
#
# 示例：
#   log-event.sh stage_enter --actor harness
#   log-event.sh dispatch --actor max --payload "target=jarvis,task_id=T5"
#   log-event.sh lint_fail --payload "rule=template-missing,file=prd.md"
#
# 输出：.dev-agents/shared/logs/events-YYYY-MM-DD.jsonl（追加一行）
# ================================================================

EVENT_TYPE="${1:-}"

if [ -z "$EVENT_TYPE" ]; then
    echo "[log-event] ERROR: 必须提供 event_type" >&2
    exit 1
fi

shift

# ── 解析参数 ──
STAGE_ARG=""
ACTOR_ARG=""
DURATION_ARG=""
PAYLOAD_ARG=""

while [ $# -gt 0 ]; do
    case "$1" in
        --stage) STAGE_ARG="$2"; shift 2 ;;
        --actor) ACTOR_ARG="$2"; shift 2 ;;
        --duration-ms) DURATION_ARG="$2"; shift 2 ;;
        --payload) PAYLOAD_ARG="$2"; shift 2 ;;
        *) shift ;;
    esac
done

# ── 读取 state 文件作为默认值 ──
STATE_FILE=".dev-agents/shared/.workflow-state"
DEFAULT_WORKFLOW_ID="idle"
DEFAULT_STAGE="idle"

if [ -f "$STATE_FILE" ]; then
    WORKFLOW_ID_FROM_STATE=$(grep '^task=' "$STATE_FILE" 2>/dev/null | cut -d'=' -f2-)
    STAGE_FROM_STATE=$(grep '^stage=' "$STATE_FILE" 2>/dev/null | cut -d'=' -f2-)
    [ -n "$WORKFLOW_ID_FROM_STATE" ] && DEFAULT_WORKFLOW_ID="$WORKFLOW_ID_FROM_STATE"
    [ -n "$STAGE_FROM_STATE" ] && DEFAULT_STAGE="$STAGE_FROM_STATE"
fi

STAGE="${STAGE_ARG:-$DEFAULT_STAGE}"
ACTOR="${ACTOR_ARG:-harness}"
WORKFLOW_ID="$DEFAULT_WORKFLOW_ID"

# ── 时间戳（ISO-8601 带时区）──
TS=$(date +%Y-%m-%dT%H:%M:%S%z)

# ── JSON 字符串转义函数 ──
json_escape() {
    # 转义顺序：\ 先转，再转 "
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    # 换行/制表符转义
    s="${s//$'\n'/\\n}"
    s="${s//$'\t'/\\t}"
    echo "$s"
}

# ── 拼接 payload ──
PAYLOAD_JSON="{}"
if [ -n "$PAYLOAD_ARG" ]; then
    PAYLOAD_JSON="{"
    FIRST=1
    # payload 用 "," 分隔 k=v 对；v 内含 "," 需用户调用方避免（本轮不支持复杂 payload）
    IFS=',' read -ra PAIRS <<< "$PAYLOAD_ARG"
    for pair in "${PAIRS[@]}"; do
        K="${pair%%=*}"
        V="${pair#*=}"
        K_ESC=$(json_escape "$K")
        V_ESC=$(json_escape "$V")
        if [ "$FIRST" -eq 1 ]; then
            PAYLOAD_JSON="${PAYLOAD_JSON}\"${K_ESC}\":\"${V_ESC}\""
            FIRST=0
        else
            PAYLOAD_JSON="${PAYLOAD_JSON},\"${K_ESC}\":\"${V_ESC}\""
        fi
    done
    PAYLOAD_JSON="${PAYLOAD_JSON}}"
fi

# ── duration_ms 字段（可选）──
DURATION_FIELD=""
if [ -n "$DURATION_ARG" ]; then
    # 仅接受数字
    if echo "$DURATION_ARG" | grep -qE '^[0-9]+$'; then
        DURATION_FIELD=",\"duration_ms\":${DURATION_ARG}"
    fi
fi

# ── 拼接最终 JSON（字段顺序固定）──
JSON="{\"ts\":\"${TS}\",\"workflow_id\":\"$(json_escape "$WORKFLOW_ID")\",\"stage\":\"$(json_escape "$STAGE")\",\"event_type\":\"$(json_escape "$EVENT_TYPE")\",\"actor\":\"$(json_escape "$ACTOR")\"${DURATION_FIELD},\"payload\":${PAYLOAD_JSON}}"

# ── 写入（fail-silent）──
LOG_DIR=".dev-agents/shared/logs"
LOG_FILE="${LOG_DIR}/events-$(date +%Y-%m-%d).jsonl"

{
    mkdir -p "$LOG_DIR" 2>/dev/null
    echo "$JSON" >> "$LOG_FILE" 2>/dev/null
} || true

# 永远返回 0，即使写入失败
exit 0
```

- [x] **步骤 5.4：赋予执行权限**

```bash
chmod +x scripts/harness/log-event.sh scripts/harness/tests/test-log-event.sh
```

- [x] **步骤 5.5：运行测试确认通过**

```bash
bash scripts/harness/tests/test-log-event.sh
```
预期：`结果: 13 通过 / 0 失败`（或全部通过，具体条目数以测试为准）

- [x] **步骤 5.6：提交**

```bash
git add scripts/harness/log-event.sh scripts/harness/tests/test-log-event.sh
git commit -m "feat(harness): 新增 log-event.sh 事件写入工具 + 单元测试"
```

---

## 任务 6：实现 `scripts/harness/logs-query.sh`（C 项查询）

**文件：**
- 新建：`scripts/harness/logs-query.sh`
- 测试：`scripts/harness/tests/test-logs-query.sh`

- [x] **步骤 6.1：先写测试**

写入文件 `scripts/harness/tests/test-logs-query.sh`：

```bash
#!/bin/bash
# 单元测试：logs-query.sh
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
QUERY="$ROOT/scripts/harness/logs-query.sh"

TMP=$(mktemp -d)
trap "rm -rf $TMP" EXIT
cd "$TMP"

# 构造 mock 日志
mkdir -p .dev-agents/shared/logs
TODAY=$(date +%Y-%m-%d)
LOG="$TMP/.dev-agents/shared/logs/events-$TODAY.jsonl"

cat > "$LOG" <<EOF
{"ts":"2026-04-23T10:00:00+0800","workflow_id":"wf1","stage":"brainstorming","event_type":"stage_enter","actor":"harness","payload":{}}
{"ts":"2026-04-23T10:15:00+0800","workflow_id":"wf1","stage":"brainstorming","event_type":"stage_exit","actor":"harness","duration_ms":900000,"payload":{"next_stage":"design"}}
{"ts":"2026-04-23T10:15:01+0800","workflow_id":"wf1","stage":"design","event_type":"stage_enter","actor":"harness","payload":{}}
{"ts":"2026-04-23T10:45:00+0800","workflow_id":"wf1","stage":"design","event_type":"stage_exit","actor":"harness","duration_ms":1800000,"payload":{"next_stage":"planning"}}
{"ts":"2026-04-23T11:00:00+0800","workflow_id":"wf1","stage":"testing","event_type":"lint_fail","actor":"harness","payload":{"rule":"template-missing"}}
{"ts":"2026-04-23T11:05:00+0800","workflow_id":"wf1","stage":"testing","event_type":"lint_fail","actor":"harness","payload":{"rule":"template-missing"}}
{"ts":"2026-04-23T11:10:00+0800","workflow_id":"wf1","stage":"testing","event_type":"lint_fail","actor":"harness","payload":{"rule":"empty-doc"}}
{"ts":"2026-04-23T11:15:00+0800","workflow_id":"wf1","stage":"testing","event_type":"red_flag","actor":"max","payload":{"flag_id":"3"}}
EOF

PASS=0; FAIL=0
assert() {
    if eval "$2"; then echo "  [PASS] $1"; PASS=$((PASS+1))
    else echo "  [FAIL] $1 — cond: $2"; FAIL=$((FAIL+1)); fi
}

echo "▸ 测试 1：--stats 输出包含阶段耗时"
OUT=$(bash "$QUERY" --stats wf1)
assert "含 brainstorming 900000 ms" "echo '$OUT' | grep -q 'brainstorming.*900000'"
assert "含 design 1800000 ms" "echo '$OUT' | grep -q 'design.*1800000'"

echo ""
echo "▸ 测试 2：--hotspots 输出按次数降序"
OUT=$(bash "$QUERY" --hotspots --days 30)
assert "template-missing 出现 2 次排第一" "echo '$OUT' | grep -E 'template-missing.*2|2.*template-missing'"
assert "empty-doc 出现 1 次" "echo '$OUT' | grep -E 'empty-doc.*1|1.*empty-doc'"

echo ""
echo "▸ 测试 3：--export 生成 CSV"
bash "$QUERY" --export --out "$TMP/out.csv"
assert "CSV 文件生成" "[ -f '$TMP/out.csv' ]"
assert "CSV 含表头" "head -1 '$TMP/out.csv' | grep -q 'ts,workflow_id,stage,event_type'"
assert "CSV 行数 >= 8" "[ \$(wc -l < '$TMP/out.csv') -ge 8 ]"

echo ""
echo "▸ 测试 4：空日志不报错"
rm "$LOG"
OUT=$(bash "$QUERY" --stats 2>&1)
assert "空日志返回码 0" "bash '$QUERY' --stats >/dev/null 2>&1"
assert "含 '无匹配事件' 提示" "echo '$OUT' | grep -qE '无匹配|无事件|no events'"

echo ""
echo "结果: $PASS 通过 / $FAIL 失败"
[ "$FAIL" -eq 0 ]
```

- [x] **步骤 6.2：运行测试确认失败**

```bash
bash scripts/harness/tests/test-logs-query.sh
```
预期：失败。

- [x] **步骤 6.3：实现 `scripts/harness/logs-query.sh`**

写入文件 `scripts/harness/logs-query.sh`：

```bash
#!/bin/bash
# ================================================================
# Harness 日志查询工具
#
# 用法：
#   logs-query.sh --stats [workflow_id]
#   logs-query.sh --hotspots [--days N]
#   logs-query.sh --export [--days N] [--out PATH]
#
# 实现：纯 bash + grep + sed，无 jq 依赖
# ================================================================

LOG_DIR=".dev-agents/shared/logs"

cmd_stats() {
    local wf_id="$1"
    local state_file=".dev-agents/shared/.workflow-state"
    if [ -z "$wf_id" ] && [ -f "$state_file" ]; then
        wf_id=$(grep '^task=' "$state_file" 2>/dev/null | cut -d'=' -f2-)
    fi
    wf_id="${wf_id:-unknown}"

    if [ ! -d "$LOG_DIR" ]; then
        echo "[INFO] 无匹配事件（logs 目录不存在）"
        return 0
    fi

    local files
    files=$(ls -1 "$LOG_DIR"/events-*.jsonl 2>/dev/null)
    if [ -z "$files" ]; then
        echo "[INFO] 无匹配事件"
        return 0
    fi

    echo "======================================"
    echo "  工作流统计: $wf_id"
    echo "======================================"
    echo ""
    echo "▸ 阶段耗时（ms）"

    # 提取 stage_exit 事件，按 stage 聚合 duration_ms
    grep -h "\"workflow_id\":\"${wf_id}\"" $files 2>/dev/null \
        | grep "\"event_type\":\"stage_exit\"" \
        | while IFS= read -r line; do
            stage=$(echo "$line" | sed -n 's/.*"stage":"\([^"]*\)".*/\1/p')
            dur=$(echo "$line" | sed -n 's/.*"duration_ms":\([0-9]*\).*/\1/p')
            [ -n "$stage" ] && [ -n "$dur" ] && echo "$stage $dur"
        done \
        | sort \
        | awk '
            {
                sum[$1] += $2
                cnt[$1] += 1
            }
            END {
                for (s in sum) printf "  %-16s %10d ms (× %d)\n", s, sum[s], cnt[s]
            }
        '

    echo ""
    echo "▸ 循环次数"
    local loop_count
    loop_count=$(grep -h "\"workflow_id\":\"${wf_id}\"" $files 2>/dev/null \
        | grep -c "\"event_type\":\"loop_iter\"")
    echo "  Kyle 审查-修复循环: $loop_count 次"
}

cmd_hotspots() {
    local days="${1:-30}"
    if [ ! -d "$LOG_DIR" ]; then
        echo "[INFO] 无匹配事件"
        return 0
    fi

    local files
    files=$(ls -1 "$LOG_DIR"/events-*.jsonl 2>/dev/null)
    if [ -z "$files" ]; then
        echo "[INFO] 无匹配事件"
        return 0
    fi

    echo "======================================"
    echo "  失败热点（近 $days 天 top 10）"
    echo "======================================"
    echo ""
    echo "▸ lint_fail 规则 top 10"

    grep -h -E '"event_type":"(lint_fail|red_flag)"' $files 2>/dev/null \
        | while IFS= read -r line; do
            rule=$(echo "$line" | sed -n 's/.*"rule":"\([^"]*\)".*/\1/p')
            flag=$(echo "$line" | sed -n 's/.*"flag_id":"\([^"]*\)".*/\1/p')
            type=$(echo "$line" | sed -n 's/.*"event_type":"\([^"]*\)".*/\1/p')
            key="${rule}${flag}"
            [ -n "$key" ] && echo "${type}:${key}"
        done \
        | sort | uniq -c | sort -rn | head -10 \
        | awk '{printf "  %-40s %d 次\n", $2, $1}'
}

cmd_export() {
    local days=30
    local out="events-export.csv"
    while [ $# -gt 0 ]; do
        case "$1" in
            --days) days="$2"; shift 2 ;;
            --out) out="$2"; shift 2 ;;
            *) shift ;;
        esac
    done

    if [ ! -d "$LOG_DIR" ]; then
        echo "ts,workflow_id,stage,event_type,actor,duration_ms" > "$out"
        echo "[INFO] 无事件数据，已生成空 CSV: $out"
        return 0
    fi

    echo "ts,workflow_id,stage,event_type,actor,duration_ms" > "$out"

    for f in "$LOG_DIR"/events-*.jsonl; do
        [ -f "$f" ] || continue
        while IFS= read -r line; do
            ts=$(echo "$line" | sed -n 's/.*"ts":"\([^"]*\)".*/\1/p')
            wf=$(echo "$line" | sed -n 's/.*"workflow_id":"\([^"]*\)".*/\1/p')
            stg=$(echo "$line" | sed -n 's/.*"stage":"\([^"]*\)".*/\1/p')
            et=$(echo "$line" | sed -n 's/.*"event_type":"\([^"]*\)".*/\1/p')
            ac=$(echo "$line" | sed -n 's/.*"actor":"\([^"]*\)".*/\1/p')
            dur=$(echo "$line" | sed -n 's/.*"duration_ms":\([0-9]*\).*/\1/p')
            echo "$ts,$wf,$stg,$et,$ac,$dur" >> "$out"
        done < "$f"
    done

    echo "[OK] 已导出到 $out（$(wc -l < "$out") 行）"
}

# ── 入口 ──
case "${1:-}" in
    --stats)
        shift
        cmd_stats "$@"
        ;;
    --hotspots)
        shift
        DAYS=30
        while [ $# -gt 0 ]; do
            case "$1" in
                --days) DAYS="$2"; shift 2 ;;
                *) shift ;;
            esac
        done
        cmd_hotspots "$DAYS"
        ;;
    --export)
        shift
        cmd_export "$@"
        ;;
    *)
        echo "用法: logs-query.sh {--stats [workflow_id]|--hotspots [--days N]|--export [--days N] [--out PATH]}" >&2
        exit 1
        ;;
esac
```

- [x] **步骤 6.4：赋予执行权限**

```bash
chmod +x scripts/harness/logs-query.sh scripts/harness/tests/test-logs-query.sh
```

- [x] **步骤 6.5：运行测试确认通过**

```bash
bash scripts/harness/tests/test-logs-query.sh
```
预期：全部通过。

- [x] **步骤 6.6：提交**

```bash
git add scripts/harness/logs-query.sh scripts/harness/tests/test-logs-query.sh
git commit -m "feat(harness): 新增 logs-query.sh 查询工具 + 单元测试"
```

---

## 任务 7：workflow-state.sh 埋点 + 记忆提示（B+C 合并）

**文件：**
- 修改：`scripts/harness/workflow-state.sh`

- [x] **步骤 7.1：在 `write_state()` 函数后新增辅助函数**

在 `write_state()` 函数（第 71-84 行）结束后，新增辅助函数用于计算阶段耗时。使用 Edit 工具：

- old_string:
```
write_state() {
    local stage="$1"
    local task="$2"
    local started="$3"
    local exempt="${4:-false}"
    ensure_state_dir
    cat > "$STATE_FILE" << EOF
stage=$stage
task=$task
started=$started
exempt=$exempt
updated=$(date '+%Y-%m-%d %H:%M:%S')
EOF
}
```
- new_string:
```
write_state() {
    local stage="$1"
    local task="$2"
    local started="$3"
    local exempt="${4:-false}"
    ensure_state_dir
    cat > "$STATE_FILE" << EOF
stage=$stage
task=$task
started=$started
exempt=$exempt
updated=$(date '+%Y-%m-%d %H:%M:%S')
EOF
}

# 计算自上次 updated 以来的毫秒数（用于 stage_exit duration）
compute_stage_duration_ms() {
    local last_updated
    last_updated=$(get_field "updated")
    if [ -z "$last_updated" ]; then
        echo "0"
        return
    fi
    local last_ts
    last_ts=$(date -d "$last_updated" +%s 2>/dev/null || echo "0")
    local now_ts
    now_ts=$(date +%s)
    if [ "$last_ts" -eq 0 ]; then
        echo "0"
    else
        echo $(( (now_ts - last_ts) * 1000 ))
    fi
}

# 调用 log-event.sh（失败不报错）
log_event() {
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    bash "$script_dir/log-event.sh" "$@" 2>/dev/null || true
}
```

- [x] **步骤 7.2：修改 `cmd_init()` 末尾追加事件 + 欢迎提示**

使用 Edit 工具：
- old_string:
```
    write_state "brainstorming" "$task_name" "$(date '+%Y-%m-%d %H:%M:%S')"
    echo "[OK] 工作流已启动: $task_name"
    echo "[STATE] 当前阶段: brainstorming（需求收集）"
    echo "[NEXT] 收集和分析功能需求，记录到 .dev-agents/shared/designs/ 后运行 advance"
}
```
- new_string:
```
    write_state "brainstorming" "$task_name" "$(date '+%Y-%m-%d %H:%M:%S')"
    log_event workflow_start --stage brainstorming --payload "task_name=$task_name"
    log_event stage_enter --stage brainstorming
    echo "[OK] 工作流已启动: $task_name"
    echo "[STATE] 当前阶段: brainstorming（需求收集）"
    echo "[NEXT] 收集和分析功能需求，记录到 .dev-agents/shared/designs/ 后运行 advance"
    echo "[REMIND] 若本工作流涉及架构决策，完成后请更新 .dev-agents/shared/memory/activeContext.md"
}
```

- [x] **步骤 7.3：修改 `cmd_advance()` 在状态切换前后埋点**

在 `cmd_advance()` 的 `write_state "$next" "$task" ...` 之前增加 stage_exit 事件，之后增加 stage_enter 事件 + 提示文案。

使用 Edit 工具：
- old_string:
```
    local next
    next=$(next_stage "$current_stage")

    if [ "$next" = "idle" ]; then
        write_state "idle" "" "" "false"
        echo "[OK] 工作流已完成: $task"
        echo "[STATE] 状态已重置为 idle"
    else
        write_state "$next" "$task" "$(get_field 'started')"
        echo "[OK] 阶段推进: $current_stage（$(stage_label "$current_stage")） → $next（$(stage_label "$next")）"
        echo "[STATE] 当前阶段: $next（$(stage_label "$next")）"

        case "$next" in
            validation)
                echo "[NEXT] 验证需求的完整性和可行性，确认无歧义后 advance" ;;
            design)
                echo "[NEXT] 设计技术方案和架构，产出方案决策文档后 advance" ;;
            planning)
                echo "[NEXT] 将需求拆解为可执行任务，保存到 .dev-agents/shared/tasks/" ;;
            development)
                echo "[NEXT] 派遣 Jarvis 子代理按任务执行开发" ;;
            testing)
                echo "[NEXT] 派遣 Kyle 编写和执行测试用例，进行两阶段审查" ;;
            documentation)
                echo "[NEXT] 更新相关文档（API 文档、README、ARCHITECTURE 等）" ;;
            finishing)
                echo "[NEXT] 执行分支收尾流程（集成/PR/归档）" ;;
        esac
    fi
}
```
- new_string:
```
    local next
    next=$(next_stage "$current_stage")

    local stage_duration_ms
    stage_duration_ms=$(compute_stage_duration_ms)
    log_event stage_exit --stage "$current_stage" --duration-ms "$stage_duration_ms" --payload "next_stage=$next"

    if [ "$next" = "idle" ]; then
        write_state "idle" "" "" "false"
        log_event workflow_complete --stage idle --payload "prev_stage=$current_stage"
        echo "[OK] 工作流已完成: $task"
        echo "[STATE] 状态已重置为 idle"
    else
        write_state "$next" "$task" "$(get_field 'started')"
        log_event stage_enter --stage "$next" --payload "prev_stage=$current_stage"
        echo "[OK] 阶段推进: $current_stage（$(stage_label "$current_stage")） → $next（$(stage_label "$next")）"
        echo "[STATE] 当前阶段: $next（$(stage_label "$next")）"

        case "$next" in
            validation)
                echo "[NEXT] 验证需求的完整性和可行性，确认无歧义后 advance" ;;
            design)
                echo "[NEXT] 设计技术方案和架构，产出方案决策文档后 advance" ;;
            planning)
                echo "[NEXT] 将需求拆解为可执行任务，保存到 .dev-agents/shared/tasks/"
                echo "[REMIND] 方案设计已完成，请更新 .dev-agents/shared/memory/projectContext.md 记录架构决策" ;;
            development)
                echo "[NEXT] 派遣 Jarvis 子代理按任务执行开发" ;;
            testing)
                echo "[NEXT] 派遣 Kyle 编写和执行测试用例，进行两阶段审查" ;;
            documentation)
                echo "[NEXT] 更新相关文档（API 文档、README、ARCHITECTURE 等）"
                echo "[REMIND] Kyle 已通过审查，若发现值得沉淀的代码模式，请更新 .dev-agents/shared/memory/systemPatterns.md" ;;
            finishing)
                echo "[NEXT] 执行分支收尾流程（集成/PR/归档）" ;;
        esac
        echo "[REMIND] 阶段已推进，请同步更新 .dev-agents/shared/memory/activeContext.md 反映当前状态"
    fi
}
```

- [x] **步骤 7.4：修改 `cmd_reset()`**

使用 Edit 工具：
- old_string:
```
    write_state "idle" "" "" "false"
    echo "[OK] 工作流已重置（原任务: ${task:-未命名}，原阶段: $current_stage）"
}
```
- new_string:
```
    log_event workflow_reset --stage "$current_stage" --payload "prev_task=${task:-unnamed}"
    write_state "idle" "" "" "false"
    echo "[OK] 工作流已重置（原任务: ${task:-未命名}，原阶段: $current_stage）"
}
```

- [x] **步骤 7.5：修改 `cmd_exempt()`**

使用 Edit 工具：
- old_string:
```
    write_state "idle" "exempt: $reason" "$(date '+%Y-%m-%d %H:%M:%S')" "true"
    echo "[OK] 已标记为简单任务豁免: $reason"
    echo "[INFO] 豁免任务完成后请运行 workflow-state.sh reset 恢复正常模式"
}
```
- new_string:
```
    write_state "idle" "exempt: $reason" "$(date '+%Y-%m-%d %H:%M:%S')" "true"
    log_event workflow_exempt --stage idle --payload "reason=$reason"
    echo "[OK] 已标记为简单任务豁免: $reason"
    echo "[INFO] 豁免任务完成后请运行 workflow-state.sh reset 恢复正常模式"
}
```

- [x] **步骤 7.6：集成测试**（跳过：活跃工作流中不执行，任务 12 端到端统一验证；已做 `bash -n` 语法验证）

```bash
# 模拟：先 reset，确保干净
bash scripts/harness/workflow-state.sh reset >/dev/null 2>&1

# 创建临时 workflow 看埋点
bash scripts/harness/workflow-state.sh init "test-integration"
bash scripts/harness/workflow-state.sh advance 2>&1 | tail -5
# 清理
bash scripts/harness/workflow-state.sh reset

# 验证日志有事件
LOG=".dev-agents/shared/logs/events-$(date +%Y-%m-%d).jsonl"
grep -c '"event_type":"workflow_start"' "$LOG"
grep -c '"event_type":"stage_enter"' "$LOG"
grep -c '"event_type":"stage_exit"' "$LOG"
grep -c '"event_type":"workflow_reset"' "$LOG"
```
预期：每个事件计数 ≥ 1。

⚠️ **注意**：本步骤会向日志追加条目。执行前若当前正有活跃工作流（比如本次开发工作流），应先备份 `.workflow-state`，测试完恢复。实际 Jarvis 执行时由于任务 7 在真实工作流中进行，可以跳过此步骤验证（任务 12 端到端验证会覆盖）。

- [x] **步骤 7.7：提交**（commit 2182539）

```bash
git add scripts/harness/workflow-state.sh
git commit -m "feat(harness): workflow-state.sh 集成 log-event + 记忆更新提示"
```

---

## 任务 8：5 个 lint 脚本插桩（C 项失败采集）

**文件：**
- 修改：`scripts/harness/lint-structure.sh`
- 修改：`scripts/harness/lint-docs.sh`
- 修改：`scripts/harness/lint-workflow-artifacts.sh`
- 修改：`scripts/harness/lint-delegation.sh`
- 修改：`scripts/harness/lint-process.sh`

**实施策略**：在每个脚本的 `fail()` 函数内部统一调用 `log-event.sh lint_fail`，这样只需改 5 行。

- [x] **步骤 8.1：修改所有 5 个 lint 脚本的 `fail()` 函数**

每个脚本的 `fail()` 函数当前形如：
```bash
fail() { echo -e "  [FAIL] $1"; ERRORS=$((ERRORS + 1)); }
```

对以下 5 个文件**逐一**使用 Edit 工具（每个文件单独 Edit，因为 lint-structure.sh 的 `fail()` 要单独调整 rule 变量）：

#### 8.1.1 lint-structure.sh

- old_string: `fail() { echo -e "  [FAIL] $1"; ERRORS=$((ERRORS + 1)); }`
- new_string:
```
fail() {
    echo -e "  [FAIL] $1"
    ERRORS=$((ERRORS + 1))
    bash "$(dirname "${BASH_SOURCE[0]}")/log-event.sh" lint_fail --actor harness --payload "lint=structure,msg=$1" 2>/dev/null || true
}
```

#### 8.1.2 lint-docs.sh

- old_string: `fail() { echo -e "  [FAIL] $1"; ERRORS=$((ERRORS + 1)); }`
- new_string:
```
fail() {
    echo -e "  [FAIL] $1"
    ERRORS=$((ERRORS + 1))
    bash "$(dirname "${BASH_SOURCE[0]}")/log-event.sh" lint_fail --actor harness --payload "lint=docs,msg=$1" 2>/dev/null || true
}
```

#### 8.1.3 lint-workflow-artifacts.sh

- old_string: `fail() { echo -e "  [FAIL] $1"; ERRORS=$((ERRORS + 1)); }`
- new_string:
```
fail() {
    echo -e "  [FAIL] $1"
    ERRORS=$((ERRORS + 1))
    bash "$(dirname "${BASH_SOURCE[0]}")/log-event.sh" lint_fail --actor harness --payload "lint=workflow-artifacts,msg=$1" 2>/dev/null || true
}
```

#### 8.1.4 lint-delegation.sh

- old_string: `fail() { echo -e "  [FAIL] $1"; ERRORS=$((ERRORS + 1)); }`
- new_string:
```
fail() {
    echo -e "  [FAIL] $1"
    ERRORS=$((ERRORS + 1))
    bash "$(dirname "${BASH_SOURCE[0]}")/log-event.sh" lint_fail --actor harness --payload "lint=delegation,msg=$1" 2>/dev/null || true
}
```

#### 8.1.5 lint-process.sh

- old_string: `fail() { echo -e "  [FAIL] $1"; ERRORS=$((ERRORS + 1)); }`
- new_string:
```
fail() {
    echo -e "  [FAIL] $1"
    ERRORS=$((ERRORS + 1))
    bash "$(dirname "${BASH_SOURCE[0]}")/log-event.sh" lint_fail --actor harness --payload "lint=process,msg=$1" 2>/dev/null || true
}
```

⚠️ payload 中的 `$1` 含空格和中文，依赖 `log-event.sh` 的 JSON 转义。`,` 逗号是 payload 分隔符会与消息冲突：为避免问题，我们**只保留 lint 名称**，不传消息详情。

**修正**：把上述 5 处 new_string 中的 `,msg=$1` **删除**（因为 `$1` 含有 `,` 会破坏 payload 解析）。最终 new_string 应为：

```
fail() {
    echo -e "  [FAIL] $1"
    ERRORS=$((ERRORS + 1))
    bash "$(dirname "${BASH_SOURCE[0]}")/log-event.sh" lint_fail --actor harness --payload "lint=<LINT_NAME>" 2>/dev/null || true
}
```

其中 `<LINT_NAME>` 分别替换为：`structure` / `docs` / `workflow-artifacts` / `delegation` / `process`。

- [x] **步骤 8.2：验证插桩不影响原 lint 行为**（run-all.sh 仍 0 FAIL，与基线一致）

```bash
bash scripts/harness/run-all.sh 2>&1 | tail -15
```
预期：run-all.sh 输出与插桩前一致（统计数字可能因为阶段添加而变化，但不应出现新的 [FAIL]）。

如果有新的 [FAIL]，大多是 `memory/` `logs/` 目录不存在的 warn 级别（可接受）。

- [x] **步骤 8.3：验证事件被采集**（留待任务 12 端到端验证；本批次仅验证插桩语法 + run-all 行为不变）

```bash
# 故意制造一个 lint fail 场景：创建一个缺少验收条件的伪计划
mkdir -p /tmp/test-lint && echo "fake plan" > /tmp/test-lint/fake.md
# 直接运行某个 lint 看是否写入日志
bash scripts/harness/lint-structure.sh >/dev/null 2>&1 || true

# 查看最新日志
LOG=".dev-agents/shared/logs/events-$(date +%Y-%m-%d).jsonl"
grep 'lint_fail' "$LOG" | tail -3
```
预期：若有 lint fail，则日志中出现 `"event_type":"lint_fail"`。

- [x] **步骤 8.4：提交**（commit 58695a0）

```bash
git add scripts/harness/lint-*.sh
git commit -m "feat(harness): 5 个 lint 脚本 fail() 函数插桩记录失败事件"
```

---

## 任务 9：更新 CLAUDE.md 加入会话启动协议（B 项）

**文件：**
- 修改：`CLAUDE.md`

- [x] **步骤 9.1：检查当前行数**

```bash
wc -l CLAUDE.md
```
记录当前行数（设为 N）。插入后应 ≤ 100，否则需精简现有内容。

- [x] **步骤 9.2：在 "## 全局铁律" 之前插入新章节**

使用 Edit 工具：
- old_string:
```
## 全局铁律

```
- new_string:
```
## 会话启动协议

Max 每次会话启动时必须：
1. 读取 `.dev-agents/shared/memory/activeContext.md`（若存在）了解上次工作状态
2. 读取 `.dev-agents/shared/.workflow-state`（若存在）确认活跃工作流
3. 怀疑反复错误时运行 `bash scripts/harness/logs-query.sh --hotspots`

## 全局铁律

```

- [x] **步骤 9.3：验证行数不超限**

```bash
wc -l CLAUDE.md
```
预期：≤ 100 行（lint-docs.sh 约束）。

若超出，精简方式：把"## 知识库地图"表格的某些行合并（不在本任务范围内），此时 Jarvis 应停下来报告给 Max。

- [x] **步骤 9.4：跑 lint-docs 确认无告警**

```bash
bash scripts/harness/lint-docs.sh 2>&1 | grep -E 'CLAUDE\.md.*(PASS|WARN|FAIL)'
```
预期：CLAUDE.md 检查通过或仅警告，无 FAIL。

- [x] **步骤 9.5：提交**

```bash
git add CLAUDE.md
git commit -m "docs(claude): 新增会话启动协议，要求 Max 启动时加载记忆和工作流状态"
```

---

## 任务 10：创建 logs/ 目录和 README（C 项 schema 文档）

**文件：**
- 新建：`.dev-agents/shared/logs/README.md`

- [x] **步骤 10.1：创建目录**

```bash
mkdir -p .dev-agents/shared/logs
```

- [x] **步骤 10.2：写入 README.md**

完整内容：

````markdown
# Harness 运行时日志

此目录存储 Harness 各组件产生的结构化事件日志。

## 文件命名

- `events-YYYY-MM-DD.jsonl` — 按日滚动
- 每行一个完整 JSON 对象

## 事件 Schema

```json
{
  "ts": "ISO-8601 带时区",
  "workflow_id": "workflow-state.sh 的 task 名；空闲时为 idle",
  "stage": "brainstorming|validation|design|planning|development|testing|documentation|finishing|idle",
  "event_type": "见下方枚举",
  "actor": "max|jarvis|ella|kyle|harness",
  "duration_ms": 123456,
  "payload": { "自由字段": "..." }
}
```

### event_type 枚举

| event_type | 触发者 | 典型 payload |
|-----------|--------|-------------|
| `workflow_start` | workflow-state.sh init | `task_name` |
| `workflow_reset` | workflow-state.sh reset | `prev_task` |
| `workflow_exempt` | workflow-state.sh exempt | `reason` |
| `workflow_complete` | workflow-state.sh advance（finishing 后） | `prev_stage` |
| `stage_enter` | workflow-state.sh advance | `prev_stage` |
| `stage_exit` | workflow-state.sh advance（新阶段前） | `next_stage` + duration_ms |
| `dispatch` | Max 派遣子代理时 | `target`, `task_id` |
| `loop_iter` | Max 在 Kyle 循环中 | `iteration`, `result` |
| `lint_fail` | lint-*.sh 失败路径 | `lint` |
| `red_flag` | Max 检测到 red-flag | `flag_id`, `severity` |

## 查询

```bash
bash scripts/harness/logs-query.sh --stats [workflow_id]
bash scripts/harness/logs-query.sh --hotspots [--days N]
bash scripts/harness/logs-query.sh --export --out report.csv
```

## Git 策略

- **不追踪**：`events-*.jsonl`（个人运行时状态）
- **追踪**：本 README.md（schema 说明）
````

- [x] **步骤 10.3：验证**

```bash
ls -la .dev-agents/shared/logs/
cat .dev-agents/shared/logs/README.md | head -5
```
预期：目录存在，README 包含"Harness 运行时日志"标题。

---

## 任务 11：更新 .gitignore（B+C 合并）

**文件：**
- 修改：`.gitignore`

- [x] **步骤 11.1：查看当前 .gitignore**

```bash
cat .gitignore
```

- [x] **步骤 11.2：追加新规则**

使用 Edit 工具，在 .gitignore 末尾追加（如果 .gitignore 末尾无 `# Harness` 段）：

- old_string: `（.gitignore 最后一行的内容，用 tail -1 .gitignore 查看）`

或更稳妥的做法：用 Write 读取再追加的方式。**简化做法**：直接在末尾追加：

```bash
cat >> .gitignore <<'EOF'

# ── Harness 运行时状态 ──
# 日志（个人运行时，不入库）
.dev-agents/shared/logs/events-*.jsonl
# 会话级记忆（个人工作状态，频繁变更）
.dev-agents/shared/memory/activeContext.md
EOF
```

**但 bash here-doc 需要 sh 支持**。更稳妥做法：**先 Read .gitignore 全文，再用 Write 重写**。

实际执行：
1. Read .gitignore 全文
2. 用 Edit 工具在文件末尾（或任意已知锚点）追加

假设 .gitignore 末尾有 `.idea/`（从项目结构看这是最后一项），Edit：
- old_string: `.idea/`
- new_string:
```
.idea/

# ── Harness 运行时状态 ──
.dev-agents/shared/logs/events-*.jsonl
.dev-agents/shared/memory/activeContext.md
```

（Jarvis 执行时应 `cat .gitignore` 确认 old_string 锚点再用 Edit；若末尾不是 `.idea/`，调整 old_string。）

- [x] **步骤 11.3：验证规则生效**

```bash
# 先创建一个测试文件
echo '{}' > .dev-agents/shared/logs/events-test.jsonl
git status --short | grep events-test
```
预期：无输出（表明被 gitignore）。

```bash
# 清理测试文件
rm .dev-agents/shared/logs/events-test.jsonl
```

- [x] **步骤 11.4：验证 projectContext/systemPatterns 被追踪**

```bash
git status --short | grep -E "memory/(project|system)"
```
预期：显示 `?? .dev-agents/shared/memory/projectContext.md` 和 `?? .dev-agents/shared/memory/systemPatterns.md`（新文件，未追踪但将被 git add）。

---

## 任务 12：整体验证 + 冒烟测试

- [x] **步骤 12.1：运行全量 harness 自检**

```bash
bash scripts/harness/run-all.sh 2>&1 | tail -20
```
预期：状态为 `✅ 全部通过`。若有 warn 是 memory/ 目录刚建 + 日志刚开始，可接受；若有 FAIL 必须修复。

- [x] **步骤 12.2：运行单元测试**

```bash
bash scripts/harness/tests/test-log-event.sh
bash scripts/harness/tests/test-logs-query.sh
```
预期：两个测试全部通过。

- [x] **步骤 12.3：冒烟测试 — B 项记忆系统**

打开 `.dev-agents/shared/memory/activeContext.md`，手动写入：
- workflow_id：当前工作流名
- 上次做到哪：本 plan 的任务 12 验证
- 下一步动作：finishing 阶段收尾

然后模拟"重启会话"：Max 读取该文件，应能复述三项内容。

```bash
cat .dev-agents/shared/memory/activeContext.md
```

- [x] **步骤 12.4：冒烟测试 — C 项查询**

```bash
# 确保有活跃工作流（当前应该就是）
bash scripts/harness/logs-query.sh --stats
bash scripts/harness/logs-query.sh --hotspots --days 7
```
预期：`--stats` 输出当前工作流各阶段耗时；`--hotspots` 输出 lint_fail 类别排行（或"无匹配事件"若未触发 lint 失败）。

- [x] **步骤 12.5：验证 A 项迁移完成**

```bash
# 旧路径不应存在
[ ! -d .dev-agents/shared/templates ] && echo "[OK] 旧路径已清除"
# 新路径应存在
[ -d docs/templates ] && [ -f docs/templates/prd.md ] && echo "[OK] 新路径完整"
# 引用已更新
grep -rn "dev-agents/shared/templates" --include="*.sh" --include="*.mjs" scripts/ cli/ 2>/dev/null | wc -l
```
预期：
- "[OK] 旧路径已清除"
- "[OK] 新路径完整"
- 引用计数：0

- [x] **步骤 12.6：提交**

```bash
git add .gitignore .dev-agents/shared/logs/README.md .dev-agents/shared/memory/
git commit -m "feat(harness): 新增记忆系统 3 件套 + 日志 schema + gitignore 规则"
```

---

## 实现计划自检

对照设计文档 19+1 条 FR 的覆盖：

- [x] FR-A1-A4（templates 迁移 + 引用更新 + ARCHITECTURE 更新）→ 任务 1/2/3
- [x] FR-B1-B6（memory 目录 + 3 文件 + frontmatter + 启动规则 + 写入协议 + 模板）→ 任务 4 + 7 + 9
- [x] FR-C1-C8（logs 目录 + 滚动 + schema + 埋点 + 查询 + gitignore + log-event 工具）→ 任务 5/6/7/8/10/11
- [x] 验收标准：run-all.sh 全绿 + 冒烟测试 → 任务 12

**禁止占位符扫描**：
- ✅ 无"待定"/"TODO"/"之后实现"
- ✅ 所有代码块均为完整可执行内容
- ✅ 所有 Edit 操作给出完整 old_string 和 new_string

**类型一致性**：
- ✅ JSON schema 字段在 log-event.sh / logs-query.sh / README 中一致
- ✅ 事件类型枚举在 CLAUDE.md / README / workflow-state.sh 中一致

## 执行顺序与派遣建议

**必须串行**（由于 workflow-pipeline 规定不并行实施）：

```
任务 1 → 任务 2 → 任务 3          （A 项闭环）
      → 任务 4                    （B 项记忆）
      → 任务 5 → 任务 6 → 任务 7  （C 项工具 + 埋点，workflow-state 改动合并）
      → 任务 8                    （lint 插桩）
      → 任务 9                    （CLAUDE.md 启动协议）
      → 任务 10 → 任务 11         （目录+gitignore 收尾）
      → 任务 12                   （整体验证）
```

**派遣方式**：每个任务派遣一个新的 Jarvis 子代理，Max 注入上下文（本计划相对路径 + 当前任务编号 + 依赖的前置产物路径）。

## 验收条件（Done Criteria）

- [ ] 12 个任务全部 checkbox 打勾
- [ ] `bash scripts/harness/run-all.sh` 返回 exit 0
- [ ] `bash scripts/harness/tests/test-log-event.sh` 全部通过
- [ ] `bash scripts/harness/tests/test-logs-query.sh` 全部通过
- [ ] 旧路径 `.dev-agents/shared/templates` 不存在
- [ ] 新路径 `docs/templates` 含 10 个 .md 文件
- [ ] `.dev-agents/shared/memory/` 含 3 个 .md 文件
- [ ] `.dev-agents/shared/logs/README.md` 存在
- [ ] `.gitignore` 包含 `events-*.jsonl` 和 `activeContext.md` 规则
- [ ] 手动触发一次 advance，日志文件中出现 stage_exit 和 stage_enter 事件

## Post-review Fix（2026-04-23 Kyle 一轮后补修）

Kyle 一轮审查发现 2 BLOCK + 1 WARN（见 `.dev-agents/shared/reviews/2026-04-23-harness-l4-l5-enhancement-review.md`）：
- [Fix] `logs-query.sh` cmd_hotspots sed 提取从 `rule` 改为 `lint` 跟随任务 8.1 字段契约
- [Fix] `logs-query.sh` 新增 `get_log_files_within_days()` 使 `--days N` 对 cmd_hotspots/cmd_export 真实过滤
- [Fix] `tests/test-logs-query.sh` mock 数据同步为 `lint=structure/docs`，新增 `--days 1/3650` 过滤断言与 `red_flag` flag_id 聚合断言；测试 4 改用 `rm -f events-*.jsonl` 清理全部历史日志
- 测试结果：12 通过 / 0 失败（原 9 通过）；run-all.sh 全绿；手动 `lint_fail` + `--hotspots` 能正常输出 lint 名

## 实现计划自检（Documentation 阶段 2026-04-23）

documentation 阶段由 Jarvis 执行，完成以下文档更新：
- [x] `docs/ARCHITECTURE.md` 新增"六层架构实现映射"章节（含 L4 记忆系统详解 + L5 观测系统详解）
- [x] `docs/workflow-pipeline.md` 新增"advance 命令副作用"小节
- [x] `docs/red-flags.md` 第 8 条补充 `logs-query.sh --hotspots` 命令提示
- [x] `docs/README.md` 新增子目录小节，引用 `templates/`
- [x] `docs/QUALITY_SCORE.md` 更新日期至 2026-04-23，变更记录追加 L4/L5 补强条目
- [x] `bash scripts/harness/lint-docs.sh` 全部通过
- [x] `bash scripts/harness/run-all.sh` 0 错误（仅 1 个已知设计文档 WARN 与本次无关）

范围仅限上述 5 个文档，未触及其他文件，符合"只更新受影响的文档"原则。

