'use strict';

const fs = require('fs');
const path = require('path');
const { createReport, ROOT, relPosix } = require('../lib/runner.cjs');

const MIN_BYTES = 50;

function run() {
  const report = createReport();
  const docsDir = path.join(ROOT, 'docs');
  let entries;
  try {
    entries = fs.readdirSync(docsDir, { withFileTypes: true });
  } catch (_error) {
    return report;
  }
  for (const entry of entries) {
    if (!entry.isFile() || !entry.name.endsWith('.md')) continue;
    const full = path.join(docsDir, entry.name);
    const size = fs.statSync(full).size;
    if (size < MIN_BYTES) {
      report.fail(
        `${relPosix(full)} 内容过少（${size} bytes）`,
        '文档不应为空壳，请补充实质内容或删除'
      );
    }
  }
  return report;
}

module.exports = { run, section: 'docs 空壳检查' };
