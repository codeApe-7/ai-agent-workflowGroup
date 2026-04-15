/**
 * 日志输出工具 — 统一的终端输出格式
 */

const COLORS = {
  reset: '\x1b[0m',
  bold: '\x1b[1m',
  dim: '\x1b[2m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  red: '\x1b[31m',
  cyan: '\x1b[36m',
  blue: '\x1b[34m',
  gray: '\x1b[90m',
}

export function success(msg) {
  console.log(`  ${COLORS.green}✔${COLORS.reset} ${msg}`)
}

export function warn(msg) {
  console.log(`  ${COLORS.yellow}⚠${COLORS.reset} ${msg}`)
}

export function error(msg) {
  console.error(`  ${COLORS.red}✘${COLORS.reset} ${msg}`)
}

export function info(msg) {
  console.log(`  ${COLORS.cyan}ℹ${COLORS.reset} ${msg}`)
}

export function step(msg) {
  console.log(`\n  ${COLORS.bold}${COLORS.blue}▸${COLORS.reset} ${COLORS.bold}${msg}${COLORS.reset}`)
}

export function dim(msg) {
  console.log(`    ${COLORS.gray}${msg}${COLORS.reset}`)
}

export function banner() {
  console.log(`
  ${COLORS.bold}╔══════════════════════════════════════════╗
  ║   aiGroup — AI 团队协作框架               ║
  ║   角色派遣 · 工作流管道 · Harness 传感器   ║
  ╚══════════════════════════════════════════╝${COLORS.reset}
`)
}
