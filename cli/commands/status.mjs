/**
 * status 命令 — 查看工作流状态和项目概况
 */

import { existsSync, readFileSync, readdirSync } from 'node:fs'
import { join } from 'node:path'
import { readConfig, isInitialized } from '../utils/scaffold.mjs'
import * as log from '../utils/logger.mjs'

export async function status(ctx) {
  const { PROJECT_ROOT } = ctx

  log.step('项目状态')

  if (!isInitialized(PROJECT_ROOT)) {
    log.error('项目尚未初始化 aiGroup 框架')
    log.info('请先运行: aigroup init')
    return
  }

  // ── 配置信息 ──
  const config = readConfig(PROJECT_ROOT)
  if (config) {
    log.dim(`版本: ${config.version || '未知'}`)
    log.dim(`角色: ${config.agents?.join(', ') || '未知'}`)
    log.dim(`安装: ${config.installedAt || '未知'}`)
    log.dim(`更新: ${config.updatedAt || '未知'}`)
  }

  // ── 工作流状态 ──
  log.step('工作流状态')

  const statePath = join(PROJECT_ROOT, '.dev-agents/shared/.workflow-state')
  if (existsSync(statePath)) {
    try {
      const { execSync } = await import('node:child_process')
      const output = execSync('bash scripts/harness/workflow-state.sh status', {
        cwd: PROJECT_ROOT,
        encoding: 'utf-8',
        timeout: 5000,
      })
      console.log(output)
    } catch {
      const content = readFileSync(statePath, 'utf-8')
      console.log(`    ${content}`)
    }
  } else {
    log.dim('当前无活跃工作流')
  }

  // ── 产物统计 ──
  log.step('产物统计')

  const sharedDir = join(PROJECT_ROOT, '.dev-agents/shared')
  const counts = {
    designs: countFiles(join(sharedDir, 'designs'), '.md'),
    tasks: countFiles(join(sharedDir, 'tasks'), '.md'),
    reviews: countFiles(join(sharedDir, 'reviews'), '.md'),
  }

  log.dim(`设计文档: ${counts.designs} 个`)
  log.dim(`实现计划: ${counts.tasks} 个`)
  log.dim(`审查报告: ${counts.reviews} 个`)

  // ── 技能清单 ──
  log.step('已安装技能')

  const workflowDir = join(PROJECT_ROOT, 'skills/max/workflow')
  if (existsSync(workflowDir)) {
    const skills = readdirSync(workflowDir).filter(d => {
      return existsSync(join(workflowDir, d, 'SKILL.md'))
    })
    log.dim(`工作流技能: ${skills.length} 个`)
    for (const s of skills) {
      log.dim(`  • ${s}`)
    }
  }

  console.log('')
}

function countFiles(dir, ext) {
  if (!existsSync(dir)) return 0
  try {
    return readdirSync(dir).filter(f => f.endsWith(ext)).length
  } catch {
    return 0
  }
}
