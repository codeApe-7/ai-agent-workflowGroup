'use strict';

const fs = require('fs');
const path = require('path');
const { createReport, ROOT, relPosix, dirExists } = require('../lib/runner.cjs');

// 真相源：.orchestration/<session>/<worker>/status.md
// 在 Stop 事件中：若任一 worker state=running，说明主会话要停但 worker 没走到终态。
// 终态：completed | failed | blocked （完成、失败、主动阻塞都允许 Stop）

const TERMINAL_STATES = new Set(['completed', 'failed', 'blocked']);

function readState(statusFile) {
  try {
    const content = fs.readFileSync(statusFile, 'utf8');
    const match = content.match(/^\s*-\s*State:\s*(\S+)/m);
    return match ? match[1].toLowerCase() : null;
  } catch (_error) {
    return null;
  }
}

function run() {
  const report = createReport();
  if (!dirExists('.orchestration')) return report;

  const coordRoot = path.join(ROOT, '.orchestration');
  const sessions = fs.readdirSync(coordRoot, { withFileTypes: true })
    .filter(entry => entry.isDirectory() && !entry.name.startsWith('.'));

  const stuck = [];
  for (const session of sessions) {
    const sessionDir = path.join(coordRoot, session.name);
    const workers = fs.readdirSync(sessionDir, { withFileTypes: true })
      .filter(entry => entry.isDirectory());

    for (const worker of workers) {
      const statusFile = path.join(sessionDir, worker.name, 'status.md');
      const state = readState(statusFile);
      if (state === 'running') {
        stuck.push(relPosix(statusFile));
      }
    }
  }

  if (stuck.length > 0) {
    report.fail(
      `以下 worker 仍在 running：${stuck.join(', ')}`,
      '完成 worker 后运行 `node scripts/orchestration/session.cjs set-status <session> <worker> completed`；主动放弃用 `failed` 或 `blocked`'
    );
  }

  return report;
}

module.exports = { run, section: '工作流 worker 状态检查' };
