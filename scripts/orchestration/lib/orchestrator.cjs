'use strict';

const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..', '..', '..');
const COORDINATION_ROOT = path.join(ROOT, '.orchestration');

function toPosix(p) {
  return p.split(path.sep).join('/');
}

function relPosix(target) {
  return toPosix(path.relative(ROOT, target));
}

function slugify(value, fallback = 'item') {
  const normalized = String(value || '')
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');
  return normalized || fallback;
}

function timestamp() {
  return new Date().toISOString().replace(/\.\d+Z$/, 'Z');
}

function sessionDir(sessionName) {
  const slug = slugify(sessionName, 'session');
  return path.join(COORDINATION_ROOT, slug);
}

function workerDir(sessionName, workerName) {
  return path.join(sessionDir(sessionName), slugify(workerName, 'worker'));
}

function workerArtifacts(sessionName, workerName) {
  const dir = workerDir(sessionName, workerName);
  return {
    dir,
    task: path.join(dir, 'task.md'),
    handoff: path.join(dir, 'handoff.md'),
    status: path.join(dir, 'status.md')
  };
}

function ensureDir(dirPath) {
  fs.mkdirSync(dirPath, { recursive: true });
}

function writeFile(filePath, content) {
  ensureDir(path.dirname(filePath));
  fs.writeFileSync(filePath, content.endsWith('\n') ? content : content + '\n', 'utf8');
}

function buildTaskFile({ sessionName, workerName, agent, objective, context = [], deliverables = [] }) {
  const ctx = context.length > 0 ? context.map(line => `- ${line}`).join('\n') : '- _无_';
  const deliv = deliverables.length > 0 ? deliverables.map(line => `- ${line}`).join('\n') : '- 见 handoff.md 模板';
  const artifacts = workerArtifacts(sessionName, workerName);
  return [
    `# Worker Task: ${workerName}`,
    '',
    `- Session: \`${sessionName}\``,
    `- Agent: \`${agent}\``,
    `- Created: ${timestamp()}`,
    `- Handoff: \`${relPosix(artifacts.handoff)}\``,
    `- Status: \`${relPosix(artifacts.status)}\``,
    '',
    '## Objective',
    objective.trim(),
    '',
    '## Context',
    ctx,
    '',
    '## Deliverables',
    deliv,
    '',
    '## Completion Rules',
    '- 不再向下派遣 subagent，结果写进最终响应',
    '- 主会话负责把响应抄写进 `handoff.md`',
    '- 主会话负责更新 `status.md`'
  ].join('\n');
}

function buildHandoffFile({ workerName }) {
  return [
    `# Handoff: ${workerName}`,
    '',
    '## Summary',
    '- Pending',
    '',
    '## Files Changed',
    '- Pending',
    '',
    '## Validation',
    '- Pending',
    '',
    '## Follow-ups',
    '- Pending'
  ].join('\n');
}

function buildStatusFile({ workerName, state = 'not_started', lightweight = false }) {
  const lines = [
    `# Status: ${workerName}`,
    '',
    `- State: ${state}`,
    `- Updated: ${timestamp()}`
  ];
  if (lightweight) lines.push('- Lightweight: true');
  return lines.join('\n');
}

function createWorker(spec) {
  const { sessionName, workerName, lightweight = false } = spec;
  if (!sessionName) throw new Error('sessionName is required');
  if (!workerName) throw new Error('workerName is required');
  if (!spec.agent) throw new Error('agent is required');
  if (!spec.objective) throw new Error('objective is required');

  const artifacts = workerArtifacts(sessionName, workerName);
  ensureDir(artifacts.dir);
  if (!lightweight) {
    writeFile(artifacts.task, buildTaskFile(spec));
  }
  writeFile(artifacts.handoff, buildHandoffFile({ workerName }));
  writeFile(artifacts.status, buildStatusFile({ workerName, lightweight }));
  return { ...artifacts, lightweight };
}

function isLightweight(statusFile) {
  try {
    const raw = fs.readFileSync(statusFile, 'utf8');
    return /^\s*-\s*Lightweight:\s*true/m.test(raw);
  } catch (_error) {
    return false;
  }
}

function updateStatus(sessionName, workerName, state, details = '') {
  const artifacts = workerArtifacts(sessionName, workerName);
  const lightweight = isLightweight(artifacts.status);
  const body = [
    `# Status: ${workerName}`,
    '',
    `- State: ${state}`,
    `- Updated: ${timestamp()}`
  ];
  if (lightweight) body.push('- Lightweight: true');
  if (details) body.push('', details.trim());
  writeFile(artifacts.status, body.join('\n'));
  return artifacts.status;
}

function appendHandoff(sessionName, workerName, sectionTitle, content) {
  const artifacts = workerArtifacts(sessionName, workerName);
  const existing = fs.existsSync(artifacts.handoff)
    ? fs.readFileSync(artifacts.handoff, 'utf8')
    : buildHandoffFile({ workerName });
  const block = `\n## ${sectionTitle} (${timestamp()})\n${content.trim()}\n`;
  writeFile(artifacts.handoff, existing.replace(/\s+$/, '') + block);
  return artifacts.handoff;
}

const STANDARD_SECTIONS = ['Summary', 'Files Changed', 'Validation', 'Follow-ups'];

function replaceStandardSection(body, title, content) {
  const trimmed = (content || '').trim() || '- _未提供_';
  const escaped = title.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  const re = new RegExp(`(^|\\n)## ${escaped}\\n[\\s\\S]*?(?=\\n## |$)`);
  const replacement = `$1## ${title}\n${trimmed}\n`;
  if (re.test(body)) return body.replace(re, replacement);
  return body.replace(/\s+$/, '') + `\n\n## ${title}\n${trimmed}\n`;
}

function completeHandoff(sessionName, workerName, fields = {}) {
  const artifacts = workerArtifacts(sessionName, workerName);
  let body = fs.existsSync(artifacts.handoff)
    ? fs.readFileSync(artifacts.handoff, 'utf8')
    : buildHandoffFile({ workerName });
  const map = {
    Summary: fields.summary,
    'Files Changed': fields.files,
    Validation: fields.validation,
    'Follow-ups': fields.followUps
  };
  for (const title of STANDARD_SECTIONS) {
    if (map[title] !== undefined && map[title] !== null) {
      body = replaceStandardSection(body, title, map[title]);
    }
  }
  const stamp = `\n<!-- finalized: ${timestamp()} -->\n`;
  body = body.replace(/\n<!-- finalized: [^>]+ -->\n?/g, '');
  writeFile(artifacts.handoff, body.replace(/\s+$/, '') + stamp);
  return artifacts.handoff;
}

module.exports = {
  COORDINATION_ROOT,
  ROOT,
  sessionDir,
  workerDir,
  workerArtifacts,
  createWorker,
  updateStatus,
  appendHandoff,
  completeHandoff,
  isLightweight,
  slugify,
  timestamp,
  relPosix,
  toPosix
};
