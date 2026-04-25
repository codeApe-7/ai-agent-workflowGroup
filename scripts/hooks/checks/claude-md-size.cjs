'use strict';

const { createReport, readFileSafe } = require('../lib/runner.cjs');

const MAX_LINES = 100;

function run() {
  const report = createReport();
  const content = readFileSafe('CLAUDE.md');
  if (content === null) return report;
  const lines = content.split('\n').length;
  if (lines > MAX_LINES) {
    report.fail(
      `CLAUDE.md 超过 ${MAX_LINES} 行（当前 ${lines} 行）`,
      'CLAUDE.md 应保持为目录式入口，详细内容移至 docs/'
    );
  }
  return report;
}

module.exports = { run, section: 'CLAUDE.md 体积检查' };
