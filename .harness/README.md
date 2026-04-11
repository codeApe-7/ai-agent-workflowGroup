# Harness Engineering Layer

**Agent = Model + Harness**

本目录包含 aiGroup 的 Computational Sensors 层 — 通过确定性工具机械化强制执行架构约束，
而非依赖 Agent "自觉遵守文档"。

## 核心原则

> When documentation falls short, we promote the rule into code.
> — OpenAI Harness Engineering

- **Feedforward（前馈引导）** = Agent 行动前的约束 → `AGENTS.md`、技能文件、模板
- **Feedback（反馈传感）** = Agent 行动后的检测 → 本目录的 Linter、结构测试、Hook
- **Computational** 优先于 **Inferential** — 能用代码检查的，不靠提示词

## 目录结构

```
.harness/
├── README.md                     # 本文件
├── run-all.sh                    # 一键执行所有检查
├── linters/                      # 自定义 Linter 规则
│   ├── check-write-scope.sh      # 验证子代理是否越权写入
│   ├── check-task-format.sh      # 验证任务文档格式规范
│   └── check-doc-freshness.sh    # 检查文档交叉引用完整性
├── structural-tests/             # 架构结构测试
│   ├── test-skill-integrity.sh   # 验证技能索引与文件的一致性
│   ├── test-persona-refs.sh      # 验证角色引用完整性
│   └── test-template-schema.sh   # 验证模板格式规范
├── hooks/                        # Git hooks
│   └── pre-commit.sh             # 提交前自动检查
├── quality/                      # 质量追踪
│   └── QUALITY_SCORE.md          # 模块质量评分
└── garbage-collection/           # 熵治理
    └── drift-scanner.sh          # 定期漂移扫描
```

## 使用方式

```bash
# 执行所有 Harness 检查
bash .harness/run-all.sh

# 单独执行某项检查
bash .harness/linters/check-task-format.sh
bash .harness/structural-tests/test-skill-integrity.sh

# 安装 Git pre-commit hook
bash .harness/hooks/install.sh
```

## Steering Loop

当 Agent 犯错时：

1. 记录到 `.cursor/rules/harness-log.mdc`
2. 判断能否机械化 →
   - **是** → 在本目录新增 Linter 或结构测试
   - **否** → 更新技能文件或 `AGENTS.md`（Inferential Guide）
3. 验证新规则能阻止同类问题复发
