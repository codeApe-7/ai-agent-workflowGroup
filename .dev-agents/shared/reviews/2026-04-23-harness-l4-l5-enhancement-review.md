# Harness L4/L5 补强审查报告

**审查日期**：2026-04-23
**审查人**：Kyle
**审查范围**：9 个 commits（293039d → 19aacfa），A/B/C 三项改造

---

## 冒烟验证结果（任务 12.1-12.5）

### 12.1 run-all.sh

- **退出码**：0
- **结果**：✅ 全部通过（5 个传感器全绿，累计错误数 0）
- **允许的 warn**：1 条（设计文档含 TODO/待定语气，lint-process.sh 已存在的告警，非本次范围）

### 12.2 单元测试

| 测试 | 结果 |
|------|------|
| `test-log-event.sh` | 12 通过 / 0 失败 |
| `test-logs-query.sh` | 9 通过 / 0 失败 |

两个单元测试均按期望全通过。

### 12.3 B 项冒烟（记忆文件可读性）

3 个记忆文件均存在、均含完整 frontmatter（`last_updated` / `updated_by` / `version`），`activeContext.md` 附加 `workflow_id` 字段。

**重启会话复述验证**：读取 `activeContext.md` 可准确复述：
- workflow_id：`harness-l4-l5-enhancement`
- 上次做到哪：需求/设计/计划已归档（路径齐全）
- 下一步动作：派遣 Jarvis 按 12 任务执行

### 12.4 C 项冒烟（查询工具）

**`--stats`**：输出 `development 1437000 ms (× 1)`、Kyle 循环 0 次。

**`--hotspots --days 7`**：输出"无匹配事件"（本工作流未触发 lint 失败，符合预期）。

**日志文件统计**：
- 文件：`events-2026-04-24.jsonl`（注：本日期 UTC+8 已跨过 0 点）
- 行数：2 条（stage_exit × 1 + stage_enter × 1）
- workflow_start：0 条
- stage_exit：1 条
- stage_enter：1 条

**观察**：期望"至少 1 条 workflow_start、5+ advance 的 stage_exit/enter"与现实不符。根因：`log-event.sh`（commit 293039d）和 `workflow-state.sh` 集成（commit 2182539）发生时间为 2026-04-24 00:00 附近，早于本次测试但**晚于本工作流前序 advance（brainstorming→validation→design→planning→development）**——前序 advance 在集成前发生，未被记录。这是**时序特性**不是功能缺陷，工具本身工作正常（单元测试已覆盖）。

### 12.5 A 项验证

- `[OK-A1]`：`.dev-agents/shared/templates` 已消失
- `[OK-A2]`：`docs/templates/prd.md` 存在（全部 11 个 .md 文件 git mv 保留历史）
- 引用计数：0（全仓无 `dev-agents/shared/templates` 残留）

**冒烟总结**：5/5 通过，可进入 Stage 1。

---

## Stage 1：规格符合性审查

### A 项覆盖（FR-A1~A4）

| FR | 覆盖状态 | 证据 |
|----|---------|------|
| FR-A1 迁移 templates 保留历史 | ✅ 通过 | 旧目录消失；docs/templates 存在 11 个 .md；git rename 历史验证 |
| FR-A2 更新 6 处引用 | ✅ 通过 | `cli/utils/scaffold.mjs:31` / `lint-structure.sh:58` / `lint-delegation.sh:38,49` / `lint-workflow-artifacts.sh:45,109,112,127` 全部更新；grep 无旧引用残留 |
| FR-A3 ARCHITECTURE.md 目录图更新 | ✅ 通过 | 第 24-30 行含 memory/ + logs/；docs/ 段第 15 行含 templates/ |
| FR-A4 shared/ 只剩动态产物 | ✅ 通过 | 实际包含 designs/ logs/ memory/ reviews/ tasks/，均为运行时产物 |

### B 项覆盖（FR-B1~B6）

| FR | 覆盖状态 | 证据 |
|----|---------|------|
| FR-B1 memory 目录存在 | ✅ 通过 | `.dev-agents/shared/memory/` 存在 |
| FR-B2 3 个记忆文件 | ✅ 通过 | projectContext.md (43行) / activeContext.md (35行) / systemPatterns.md (30行) |
| FR-B3 frontmatter 字段 | ✅ 通过 | 3 个文件均含 `last_updated` / `updated_by` / `version`；activeContext 附加 `workflow_id` |
| FR-B4 CLAUDE.md 启动协议 | ✅ 通过 | CLAUDE.md:5-10 包含 "会话启动协议"，要求读 activeContext.md 和 .workflow-state |
| FR-B5 workflow-state.sh [REMIND] 输出 | ✅ 通过 | workflow-state.sh 第 180/289/296/300 行 4 处 [REMIND] 提示：init/design→planning/documentation/任意 advance |
| FR-B6 模板由 Jarvis 首任务创建 | ✅ 通过 | 3 个文件 `updated_by: initial-bootstrap` 一致；含示例字段与填写指引 |

### C 项覆盖（FR-C1~C8）

| FR | 覆盖状态 | 证据 |
|----|---------|------|
| FR-C1 logs 目录 | ✅ 通过 | `.dev-agents/shared/logs/` 存在，含 README.md + 运行时 jsonl |
| FR-C2 按日滚动 | ✅ 通过 | 命名 `events-YYYY-MM-DD.jsonl`；log-event.sh 第 112 行按 `date +%Y-%m-%d` 生成 |
| FR-C3 事件 schema | ⚠️ WARN | schema 字段顺序在 log-event.sh/README/实际日志中一致（ts/workflow_id/stage/event_type/actor/duration_ms?/payload），但 **payload 字段契约与需求/设计不一致**（见问题 S1-1） |
| FR-C4 四类采集埋点 | ⚠️ WARN | 阶段耗时 ✅、工作流生命周期 ✅、失败热点 ✅（插桩存在）、循环次数埋点⚠️（依赖 Max 主动调用，本工作流未触发） |
| FR-C5 logs-query 3 个子命令 | ❌ **不通过** | `--stats` ✅；`--hotspots` ❌ **字段契约错位**（见问题 S1-1）；`--export` ⚠️ `--days` 参数虚设（见问题 S1-2） |
| FR-C6 CLAUDE.md hotspots 指引 | ✅ 通过 | CLAUDE.md:10 "怀疑反复错误时运行 `bash scripts/harness/logs-query.sh --hotspots`" |
| FR-C7 .gitignore 规则 | ✅ 通过 | 忽略 `events-*.jsonl` 和 `activeContext.md`；追踪 README.md / projectContext / systemPatterns（实测 `git ls-files` 确认） |
| FR-C8 log-event.sh 工具 | ✅ 通过 | 脚本存在、可执行、签名符合规格；单元测试 12/0 通过 |

### Stage 1 发现的问题

#### 问题 S1-1【BLOCK】：`--hotspots` 字段契约不一致，实际 lint_fail 事件无法被统计

**事实链**：

| 来源 | lint_fail payload 字段名 |
|------|-------------------------|
| 需求 FR-C4 | `rule=<ID>` |
| 设计文档事件表 | `{"rule": "...", "file": "...", "message": "..."}` |
| 实施计划任务 8.1 修正 | 改为 `lint=<LINT_NAME>`（避免 `$1` 含逗号破坏 payload） |
| `logs/README.md` schema 表 | `lint`（跟随实施修正） |
| `lint-*.sh` 实际插桩（`lint-structure.sh:18`  等 5 处） | `--payload "lint=structure"`（`lint=docs`/`=workflow-artifacts`/`=delegation`/`=process`） |
| `logs-query.sh:90-91` cmd_hotspots sed 提取 | `rule=...`（未跟随修正） + `flag_id=...` |

**问题**：`logs-query.sh` 提取 `rule` 和 `flag_id` 字段，但生产环境实际生成的 lint_fail 事件 payload 是 `{"lint":"structure"}` 没有 `rule` 字段。`sed -n 's/.*"rule":"..."/...'` 对 `{"lint":"structure"}` 匹配失败，`rule` 为空；`flag_id` 也为空（lint 事件没有此字段）；`key="${rule}${flag}"` 为空字符串被 `[ -n "$key" ]` 过滤。

**后果**：**FR-C5 的核心验收条件**"`logs-query.sh --hotspots` 能输出 lint 失败 top N"**无法兑现**——hotspots 永远对 lint_fail 输出空。

**复现证据**：
```bash
# 构造含插桩格式的 lint_fail 日志
$ cat > events-$(date +%F).jsonl <<EOF
{"ts":"...","event_type":"lint_fail","payload":{"lint":"structure"}}
{"ts":"...","event_type":"lint_fail","payload":{"lint":"structure"}}
{"ts":"...","event_type":"lint_fail","payload":{"lint":"docs"}}
EOF

$ bash scripts/harness/logs-query.sh --hotspots
▸ lint_fail 规则 top 10
# （输出为空）
```

**为什么单元测试没抓出来**：`test-logs-query.sh:22-24` 的 mock 日志用 `"rule":"template-missing"`（旧契约），与实际插桩 `"lint":"structure"`（新契约）不一致。测试构造的 mock 数据不是生产代码生成的格式——测试在自娱自乐。

**根因**：任务 8.1 步骤修正（把 `rule=` 改 `lint=`）时，**未同步修改** `logs-query.sh` 的 sed 提取逻辑和 `test-logs-query.sh` 的 mock 数据。

**修复建议（任选其一）**：
- **方案 A（推荐）**：修改 `logs-query.sh:90`，新增 `lint=$(echo "$line" | sed -n 's/.*"lint":"\([^"]*\)".*/\1/p')`，`key="${rule}${lint}${flag}"`。同时更新 `test-logs-query.sh` mock 数据至少覆盖一条 `"lint":"..."` 事件。
- **方案 B**：统一回归 `rule` 字段命名，修改 5 个 lint 脚本插桩为 `--payload "rule=structure"`（不过 README.md 也要同步改）。

#### 问题 S1-2【WARN】：`--days N` 参数虚设

**事实**：`cmd_hotspots` 和 `cmd_export` 都接受 `--days N`，但函数内部仅用于 `echo "近 $days 天"`，**没有基于日期过滤日志文件**。

**复现证据**：
```bash
$ # 日志里有 2025-01-01 的 old-rule 事件
$ bash logs-query.sh --hotspots --days 1
▸ lint_fail 规则 top 10
  lint_fail:old-rule                       1 次    # 应被过滤掉（已过 >1 天）

$ bash logs-query.sh --hotspots --days 365
  lint_fail:old-rule                       1 次    # 正常
# 结果完全相同
```

**后果**：违反 FR-C5"`--days N` 可配置"的可验证语义。近 1 天和近 1000 天效果一样。

**修复建议**：在遍历 `events-*.jsonl` 时加入日期过滤，比较文件名 `events-YYYY-MM-DD` 的日期与当前日期差值。若希望保持零依赖，可用 `date +%s` 计算阈值时间戳：
```bash
threshold=$(date -d "-${days} days" +%s)
for f in "$LOG_DIR"/events-*.jsonl; do
  file_date=$(basename "$f" .jsonl | sed 's/events-//')
  file_ts=$(date -d "$file_date" +%s 2>/dev/null || continue)
  [ "$file_ts" -lt "$threshold" ] && continue
  # process $f
done
```

### Stage 1 结论

**❌ 不通过**（2 个问题）：
- **S1-1 BLOCK**：`--hotspots` 对 lint_fail 永远返回空，违反 FR-C5 核心成功标准
- **S1-2 WARN**：`--days` 虚设，违反 FR-C5 可配置语义

由于 Stage 1 不通过，按门控铁律，**Stage 2 仍需完整审查并出具清单，但不作为整体通过依据**。

---

## Stage 2：代码质量审查

### 可读性

- ✅ `log-event.sh` 和 `logs-query.sh` 头部注释完整（职责/用法/调用者/设计原则）
- ✅ 命名清晰（`cmd_stats` / `cmd_hotspots` / `cmd_export` / `json_escape` / `compute_stage_duration_ms` / `log_event`）
- ✅ 段落分隔符（`# ── xxx ──`）结构可读
- ⚠️ `logs-query.sh` 中 `cmd_hotspots` 的 `key="${rule}${flag}"` 缺少注释说明为什么拼接（让读者难理解"取哪个字段"）——这也正是 S1-1 bug 的隐身处

### 安全性

- ✅ JSON 字符串转义顺序正确：反斜杠先转（`s//\\/\\\\`），再转双引号（避免二次转义）
- ✅ 换行/制表符转义（`\n` `\t`）避免 JSONL 单行断行
- ✅ `duration_ms` 强校验数字（`grep -qE '^[0-9]+$'`），非数字被拒绝
- ✅ shell 注入风险低：所有变量扩展都在 `"..."` 中；`$files` 扩展作为 grep 参数虽无引号但路径内固定不含空格
- ✅ fail-silent（`2>/dev/null || true`）不会暴露敏感路径到 stderr
- ⚠️ **边界**：payload 中 `V="${pair#*=}"` 保留值中的 `,` 会被上层按 `,` 切分破坏——文档已说明"不支持 V 含逗号"。消费方（比如 lint 插桩传 `msg=$1`）若不知情会触发分隔歧义，幸好任务 8.1 修正为只传 `lint=X` 规避了

### 鲁棒性

- ✅ `log-event.sh` 写入失败不中断（`{ ... } || true`）+ `exit 0` 保底
- ✅ `log_event()` wrapper（workflow-state.sh:106）再套一层 `|| true` 双重保险
- ✅ 5 个 lint 脚本 fail() 插桩使用 `2>/dev/null || true`，不污染 lint 退出码
- ✅ `.workflow-state` 缺失时 fallback 为 `idle`（已单元测试）
- ⚠️ `cmd_hotspots` 的 `--days` 虚设是**功能缺陷而非鲁棒性问题**（S1-2）
- ⚠️ `compute_stage_duration_ms` 依赖 `date -d`（GNU 扩展），Windows Git Bash 实测可用，但 macOS BSD date 不支持。若未来跨平台需留意

### 一致性

- ✅ JSON 字段顺序在 log-event.sh 输出、README schema、单元测试 mock 中完全一致
- ✅ 5 个 lint 脚本的 fail() 插桩格式完全对齐（唯一差异只有 `lint=<name>`）
- ❌ **S1-1 指出的严重不一致**：lint_fail payload 实际字段 `lint` vs hotspots 查询字段 `rule`
- ❌ 单元测试 mock 数据 `"rule":"template-missing"` 与生产代码生成 `"lint":"structure"` 不一致（测试与实现脱节）

### 冗余

- ⚠️ `cmd_stats` 和 `cmd_hotspots` 中的 "logs 目录/空 files 检查"（第 23-33 行 vs 70-80 行）几乎字字相同，可抽取为 `get_log_files()` 辅助函数
- ⚠️ `cmd_export` 每行 6 次 `sed -n` 调用，10000 行日志产生 60000 次 sed 子进程（性能问题，非当前规模问题）。可改为单次 awk 提取多字段

### Stage 2 问题清单

| # | 严重级别 | 文件 | 问题描述 | 修复建议 |
|---|---------|------|---------|---------|
| S2-1 | BLOCK（= S1-1） | `scripts/harness/logs-query.sh:90-91` | cmd_hotspots sed 提取 `rule`/`flag_id`，与实际插桩 `lint=X` 不匹配 | 新增 `lint=$(sed -n 's/.*"lint":"..."/...')`，`key="${rule}${lint}${flag}"`；同步修改 `test-logs-query.sh` mock 数据 |
| S2-2 | BLOCK（= S1-2） | `scripts/harness/logs-query.sh:69,101` | `--days` 参数被接收但未用于过滤日志文件 | 用 `date -d "-N days" +%s` 和 `basename events-DATE.jsonl` 计算文件日期做过滤 |
| S2-3 | WARN | `scripts/harness/tests/test-logs-query.sh:22-25` | mock 日志格式与生产代码插桩不一致，测试无法验证真实集成 | mock 数据应至少包含一条 `"lint":"..."` 事件以匹配实际插桩格式 |
| S2-4 | INFO（冗余） | `scripts/harness/logs-query.sh:28-33, 75-80` | 空 files 检查在两函数中重复 | 抽取 `get_log_files()` 辅助函数 |
| S2-5 | INFO | `scripts/harness/logs-query.sh:119-129` | cmd_export 每行 6 次 sed 性能开销 | 可改单次 awk 提取（非当前规模问题，可延后） |
| S2-6 | INFO | `scripts/harness/logs-query.sh:90-94` | `key="${rule}${flag}"` 拼接逻辑无注释 | 补充注释说明字段来源及优先级 |

### Stage 2 结论

**❌ 不通过**（由 S2-1/S2-2 阻塞）：代码基础质量扎实（边界、安全、JSON 转义、跨工作流容错都经得住敲打），但查询工具存在两个**功能性 bug**，分别破坏了 FR-C5 的核心成功标准和可配置语义。

---

## 总审查结论

**状态：❌ 不通过**

### 问题汇总（按严重级别）

| # | 级别 | 描述 | 影响 FR |
|---|------|------|---------|
| S1-1 / S2-1 | **BLOCK** | `--hotspots` 字段契约错位，对 lint_fail 永远返回空 | FR-C5 核心成功标准 |
| S1-2 / S2-2 | **BLOCK** | `--days` 参数虚设，不参与日志过滤 | FR-C5 可配置语义 |
| S2-3 | WARN | 单元测试 mock 数据与生产代码脱节（伪绿色） | 测试有效性 |
| S2-4 | INFO | logs-query.sh 空 files 检查冗余 | 代码简洁性 |
| S2-5 | INFO | cmd_export sed 性能开销 | 未来可扩展性 |
| S2-6 | INFO | hotspots 拼接逻辑缺注释 | 可维护性 |

### 修复顺序建议（给 Jarvis）

**P0（必须修）**：
1. **S2-1**：修改 `scripts/harness/logs-query.sh` 的 `cmd_hotspots`，新增对 `lint` 字段的 sed 提取，更新 `key` 拼接
2. **S2-2**：为 `cmd_hotspots` 和 `cmd_export` 的 `--days` 实现真实日期过滤（基于 `basename events-DATE.jsonl` + `date -d`）
3. **S2-3**：同步更新 `scripts/harness/tests/test-logs-query.sh`，mock 日志必须至少含一条 `"lint":"<name>"` 格式，且补充 `--days` 过滤的断言

**P1（建议修）**：
4. **S2-4**：抽取 `get_log_files()` 辅助函数，去除 cmd_stats/cmd_hotspots 重复

**P2（可选）**：
5. **S2-5**：sed → awk 性能优化
6. **S2-6**：补注释

### 不在本次修复范围内

以下属于**时序客观约束**而非质量问题，不计入修复：
- 本工作流前序 advance 未被记录（log-event 集成时间晚于前序 advance），由于历史不可改写，下次完整工作流即可验证 10+ 事件

### 派遣契约

修复完成后需要：
1. 重跑 `bash scripts/harness/tests/test-logs-query.sh`（含新增 `--days` 断言 + lint 字段断言）
2. 手动冒烟：构造 lint_fail 事件 + 跑 `--hotspots` 确认能输出；构造"近 365 天"的历史事件 + 跑 `--hotspots --days 1` 确认被过滤
3. 交给 Kyle 二次审查（重走 Stage 1 + Stage 2）

### 验证证据文件

- 本次审查实际运行的命令和输出均已粘贴在"冒烟验证结果"和"Stage 2"章节中
- 核心 bug 复现命令见 S1-1 和 S1-2 的"复现证据"块，可直接在 repo 根目录复现
