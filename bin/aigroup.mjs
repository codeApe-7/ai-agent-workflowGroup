#!/usr/bin/env node

/**
 * aiGroup CLI — AI 团队协作框架脚手架
 *
 * 用法：
 *   npx aigroup-workflow init      完整初始化
 *   npx aigroup-workflow update    增量更新技能和传感器
 *   npx aigroup-workflow check     运行 Harness 健康检查
 *   npx aigroup-workflow status    查看工作流状态
 */

import { fileURLToPath } from 'node:url'
import { dirname, resolve } from 'node:path'

const __filename = fileURLToPath(import.meta.url)
const __dirname = dirname(__filename)

// 包根目录（模板资产所在位置）
const PKG_ROOT = resolve(__dirname, '..')

// 用户项目目录
const PROJECT_ROOT = process.cwd()

const args = process.argv.slice(2)
const command = args[0] || ''
const flags = args.slice(1)

// 解析 flags
function hasFlag(name) {
  return flags.includes(`--${name}`) || flags.includes(`-${name[0]}`)
}

function getFlagValue(name) {
  const idx = flags.indexOf(`--${name}`)
  if (idx !== -1 && flags[idx + 1]) return flags[idx + 1]
  return null
}

async function main() {
  const ctx = { PKG_ROOT, PROJECT_ROOT, flags, hasFlag, getFlagValue }

  switch (command) {
    case 'init':
    case 'i': {
      const { init } = await import('../cli/commands/init.mjs')
      await init(ctx)
      break
    }
    case 'update':
    case 'u': {
      const { update } = await import('../cli/commands/update.mjs')
      await update(ctx)
      break
    }
    case 'check':
    case 'c': {
      const { check } = await import('../cli/commands/check.mjs')
      await check(ctx)
      break
    }
    case 'status':
    case 's': {
      const { status } = await import('../cli/commands/status.mjs')
      await status(ctx)
      break
    }
    case 'help':
    case '--help':
    case '-h':
    case '': {
      printHelp()
      break
    }
    default: {
      console.error(`\n  未知命令: ${command}\n`)
      printHelp()
      process.exit(1)
    }
  }
}

function printHelp() {
  console.log(`
  ╔══════════════════════════════════════════╗
  ║   aiGroup — AI 团队协作框架 CLI          ║
  ╚══════════════════════════════════════════╝

  用法: aigroup <命令> [选项]

  命令:
    init,   i     完整初始化（交互式选择角色、技能、配置）
    update, u     增量更新（只更新技能和传感器，不覆盖自定义）
    check,  c     运行 Harness 健康检查
    status, s     查看工作流状态
    help          显示帮助

  选项:
    --yes, -y     跳过确认，全部使用默认值
    --lang <语言>  设置语言（zh-CN / en）

  示例:
    npx aigroup-workflow init          # 交互式初始化
    npx aigroup-workflow init --yes    # 使用默认配置初始化
    npx aigroup-workflow update        # 增量更新
    npx aigroup-workflow check         # 健康检查
`)
}

main().catch(err => {
  console.error('\n  错误:', err.message)
  process.exit(1)
})
