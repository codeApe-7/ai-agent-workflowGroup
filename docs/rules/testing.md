# Testing Requirements

## Minimum Coverage: 80%

测试类型（**全部必需**）：

1. **单元测试** — 单个函数、工具、组件
2. **集成测试** — API 端点、数据库操作
3. **E2E 测试** — 关键用户流程（按语言/栈选择框架）

## TDD 工作流（强制）

```
1. 先写测试（RED）— 测试应当失败
2. 跑测试 — 确认 FAIL
3. 写最小实现（GREEN）— 测试通过
4. 跑测试 — 确认 PASS
5. 重构（IMPROVE）— 不破坏行为
6. 验证覆盖率（≥ 80%）
```

## Agent 支持

- **新功能 / bug 修复** → 派遣 `tdd-guide` 走 TDD 流程
- **测试失败诊断** → `tdd-guide` 默认改实现不改测试
- **E2E** → 独立派 `e2e-runner`（待补，Phase 2+）

## 失败排查顺序

1. 检查测试隔离（每个测试是否独立可跑）
2. 验证 mock 是否正确
3. 修实现，**不修测试**（除非测试本身的断言错误，且必须在报告中明说）

## Test Structure (AAA Pattern)

优先使用 Arrange-Act-Assert：

```typescript
test('计算余弦相似度', () => {
  // Arrange
  const v1 = [1, 0, 0]
  const v2 = [0, 1, 0]

  // Act
  const sim = cosineSimilarity(v1, v2)

  // Assert
  expect(sim).toBe(0)
})
```

## Test Naming

用描述行为的中文/英文，不要堆栈技术词：

```typescript
test('查询无匹配市场时返回空数组', () => {})
test('API key 缺失时抛出错误', () => {})
test('Redis 不可用时降级到子串搜索', () => {})
```

## 完成前必跑

- [ ] 所有相关测试通过
- [ ] 覆盖率达标（项目目标，通常 80%+）
- [ ] 行为变更同步更新或新增测试
- [ ] 没有跳过的测试（`.skip` / `xit` / `pending`）—— 跳过等于隐藏 bug

## 反模式

| 反模式 | 为什么错 |
|--------|---------|
| 用 `@ts-ignore` / `as any` 掩盖测试失败 | 隐藏类型问题 |
| 测试断言改成"通过"了事 | 抛弃了测试本身的价值 |
| `expect(true).toBe(true)` 占位测试 | 浪费维护成本 |
| 单个测试覆盖 5 个不相关行为 | 失败时定位困难 |
| 测试有顺序依赖（test A 必须在 test B 前跑） | 隔离失败，CI 必爆 |
