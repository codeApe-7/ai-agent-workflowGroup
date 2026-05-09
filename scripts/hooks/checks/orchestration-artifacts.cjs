'use strict';

const fs = require('fs');
const path = require('path');
const { createReport, ROOT, relPosix, dirExists } = require('../lib/runner.cjs');

const COORD_ROOT = path.join(ROOT, '.orchestration');

function readJsonSafe(filePath) {
  try {
    return JSON.parse(fs.readFileSync(filePath, 'utf8'));
  } catch (_error) {
    return null;
  }
}

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
      const statusFile = path.join(workerDir, 'status.json');
      const handoffFile = path.join(workerDir, 'handoff.json');
      const taskFile = path.join(workerDir, 'task.json');

      // JSON 化后所有 worker 三件套统一：task + handoff + status 都必须存在。
      // 轻量与否通过 task.lightweight / status.lightweight 字段区分，不再靠文件缺失。
      const required = [
        ['task.json', taskFile],
        ['handoff.json', handoffFile],
        ['status.json', statusFile]
      ];

      for (const [name, full] of required) {
        if (!fs.existsSync(full)) {
          report.fail(
            `${relPosix(workerDir)}/ 缺失 ${name}`,
            '用 `node scripts/orchestration/session.cjs add-worker` 创建（轻量加 --lightweight）'
          );
        }
      }

      // code-reviewer 强制双阶段产物
      if (worker.name === 'code-reviewer') {
        const handoff = readJsonSafe(handoffFile);
        if (handoff && handoff.finalizedAt) {
          const stages = handoff.stages || {};
          if (!stages.spec || !stages.quality) {
            report.fail(
              `${relPosix(handoffFile)} 缺少双阶段产物`,
              '审查报告必须填 handoff.stages.spec (Stage 1 规格符合性) + handoff.stages.quality (Stage 2 代码质量)；用 `--stage-spec`/`--stage-quality` 传给 complete 命令'
            );
          }
        }
      }
    }
  }
  return report;
}

module.exports = { run, section: 'Orchestration 产物检查' };
