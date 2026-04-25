/**
 * init 命令 — 完整初始化，交互式选择 skill 模块和目标 harness
 *
 * Phase 4 起不再按三角色选择，改为按 manifest 中的 skill 模块选择。
 */

import { confirm, multiSelect } from '../utils/prompts.mjs'
import {
  scaffold,
  writeConfig,
  readConfig,
  isInitialized,
  getSkillModules,
  getDefaultSkillModuleIds,
  getAgentModules,
  getDefaultAgentModuleIds,
  listAvailableAgents,
} from '../utils/scaffold.mjs'
import * as log from '../utils/logger.mjs'

export async function init(ctx) {
  const { PKG_ROOT, PROJECT_ROOT, hasFlag } = ctx
  const skipPrompt = hasFlag('yes')

  log.banner()
  log.step('初始化 aiGroup 框架（双端：Claude Code + Codex）')
  log.dim(`目标目录: ${PROJECT_ROOT}`)

  // ── 1. 检查是否已初始化 ──
  if (isInitialized(PROJECT_ROOT)) {
    const existingConfig = readConfig(PROJECT_ROOT)
    log.warn('检测到项目已初始化 aiGroup 框架')

    if (existingConfig) {
      log.dim(`已安装模块: ${existingConfig.modules?.join(', ') || existingConfig.agents?.join(', ') || '未知'}`)
      log.dim(`已启用 harness: ${existingConfig.targets?.join(', ') || '未知'}`)
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

  // ── 2. 选择 harness ──
  let selectedTargets
  if (skipPrompt) {
    selectedTargets = ['claude', 'codex']
    log.info('使用默认配置：Claude Code + Codex 双端')
  } else {
    selectedTargets = await multiSelect('选择要启用的 AI harness', [
      { name: 'Claude Code', value: 'claude', description: '原生 subagent 派遣 + hooks 自动化', checked: true },
      { name: 'Codex CLI', value: 'codex', description: '3 Codex 原生 persona + skill 加载', checked: true },
    ])

    if (selectedTargets.length === 0) {
      log.warn('至少需要选择一个 harness，已自动选择 Claude Code')
      selectedTargets = ['claude']
    }
  }

  // ── 3. 选择 skill 模块 ──
  const allSkillModules = getSkillModules(PKG_ROOT)
  let selectedModules

  if (skipPrompt) {
    selectedModules = getDefaultSkillModuleIds(PKG_ROOT)
    log.info(`使用默认 skill 模块：${selectedModules.join(', ')}`)
  } else {
    const choices = allSkillModules.map(mod => ({
      name: `${mod.id} — ${mod.description}`,
      value: mod.id,
      description: `路径数: ${mod.paths.length} · 成本: ${mod.cost || 'n/a'}`,
      checked: mod.defaultInstall === true,
    }))

    selectedModules = await multiSelect('选择要安装的 skill 模块', choices)

    if (selectedModules.length === 0) {
      log.warn('至少需要选择一个模块，已自动选择默认集')
      selectedModules = getDefaultSkillModuleIds(PKG_ROOT)
    }
  }

  // ── 3b. 选择 agent 模块（仅 Claude target 启用时） ──
  let selectedAgentModules = []
  if (selectedTargets.includes('claude')) {
    const allAgentModules = getAgentModules(PKG_ROOT)
    const totalAgents = listAvailableAgents(PKG_ROOT).length

    if (skipPrompt) {
      selectedAgentModules = getDefaultAgentModuleIds(PKG_ROOT)
      log.info(`使用默认 agent 模块：${selectedAgentModules.join(', ')}`)
    } else {
      log.info(`agent 源池共 ${totalAgents} 个，按模块分组按需选`)
      const agentChoices = allAgentModules.map(mod => ({
        name: `${mod.id} — ${mod.description}`,
        value: mod.id,
        description: `agent 数: ${mod.agents.length} · 稳定性: ${mod.stability || 'stable'}`,
        checked: mod.defaultInstall === true,
      }))

      selectedAgentModules = await multiSelect('选择要安装的 agent 模块', agentChoices)

      if (selectedAgentModules.length === 0) {
        log.warn('未选 agent，将至少安装 agents-core')
        selectedAgentModules = ['agents-core']
      }
    }
  }

  // ── 4. 确认安装 ──
  log.step('安装清单')
  log.dim('基础组件（必装）:')
  log.dim('  • CLAUDE.md + AGENTS.md（双端入口）')
  log.dim('  • docs/（rules/agents（ECC 派遣）+ rules/<lang>（13 语言）+ workflow-pipeline + red-flags）')
  log.dim('  • scripts/hooks/（dispatcher + checks）+ scripts/orchestration/（session.cjs）')
  log.dim('  • manifests/install-modules.json（跨端清单）')
  log.dim('  • .orchestration/<session>/（产物工作区）')
  log.dim('')
  log.dim('启用的 harness:')
  for (const t of selectedTargets) {
    const label = t === 'claude'
      ? 'Claude Code（commands + hooks + 已选 agent 模块）'
      : 'Codex CLI（3 persona + config.toml + plugin）'
    log.dim(`  • ${label}`)
  }
  log.dim('')
  if (selectedAgentModules.length > 0) {
    const allAgentModules = getAgentModules(PKG_ROOT)
    log.dim('Agent 模块:')
    for (const modId of selectedAgentModules) {
      const mod = allAgentModules.find(m => m.id === modId)
      if (mod) log.dim(`  • ${modId}（${mod.agents.length} 个 agent）— ${mod.description}`)
    }
    log.dim('')
  }
  log.dim('Skill 模块:')
  for (const modId of selectedModules) {
    const mod = allSkillModules.find(m => m.id === modId)
    if (mod) log.dim(`  • ${modId}（${mod.paths.length} 个 skill）— ${mod.description}`)
  }

  if (!skipPrompt) {
    const proceed = await confirm('确认安装？', true)
    if (!proceed) {
      log.info('已取消')
      return
    }
  }

  // ── 5. 执行安装 ──
  log.step('正在安装...')

  const result = scaffold(PKG_ROOT, PROJECT_ROOT, {
    modules: selectedModules,
    agentModules: selectedAgentModules,
    targets: selectedTargets,
    overwrite: skipPrompt || isInitialized(PROJECT_ROOT),
  })

  for (const section of result.sections) {
    if (section.count > 0) {
      log.success(`${section.name}（${section.count} 个文件）`)
    } else {
      log.dim(`  ${section.name}（已存在，跳过）`)
    }
  }

  // ── 6. 写入配置 ──
  writeConfig(PROJECT_ROOT, {
    version: '2.0.0',
    targets: selectedTargets,
    modules: selectedModules,
    agentModules: selectedAgentModules,
    installedAt: new Date().toISOString().split('T')[0],
    updatedAt: new Date().toISOString().split('T')[0],
  })
  log.success('配置已保存到 .aigroup.json')

  // ── 7. 运行健康检查 ──
  log.step('运行 Harness 健康检查...')

  try {
    const { execSync } = await import('node:child_process')
    execSync('node scripts/hooks/dispatcher.cjs stop', {
      cwd: PROJECT_ROOT,
      encoding: 'utf-8',
      input: '{}',
      timeout: 30000,
    })
    log.success('Harness 健康检查通过')
  } catch (err) {
    if (err.stderr) console.error(err.stderr.toString())
    log.warn('Harness 检查发现问题，请根据 [FIX] 指令修复')
    log.dim('手动运行: node scripts/hooks/dispatcher.cjs stop')
  }

  // ── 8. 完成 ──
  console.log('')
  log.step('安装完成！')
  console.log(`
    ${result.totalCopied} 个文件已安装到项目中。

    下一步:
    1. 阅读 ${selectedTargets.includes('claude') ? 'CLAUDE.md' : 'AGENTS.md'} 了解入口
    2. 开始一个任务 session:
       node scripts/orchestration/session.cjs init <任务名>
       或在 Claude Code 中用 /workflow-start <任务名>
    3. 定期运行健康检查:
       aigroup check

    Phase 心智模型（按需裁剪）:
    需求收集 → 需求验证 → 方案设计 → 任务拆解
    → 实施开发 → 测试验证 → 文档更新 → 分支收尾

    派遣规则主源: docs/rules/agents.md
    Phase 裁剪示例: docs/workflow-pipeline.md
    危险信号: docs/red-flags.md
    Codex 端差异: .codex/AGENTS.md
  `)
}
