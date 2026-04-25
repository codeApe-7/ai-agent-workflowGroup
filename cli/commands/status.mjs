/**
 * status 命令 — 查看工作流 session 状态和项目概况
 */

import { existsSync, readFileSync, readdirSync, statSync } from 'node:fs'
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

  // ── 协调 session 列表 ──
  log.step('活跃 session')

  const coordRoot = join(PROJECT_ROOT, '.orchestration')
  const sessions = existsSync(coordRoot)
    ? readdirSync(coordRoot, { withFileTypes: true })
        .filter(d => d.isDirectory() && !d.name.startsWith('.'))
        .map(d => d.name)
    : []

  if (sessions.length === 0) {
    log.dim('当前无活跃 session（.orchestration/ 下无 session 目录）')
  } else {
    for (const session of sessions) {
      log.dim(`  ▸ ${session}`)
      const sessionDir = join(coordRoot, session)
      const workers = readdirSync(sessionDir, { withFileTypes: true })
        .filter(d => d.isDirectory())
      for (const worker of workers) {
        const statusFile = join(sessionDir, worker.name, 'status.md')
        if (!existsSync(statusFile)) continue
        const raw = readFileSync(statusFile, 'utf-8')
        const match = raw.match(/^\s*-\s*State:\s*(\S+)/m)
        log.dim(`      ${worker.name}: ${match ? match[1] : '?'}`)
      }
    }
  }

  // ── 产物统计 ──
  log.step('协调产物统计')

  let handoffs = 0
  let tasks = 0
  for (const session of sessions) {
    const sessionDir = join(coordRoot, session)
    const workers = readdirSync(sessionDir, { withFileTypes: true })
      .filter(d => d.isDirectory())
    for (const worker of workers) {
      const wd = join(sessionDir, worker.name)
      if (existsSync(join(wd, 'handoff.md'))) handoffs += 1
      if (existsSync(join(wd, 'task.md'))) tasks += 1
    }
  }
  log.dim(`session 数: ${sessions.length}`)
  log.dim(`task.md 数: ${tasks}`)
  log.dim(`handoff.md 数: ${handoffs}`)

  // ── 技能清单 ──
  log.step('已安装技能')

  const workflowDir = join(PROJECT_ROOT, 'skills/workflow')
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
