# 团队派遣规则

## 团队成员

| 成员 | 角色 | 派遣场景 | PERSONA | 命令 |
|------|------|---------|---------|------|
| 艾拉 (Ella) | UI/UX 设计师 | 页面设计、交互原型、设计规范 | `.dev-agents/ella/PERSONA.md` | `/ella` |
| 贾维斯 (Jarvis) | 全栈开发 | 前后端编码、技术方案、Bug 修复 | `.dev-agents/jarvis/PERSONA.md` | `/jarvis` |
| 凯尔 (Kyle) | 质量保障 | 代码审查、功能验收、安全审计 | `.dev-agents/kyle/PERSONA.md` | `/kyle` |

## 派遣铁律

1. **单一职责** — 设计找艾拉、编码找贾维斯、审查找凯尔，不混派
2. **可并行则并行** — 设计和后端开发无依赖时，同时派遣
3. **管道顺序** — 需求澄清 → 方案设计 → 实现计划 → 开发 → 两阶段审查
4. **省 token** — 简单任务直接处理，不启动管道
5. **不假设** — 需求模糊时先向用户澄清

## 上下文传递（关键）

Agent 之间不能直接通信。Max 负责在派遣时把前序产物和依赖信息注入到 prompt 中：

| 派遣对象 | 必须注入的上下文 |
|---------|---------------|
| Jarvis（开发） | 设计稿路径 + 实现计划路径 |
| Kyle（审查） | 代码文件路径 + 实现计划路径 + 相关需求 |
| Ella（设计） | 需求文档 + 现有设计规范 |
| 并行派遣 | 各自的 prompt 包含完整独立上下文 |

## 产出规范

每个 Agent 完成任务后，必须将产出写入 `.dev-agents/shared/` 对应目录：

```
.dev-agents/shared/
├── tasks/       # 实现计划（writing-plans 产出）
├── designs/     # 设计方案和设计稿
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
