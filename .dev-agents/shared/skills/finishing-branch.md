---
name: finishing-branch
owner: Max
description: 所有任务完成且测试通过后使用 - 引导分支收尾的结构化选项：合并、PR、保留或丢弃
---

# 分支收尾

Max 主导的开发分支收尾流程。

## 触发条件

- 所有计划任务完成
- Kyle 验收全部通过
- 测试全部绿色

## 流程

### 步骤 1: 验证测试

**提供选项之前，必须验证测试通过：**

```bash
# 运行项目测试套件
npm test / cargo test / pytest / go test ./...
```

**测试失败 → 停止。** 不继续到步骤 2。

### 步骤 2: 确定基础分支

```bash
git merge-base HEAD main 2>/dev/null || git merge-base HEAD master 2>/dev/null
```

### 步骤 3: 提供选项

恰好提供这 4 个选项：

```
实施完成。你希望怎么处理？

1. 本地合并到 <base-branch>
2. 推送并创建 Pull Request
3. 保持分支现状（稍后处理）
4. 丢弃这次工作

选择哪个？
```

### 步骤 4: 执行选择

#### 选项 1: 本地合并

```bash
git checkout <base-branch>
git pull
git merge <feature-branch>
# 验证合并结果的测试
<test command>
git branch -d <feature-branch>
```

#### 选项 2: 推送并创建 PR

```bash
git push -u origin <feature-branch>
gh pr create --title "<标题>" --body "## 摘要
- <变更要点>

## 测试计划
- [ ] <验证步骤>"
```

#### 选项 3: 保持现状

报告分支位置，不做清理。

#### 选项 4: 丢弃

**必须确认：**
```
这将永久删除：
- 分支 <name>
- 所有提交: <commit-list>

输入 'discard' 确认。
```

等待明确确认后才执行。

### 步骤 5: 清理工作树

- 选项 1、4：清理工作树
- 选项 2：保留工作树（PR 可能需要修改）
- 选项 3：保留工作树

## 禁止事项

- 测试未通过就提供选项
- 合并前不验证合并结果的测试
- 不确认就删除工作
- 未经明确请求就 force-push
