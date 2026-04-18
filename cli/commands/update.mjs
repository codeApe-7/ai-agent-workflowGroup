/**
 * update 命令 — 增量更新技能和传感器，不覆盖用户自定义
 */

import { scaffoldUpdate, readConfig, writeConfig, isInitialized } from '../utils/scaffold.mjs'
import { confirm } from '../utils/prompts.mjs'
import * as log from '../utils/logger.mjs'

export async function update(ctx) {
  const { PKG_ROOT, PROJECT_ROOT, hasFlag } = ctx
  const skipPrompt = hasFlag('yes')

  log.banner()
  log.step('增量更新')

  // 检查是否已初始化
  if (!isInitialized(PROJECT_ROOT)) {
    log.error('项目尚未初始化 aiGroup 框架')
    log.info('请先运行: aigroup init')
    return
  }

  const config = readConfig(PROJECT_ROOT)
  if (config) {
    log.dim(`已安装角色: ${config.agents?.join(', ')}`)
    log.dim(`上次更新: ${config.updatedAt || config.installedAt || '未知'}`)
  }

  // 说明更新范围
  log.step('更新范围')
  log.dim('将覆盖更新:')
  log.dim('  • scripts/harness/*（传感器脚本）')
  log.dim('  • skills/max/workflow/*（工作流技能）')
  log.dim('  • .claude/commands/*（通用命令）')
  log.dim('  • .claude/agents/*（原生子代理定义）')
  log.dim('')
  log.dim('不会触碰:')
  log.dim('  • CLAUDE.md（项目入口）')
  log.dim('  • docs/*（知识库文档）')
  log.dim('  • .dev-agents/shared/*（工作产物）')

  if (!skipPrompt) {
    const proceed = await confirm('确认更新？', true)
    if (!proceed) {
      log.info('已取消')
      return
    }
  }

  // 执行更新
  log.step('正在更新...')

  const result = scaffoldUpdate(PKG_ROOT, PROJECT_ROOT)

  for (const section of result.sections) {
    if (section.count > 0) {
      log.success(`${section.name}（${section.count} 个文件更新）`)
    }
  }

  // 更新配置时间戳
  if (config) {
    config.updatedAt = new Date().toISOString().split('T')[0]
    writeConfig(PROJECT_ROOT, config)
  }

  log.success(`更新完成，共 ${result.totalCopied} 个文件`)
  log.info('运行 aigroup check 验证更新')
}
