/**
 * init 命令 — 完整初始化，交互式选择角色和技能
 */

import { existsSync } from 'node:fs'
import { join } from 'node:path'
import { confirm, multiSelect, input } from '../utils/prompts.mjs'
import { scaffold, writeConfig, readConfig, isInitialized, AGENT_ASSETS } from '../utils/scaffold.mjs'
import * as log from '../utils/logger.mjs'

export async function init(ctx) {
  const { PKG_ROOT, PROJECT_ROOT, hasFlag } = ctx
  const skipPrompt = hasFlag('yes')

  log.banner()
  log.step('初始化 aiGroup 框架')
  log.dim(`目标目录: ${PROJECT_ROOT}`)

  // ── 1. 检查是否已初始化 ──
  if (isInitialized(PROJECT_ROOT)) {
    const existingConfig = readConfig(PROJECT_ROOT)
    log.warn('检测到项目已初始化 aiGroup 框架')

    if (existingConfig) {
      log.dim(`已安装角色: ${existingConfig.agents?.join(', ') || '未知'}`)
      log.dim(`安装时间: ${existingConfig.installedAt || '未知'}`)
    }

    if (!skipPrompt) {
      const overwrite = await confirm('是否覆盖现有配置？', false)
      if (!overwrite) {
        log.info('已取消。如果只想更新技能和传感器，请使用 aigroup update')
        return
      }
    }
  }

  // ── 2. 选择角色 ──
  let selectedAgents

  if (skipPrompt) {
    selectedAgents = ['jarvis', 'ella', 'kyle']
    log.info('使用默认配置：全部角色')
  } else {
    selectedAgents = await multiSelect('选择要安装的团队成员', [
      { name: '贾维斯 (Jarvis)', value: 'jarvis', description: '全栈开发工程师 · 45 Skills', checked: true },
      { name: '艾拉 (Ella)', value: 'ella', description: 'UI/UX 设计师 · 10 Skills', checked: true },
      { name: '凯尔 (Kyle)', value: 'kyle', description: '质量保证工程师 · 7 Skills', checked: true },
    ])

    if (selectedAgents.length === 0) {
      log.warn('至少需要选择一个角色，已自动选择 Jarvis')
      selectedAgents = ['jarvis']
    }
  }

  // ── 3. 确认安装 ──
  log.step('安装清单')
  log.dim('基础组件:')
  log.dim('  • CLAUDE.md（项目入口）')
  log.dim('  • docs/（知识库文档 x8）')
  log.dim('  • scripts/harness/（传感器 x6）')
  log.dim('  • skills/max/workflow/（工作流技能 x11）')
  log.dim('  • .claude/hooks.json（自动化 Hook）')
  log.dim('')
  log.dim('团队成员:')
  for (const agentId of selectedAgents) {
    log.dim(`  • ${AGENT_ASSETS[agentId].label}`)
  }

  if (!skipPrompt) {
    const proceed = await confirm('确认安装？', true)
    if (!proceed) {
      log.info('已取消')
      return
    }
  }

  // ── 4. 执行安装 ──
  log.step('正在安装...')

  const result = scaffold(PKG_ROOT, PROJECT_ROOT, {
    agents: selectedAgents,
    overwrite: skipPrompt || isInitialized(PROJECT_ROOT),
  })

  for (const section of result.sections) {
    if (section.count > 0) {
      log.success(`${section.name}（${section.count} 个文件）`)
    } else {
      log.dim(`  ${section.name}（已存在，跳过）`)
    }
  }

  // ── 5. 写入配置 ──
  writeConfig(PROJECT_ROOT, {
    version: '1.0.0',
    agents: selectedAgents,
    installedAt: new Date().toISOString().split('T')[0],
    updatedAt: new Date().toISOString().split('T')[0],
  })
  log.success('配置已保存到 .aigroup.json')

  // ── 6. 运行健康检查 ──
  log.step('运行 Harness 健康检查...')

  try {
    const { execSync } = await import('node:child_process')
    const output = execSync('bash scripts/harness/run-all.sh', {
      cwd: PROJECT_ROOT,
      encoding: 'utf-8',
      timeout: 30000,
    })

    if (output.includes('全部通过')) {
      log.success('Harness 健康检查通过')
    } else {
      log.warn('Harness 检查发现问题，请查看上方输出')
    }
  } catch (err) {
    log.warn('Harness 检查未能运行（可能缺少 bash 环境）')
    log.dim('手动运行: bash scripts/harness/run-all.sh')
  }

  // ── 7. 完成 ──
  console.log('')
  log.step('安装完成！')
  console.log(`
    ${result.totalCopied} 个文件已安装到项目中。

    下一步:
    1. 阅读 CLAUDE.md 了解框架入口
    2. 使用工作流管道开始开发:
       bash scripts/harness/workflow-state.sh init <任务名>
    3. 定期运行健康检查:
       aigroup check

    工作流管道（8 阶段）:
    需求收集 → 需求验证 → 方案设计 → 任务拆解
    → 实施开发 → 测试验证 → 文档更新 → 分支收尾
  `)
}
