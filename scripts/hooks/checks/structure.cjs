'use strict';

const { createReport, dirExists } = require('../lib/runner.cjs');

const REQUIRED_DIRS = [
  { path: '.orchestration', hint: 'mkdir -p .orchestration' },
  { path: '.orchestration/.logs', hint: 'mkdir -p .orchestration/.logs' },
  { path: '.claude/agents', hint: 'agent 定义根' },
  { path: 'skills', hint: 'skill 根（扁平结构）' },
  { path: 'docs/rules', hint: '强制规则集' }
];

function run() {
  const report = createReport();
  for (const entry of REQUIRED_DIRS) {
    if (!dirExists(entry.path)) {
      report.fail(`缺失目录 ${entry.path}/`, entry.hint);
    }
  }
  return report;
}

module.exports = { run, section: '基础结构检查' };
