# Harness L4/L5 层补强技术设计文档

**工作流 ID**：harness-l4-l5-enhancement
**创建日期**：2026-04-23
**状态**：待用户确认

## 需求引用

需求文档：`.dev-agents/shared/designs/2026-04-23-harness-l4-l5-enhancement-requirements.md`
范围：A（templates 迁移）+ B（长期记忆）+ C（运行时观测）

## 开源项目调研摘要

| 参考项目 | 关键借鉴点 | 采纳程度 |
|---------|-----------|---------|
| **Cline Memory Bank** | 6 文件分层（projectbrief/productContext/activeContext/systemPatterns/techContext/progress）+ 会话启动强制加载 + 依赖顺序 | 简化为 3 文件（合并 projectbrief+productContext+techContext → projectContext；去掉 progress） |
| **Aider repo-map** | tree-sitter + PageRank 生成符号地图 | ❌ 不采纳（需要 tree-sitter 依赖，超出"零外部依赖"约束；场景不匹配：我们要 human-readable 记忆，非机器检索） |
| **AutoGen / AG2 logging** | OpenTelemetry GenAI Semantic Conventions + trace_id + structured spans | 部分借鉴字段命名（ts / actor / event_type / duration_ms），放弃 span 树结构（过重） |
| **LangFuse trace/observation** | session → trace → observation 三层模型 | 映射为：workflow → stage → event（扁平化，省一层 span_id） |
| **Claude Code transcript** | JSONL 按会话文件滚动 | 采纳：按日滚动 `events-YYYY-MM-DD.jsonl` |

## B 项（长期记忆）设计

### 方案对比

#### 方案 B-α：严格 3 件套（推荐）

- **描述**：落地需求中锁定的 projectContext + activeContext + systemPatterns 三个 Markdown 文件
- **加载协议**：CLAUDE.md 明文规定"会话启动必读 activeContext.md"，其他两个按需读取
- **写入协议**：由 `workflow-state.sh` 的 advance 命令在特定阶段尾部输出提示文案
- **优点**：
  - 与需求完全一致，改动面最小
  - 与 Cline 社区最佳实践对齐
  - 人类可读，git diff 友好
- **缺点**：
  - 不做自动符号索引，大项目时无法像 Aider 那样定位代码
  - 需 Max 自律更新（软约束）

#### 方案 B-β：3 件套 + Max Hook 自动提示

- **描述**：在 `.claude/hooks.json` PostToolUse/Stop 中加逻辑，检测到 Max 会话且 activeContext.md 未更新 → 给出提醒
- **优点**：
  - 减少 Max 忘记更新记忆的风险
  - 利用现有 hook 基础设施
- **缺点**：
  - hook 增加复杂度，仅 Claude Code CLI 环境生效（需求约束条件下本项目主要就是 Claude Code，但引入了对 hook 的紧耦合）
  - "未更新"的检测逻辑不清晰（更新阈值难定）
  - 过度工程化，P2 阶段再做更合适

**选定方案**：**B-α**。理由：符合"极致简单"原则；Cline 已用同样机制验证过可用；B-β 可作为 P2 增强，不阻塞当前工作流。

### 架构设计

```
┌─────────────────────────────────────────────────────────┐
│  CLAUDE.md （< 100 行，全局入口）                       │
│  ┌──────────────────────────────────────────────────┐  │
│  │ 会话启动规则：先读 memory/activeContext.md        │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
                          │ 读
                          ↓
┌─────────────────────────────────────────────────────────┐
│  .dev-agents/shared/memory/                             │
│  ┌───────────────────┐  ┌──────────────────────┐       │
│  │ activeContext.md  │  │ projectContext.md    │       │
│  │ (gitignore)       │  │ (git 追踪)           │       │
│  │ 当前进度/下一步   │  │ 架构决策/产品愿景    │       │
│  └───────────────────┘  └──────────────────────┘       │
│          ↑                      ↑                       │
│          │ advance 后提示更新    │ design 后提示更新    │
│  ┌───────────────────┐                                  │
│  │ systemPatterns.md │←── Kyle 通过后 Max 提炼          │
│  │ (git 追踪)        │                                  │
│  │ 代码模式沉淀      │                                  │
│  └───────────────────┘                                  │
└─────────────────────────────────────────────────────────┘
                          ↑ 写
                          │
┌─────────────────────────────────────────────────────────┐
│  scripts/harness/workflow-state.sh                      │
│  advance → 阶段尾部输出提示文案（根据阶段类型）         │
└─────────────────────────────────────────────────────────┘
```

### 文件 Schema 设计

#### projectContext.md

```markdown
---
last_updated: 2026-04-23
updated_by: design-stage
version: 1
---

# 项目上下文

## 产品愿景
<一句话描述项目使命>

## 核心架构决策
<表格形式，记录关键决策和放弃的替代方案>
| 决策 | 做出时间 | 上下文 | 放弃的替代方案 |
|------|---------|--------|---------------|

## 技术栈
<使用的语言、框架、关键库>

## 关键约束
<硬约束：性能/合规/兼容性等>

## 团队惯例
<与 coding-standards.md 互补：偏好、隐含规则>
```

#### activeContext.md

```markdown
---
last_updated: 2026-04-23T12:34:56
updated_by: advance-to-planning
workflow_id: harness-l4-l5-enhancement
version: 1
---

# 当前工作上下文

## 当前焦点
<workflow_id + 当前阶段 + 正在做什么>

## 上次做到哪
<具体产出位置和关键决策>

## 下一步动作
<下次启动 Max 第一件事做什么>

## 开放的阻塞问题
<需要用户决定的问题清单>

## 近期学到的（本次会话新发现）
<非系统性的临时笔记，稳定后转入 systemPatterns>
```

#### systemPatterns.md

```markdown
---
last_updated: 2026-04-23
updated_by: testing-stage
version: 1
---

# 系统模式

## 代码模式
<表格：Kyle 审查中反复出现的好/坏模式>
| 模式名 | 类型（推荐/反模式） | 场景 | 示例位置 | 首次发现日期 |

## 常用重构手法
<场景 → 重构方法的映射>

## 已沉淀的团队约定
<从"近期学到"转正的约定，每条需包含"为什么">
```

### 写入协议（workflow-state.sh 增强）

| 触发阶段 | 输出提示文案 |
|---------|-------------|
| `advance` 到 `design` 之后 | `[REMIND] 进入方案设计，完成后请更新 .dev-agents/shared/memory/projectContext.md 记录架构决策` |
| `advance` 任意阶段 | `[REMIND] 请更新 activeContext.md：当前焦点、上次做到哪、下一步` |
| `advance` 到 `documentation` 之后（即 testing 完成后） | `[REMIND] Kyle 已通过审查，若发现值得沉淀的代码模式，请更新 systemPatterns.md` |
| `reset` / `finishing` | `[REMIND] 工作流结束，请归档 activeContext.md 中本次相关状态` |

### CLAUDE.md 补丁（预览）

在"## 全局铁律"之前插入：

```markdown
## 会话启动协议

Max 每次会话启动时，**必须**先执行：
1. 读取 `.dev-agents/shared/memory/activeContext.md` — 了解上次工作状态
2. 读取 `.dev-agents/shared/.workflow-state`（若存在）— 确认是否有进行中的工作流
3. 若两者不一致，先与用户澄清
```

## C 项（运行时观测）设计

### 方案对比

#### 方案 C-α：扁平 JSONL（推荐）

- **描述**：单一 JSONL 文件按日滚动，每行独立事件，通过 `workflow_id` 关联
- **优点**：
  - 零依赖，grep/sed 直接查
  - 写入原子（追加单行，并发安全）
  - schema 演进无痛（`payload` 字段自由扩展）
  - 与 Claude Code transcript 风格一致
- **缺点**：
  - 查询慢于 DB（但本场景数据量小，grep 已够）
  - 无法表达 span 父子关系（故意简化）

#### 方案 C-β：OpenTelemetry 风格 trace/span 嵌套 JSON

- **描述**：每个 workflow 一个 trace，每个 stage/dispatch/loop 是 span，有 parent_span_id
- **优点**：
  - 语义精确（可反映派遣层级）
  - 可直接导出到 Jaeger/LangFuse/Phoenix
- **缺点**：
  - 纯 bash 实现 span 堆栈难度大
  - 过度设计（单人场景无真正分布式追踪需求）
  - 与现有 workflow-state.sh 扁平模型不匹配

**选定方案**：**C-α**。理由：单人场景 + 零依赖 + 够用；未来若需要 span 树，可在 payload 中加 `parent_event_id` 渐进演化。

### 事件 Schema（最终版）

每行单个 JSON 对象，字段顺序固定（方便 grep 和肉眼读取）：

```
{"ts":"2026-04-23T23:05:12+0800","workflow_id":"harness-l4-l5-enhancement","stage":"design","event_type":"stage_exit","actor":"harness","duration_ms":1847000,"payload":{"next_stage":"planning"}}
```

**字段定义**：

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `ts` | string | ✅ | ISO-8601 带时区 |
| `workflow_id` | string | ✅ | 对应 `.workflow-state` 的 task 名；空闲时 `"idle"` |
| `stage` | string | ✅ | 8 阶段枚举 + `idle` |
| `event_type` | string | ✅ | 见下方事件类型表 |
| `actor` | string | ✅ | `max` / `jarvis` / `ella` / `kyle` / `harness`（自动化脚本） |
| `duration_ms` | number | 可选 | 耗时事件填入 |
| `payload` | object | 可选 | 自由扩展字段 |

**事件类型枚举**：

| event_type | 触发者 | payload 典型字段 |
|-----------|--------|-----------------|
| `workflow_start` | workflow-state.sh init | `{"task_name": "..."}` |
| `workflow_reset` | workflow-state.sh reset | `{"from_stage": "..."}` |
| `workflow_exempt` | workflow-state.sh exempt | `{"reason": "..."}` |
| `workflow_complete` | workflow-state.sh advance 到 finishing 后 reset | `{"total_duration_ms": N}` |
| `stage_enter` | workflow-state.sh advance | `{"prev_stage": "..."}` |
| `stage_exit` | workflow-state.sh advance（在进入新阶段前） | `{"next_stage": "..."}` |
| `dispatch` | Max 在派遣 Agent 时主动调用 | `{"target": "jarvis\|ella\|kyle", "task_id": "..."}` |
| `loop_iter` | Max 在 Kyle 审查-修复循环中 | `{"iteration": N, "result": "..."}` |
| `lint_fail` | 5 个 lint 脚本失败路径 | `{"rule": "...", "file": "...", "message": "..."}` |
| `red_flag` | Max 在检测到 red-flags 信号时 | `{"flag_id": N, "severity": "high\|medium"}` |

### 组件设计

#### 1. `scripts/harness/log-event.sh`（新增）

**职责**：唯一事件写入入口。封装时间戳生成、workflow_id 读取、JSONL 字符转义。

**签名**：
```bash
log-event.sh <event_type> [--stage S] [--actor A] [--duration-ms D] [--payload k=v,k=v,...]
```

**行为**：
1. 若 `--stage` 未传 → 从 `.dev-agents/shared/.workflow-state` 读 `stage=`
2. 若 `--actor` 未传 → 默认 `harness`
3. 自动生成 `ts`（`date -u +%Y-%m-%dT%H:%M:%S%z`）
4. 自动读取 `workflow_id`（= `.workflow-state` 的 `task=`，空则 `idle`）
5. 拼接 JSON：手动引号转义，目标 Windows Git Bash 纯 bash
6. 追加写入 `.dev-agents/shared/logs/events-$(date +%Y-%m-%d).jsonl`
7. 写入失败**不报错**（避免打断 lint / workflow 主流程）—— 观测层不得影响主链路

**最小骨架伪代码**：
```bash
#!/bin/bash
EVENT_TYPE="$1"; shift
# 解析参数...
mkdir -p .dev-agents/shared/logs
LOG_FILE=".dev-agents/shared/logs/events-$(date +%Y-%m-%d).jsonl"
TS=$(date +%Y-%m-%dT%H:%M:%S%z)
WORKFLOW_ID=$(grep '^task=' .dev-agents/shared/.workflow-state 2>/dev/null | cut -d= -f2)
WORKFLOW_ID="${WORKFLOW_ID:-idle}"
STAGE=$(grep '^stage=' .dev-agents/shared/.workflow-state 2>/dev/null | cut -d= -f2)
STAGE="${STAGE:-idle}"
# 拼 JSON...
echo "{\"ts\":\"$TS\",\"workflow_id\":\"$WORKFLOW_ID\",\"stage\":\"$STAGE\",\"event_type\":\"$EVENT_TYPE\",\"actor\":\"$ACTOR\"$DURATION_FIELD,\"payload\":$PAYLOAD_JSON}" >> "$LOG_FILE" 2>/dev/null || true
```

#### 2. `scripts/harness/workflow-state.sh`（修改）

在现有 `advance` / `init` / `reset` / `exempt` 命令执行成功后追加 `log-event.sh` 调用。
`advance` 需要记录**上一阶段的 duration_ms**：基于 `.workflow-state` 中 `started=` 时间戳计算。

#### 3. 5 个 lint 脚本（修改）

在每个 `[FAIL]` 或 `fix "..."` 调用点旁追加：
```bash
bash scripts/harness/log-event.sh lint_fail --actor harness --payload "rule=<RULE_ID>,file=<PATH>"
```

最小侵入：每个脚本约新增 3-8 行（视失败分支数量）。

#### 4. `scripts/harness/logs-query.sh`（新增）

**子命令**：

| 子命令 | 功能 | 实现思路 |
|-------|------|---------|
| `--stats [workflow_id]` | 阶段耗时汇总 | grep `event_type":"stage_exit"` + workflow_id 过滤 + 按 stage 累加 duration_ms |
| `--hotspots [--days N]` | 失败 top 10 | 汇总 lint_fail/red_flag 事件，按 `rule`/`flag_id` 分组计数 |
| `--export [--days N] [--out PATH]` | 导出 CSV | 遍历近 N 天 `events-*.jsonl`，提取字段拼 CSV |

纯 bash + grep + sed 实现，解析 JSON 字段用正则提取（因 schema 固定可行）：
```bash
grep -o '"duration_ms":[0-9]*' | cut -d: -f2
```

### `.gitignore` 规则（追加）

```gitignore
# Harness 运行时日志（个人工作状态，不入库）
.dev-agents/shared/logs/events-*.jsonl
.dev-agents/shared/memory/activeContext.md

# 但保留 schema 说明和项目资产
!.dev-agents/shared/logs/README.md
```

（projectContext.md / systemPatterns.md 不出现在 .gitignore 意味着默认追踪。）

## 数据流图

```
用户操作
  │
  ├── workflow-state.sh advance ──→ log-event.sh stage_enter/stage_exit ──→ events-YYYY-MM-DD.jsonl
  │                              └→ 输出 [REMIND] 提示
  │
  ├── Max 派遣子代理 ──→ log-event.sh dispatch ──→ events-*.jsonl
  │
  ├── Max 发现 red-flag ──→ log-event.sh red_flag ──→ events-*.jsonl
  │
  ├── Kyle 循环迭代 ──→ log-event.sh loop_iter ──→ events-*.jsonl
  │
  └── lint-*.sh 运行
         └── 失败路径 ──→ log-event.sh lint_fail ──→ events-*.jsonl

查询链路：
  logs-query.sh --stats ─→ grep events-*.jsonl ─→ 聚合输出
```

## 技术栈

- **语言**：纯 bash（target: Git Bash for Windows + POSIX sh 兼容）
- **依赖**：`date`, `grep`, `sed`, `cut`, `wc`, `mkdir` — 全部 coreutils 内置
- **格式**：Markdown（记忆）+ JSONL（日志）
- **版本控制**：git（对 projectContext/systemPatterns 追踪）

## 错误处理策略

| 场景 | 处理 |
|------|------|
| `log-event.sh` 写入失败（磁盘满、权限问题） | 静默 `|| true`，不中断主流程 |
| `.workflow-state` 不存在 | `log-event.sh` 使用默认 `workflow_id=idle, stage=idle` |
| 记忆文件缺失 | CLAUDE.md 启动协议步骤 1 读取失败时提示用户运行初始化 |
| JSON 字符串中含特殊字符 | `log-event.sh` 内部做最小转义（`"` → `\"`，`\n` → `\\n`） |
| logs-query.sh 没找到事件 | 输出 `[INFO] 无匹配事件`，退出码 0 |

## 测试策略

| 层级 | 测试内容 | 方法 |
|------|---------|------|
| 单元 | `log-event.sh` 各参数组合 | Kyle 写 bash test 脚本，断言 JSONL 字段 |
| 单元 | `logs-query.sh --stats` 聚合逻辑 | 构造 mock events-*.jsonl，断言输出 |
| 集成 | workflow-state.sh advance 是否正确埋点 | 跑完整 advance 链路，grep 日志 |
| 集成 | 5 个 lint 脚本插桩后退出码不变 | 故意触发 lint 失败，验证 JSONL 有事件 |
| 端到端 | 记忆加载 + 日志采集闭环 | 本工作流的 finishing 冒烟测试作为验证 |

## 接口清单

### 面向 Max（Agent 使用）

| 场景 | 调用 |
|------|------|
| 启动会话 | 读取 `.dev-agents/shared/memory/activeContext.md` |
| 派遣子代理前 | `bash scripts/harness/log-event.sh dispatch --actor max --payload "target=jarvis,task_id=XXX"` |
| 检测 red-flag | `bash scripts/harness/log-event.sh red_flag --actor max --payload "flag_id=3,severity=high"` |
| Kyle 审查后 | `bash scripts/harness/log-event.sh loop_iter --actor max --payload "iteration=2,result=NEEDS_FIX"` |
| 排查重复错误 | `bash scripts/harness/logs-query.sh --hotspots --days 30` |

### 面向用户（CLI）

| 命令 | 作用 |
|------|------|
| `bash scripts/harness/logs-query.sh --stats` | 看当前工作流阶段耗时 |
| `bash scripts/harness/logs-query.sh --hotspots` | 看近 30 天失败热点 |
| `bash scripts/harness/logs-query.sh --export --out report.csv` | 导出分析报表 |

## 实施顺序依赖

```
A 迁移（无依赖）
   │
   └→ B-1 创建 memory/ 目录 + 3 模板
          │
          └→ B-2 CLAUDE.md 加入启动协议
   │
   └→ C-1 创建 logs/ 目录 + log-event.sh
          │
          ├→ C-2 workflow-state.sh 埋点
          ├→ C-3 5 个 lint 脚本插桩
          └→ C-4 logs-query.sh 实现
```

A 与 B/C 之间无强依赖（可并行）；B 与 C 同样可并行。但考虑 Jarvis 按任务顺序执行且不并行实施（workflow-pipeline 规定），实施时按 A → B → C 串行。

## 设计自检

- [x] 无"待定"/"TODO"占位符
- [x] 所有 19+1 条 FR 均有对应设计
- [x] 无内部矛盾（零依赖约束 ↔ 纯 bash 实现 ↔ .gitignore 规则一致）
- [x] 技术可行性已核实（jq 不可用 → 纯 bash；workflow-state.sh 现有结构可扩展）
- [x] 2 种方案对比 + 推荐理由
- [x] 提供最小实现骨架代码作为 Jarvis 入口

## 开放问题

无。所有决策已锁定，可进入 planning 阶段。

## 下一步

待用户确认设计 → advance 到 **planning（任务拆解）**。
