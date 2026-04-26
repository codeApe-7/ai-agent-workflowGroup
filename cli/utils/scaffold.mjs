/**
 * 脚手架工具 — 文件复制、配置管理、模板变量替换
 *
 * Phase 4 起本模块由 manifests/install-modules.json 驱动安装内容：
 * - skill 安装不再按三角色，而是按模块（workflow / product / design / engineering / quality）
 * - Claude / Codex 的适配层文件分组独立装
 */

import { existsSync, mkdirSync, readdirSync, statSync, readFileSync, writeFileSync, copyFileSync } from 'node:fs'
import { join, dirname } from 'node:path'

// ─── 基础文件（必装） ───

/** 共享的主源文档（与 harness 无关，必装）；CLAUDE.md / AGENTS.md 改为按 target 分流 */
export const BASE_FILES = [
  'docs/README.md',
  'docs/workflow-pipeline.md',
  'docs/red-flags.md',
  'docs/rules/README.md',
  'docs/rules/agents.md',
  'docs/rules/coding-style.md',
  'docs/rules/git-workflow.md',
  'docs/rules/testing.md',
  'docs/rules/security.md',
  'docs/rules/performance.md',
  'docs/rules/hooks.md',
  'manifests/install-modules.json',
]

/** 语言专项规则目录（按需复制整个目录） */
export const RULES_LANGUAGE_DIRS = [
  'docs/rules/cpp',
  'docs/rules/csharp',
  'docs/rules/dart',
  'docs/rules/golang',
  'docs/rules/java',
  'docs/rules/kotlin',
  'docs/rules/perl',
  'docs/rules/php',
  'docs/rules/python',
  'docs/rules/rust',
  'docs/rules/swift',
  'docs/rules/typescript',
  'docs/rules/web',
]

/** 空目录结构（必装；session/worker 由 session.cjs 按需创建） */
export const BASE_DIRS = [
  'scripts/harness',
  'scripts/hooks',
  'scripts/orchestration',
  '.orchestration/.logs',
  'docs/templates',
]

/**
 * Agent 源池目录（开发态分发位置）。
 * init 时按用户选择的 agent 模块从这里复制到 .claude/agents/。
 */
export const AGENT_SOURCE_DIR = 'agents'

/** Claude Code hooks + commands + plugin 元数据 + 入口 */
export const CLAUDE_CORE_FILES = [
  'CLAUDE.md',
  '.claude/hooks.json',
  '.claude/commands/init-project.md',
  '.claude/commands/git-commit.md',
  '.claude/commands/workflow-start.md',
  '.claude/commands/plan.md',
  '.claude/commands/review.md',
  '.claude/commands/fix-build.md',
  '.claude/commands/tdd.md',
  '.claude-plugin/plugin.json',
]

/** Codex 适配层（config + 3 个 Codex 原生 persona TOML + plugin 元数据 + 入口） */
export const CODEX_CORE_FILES = [
  'AGENTS.md',
  '.codex/AGENTS.md',
  '.codex/config.toml',
  '.codex/agents/explorer.toml',
  '.codex/agents/reviewer.toml',
  '.codex/agents/docs-researcher.toml',
  '.codex-plugin/plugin.json',
]

// ─── Manifest 加载 ───

const MANIFEST_PATH = 'manifests/install-modules.json'

/**
 * 读取安装清单
 */
export function loadManifest(pkgRoot) {
  const path = join(pkgRoot, MANIFEST_PATH)
  if (!existsSync(path)) {
    return { version: 0, modules: [] }
  }
  try {
    return JSON.parse(readFileSync(path, 'utf-8'))
  } catch {
    return { version: 0, modules: [] }
  }
}

/**
 * 获取所有 skill 模块
 */
export function getSkillModules(pkgRoot) {
  return loadManifest(pkgRoot).modules.filter(m => m.kind === 'skills')
}

/**
 * 获取默认安装的 skill 模块 id
 */
export function getDefaultSkillModuleIds(pkgRoot) {
  return getSkillModules(pkgRoot)
    .filter(m => m.defaultInstall)
    .map(m => m.id)
}

/**
 * 获取所有 agent 模块（仅 Claude target，含按 agents 列表分组的）
 */
export function getAgentModules(pkgRoot) {
  return loadManifest(pkgRoot).modules.filter(
    m => m.kind === 'agents' && Array.isArray(m.agents)
  )
}

/**
 * 获取默认安装的 agent 模块 id
 */
export function getDefaultAgentModuleIds(pkgRoot) {
  return getAgentModules(pkgRoot)
    .filter(m => m.defaultInstall)
    .map(m => m.id)
}

/**
 * 列出 agent 源池中所有可用的 agent 名（不含 .md 后缀）
 */
export function listAvailableAgents(pkgRoot) {
  const dir = join(pkgRoot, AGENT_SOURCE_DIR)
  if (!existsSync(dir)) return []
  return readdirSync(dir)
    .filter(f => f.endsWith('.md'))
    .map(f => f.slice(0, -3))
    .sort()
}

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

    if (entry === '.git' || entry === 'node_modules') continue
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
 * 确保目录存在（空目录也创建）
 */
function ensureDir(dir) {
  if (!existsSync(dir)) mkdirSync(dir, { recursive: true })
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

export function readConfig(projectRoot) {
  const configPath = join(projectRoot, CONFIG_FILE)
  if (!existsSync(configPath)) return null
  try {
    return JSON.parse(readFileSync(configPath, 'utf-8'))
  } catch {
    return null
  }
}

export function writeConfig(projectRoot, config) {
  const configPath = join(projectRoot, CONFIG_FILE)
  writeFileSync(configPath, JSON.stringify(config, null, 2) + '\n', 'utf-8')
}

// ─── 脚手架主流程 ───

/**
 * 执行完整的脚手架安装
 *
 * @param {string} pkgRoot - npm 包根目录
 * @param {string} projectRoot - 用户项目目录
 * @param {object} options
 * @param {string[]} [options.modules] - 要安装的 skill 模块 id 列表（不传则装所有 defaultInstall）
 * @param {string[]} [options.targets] - 目标 harness ['claude', 'codex']（不传则双端都装）
 * @param {boolean} [options.overwrite] - 是否覆盖已有文件
 * @returns {{ totalCopied: number, sections: object[] }}
 */
export function scaffold(pkgRoot, projectRoot, options = {}) {
  const {
    modules = null,
    agentModules = null,
    targets = ['claude', 'codex'],
    overwrite = false,
  } = options

  const sections = []
  let totalCopied = 0

  // 1. 基础文件
  let baseCopied = 0
  for (const file of BASE_FILES) {
    const ok = copySingleFile(join(pkgRoot, file), join(projectRoot, file), overwrite)
    if (ok) baseCopied++
  }
  sections.push({ name: '基础文件（入口 + 主源文档 + 清单）', count: baseCopied })
  totalCopied += baseCopied

  // 2. 基础目录
  for (const dir of BASE_DIRS) {
    const src = join(pkgRoot, dir)
    const dest = join(projectRoot, dir)
    if (existsSync(src)) {
      totalCopied += copyDirRecursive(src, dest, { overwrite })
    } else {
      ensureDir(dest)
    }
  }
  sections.push({ name: '传感器 + 协作产物目录', count: totalCopied - baseCopied })

  // 2b. 语言专项规则（13 个目录，递归复制）
  let langRulesCopied = 0
  for (const dir of RULES_LANGUAGE_DIRS) {
    langRulesCopied += copyDirRecursive(join(pkgRoot, dir), join(projectRoot, dir), { overwrite })
  }
  sections.push({ name: '语言专项规则（cpp/golang/java/python/rust/ts/...）', count: langRulesCopied })
  totalCopied += langRulesCopied

  // 3. Claude Code 适配层（commands + hooks + plugin；agent 由独立步骤按选择安装）
  if (targets.includes('claude')) {
    let claudeCopied = 0
    for (const file of CLAUDE_CORE_FILES) {
      const ok = copySingleFile(join(pkgRoot, file), join(projectRoot, file), overwrite)
      if (ok) claudeCopied++
    }
    sections.push({ name: 'Claude Code 核心（commands + hooks + plugin）', count: claudeCopied })
    totalCopied += claudeCopied

    // 3b. Agent 模块（按用户选择，从 agents/ 源池复制到 .claude/agents/）
    const allAgentModules = getAgentModules(pkgRoot)
    const selectedAgentIds = agentModules || getDefaultAgentModuleIds(pkgRoot)

    let agentCopied = 0
    const installedAgents = new Set()
    for (const modId of selectedAgentIds) {
      const mod = allAgentModules.find(m => m.id === modId)
      if (!mod || !Array.isArray(mod.agents)) continue
      for (const agentName of mod.agents) {
        if (installedAgents.has(agentName)) continue
        const src = join(pkgRoot, AGENT_SOURCE_DIR, `${agentName}.md`)
        const dest = join(projectRoot, '.claude/agents', `${agentName}.md`)
        const ok = copySingleFile(src, dest, overwrite)
        if (ok) {
          agentCopied++
          installedAgents.add(agentName)
        }
      }
    }
    sections.push({
      name: `Claude agent（${installedAgents.size} 个：${[...installedAgents].slice(0, 5).join(', ')}${installedAgents.size > 5 ? '…' : ''}）`,
      count: agentCopied,
    })
    totalCopied += agentCopied
  }

  // 4. Codex 适配层
  if (targets.includes('codex')) {
    let codexCopied = 0
    for (const file of CODEX_CORE_FILES) {
      const ok = copySingleFile(join(pkgRoot, file), join(projectRoot, file), overwrite)
      if (ok) codexCopied++
    }
    sections.push({ name: 'Codex 适配（config + roles + plugin）', count: codexCopied })
    totalCopied += codexCopied
  }

  // 5. Skill 模块（manifest 驱动）
  // Claude Code 启动自动加载位置：.claude/skills/<name>/SKILL.md
  // Codex 端按文件路径手动加载，沿用根 skills/<name>/SKILL.md
  const allSkillModules = getSkillModules(pkgRoot)
  const selectedIds = modules || getDefaultSkillModuleIds(pkgRoot)

  for (const modId of selectedIds) {
    const mod = allSkillModules.find(m => m.id === modId)
    if (!mod) continue

    // 过滤：该模块是否适用于任一选中的 target
    const modTargets = mod.targets || ['claude', 'codex']
    if (!modTargets.some(t => targets.includes(t))) continue

    let modCopied = 0
    for (const skillPath of mod.paths) {
      const src = join(pkgRoot, skillPath)
      // skills/<name> → 根据 target 决定落盘位置
      // Claude target：.claude/skills/<name>（Claude Code 自动加载）
      // Codex target：skills/<name>（文件路径手动加载）
      if (targets.includes('claude')) {
        const claudeDest = join(projectRoot, skillPath.replace(/^skills\//, '.claude/skills/'))
        modCopied += copyDirRecursive(src, claudeDest, { overwrite })
      }
      if (targets.includes('codex')) {
        const codexDest = join(projectRoot, skillPath)
        modCopied += copyDirRecursive(src, codexDest, { overwrite })
      }
    }
    sections.push({
      name: `skill 模块: ${modId} — ${mod.description || ''}`,
      count: modCopied,
    })
    totalCopied += modCopied
  }

  return { totalCopied, sections }
}

/**
 * 执行增量更新（按配置中的 modules 和 targets 覆盖更新）
 */
export function scaffoldUpdate(pkgRoot, projectRoot) {
  const sections = []
  let totalCopied = 0

  const config = readConfig(projectRoot)
  const modules = config?.modules || getDefaultSkillModuleIds(pkgRoot)
  const targets = config?.targets || ['claude', 'codex']

  // 传感器
  const sensorCopied = copyDirRecursive(
    join(pkgRoot, 'scripts/harness'),
    join(projectRoot, 'scripts/harness'),
    { overwrite: true }
  )
  sections.push({ name: 'Harness 传感器', count: sensorCopied })
  totalCopied += sensorCopied

  // Claude adapter（如启用）：commands + hooks + plugin + 已选 agent 模块
  if (targets.includes('claude')) {
    let claudeCopied = 0
    for (const file of CLAUDE_CORE_FILES) {
      const ok = copySingleFile(join(pkgRoot, file), join(projectRoot, file), true)
      if (ok) claudeCopied++
    }
    // 已安装的 agent 模块按 config 覆盖更新
    const agentModules = config?.agentModules || getDefaultAgentModuleIds(pkgRoot)
    const allAgentModules = getAgentModules(pkgRoot)
    const installedAgents = new Set()
    for (const modId of agentModules) {
      const mod = allAgentModules.find(m => m.id === modId)
      if (!mod || !Array.isArray(mod.agents)) continue
      for (const agentName of mod.agents) {
        if (installedAgents.has(agentName)) continue
        const src = join(pkgRoot, AGENT_SOURCE_DIR, `${agentName}.md`)
        const dest = join(projectRoot, '.claude/agents', `${agentName}.md`)
        const ok = copySingleFile(src, dest, true)
        if (ok) {
          claudeCopied++
          installedAgents.add(agentName)
        }
      }
    }
    sections.push({ name: `Claude Code 适配层（含 ${installedAgents.size} 个 agent）`, count: claudeCopied })
    totalCopied += claudeCopied
  }

  // Codex adapter（如启用）
  if (targets.includes('codex')) {
    let codexCopied = 0
    for (const file of CODEX_CORE_FILES) {
      const ok = copySingleFile(join(pkgRoot, file), join(projectRoot, file), true)
      if (ok) codexCopied++
    }
    sections.push({ name: 'Codex 适配层', count: codexCopied })
    totalCopied += codexCopied
  }

  // Skill 模块（按 target 分流：claude → .claude/skills/，codex → skills/）
  const allSkillModules = getSkillModules(pkgRoot)
  for (const modId of modules) {
    const mod = allSkillModules.find(m => m.id === modId)
    if (!mod) continue
    let modCopied = 0
    for (const skillPath of mod.paths) {
      const src = join(pkgRoot, skillPath)
      if (targets.includes('claude')) {
        const claudeDest = join(projectRoot, skillPath.replace(/^skills\//, '.claude/skills/'))
        modCopied += copyDirRecursive(src, claudeDest, { overwrite: true })
      }
      if (targets.includes('codex')) {
        modCopied += copyDirRecursive(src, join(projectRoot, skillPath), { overwrite: true })
      }
    }
    sections.push({ name: `skill 模块: ${modId}`, count: modCopied })
    totalCopied += modCopied
  }

  // 基础文档与清单（覆盖）
  let docsCopied = 0
  for (const file of BASE_FILES) {
    const ok = copySingleFile(join(pkgRoot, file), join(projectRoot, file), true)
    if (ok) docsCopied++
  }
  sections.push({ name: '主源文档 + 清单', count: docsCopied })
  totalCopied += docsCopied

  return { totalCopied, sections }
}

/**
 * 检查用户项目是否已初始化
 */
export function isInitialized(projectRoot) {
  return existsSync(join(projectRoot, 'CLAUDE.md'))
    && existsSync(join(projectRoot, 'scripts/hooks/dispatcher.cjs'))
}
