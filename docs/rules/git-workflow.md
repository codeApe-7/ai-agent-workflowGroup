# Git Workflow

## Git 安全（绝不自动）

- **禁止自动** `git commit` / `push` / `merge`，必须等用户明确授权
- `git add` / `git status` / `git diff` 可以直接执行（只读或安全）
- **禁止破坏性操作**：force push、`git reset --hard`、`git checkout --`、删分支等，除非用户明确要求
- 提交署名只用仓库主人，**不出现** `Co-Authored-By` 行

## Commit Message Format

```
<type>: <中文描述>

<可选正文>
```

可用 type：

| type | 用途 |
|------|------|
| feat | 新功能 |
| fix | Bug 修复 |
| refactor | 重构（不影响功能） |
| docs | 文档变更 |
| style | 格式调整（不影响逻辑） |
| test | 测试相关 |
| chore | 构建 / 依赖 / 工具调整 |
| ci | CI/CD 配置 |
| perf | 性能优化 |

**规则**：
- type 用英文
- 描述用中文，72 字符以内
- 一个 commit 只做一件事，不混合无关变更

## Pull Request Workflow

创建 PR 时：

1. 分析**全部 commit history**（不只是最新 commit）
2. 用 `git diff <base-branch>...HEAD` 看完整变更
3. 起草综合性 PR summary
4. 包含 test plan checklist
5. 新分支首次推送加 `-u` flag

## 提交前自检（pre-commit checklist）

- [ ] 已运行 `node scripts/hooks/dispatcher.cjs stop`
- [ ] 无敏感文件（`.env` / `credentials*` / `secrets*`）
- [ ] 无 `console.log` / `print` 调试残留
- [ ] 改动符合 Conventional Commits 格式
- [ ] 仅添加相关文件（`git add <file>`，不用 `git add .`）
