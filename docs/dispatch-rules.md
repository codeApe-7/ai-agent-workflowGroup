# 团队派遣规则

## 核心原则：Agent 工具派遣 ≠ 角色切换

```
❌ 角色切换（禁止）：
   Max 在当前对话里读 PERSONA.md 然后"变成" Jarvis 写代码
   → 这只是同一个 Claude 在角色扮演，没有上下文隔离

✅ Agent 工具派遣（正确）：
   Max 调用 Agent 工具 → 创建独立子代理 → 子代理隔离执行
   → 子代理返回结果 → Max 继续协调
```

**Max 自己绝不写项目代码、做 UI 设计或做测试验收。所有这些工作必须通过 Agent 工具委派。**

## 团队成员

| 成员 | 角色 | PERSONA | 派遣场景 |
|------|------|---------|---------|
| 艾拉 (Ella) | UI/UX 设计师 | `.dev-agents/ella/PERSONA.md` | 页面设计、交互原型、设计规范 |
| 贾维斯 (Jarvis) | 全栈开发 | `.dev-agents/jarvis/PERSONA.md` | 前后端编码、技术方案、Bug 修复 |
| 凯尔 (Kyle) | 质量保障 | `.dev-agents/kyle/PERSONA.md` | 代码审查、测试验证、安全审计 |

## 派遣方式

### Max 主动派遣（正规流程）

Max 在工作流管道中驱动时，使用 **Agent 工具** 派遣子代理：

```
Agent({
  description: "[角色]: [任务简述]",
  prompt: "
先读取 `.dev-agents/[角色]/PERSONA.md` 了解你的角色。

[前置门控检查]
[任务全文]
[上下文信息]
[完成标准]
  "
})
```

### 用户直接派遣（快捷命令）

用户可以直接使用 `/jarvis`、`/ella`、`/kyle` 命令。这些命令会将任务注入当前对话。

**注意**：`/jarvis` 等快捷命令是用户手动使用的。Max 在工作流中派遣时，必须使用 Agent 工具，不是 `/jarvis` 命令。

## 派遣铁律

1. **Agent 工具派遣** — Max 必须通过 Agent 工具创建隔离子代理
2. **单一职责** — 设计找艾拉、编码找贾维斯、审查找凯尔，不混派
3. **可并行则并行** — 独立任务的 Agent 调用可以并行发起
4. **管道顺序** — 需求收集 → 需求验证 → 方案设计 → 任务拆解 → 开发 → 测试验证 → 文档更新
5. **省 token** — 简单任务直接处理（exempt），不启动管道
6. **不假设** — 需求模糊时先向用户澄清

## 上下文传递（关键）

Agent 之间不能直接通信。Max 负责在 Agent 工具的 prompt 中注入前序产物和依赖信息：

| 派遣对象 | prompt 必须注入的内容 |
|---------|---------------------|
| Jarvis（开发） | PERSONA 路径 + 门控检查 + 任务全文 + 设计文档路径 + 实现计划路径 |
| Kyle（审查） | PERSONA 路径 + 门控检查 + 审查规格 + 代码文件路径 + 实现计划路径 |
| Ella（设计） | PERSONA 路径 + 需求文档 + 现有设计规范 |

## 产出规范

每个子代理完成任务后，必须将产出写入 `.dev-agents/shared/` 对应目录：

```
.dev-agents/shared/
├── tasks/       # 实现计划（writing-plans 产出）
├── designs/     # 设计方案和需求文档
├── reviews/     # 审查报告（Kyle 产出）
└── templates/   # 文档模板
```

## 技能资源

| 成员 | 技能目录 | 包含内容 |
|------|---------|---------|
| Max | `skills/max/` | CCPM 项目管理、PM 技能集、工作流技能 |
| Ella | `skills/ella/` | UI/UX Pro Max 设计工具、前端参考 |
| Jarvis | `skills/jarvis/` | Claude Simone 框架、工程团队技能集 |
| Kyle | `skills/kyle/` | 高级 QA 技能包、TDD 指南 |
