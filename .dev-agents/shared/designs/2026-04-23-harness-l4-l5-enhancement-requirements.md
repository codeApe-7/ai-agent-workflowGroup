# Harness L4/L5 层补强需求文档

**工作流 ID**：harness-l4-l5-enhancement
**创建日期**：2026-04-23
**状态**：待用户确认

## 背景与目的

### 问题陈述
项目对照 Harness Engineering 六层架构评估后发现三项薄弱：
1. **结构层面**：`.dev-agents/shared/templates/`（静态模板）与 `designs/tasks/reviews`（运行时产物）混放，违反"分类存储"原则（图片第 4 层管理原则）
2. **L4 记忆与状态层**：仅有任务状态 `.workflow-state`，缺少图片定义的"长期记忆与用户偏好"——跨会话失忆
3. **L5 评估与观测层**：只有 5 个静态 lint，缺少图片定义的"日志与指标监控、错误归因分析"——无法驱动 steering-loop 形成数据闭环

### 为什么要做
- 单人长期开发场景下，每次会话从零开始读完 10+ 个文档效率低
- red-flags 第 8 条"同一类错误反复出现"当前只能靠 Max 人工回忆，无数据支撑
- steering-loop 机制缺少观测数据作为转向信号输入

### 不做什么（延后到 P2 独立工作流）
- D：失败恢复策略（重试/回滚）
- E：环境化验证（真实操作验证）
- F：Context Reset 机制

## 用户场景

| 角色 | 场景 | 期望 |
|------|------|------|
| 开发者（Max 使用者） | 本周开工续接上周未完的任务 | 启动时 Max 自动加载 activeContext，说出"上次做到 X，下一步 Y" |
| 开发者 | 某次 Kyle 审查发现了反复出现的问题 | Max 能从日志识别热点，建议写入 systemPatterns 并更新 coding-standards |
| 开发者 | 想知道"哪个阶段最耗时" | 查询 JSONL 日志即可得出阶段耗时分布 |
| Max（Agent） | 进入新阶段前 | 自动加载相关记忆文件作为上下文 |
| Max（Agent） | 检测到同类错误第 3 次发生 | 触发 steering-loop，将规则编码到 red-flags 或 skills |

## 功能需求

### A 项：templates 目录迁移

- [ ] **FR-A1**：将 `.dev-agents/shared/templates/` 整体迁移到 `docs/templates/`（git mv 保留历史）
- [ ] **FR-A2**：更新以下 4 个文件中的 6 处引用（validation 阶段已全量识别）：
  - `cli/utils/scaffold.mjs:31` — 脚手架目录列表
  - `scripts/harness/lint-structure.sh:54` — 结构检查路径
  - `scripts/harness/lint-delegation.sh:34` — 注释说明
  - `scripts/harness/lint-workflow-artifacts.sh:41,105,108` — fix 指引（3 处）
- [ ] **FR-A3**：同步更新 `docs/ARCHITECTURE.md` 第 22-26 行目录结构图
- [ ] **FR-A4**：保证 `.dev-agents/shared/` 只保留动态产物（designs/tasks/reviews + 新增的 memory/ logs/）

### B 项：长期记忆（Cline memory-bank 核心三件套）

- [ ] **FR-B1**：新增目录 `.dev-agents/shared/memory/` 存放记忆文件
- [ ] **FR-B2**：三个记忆文件及其职责：
  - `projectContext.md` — 项目级记忆（产品愿景、架构决策、技术栈、关键约束）
  - `activeContext.md` — 会话级记忆（当前焦点、未完成任务、最近阻塞、下一步）
  - `systemPatterns.md` — 模式级记忆（代码模式、常用重构手法、已沉淀的团队约定）
- [ ] **FR-B3**：每个记忆文件包含 frontmatter：`last_updated`、`updated_by`（哪个阶段更新）、`version`
- [ ] **FR-B4**：Max 启动机制：CLAUDE.md 中增加"会话启动时必读 `.dev-agents/shared/memory/activeContext.md`"规则
- [ ] **FR-B5**：写入机制——记忆更新由对应阶段触发：
  - `projectContext.md`：solution-design 阶段 advance 时，`workflow-state.sh` 输出提示 "请更新 projectContext.md 记录本次架构决策"
  - `activeContext.md`：每次 `workflow-state.sh advance` 命令尾部追加提示 "请更新 activeContext.md 反映当前阶段"（提示机制 = 标准输出文案，非 hook）
  - `systemPatterns.md`：Kyle 审查通过 advance 到 documentation 时，提示 Max 检视是否有新模式入库
- [ ] **FR-B6**：记忆模板（空白骨架）由 Jarvis 在 development 阶段作为首个任务创建，含示例字段与填写指引

### C 项：运行时观测（JSONL 被动式日志）

- [ ] **FR-C1**：新增目录 `.dev-agents/shared/logs/` 存放 JSONL 日志
- [ ] **FR-C2**：日志文件按日滚动：`events-YYYY-MM-DD.jsonl`
- [ ] **FR-C3**：事件 schema（每行一个 JSON 对象）：
  ```json
  {
    "ts": "ISO-8601 时间戳",
    "workflow_id": "状态机任务名",
    "stage": "brainstorming|validation|...|finishing",
    "event_type": "stage_enter|stage_exit|dispatch|red_flag|lint_fail|loop_iter|workflow_complete",
    "actor": "max|jarvis|ella|kyle|harness",
    "duration_ms": "数字（可选）",
    "payload": { "自由字段": "..." }
  }
  ```
- [ ] **FR-C4**：四类指标的采集埋点（责任人明确）：
  - **阶段耗时**：`workflow-state.sh advance/exempt/reset` 内部调用 `log-event.sh`，写 `stage_exit` 事件（含 duration_ms）
  - **循环次数**：Max 在派遣 Kyle 循环前后调用 `log-event.sh loop_iter --payload iteration=N`（CLAUDE.md 明文指引）
  - **失败热点**：5 个 lint 脚本失败路径插桩调用 `log-event.sh lint_fail --payload rule=<ID>`；red-flag 触发由 Max 调用 `log-event.sh red_flag`
  - **工作流生命周期**：`workflow-state.sh init/reset/exempt` 内部写 `workflow_start/reset/exempt` 事件；advance 到 finishing 时写 `workflow_complete`
- [ ] **FR-C5**：提供查询脚本 `scripts/harness/logs-query.sh`，支持：
  - `--stats [workflow_id]`：汇总指定工作流的阶段耗时、循环次数（默认当前 workflow_id）
  - `--hotspots [--days N]`：列出 top 10 失败热点，默认近 30 天，`--days` 可配置
  - `--export [--days N] [--out PATH]`：导出 CSV
  - 实现语言：**纯 bash + grep + sed**，不依赖 jq（本环境无 jq）
- [ ] **FR-C6**：CLAUDE.md 中增加"怀疑存在反复错误时，运行 `logs-query.sh --hotspots`"指引
- [ ] **FR-C7**：`.gitignore` 明确规则：
  - 忽略 `.dev-agents/shared/logs/events-*.jsonl`
  - 忽略 `.dev-agents/shared/memory/activeContext.md`（个人工作状态）
  - 追踪 `.dev-agents/shared/memory/projectContext.md` 和 `systemPatterns.md`（项目资产）
  - 追踪 `.dev-agents/shared/logs/README.md`（schema 说明）
- [ ] **FR-C8**（新增）：提供 `scripts/harness/log-event.sh` 单一事件写入工具：
  - 签名：`log-event.sh <event_type> [--stage S] [--actor A] [--duration D] [--payload k=v,k=v]`
  - 自动从 `.workflow-state` 读取 workflow_id 和 stage（若未指定）
  - 自动生成 ISO-8601 时间戳
  - 纯 bash 实现，输出到当日 `events-YYYY-MM-DD.jsonl`

## 约束条件

### 技术约束
- **零外部依赖**：不引入新 npm/pip 包。本环境 jq 不可用（已验证），统一使用 **纯 bash + grep + sed + date** 实现
- **跨平台**：Windows Git Bash 可运行，避免 awk 复杂脚本和 GNU 扩展
- **向后兼容**：现有 5 个 lint 脚本的检测逻辑不变，仅新增 `log-event.sh` 调用（失败不影响 lint 退出码）
- **JSONL 手写**：单行 JSON 手动拼接（`log-event.sh` 内部做字符转义），不依赖 jq

### 流程约束
- 必须走完整 8 阶段工作流（brainstorming → finishing）
- B 和 C 的实施由 Jarvis 派遣完成
- 完成后运行 `scripts/harness/run-all.sh` 自检通过

### 范围约束
- 记忆文件读取由 Max 在 CLAUDE.md 规则层驱动，不引入 MCP/vector DB 等基础设施
- 观测仅做"采集 + 查询"，不做仪表盘/告警/可视化

## 非功能需求

- **可读性**：记忆文件和日志必须人类可读（Markdown + JSONL，非二进制）
- **可审计**：任何记忆变更有 `last_updated` 时间戳
- **可回溯**：JSONL 日志包含 workflow_id，可追溯每次工作流全过程
- **可演进**：schema 保留 `payload` 自由字段，后续扩展不破坏旧日志

## 范围排除（本次不做）

- ❌ 向量化 / 语义检索（未来 P2）
- ❌ 告警推送（未来 P2）
- ❌ 多用户 / 团队级共享记忆（场景不匹配）
- ❌ 实时仪表盘（选了方案 P）
- ❌ 自动压缩 / Context Reset（未来 P2）
- ❌ 记忆冲突合并机制（单人场景无并发写）

## 成功标准

### A 项验收
- [ ] `.dev-agents/shared/templates/` 目录消失，`docs/templates/` 存在并包含所有 10 个模板文件
- [ ] 全仓 grep 无 `dev-agents/shared/templates` 残留引用
- [ ] `run-all.sh` 全部通过

### B 项验收
- [ ] `.dev-agents/shared/memory/` 含 3 个初始化好的记忆文件（均含 frontmatter）
- [ ] CLAUDE.md 明确记载启动加载规则（validation 追加"会话启动必读 activeContext.md"）
- [ ] 本工作流自身在 design/development/testing 阶段分别更新 projectContext/activeContext/systemPatterns
- [ ] **冒烟测试**：在本工作流 finishing 前，Max 重新读取 activeContext.md 并能准确复述：(a) 当前 workflow_id (b) 上一阶段产出 (c) 下一步动作

### C 项验收
- [ ] 完整跑一次 workflow（init → finishing），`events-YYYY-MM-DD.jsonl` 至少记录 10+ 条事件
- [ ] 每类事件（stage_enter/stage_exit/dispatch/lint_fail/red_flag/loop_iter/workflow_*）至少有 1 条样本
- [ ] `logs-query.sh --stats` 能输出阶段耗时汇总
- [ ] `logs-query.sh --hotspots` 能输出 lint 失败 top N

### 整体验收
- [ ] `scripts/harness/run-all.sh` 全绿
- [ ] `docs/ARCHITECTURE.md` 六层架构章节更新（显式标注 L4/L5 实现位置）
- [ ] `docs/workflow-pipeline.md` 各阶段"产出位置"含记忆/日志更新指引
- [ ] 本工作流自身完整走完 8 阶段，自动生成的 JSONL 日志作为"自验证"证据

## 开放问题（请用户审阅时确认）

1. **OP-1**：记忆文件是否纳入 git？
   - 建议：`projectContext.md` 和 `systemPatterns.md` 纳入（项目知识资产）；`activeContext.md` 不纳入（个人工作状态，频繁变更）。请确认。

2. **OP-2**：是否在本工作流中顺便用新记忆/日志系统记录本次工作流的产出？
   - 建议：是（既验证又沉淀）。

3. **OP-3**：C 项的 lint_fail 事件采集点需要改 5 个 lint 脚本插入 echo 写日志——是否接受对 lint 脚本做最小侵入式修改？
   - 建议：接受，封装成 `harness/log-event.sh` 单一工具函数，lint 脚本调用即可。

---

## 需求验证结论

**验证日期**：2026-04-23
**验证人**：Max
**验证结论**：✅ **通过**（修正后）

### 六维验证结果

| 维度 | 结果 | 说明 |
|------|------|------|
| 完整性 | ✅ | A/B/C 三项 19 条 FR 覆盖全部用户场景；异常与开放问题已显式标记 |
| 可行性 | ✅ | 技术栈已核实：jq 不可用，降级为纯 bash 方案；Git Bash 兼容性无阻塞 |
| 无歧义性 | ✅ | "自动提示"机制、循环事件采集责任、查询时间范围、记忆模板创建者均已明确 |
| 一致性 | ✅ | 零外部依赖约束与纯 bash 方案一致；git 追踪策略与 .gitignore 规则对齐 |
| 可验证性 | ✅ | 冒烟测试步骤已具体化；每项 FR 均有对应成功标准 |
| 优先级 | ✅ | A (P0) → B (P1) → C (P1) 清晰 |

### 验证过程发现的问题与修正

| # | 发现问题 | 修正 |
|---|---------|------|
| 1 | FR-A2 "所有引用路径"模糊 | 全仓 grep 实证，明确为 4 文件 6 处 |
| 2 | FR-B5 "自动提示"机制不清 | 改为 `workflow-state.sh` 标准输出文案，非 hook |
| 3 | FR-B6 模板创建者未定 | 指定 Jarvis 在 development 首任务创建 |
| 4 | FR-C4 循环事件采集责任未定 | 明确为 Max 派遣 Kyle 循环前后主动调用 |
| 5 | FR-C5 "近 30 天"硬编码 | 改为 `--days N` 参数，默认 30 |
| 6 | jq 可行性未核实 | 本地环境 jq 不存在，全面改纯 bash 方案 |
| 7 | 新增 FR-C8 `log-event.sh` 工具 | 统一事件写入入口，避免重复代码 |
| 8 | FR-C7 gitignore 规则未细化 | 明确 4 条精确规则（日志忽略/activeContext 忽略/其余追踪） |
| 9 | B 项冒烟测试过于模糊 | 明确 3 项可验证事实（workflow_id/上阶段产出/下一步） |
| 10 | FR-A3 扩展到 ARCHITECTURE.md 目录图 | 之前仅提 lint-structure.sh |

### 遗留开放问题

无阻塞性开放问题。OP-1/2/3 均已采纳建议，并入 FR 条款。

### 下一步

✅ 需求验证通过，允许 advance 到 **design（方案设计）** 阶段。

