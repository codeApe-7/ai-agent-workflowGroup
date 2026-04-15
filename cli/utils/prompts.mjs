/**
 * 交互式提示工具 — 零依赖，inquirer 风格
 *
 * 样式参考 zcf (https://github.com/UfoMiao/zcf)
 * - 方向键移动光标
 * - 空格切换选中（多选）/ 回车选择（单选）
 * - 彩色描述文字
 */

import { createInterface } from 'node:readline'

// ── ANSI 颜色 ──

const C = {
  reset: '\x1b[0m',
  bold: '\x1b[1m',
  dim: '\x1b[2m',
  cyan: '\x1b[36m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  gray: '\x1b[90m',
  blue: '\x1b[34m',
  white: '\x1b[37m',
  hideCursor: '\x1b[?25l',
  showCursor: '\x1b[?25h',
}

function createRL() {
  return createInterface({
    input: process.stdin,
    output: process.stdout,
  })
}

/**
 * 确认提示 (y/n)
 */
export async function confirm(message, defaultValue = true) {
  const rl = createRL()
  const hint = defaultValue ? 'Y/n' : 'y/N'
  return new Promise(resolve => {
    rl.question(`  ${C.cyan}?${C.reset} ${C.bold}${message}${C.reset} ${C.dim}(${hint})${C.reset} `, answer => {
      rl.close()
      if (!answer.trim()) return resolve(defaultValue)
      resolve(answer.trim().toLowerCase().startsWith('y'))
    })
  })
}

/**
 * 文本输入
 */
export async function input(message, defaultValue = '') {
  const rl = createRL()
  const hint = defaultValue ? ` ${C.dim}(${defaultValue})${C.reset}` : ''
  return new Promise(resolve => {
    rl.question(`  ${C.cyan}?${C.reset} ${C.bold}${message}${C.reset}${hint} `, answer => {
      rl.close()
      resolve(answer.trim() || defaultValue)
    })
  })
}

/**
 * 多选菜单 — inquirer checkbox 风格
 *
 * @param {string} message
 * @param {{ name: string, value: string, description?: string, checked?: boolean }[]} choices
 * @returns {Promise<string[]>}
 */
export async function multiSelect(message, choices) {
  const selected = new Set(
    choices.filter(c => c.checked).map(c => c.value)
  )
  let cursor = 0

  function renderLine(c, i) {
    const pointer = i === cursor ? `${C.cyan}❯${C.reset}` : ' '
    const check = selected.has(c.value)
      ? `${C.green}◉${C.reset}`
      : `${C.dim}◯${C.reset}`
    const name = i === cursor ? `${C.white}${C.bold}${c.name}${C.reset}` : c.name
    const desc = c.description ? ` ${C.gray}— ${c.description}${C.reset}` : ''
    return `  ${pointer} ${check} ${name}${desc}`
  }

  function renderHint() {
    return `  ${C.dim}↑↓ 移动${C.reset}  ${C.dim}空格 选择${C.reset}  ${C.dim}a 全选/取消${C.reset}  ${C.dim}回车 确认${C.reset}`
  }

  function render(isFirst) {
    if (!isFirst) {
      // 回到列表顶部重绘
      process.stdout.write(`\x1b[${choices.length + 1}A\x1b[0J`)
    }
    for (const [i, c] of choices.entries()) {
      console.log(renderLine(c, i))
    }
    process.stdout.write(renderHint())
  }

  // 首次绘制
  console.log(`\n  ${C.cyan}?${C.reset} ${C.bold}${message}${C.reset} ${C.dim}(空格选择, 回车确认)${C.reset}`)
  process.stdout.write(C.hideCursor)
  render(true)

  return new Promise(resolve => {
    const { stdin } = process
    const wasRaw = stdin.isRaw
    stdin.setRawMode(true)
    stdin.resume()
    stdin.setEncoding('utf-8')

    function onData(key) {
      // Ctrl+C
      if (key === '\x03') {
        cleanup()
        process.stdout.write(C.showCursor)
        process.exit(0)
      }
      // 回车 — 确认
      if (key === '\r' || key === '\n') {
        cleanup()
        process.stdout.write(`\r\x1b[K\n`)
        process.stdout.write(C.showCursor)
        // 打印选择结果
        const result = [...selected]
        const names = choices.filter(c => result.includes(c.value)).map(c => c.name)
        if (names.length) {
          console.log(`  ${C.green}✔${C.reset} 已选择: ${C.cyan}${names.join(', ')}${C.reset}`)
        }
        return resolve(result)
      }
      // 空格 — 切换选中
      if (key === ' ') {
        const val = choices[cursor].value
        if (selected.has(val)) selected.delete(val)
        else selected.add(val)
        render(false)
        return
      }
      // a — 全选/全不选
      if (key === 'a' || key === 'A') {
        if (selected.size === choices.length) {
          selected.clear()
        } else {
          for (const c of choices) selected.add(c.value)
        }
        render(false)
        return
      }
      // 方向键
      if (key === '\x1b[A') { cursor = (cursor - 1 + choices.length) % choices.length; render(false) }
      if (key === '\x1b[B') { cursor = (cursor + 1) % choices.length; render(false) }
    }

    function cleanup() {
      stdin.removeListener('data', onData)
      stdin.setRawMode(wasRaw ?? false)
      stdin.pause()
    }

    stdin.on('data', onData)
  })
}

/**
 * 单选菜单 — inquirer list 风格
 *
 * @param {string} message
 * @param {{ name: string, value: string, description?: string }[]} choices
 * @returns {Promise<string>}
 */
export async function select(message, choices) {
  let cursor = 0

  function renderLine(c, i) {
    const pointer = i === cursor ? `${C.cyan}❯${C.reset}` : ' '
    const name = i === cursor ? `${C.cyan}${C.bold}${c.name}${C.reset}` : c.name
    const desc = c.description ? ` ${C.gray}— ${c.description}${C.reset}` : ''
    return `  ${pointer} ${name}${desc}`
  }

  function renderHint() {
    return `  ${C.dim}↑↓ 移动${C.reset}  ${C.dim}回车 选择${C.reset}`
  }

  function render(isFirst) {
    if (!isFirst) {
      process.stdout.write(`\x1b[${choices.length + 1}A\x1b[0J`)
    }
    for (const [i, c] of choices.entries()) {
      console.log(renderLine(c, i))
    }
    process.stdout.write(renderHint())
  }

  // 首次绘制
  console.log(`\n  ${C.cyan}?${C.reset} ${C.bold}${message}${C.reset}`)
  process.stdout.write(C.hideCursor)
  render(true)

  return new Promise(resolve => {
    const { stdin } = process
    const wasRaw = stdin.isRaw
    stdin.setRawMode(true)
    stdin.resume()
    stdin.setEncoding('utf-8')

    function onData(key) {
      if (key === '\x03') {
        cleanup()
        process.stdout.write(C.showCursor)
        process.exit(0)
      }
      if (key === '\r' || key === '\n') {
        cleanup()
        process.stdout.write(`\r\x1b[K\n`)
        process.stdout.write(C.showCursor)
        console.log(`  ${C.green}✔${C.reset} 已选择: ${C.cyan}${choices[cursor].name}${C.reset}`)
        return resolve(choices[cursor].value)
      }
      if (key === '\x1b[A') { cursor = (cursor - 1 + choices.length) % choices.length; render(false) }
      if (key === '\x1b[B') { cursor = (cursor + 1) % choices.length; render(false) }
    }

    function cleanup() {
      stdin.removeListener('data', onData)
      stdin.setRawMode(wasRaw ?? false)
      stdin.pause()
    }

    stdin.on('data', onData)
  })
}
