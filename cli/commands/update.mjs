/**
 * update 命令 — 增量更新 skill 模块、适配层和传感器，不覆盖用户自定义
 */

import { scaffoldUpdate, readConfig, writeConfig, isInitialized } from '../utils/scaffold.mjs'
import { confirm } from '../utils/prompts.mjs'
import * as log from '../utils/logger.mjs'

export async function update(ctx) {
  const { PKG_ROOT, PROJECT_ROOT, hasFlag } = ctx
  const skipPrompt = hasFlag('yes')

  log.banner()
  log.step('增量更新')

  if (!isInitialized(PROJECT_ROOT)) {
    log.error('项目尚未初始化 aiGroup 框架')
    log.info('请先运行: aigroup init')
    return
  }

  const config = readConfig(PROJECT_ROOT)
  if (config) {
    const modules = config.modules || config.agents /* 兼容旧配置 */ || []
    const targets = config.targets || ['claude']
    log.dim(`已启用 harness: ${targets.join(', ')}`)
    log.dim(`已安装模块: ${modules.join(', ') || '无'}`)
    log.dim(`上次更新: ${config.updatedAt || config.installedAt || '未知'}`)
  }

  log.step('更新范围')
  log.dim('将覆盖更新:')
  log.dim('  • scripts/harness/*（传感器脚本）')
  log.dim('  • 已启用 harness 的适配层（.claude/ 或 .codex/）')
  log.dim('  • 已选模块下的 skill 目录')
  log.dim('  • docs/（主源文档）+ manifests/')
  log.dim('')
  log.dim('不会触碰:')
  log.dim('  • .orchestration/<session>/*（工作产物）')
  log.dim('  • .aigroup.json（配置文件仅更新时间戳）')

  if (!skipPrompt) {
    const proceed = await confirm('确认更新？', true)
    if (!proceed) {
      log.info('已取消')
      return
    }
  }

  log.step('正在更新...')

  const result = scaffoldUpdate(PKG_ROOT, PROJECT_ROOT)

  for (const section of result.sections) {
    if (section.count > 0) {
      log.success(`${section.name}（${section.count} 个文件更新）`)
    }
  }

  if (config) {
    config.updatedAt = new Date().toISOString().split('T')[0]
    writeConfig(PROJECT_ROOT, config)
  }

  log.success(`更新完成，共 ${result.totalCopied} 个文件`)
  log.info('运行 aigroup check 验证更新')
}
