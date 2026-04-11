---
name: workflow-lifecycle
owner: Max
description: 每次会话开始时自动应用 - 定义完整的工作流生命周期和技能调用纪律
---

# 工作流生命周期

定义 aiGroup 团队的标准工作流程。Max 在每次会话开始时检查此技能，确保团队遵循正确的流程。

## 技能调用纪律

> **规则：在执行任何动作或回复之前，先检查是否有适用的技能。**
>
> 即使只有 1% 的可能某个技能适用，也必须先查看。如果技能适用，则必须遵循。

### 危险信号

这些想法意味着你在合理化跳过技能：

| 想法 | 现实 |
|------|------|
| "这只是个简单问题" | 问题也是任务。检查技能。 |
| "我需要先了解更多上下文" | 技能检查在澄清问题之前。 |
| "让我先看看代码" | 技能告诉你怎么看。先检查。 |
| "这不需要正式流程" | 如果技能存在，就使用它。 |
| "技能太重了" | 简单的事情会变复杂。用它。 |
| "我知道那是什么意思" | 知道概念 ≠ 使用技能。调用它。 |

## 标准工作流

```
用户提需求
    ↓
Max: 需求澄清门禁（AGENTS.md）
    ↓ 需求清晰
Max: brainstorming 技能（方案设计）
    ↓ 设计确认
Max: writing-plans 技能（实施计划）
    ↓ 计划确认
Max → Jarvis: 逐任务派发（codex-subtask 模板）
    Jarvis: tdd 技能（开发实施）
    Jarvis: verification 技能（完成验证）
    ↓ 任务完成
Max → Kyle: 审查派发
    Kyle: code-review-dispatch 技能（两阶段审查）
    ↓ 审查通过
Max: finishing-branch 技能（分支收尾）
    ↓
完成
```

## 技能优先级

当多个技能可能适用时：

1. **流程技能优先**（brainstorming、systematic-debugging）— 决定如何处理任务
2. **实施技能其次**（tdd、code-review-dispatch）— 指导具体执行

"构建 X" → 先 brainstorming，再 tdd
"修复 Bug" → 先 systematic-debugging，再 tdd

## 技能类型

**刚性技能**（TDD、调试）：严格遵循，不得偏离纪律。

**柔性技能**（brainstorming）：将原则适配到具体上下文。

技能本身会说明它是哪种类型。

## 双层技能架构

### 第一层：工作流技能（强制遵循）

位于 `.dev-agents/shared/skills/`，定义过程纪律，所有角色必须遵循。

| 技能 | 所有者 | 路径 | 触发场景 |
|------|--------|------|----------|
| brainstorming | Max | `skills/brainstorming.md` | 新功能、新项目 |
| writing-plans | Max | `skills/writing-plans.md` | 设计确认后 |
| tdd | Jarvis | `skills/tdd.md` | 写代码前 |
| systematic-debugging | Jarvis | `skills/systematic-debugging.md` | Bug、测试失败 |
| verification | 全员 | `skills/verification.md` | 声称完成前 |
| code-review-dispatch | Kyle | `skills/code-review-dispatch.md` | 任务完成后 |
| finishing-branch | Max | `skills/finishing-branch.md` | 所有任务完成后 |

### 第二层：领域技能（按需激活）

位于项目根目录 `skills/`，按角色分组，提供专业知识和工具。

| 角色 | 技能包 | 路径前缀 | 核心能力 |
|------|--------|----------|----------|
| Max | CCPM | `skills/max/ccpm/` | 项目管理、子代理编排 |
| Max | PM Skills | `skills/max/pm-claude-skills/` | PRD、竞品分析、会议纪要 |
| Ella | UI/UX Pro Max | `skills/ella/ui-ux-pro-max/` | 50+ 设计风格、97 色板、9 技术栈 |
| Ella | Senior Frontend | `skills/ella/senior-frontend/` | 前端实现模式 |
| Jarvis | Engineering Team | `skills/jarvis/engineering-team/` | 15+ 工程技能（全栈/后端/前端/安全/DevOps） |
| Jarvis | Claude Simone | `skills/jarvis/claude-simone/` | 工程化工作流 |
| Kyle | Senior QA | `skills/kyle/senior-qa/` | React/Next.js 测试自动化 |
| Kyle | TDD Guide | `skills/kyle/tdd-guide/` | 多框架 TDD 工作流 |

**调用规则：**
1. 工作流技能优先于领域技能
2. 领域技能在工作流技能框架内按需激活
3. 读取领域技能的 SKILL.md 后按其指引执行
4. 各角色的可用领域技能详见其 PERSONA.md

## Harness Engineering 集成

### Computational Sensors

所有角色在执行任务时，必须在关键节点运行 `.harness/` 中的自动化检查：

| 节点 | 检查命令 | 说明 |
|------|---------|------|
| 提交前 | `bash .harness/run-all.sh` | 全量 Harness 检查 |
| 任务完成时 | `bash .harness/linters/check-write-scope.sh` | 确认未越权 |
| 文档修改后 | `bash .harness/linters/check-doc-freshness.sh` | 确认引用完整 |

### Steering Loop

Agent 犯错时的标准响应流程：

1. 记录到 `.cursor/rules/harness-log.mdc`
2. 判断能否机械化 → 是则新增 `.harness/` 中的 Linter 或结构测试
3. 验证新规则能阻止同类问题
4. 更新 `.harness/quality/QUALITY_SCORE.md` 对应评分

### Garbage Collection（熵治理）

定期（建议每周或每个 Sprint 结束时）执行：

```bash
bash .harness/garbage-collection/drift-scanner.sh
```

扫描内容：
- 超大文档（>500 行 Markdown）→ 拆分
- 已完成但未归档的任务文件 → 归档到 `tasks/archived/`
- 孤立的设计文档 → 关联任务或归档
- AGENTS.md 膨胀（>200 行）→ 下沉详细规则
- 技能文件与实际执行的偏差 → 修正

扫描结果用于更新 `QUALITY_SCORE.md` 并生成修复任务。

## 简单请求豁免

以下情况 Max 可以直接回答，不强制走完整流程：

- 纯信息查询（"这个函数是做什么的？"）
- 单行修改（"把这个变量名改一下"）
- 配置问题（"怎么配置 X？"）

但如果"简单"请求变得复杂，立即切入对应技能。
