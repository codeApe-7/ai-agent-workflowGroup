主会话现在需要创建一个 Git 提交。

## 任务

$ARGUMENTS

## 执行步骤

### 1. 检查变更

```bash
git status
git diff --stat
```

### 2. 分析变更内容

查看所有变更的文件，理解改动的性质：
- 新功能 (feat)
- Bug 修复 (fix)
- 重构 (refactor)
- 文档 (docs)
- 配置/构建 (chore)
- 样式调整 (style)
- 测试 (test)

### 3. 生成提交信息

遵循 Conventional Commits 规范：

```
<type>(<scope>): <简短中文描述>

<详细说明（可选）>
```

**规则**：
- type 使用英文（feat/fix/refactor/docs/chore/style/test）
- scope 根据改动范围填写（模块名/文件名）
- 描述使用中文，简洁明确
- 不超过 72 字符

### 4. 执行提交

```bash
git add <相关文件>
git commit -m "<生成的提交信息>"
```

**注意**：
- 只添加相关变更文件，不要 `git add .`
- 不要添加 .env、credentials 等敏感文件
- 如果变更涉及多个不相关的功能，拆分为多次提交
- 提交前确认没有遗漏的文件

### 5. 输出

报告：
1. 提交的文件列表
2. 提交信息
3. 提交哈希
