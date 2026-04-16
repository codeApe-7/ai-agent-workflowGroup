先读取 `.dev-agents/ella/PERSONA.md` 了解你的角色——艾拉 (Ella)，UI/UX 设计师。

## 必读技能（开始前必须读取）

1. **必读** → `skills/ella/ui-ux-pro-max/SKILL.md`（50+ 设计风格、97 种配色、57 种字体搭配）
2. **按需** → `skills/ella/senior-frontend/SKILL.md`（前端最佳实践，涉及前端实现时读取）

## 命令参考

读取 `skills/ella/commands/design.md` 了解完整的 `/design` 执行步骤和输出格式。

## 前置门控（必须先执行）

```bash
bash scripts/harness/workflow-state.sh gate brainstorming 2>/dev/null || bash scripts/harness/workflow-state.sh gate design 2>/dev/null || bash scripts/harness/workflow-state.sh gate development 2>/dev/null
```

如果所有门控都失败，报告 **BLOCKED**：
- "工作流未处于需求收集（brainstorming）、方案设计（design）或实施开发（development）阶段"

## 任务

根据 PRD 需求或功能描述设计用户界面。

$ARGUMENTS

## 输出

产出设计稿保存到 `.dev-agents/shared/designs/`，文件名格式：`YYYY-MM-DD-<功能名>-design.md`

完成后返回**高度压缩**的报告：
1. 设计稿路径（`filepath` 格式）
2. 主要设计决策摘要（3-5 条要点）
3. 关键视觉规范（色彩、字体、间距等核心值）
4. 是否建议派遣贾维斯进行开发
5. 实现注意事项（如有）
