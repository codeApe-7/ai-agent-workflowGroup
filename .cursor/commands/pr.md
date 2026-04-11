为当前变更创建 Pull Request。

1. 运行 `git status` 和 `git diff` 查看所有变更
2. 根据变更内容撰写清晰的中文 commit message（格式：`<type>: <描述>`）
3. 将相关文件添加到暂存区并提交
4. 推送到当前分支（如果是新分支，使用 `git push -u origin HEAD`）
5. 使用 `gh pr create` 创建 PR，标题和描述基于变更内容
6. 返回 PR 链接

注意事项：
- 提交前必须确认用户已授权
- commit message 使用项目约定格式：feat / fix / refactor / docs / style / test / chore / ci
- 不要 force push
- 不要修改 git config
