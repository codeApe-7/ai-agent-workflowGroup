# Security

## Mandatory Security Checklist（提交前必过）

- [ ] **无硬编码密钥**（API keys、密码、token、连接串）
- [ ] **所有用户输入已校验**
- [ ] **SQL 注入防护**（参数化查询）
- [ ] **XSS 防护**（HTML 已 sanitize）
- [ ] **CSRF 保护已启用**
- [ ] **认证 / 授权已验证**
- [ ] **限流已就位**（公开端点）
- [ ] **错误消息不泄露**敏感数据（堆栈、内部路径、SQL 片段）

## Secret Management

- **绝不**硬编码密钥到源码
- **始终**使用环境变量或 secret manager
- 启动时校验所需密钥存在
- 一旦怀疑泄漏，**立即轮换**所有相关密钥

## Auth / Authz 必须独立审查

涉及以下场景的代码**必须**派遣 `security-reviewer`（Codex 用 `reviewer` + security skill）：

- 登录 / 注册 / 密码重置
- 权限变更、角色升级
- 支付、退款、积分增减
- PII（个人身份信息）读写
- 外部输入边界（API、上传、导入）
- 加密 / 哈希 / 签名使用

## OWASP Top 10 检查维度

审查时按以下维度过一遍（不是每条都要报，但要都想过）：

1. **A01 Broken Access Control** — 水平/垂直越权、IDOR
2. **A02 Cryptographic Failures** — 弱算法、弱密钥、`===` 比较密码（用 `timingSafeEqual`）
3. **A03 Injection** — SQL / NoSQL / 命令 / LDAP / XPath / 模板注入
4. **A04 Insecure Design** — 缺乏威胁建模
5. **A05 Security Misconfiguration** — 默认凭据、不必要权限、CORS 过松
6. **A06 Vulnerable Components** — `npm audit` / `pip-audit` / `bundle audit`
7. **A07 Auth Failures** — 弱密码策略、会话固定、token 泄漏
8. **A08 Software and Data Integrity Failures** — 不安全的反序列化、CI/CD 注入
9. **A09 Logging and Monitoring Failures** — 日志脱敏、异常告警
10. **A10 SSRF** — 外部 URL 校验

## Security Response Protocol

发现安全问题时：

1. **立即停止**进一步开发
2. 派遣 `security-reviewer`（Codex 用 `reviewer` + security skill）做深度审计
3. **先修 CRITICAL**，再继续其他工作
4. **轮换**任何已暴露的密钥
5. **全仓搜索**类似问题（同样的反模式可能存在多处）

## 派遣建议

| 信号 | Agent |
|------|-------|
| 新增 auth 流程 | `security-reviewer` |
| 改动支付 / 订单 / 积分 | `security-reviewer` |
| 加密 / 签名 / token 处理 | `security-reviewer` |
| 依赖升级（含 transitive） | `code-reviewer`（兼跑 `npm audit`） |
| 已知 CVE 修复 | `build-error-resolver`（限定最小修复） |

## Verdict 级别

`security-reviewer` 的输出必须给出明确级别：

- **APPROVE** — 无 CRITICAL / HIGH，中低可带 follow-up ticket
- **REQUEST_CHANGES** — HIGH 必须先修
- **BLOCK** — CRITICAL 必须先修，不得合并
