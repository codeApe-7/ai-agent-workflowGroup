'use strict';

const fs = require('fs');
const path = require('path');
const { createReport, ROOT, relPosix, dirExists } = require('../lib/runner.cjs');

const COORD_ROOT = path.join(ROOT, '.orchestration');
const STAGE1_RE = /(stage.?1|阶段.?1|规格符合)/i;
const STAGE2_RE = /(stage.?2|阶段.?2|代码质量)/i;

function run() {
  const report = createReport();
  if (!dirExists('.orchestration')) return report;

  const sessions = fs.readdirSync(COORD_ROOT, { withFileTypes: true })
    .filter(entry => entry.isDirectory() && !entry.name.startsWith('.'));

  for (const session of sessions) {
    const sessionDir = path.join(COORD_ROOT, session.name);
    const workers = fs.readdirSync(sessionDir, { withFileTypes: true })
      .filter(entry => entry.isDirectory());

    for (const worker of workers) {
      const workerDir = path.join(sessionDir, worker.name);
      const statusFile = path.join(workerDir, 'status.md');

      // 轻量 worker：只要求 handoff + status，跳过 task.md
      let lightweight = false;
      try {
        const raw = fs.readFileSync(statusFile, 'utf8');
        lightweight = /^\s*-\s*Lightweight:\s*true/m.test(raw);
      } catch (_error) { /* fall through */ }

      const required = lightweight
        ? ['handoff.md', 'status.md']
        : ['task.md', 'handoff.md', 'status.md'];

      for (const file of required) {
        const full = path.join(workerDir, file);
        if (!fs.existsSync(full)) {
          report.fail(
            `${relPosix(workerDir)}/ 缺失 ${file}${lightweight ? '（轻量 worker）' : ''}`,
            '用 node scripts/orchestration/session.cjs add-worker 创建（轻量加 --lightweight）'
          );
        }
      }

      if (worker.name === 'code-reviewer') {
        const handoff = path.join(workerDir, 'handoff.md');
        if (fs.existsSync(handoff)) {
          const content = fs.readFileSync(handoff, 'utf8');
          if (!STAGE1_RE.test(content) && !STAGE2_RE.test(content)) {
            report.fail(
              `${relPosix(handoff)} 缺少阶段标识`,
              '审查报告必须含 Stage 1 (规格符合性) 和 Stage 2 (代码质量)'
            );
          }
        }
      }
    }
  }
  return report;
}

module.exports = { run, section: 'Orchestration 产物检查' };
