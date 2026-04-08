# 结构化文档模板

将原始文档转化为 AI 友好的结构化格式，减少 token 消耗，加速理解。

## 核心原则

1. **去冗余** — 删除套话、重复内容、无效信息
2. **结构化** — 用固定格式组织，便于解析
3. **符号化** — 用符号代替长描述（如 ✅❌⚠️）
4. **图转文** — 图片转为关键信息描述
5. **层级化** — 重要信息前置，细节后置

## 文档模板

| 模板 | 用途 | 文件 |
|------|------|------|
| PRD | 产品需求文档 | `prd.md` |
| UI | 界面设计说明 | `ui.md` |
| API | 接口文档 | `api.md` |
| BUG | Bug 报告 | `bug.md` |
| MEETING | 会议纪要 | `meeting.md` |
| GENERIC | 通用文档 | `generic.md` |
| AI-PROJECT | AI 项目方案 | `ai-project.md` |
| AI-PROJECT-FINAL | AI 项目终稿 | `ai-project-final.md` |

## 子代理提示模板

| 模板 | 用途 | 使用者 |
|------|------|--------|
| CODEX-SUBTASK | Codex 子任务派发表 | Max → 任意角色 |
| IMPLEMENTER | Jarvis 实现子代理提示 | Max → Jarvis |
| SPEC-REVIEWER | Kyle 规格合规审查提示 | Max → Kyle |
| CODE-QUALITY-REVIEWER | Kyle 代码质量审查提示 | Max → Kyle |

## 使用方式

1. 选择对应模板
2. 按模板格式填写/转换内容
3. 交给对应的 Codex 子代理处理

## Token 节省预估

| 文档类型 | 原始 | 结构化后 | 节省 |
|---------|------|---------|------|
| PRD | ~3000 | ~800 | 73% |
| UI 说明 | ~2000 | ~500 | 75% |
| 会议纪要 | ~1500 | ~400 | 73% |
