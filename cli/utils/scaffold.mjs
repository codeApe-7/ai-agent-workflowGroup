/**
 * 脚手架工具 — 文件复制、配置管理、模板变量替换
 */

import { existsSync, mkdirSync, readdirSync, statSync, readFileSync, writeFileSync, copyFileSync } from 'node:fs'
import { join, relative, dirname } from 'node:path'

// ─── 框架资产清单 ───
// 定义从包根目录复制到用户项目的文件映射

/** 基础文件（必装） */
export const BASE_FILES = [
  'CLAUDE.md',
  'docs/ARCHITECTURE.md',
  'docs/README.md',
  'docs/workflow-pipeline.md',
  'docs/dispatch-rules.md',
  'docs/coding-standards.md',
  'docs/red-flags.md',
  'docs/QUALITY_SCORE.md',
  'docs/tech-debt-tracker.md',
  'docs/steering-loop.md',
]

/** 基础目录（必装） */
export const BASE_DIRS = [
  'scripts/harness',
  '.dev-agents/shared/tasks',
  '.dev-agents/shared/designs',
  '.dev-agents/shared/reviews',
  'docs/templates',
  'skills/max/workflow/brainstorming',
  'skills/max/workflow/requirement-validation',
  'skills/max/workflow/solution-design',
  'skills/max/workflow/writing-plans',
  'skills/max/workflow/subagent-driven-development',
  'skills/max/workflow/testing',
  'skills/max/workflow/documentation',
  'skills/max/workflow/finishing-a-development-branch',
  'skills/max/workflow/systematic-debugging',
  'skills/max/workflow/verification-before-completion',
  'skills/max/workflow/entropy-management',
  'skills/max/competitive-analysis',
  'skills/max/meeting-notes',
  'skills/max/prd-template',
  'skills/max/stakeholder-update',
  'skills/max/user-research-synthesis',
]

/** Hooks 和通用命令（必装） */
export const HOOKS_FILES = [
  '.claude/hooks.json',
  '.claude/commands/init-project.md',
  '.claude/commands/git-commit.md',
  '.claude/agents/init-architect.md',
  '.claude/agents/get-current-datetime.md',
]

/** 角色资产（原生子代理：`.claude/agents/{name}.md`） */
export const AGENT_ASSETS = {
  jarvis: {
    label: '贾维斯 (Jarvis) — 全栈开发工程师',
    agents: ['.claude/agents/jarvis.md'],
    skills: ['skills/jarvis'],
  },
  ella: {
    label: '艾拉 (Ella) — UI/UX 设计师',
    agents: ['.claude/agents/ella.md'],
    skills: ['skills/ella'],
  },
  kyle: {
    label: '凯尔 (Kyle) — 质量保证工程师',
    agents: ['.claude/agents/kyle.md'],
    skills: ['skills/kyle'],
  },
}

/** 可更新的资产（update 命令使用） */
export const UPDATABLE_DIRS = [
  'scripts/harness',
  'skills/max/workflow',
  'skills/max/competitive-analysis',
  'skills/max/meeting-notes',
  'skills/max/prd-template',
  'skills/max/stakeholder-update',
  'skills/max/user-research-synthesis',
]

export const UPDATABLE_FILES = [
  '.claude/hooks.json',
  '.claude/agents/jarvis.md',
  '.claude/agents/ella.md',
  '.claude/agents/kyle.md',
  '.claude/commands/init-project.md',
  '.claude/commands/git-commit.md',
  '.claude/agents/init-architect.md',
  '.claude/agents/get-current-datetime.md',
]

// ─── 文件操作 ───

/**
 * 递归复制目录
 */
export function copyDirRecursive(src, dest, options = {}) {
  const { overwrite = false, filter = null } = options
  let copied = 0

  if (!existsSync(src)) return copied
  if (!existsSync(dest)) mkdirSync(dest, { recursive: true })

  const entries = readdirSync(src)
  for (const entry of entries) {
    const srcPath = join(src, entry)
    const destPath = join(dest, entry)

    // 跳过 .git、node_modules 等
    if (entry === '.git' || entry === 'node_modules') continue

    // 自定义过滤
    if (filter && !filter(srcPath, entry)) continue

    const stat = statSync(srcPath)
    if (stat.isDirectory()) {
      copied += copyDirRecursive(srcPath, destPath, options)
    } else {
      if (!existsSync(destPath) || overwrite) {
        mkdirSync(dirname(destPath), { recursive: true })
        copyFileSync(srcPath, destPath)
        copied++
      }
    }
  }

  return copied
}

/**
 * 复制单个文件
 */
export function copySingleFile(src, dest, overwrite = false) {
  if (!existsSync(src)) return false
  if (existsSync(dest) && !overwrite) return false
  mkdirSync(dirname(dest), { recursive: true })
  copyFileSync(src, dest)
  return true
}

/**
 * 模板变量替换
 */
export function processTemplate(filePath, variables) {
  if (!existsSync(filePath)) return
  let content = readFileSync(filePath, 'utf-8')
  for (const [key, value] of Object.entries(variables)) {
    content = content.replaceAll(`{{${key}}}`, value)
  }
  writeFileSync(filePath, content, 'utf-8')
}

// ─── 配置管理 ───

const CONFIG_FILE = '.aigroup.json'

/**
 * 读取用户项目的 aigroup 配置
 */
export function readConfig(projectRoot) {
  const configPath = join(projectRoot, CONFIG_FILE)
  if (!existsSync(configPath)) return null
  try {
    return JSON.parse(readFileSync(configPath, 'utf-8'))
  } catch {
    return null
  }
}

/**
 * 写入配置
 */
export function writeConfig(projectRoot, config) {
  const configPath = join(projectRoot, CONFIG_FILE)
  writeFileSync(configPath, JSON.stringify(config, null, 2) + '\n', 'utf-8')
}

// ─── 脚手架主流程 ───

/**
 * 执行完整的脚手架安装
 * @param {string} pkgRoot - npm 包根目录（模板资产所在）
 * @param {string} projectRoot - 用户项目目录
 * @param {object} options
 * @param {string[]} options.agents - 选择的角色 ['jarvis', 'ella', 'kyle']
 * @param {boolean} options.overwrite - 是否覆盖已有文件
 * @returns {{ totalCopied: number, sections: object[] }}
 */
export function scaffold(pkgRoot, projectRoot, options = {}) {
  const { agents = ['jarvis', 'ella', 'kyle'], overwrite = false } = options
  const sections = []
  let totalCopied = 0

  // 1. 基础文件
  let baseCopied = 0
  for (const file of BASE_FILES) {
    const ok = copySingleFile(join(pkgRoot, file), join(projectRoot, file), overwrite)
    if (ok) baseCopied++
  }
  sections.push({ name: '基础文件', count: baseCopied })
  totalCopied += baseCopied

  // 2. 基础目录
  let dirCopied = 0
  for (const dir of BASE_DIRS) {
    dirCopied += copyDirRecursive(join(pkgRoot, dir), join(projectRoot, dir), { overwrite })
  }
  sections.push({ name: '工作流技能 + 传感器', count: dirCopied })
  totalCopied += dirCopied

  // 3. Hooks
  let hooksCopied = 0
  for (const file of HOOKS_FILES) {
    const ok = copySingleFile(join(pkgRoot, file), join(projectRoot, file), overwrite)
    if (ok) hooksCopied++
  }
  sections.push({ name: 'Hooks 配置', count: hooksCopied })
  totalCopied += hooksCopied

  // 4. 角色资产
  for (const agentId of agents) {
    const agent = AGENT_ASSETS[agentId]
    if (!agent) continue
    let agentCopied = 0

    for (const file of agent.agents) {
      const ok = copySingleFile(join(pkgRoot, file), join(projectRoot, file), overwrite)
      if (ok) agentCopied++
    }
    for (const dir of agent.skills) {
      agentCopied += copyDirRecursive(join(pkgRoot, dir), join(projectRoot, dir), { overwrite })
    }

    sections.push({ name: agent.label, count: agentCopied })
    totalCopied += agentCopied
  }

  return { totalCopied, sections }
}

/**
 * 执行增量更新（只更新技能和传感器）
 */
export function scaffoldUpdate(pkgRoot, projectRoot) {
  const sections = []
  let totalCopied = 0

  // 更新目录（覆盖）
  for (const dir of UPDATABLE_DIRS) {
    const copied = copyDirRecursive(join(pkgRoot, dir), join(projectRoot, dir), { overwrite: true })
    totalCopied += copied
  }
  sections.push({ name: '工作流技能 + 传感器', count: totalCopied })

  // 更新命令/子代理文件（覆盖）
  let cmdCopied = 0
  const config = readConfig(projectRoot)
  const agents = config?.agents || ['jarvis', 'ella', 'kyle']
  const roleIds = new Set(['jarvis', 'ella', 'kyle'])
  for (const file of UPDATABLE_FILES) {
    // 角色子代理文件：仅更新用户选中的角色
    const m = file.match(/agents\/([\w-]+)\.md$/)
    if (m && roleIds.has(m[1]) && !agents.includes(m[1])) continue
    const ok = copySingleFile(join(pkgRoot, file), join(projectRoot, file), true)
    if (ok) cmdCopied++
  }
  sections.push({ name: '命令/子代理文件', count: cmdCopied })
  totalCopied += cmdCopied

  return { totalCopied, sections }
}

/**
 * 检查用户项目是否已初始化
 */
export function isInitialized(projectRoot) {
  return existsSync(join(projectRoot, 'CLAUDE.md'))
    && existsSync(join(projectRoot, 'scripts/harness/run-all.sh'))
}
