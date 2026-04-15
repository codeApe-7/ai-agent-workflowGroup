/**
 * menu 命令 — 交互式主菜单（类似 zcf 风格）
 */

import { select } from '../utils/prompts.mjs'
import * as log from '../utils/logger.mjs'
import { isInitialized, readConfig } from '../utils/scaffold.mjs'

export async function showMenu(ctx) {
  log.banner()

  // 检测项目状态
  const initialized = isInitialized(ctx.PROJECT_ROOT)
  if (initialized) {
    const config = readConfig(ctx.PROJECT_ROOT)
    if (config) {
      log.dim(`已初始化 · 角色: ${config.agents?.join(', ') || '未知'} · 版本: ${config.version || '?'}`)
    }
  } else {
    log.dim('当前项目尚未初始化 aiGroup 框架')
  }

  // 主菜单循环
  while (true) {
    const action = await select('选择操作', [
      { name: '初始化项目', value: 'init', description: '交互式选择角色和技能，安装框架文件' },
      { name: '增量更新', value: 'update', description: '更新技能和传感器，保留自定义配置' },
      { name: '健康检查', value: 'check', description: '运行 Harness 传感器全量检查' },
      { name: '工作流状态', value: 'status', description: '查看当前工作流管道状态' },
      { name: '退出', value: 'quit', description: '' },
    ])

    if (action === 'quit') {
      console.log('')
      break
    }

    console.log('')

    switch (action) {
      case 'init': {
        const { init } = await import('./init.mjs')
        await init(ctx)
        break
      }
      case 'update': {
        const { update } = await import('./update.mjs')
        await update(ctx)
        break
      }
      case 'check': {
        const { check } = await import('./check.mjs')
        await check(ctx)
        break
      }
      case 'status': {
        const { status } = await import('./status.mjs')
        await status(ctx)
        break
      }
    }

    console.log('')
  }
}
