/**
 * check 命令 — 运行 Harness 健康检查
 */

import { existsSync } from 'node:fs'
import { join } from 'node:path'
import { isInitialized } from '../utils/scaffold.mjs'
import * as log from '../utils/logger.mjs'

export async function check(ctx) {
  const { PROJECT_ROOT } = ctx

  log.step('Harness 健康检查')

  if (!isInitialized(PROJECT_ROOT)) {
    log.error('项目尚未初始化 aiGroup 框架')
    log.info('请先运行: aigroup init')
    return
  }

  const dispatcherPath = join(PROJECT_ROOT, 'scripts/hooks/dispatcher.cjs')
  if (!existsSync(dispatcherPath)) {
    log.error('Hook dispatcher 不存在: scripts/hooks/dispatcher.cjs')
    log.info('请运行 aigroup update 重新安装')
    return
  }

  try {
    const { execSync } = await import('node:child_process')
    const output = execSync('node scripts/hooks/dispatcher.cjs stop', {
      cwd: PROJECT_ROOT,
      encoding: 'utf-8',
      stdio: 'pipe',
      input: '{}',
      timeout: 30000,
    })

    if (output.trim()) console.log(output)
    log.success('Harness 检查通过')
    process.exit(0)
  } catch (err) {
    if (err.stdout) console.log(err.stdout)
    if (err.stderr) console.error(err.stderr)
    log.error('Harness 检查发现问题，请根据 [FIX] 指令修复')
    process.exit(err.status || 1)
  }
}
