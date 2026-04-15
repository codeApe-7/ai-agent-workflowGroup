/**
 * 交互式提示工具 — 零依赖，基于 Node.js readline
 */

import { createInterface } from 'node:readline'

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
    rl.question(`  ? ${message} (${hint}) `, answer => {
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
  const hint = defaultValue ? ` (${defaultValue})` : ''
  return new Promise(resolve => {
    rl.question(`  ? ${message}${hint}: `, answer => {
      rl.close()
      resolve(answer.trim() || defaultValue)
    })
  })
}

/**
 * 多选菜单 — 方向键移动，空格切换选中，回车确认
 * @param {string} message
 * @param {{ name: string, value: string, checked?: boolean }[]} choices
 * @returns {Promise<string[]>}
 */
export async function multiSelect(message, choices) {
  const selected = new Set(
    choices.filter(c => c.checked).map(c => c.value)
  )
  let cursor = 0

  function render() {
    // 移动光标到列表起始位置并清除下方内容
    process.stdout.write(`\x1B[${choices.length + 1}A`)
    process.stdout.write('\x1B[0J')
    choices.forEach((c, i) => {
      const pointer = i === cursor ? '❯' : ' '
      const mark = selected.has(c.value) ? '◉' : '◯'
      console.log(`    ${pointer} ${mark} ${c.name}`)
    })
    process.stdout.write('  ↑↓ 移动  空格 切换  回车 确认')
  }

  // 首次绘制
  console.log(`\n  ? ${message}`)
  choices.forEach((c, i) => {
    const pointer = i === cursor ? '❯' : ' '
    const mark = selected.has(c.value) ? '◉' : '◯'
    console.log(`    ${pointer} ${mark} ${c.name}`)
  })
  process.stdout.write('  ↑↓ 移动  空格 切换  回车 确认')

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
        process.exit(0)
      }
      // 回车 — 确认
      if (key === '\r' || key === '\n') {
        cleanup()
        // 清除提示行并显示最终选择
        process.stdout.write('\r\x1B[K\n')
        return resolve([...selected])
      }
      // 空格 — 切换选中
      if (key === ' ') {
        const val = choices[cursor].value
        if (selected.has(val)) selected.delete(val)
        else selected.add(val)
        render()
        return
      }
      // 方向键（上: \x1B[A, 下: \x1B[B）
      if (key === '\x1B[A' || key === '\x1B[B') {
        if (key === '\x1B[A') cursor = (cursor - 1 + choices.length) % choices.length
        else cursor = (cursor + 1) % choices.length
        render()
      }
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
 * 单选菜单
 * @param {string} message
 * @param {{ name: string, value: string }[]} choices
 * @returns {Promise<string>}
 */
export async function select(message, choices) {
  console.log(`\n  ? ${message}`)
  console.log('')

  choices.forEach((c, i) => {
    console.log(`    ${i + 1}. ${c.name}`)
  })

  const rl = createRL()
  return new Promise(resolve => {
    rl.question(`\n  输入编号选择 (1-${choices.length}): `, answer => {
      rl.close()
      const idx = parseInt(answer.trim()) - 1
      if (idx >= 0 && idx < choices.length) {
        resolve(choices[idx].value)
      } else {
        resolve(choices[0].value)
      }
    })
  })
}
