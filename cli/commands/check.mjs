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

  const runAllPath = join(PROJECT_ROOT, 'scripts/harness/run-all.sh')
  if (!existsSync(runAllPath)) {
    log.error('传感器脚本不存在: scripts/harness/run-all.sh')
    log.info('请运行 aigroup update 重新安装传感器')
    return
  }

  try {
    const { execSync } = await import('node:child_process')
    const output = execSync('bash scripts/harness/run-all.sh', {
      cwd: PROJECT_ROOT,
      encoding: 'utf-8',
      stdio: 'pipe',
      timeout: 30000,
    })

    // 直接输出传感器结果
    console.log(output)

    if (output.includes('全部通过')) {
      process.exit(0)
    } else {
      process.exit(1)
    }
  } catch (err) {
    if (err.stdout) {
      console.log(err.stdout)
    }
    if (err.stderr) {
      console.error(err.stderr)
    }
    log.error('Harness 检查发现问题，请根据 [FIX] 指令修复')
    process.exit(err.status || 1)
  }
}
