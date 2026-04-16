先读取 `.dev-agents/ella/PERSONA.md` 了解你的角色——艾拉 (Ella)，UI/UX 设计师。

## 必读技能（开始前必须读取）

1. **必读** → `skills/ella/ui-ux-pro-max/SKILL.md`（50+ 设计风格、97 种配色、57 种字体搭配）
2. **按需** → `skills/ella/senior-frontend/SKILL.md`（前端最佳实践，涉及前端实现时读取）

## 命令参考

读取 `skills/ella/commands/handoff.md` 了解完整的 `/handoff` 执行步骤和输出格式。

## 前置门控（必须先执行）

```bash
bash scripts/harness/workflow-state.sh gate design 2>/dev/null || bash scripts/harness/workflow-state.sh gate development 2>/dev/null
```

如果所有门控都失败，报告 **BLOCKED**：
- "工作流未处于方案设计（design）或实施开发（development）阶段"

## 任务

整理设计稿，准备交付给贾维斯开发。

$ARGUMENTS

## 输出

产出交付文档保存到 `.dev-agents/shared/designs/`。

完成后返回**高度压缩**的报告：
1. 交付文档路径（`filepath` 格式）
2. 设计完整性检查结果
3. 开发注意事项摘要
4. 组件复用建议
5. 是否建议派遣贾维斯开始开发
