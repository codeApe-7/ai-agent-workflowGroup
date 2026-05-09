'use strict';

const fs = require('fs');
const path = require('path');
const { validateAgainstSchema, loadSchema } = require('./validate.cjs');

const ROOT = path.resolve(__dirname, '..', '..', '..');
const COORDINATION_ROOT = path.join(ROOT, '.orchestration');
const SCHEMAS_ROOT = path.join(ROOT, 'schemas', 'orchestration');
const SCHEMA_VERSION = '1.0';

const TERMINAL_STATES = new Set(['completed', 'failed', 'blocked']);
const VALID_STATES = ['not_started', 'running', 'blocked', 'completed', 'failed'];

// ─── Path helpers ───

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
  return path.join(COORDINATION_ROOT, slugify(sessionName, 'session'));
}

function workerDir(sessionName, workerName) {
  return path.join(sessionDir(sessionName), slugify(workerName, 'worker'));
}

function workerArtifacts(sessionName, workerName) {
  const dir = workerDir(sessionName, workerName);
  return {
    dir,
    task: path.join(dir, 'task.json'),
    handoff: path.join(dir, 'handoff.json'),
    status: path.join(dir, 'status.json')
  };
}

function sessionMetaPath(sessionName) {
  return path.join(sessionDir(sessionName), 'session.json');
}

function sessionPlanPath(sessionName) {
  return path.join(sessionDir(sessionName), 'plan.json');
}

// ─── IO ───

function ensureDir(dirPath) {
  fs.mkdirSync(dirPath, { recursive: true });
}

function readJson(filePath) {
  if (!fs.existsSync(filePath)) return null;
  try {
    return JSON.parse(fs.readFileSync(filePath, 'utf8'));
  } catch (error) {
    throw new Error(`failed to parse ${relPosix(filePath)}: ${error.message}`);
  }
}

function writeJson(filePath, data) {
  ensureDir(path.dirname(filePath));
  fs.writeFileSync(filePath, JSON.stringify(data, null, 2) + '\n', 'utf8');
}

// ─── Session-level ───

function readSessionMeta(sessionName) {
  return readJson(sessionMetaPath(sessionName));
}

function writeSessionMeta(sessionName, meta) {
  writeJson(sessionMetaPath(sessionName), meta);
}

function initSession(sessionName) {
  const slug = slugify(sessionName, 'session');
  const dir = sessionDir(sessionName);
  ensureDir(dir);
  const metaPath = sessionMetaPath(sessionName);
  if (!fs.existsSync(metaPath)) {
    const meta = {
      schemaVersion: SCHEMA_VERSION,
      name: slug,
      label: sessionName,
      createdAt: timestamp(),
      workers: []
    };
    writeJson(metaPath, meta);
  }
  return dir;
}

function registerWorker(sessionName, workerName) {
  const slug = slugify(workerName, 'worker');
  const meta = readSessionMeta(sessionName) || {
    schemaVersion: SCHEMA_VERSION,
    name: slugify(sessionName, 'session'),
    label: sessionName,
    createdAt: timestamp(),
    workers: []
  };
  if (!Array.isArray(meta.workers)) meta.workers = [];
  if (!meta.workers.includes(slug)) meta.workers.push(slug);
  meta.updatedAt = timestamp();
  writeSessionMeta(sessionName, meta);
}

function touchSession(sessionName) {
  const meta = readSessionMeta(sessionName);
  if (!meta) return;
  meta.updatedAt = timestamp();
  writeSessionMeta(sessionName, meta);
}

// ─── Worker artifacts: builders ───

function buildTask({ sessionName, workerName, agent, objective, context = [], deliverables = [], dependsOn = [], lightweight = false }) {
  return {
    schemaVersion: SCHEMA_VERSION,
    session: slugify(sessionName, 'session'),
    worker: slugify(workerName, 'worker'),
    agent,
    createdAt: timestamp(),
    objective: objective.trim(),
    context: context.filter(Boolean),
    deliverables: deliverables.filter(Boolean),
    dependsOn: dependsOn.filter(Boolean),
    lightweight: Boolean(lightweight),
    completionRules: [
      '不再向下派遣 subagent，结果写进最终响应',
      '主会话负责把响应写进 handoff.json',
      '主会话负责更新 status.json'
    ]
  };
}

function buildHandoff({ sessionName, workerName }) {
  return {
    schemaVersion: SCHEMA_VERSION,
    session: slugify(sessionName, 'session'),
    worker: slugify(workerName, 'worker'),
    summary: null,
    filesChanged: [],
    validation: null,
    followUps: [],
    notes: [],
    finalizedAt: null
  };
}

function buildStatus({ sessionName, workerName, state = 'not_started', lightweight = false, details = null }) {
  const at = timestamp();
  return {
    schemaVersion: SCHEMA_VERSION,
    session: slugify(sessionName, 'session'),
    worker: slugify(workerName, 'worker'),
    state,
    updatedAt: at,
    lightweight: Boolean(lightweight),
    details: details || null,
    history: [{ state, at, details: details || null }]
  };
}

// ─── Worker operations ───

function createWorker(spec) {
  const { sessionName, workerName, lightweight = false } = spec;
  if (!sessionName) throw new Error('sessionName is required');
  if (!workerName) throw new Error('workerName is required');
  if (!spec.agent) throw new Error('agent is required');
  if (!spec.objective) throw new Error('objective is required');

  const artifacts = workerArtifacts(sessionName, workerName);
  ensureDir(artifacts.dir);
  // task.json 总是写入（统一 shape）；轻量 worker 通过 task.lightweight=true 区分，
  // 而非通过文件缺失。hook 与下游消费者按字段判断，不靠 fs.exists。
  writeJson(artifacts.task, buildTask(spec));
  writeJson(artifacts.handoff, buildHandoff({ sessionName, workerName }));
  writeJson(artifacts.status, buildStatus({ sessionName, workerName, lightweight }));
  registerWorker(sessionName, workerName);
  return { ...artifacts, lightweight };
}

function isLightweight(sessionName, workerName) {
  const status = readJson(workerArtifacts(sessionName, workerName).status);
  return Boolean(status && status.lightweight);
}

function updateStatus(sessionName, workerName, state, details = '') {
  if (!VALID_STATES.includes(state)) {
    throw new Error(`invalid state '${state}'. Valid: ${VALID_STATES.join(' | ')}`);
  }
  const artifacts = workerArtifacts(sessionName, workerName);
  const existing = readJson(artifacts.status) || buildStatus({ sessionName, workerName });
  const at = timestamp();
  const entry = { state, at, details: details ? String(details).trim() : null };
  existing.state = state;
  existing.updatedAt = at;
  existing.details = entry.details;
  if (!Array.isArray(existing.history)) existing.history = [];
  existing.history.push(entry);
  writeJson(artifacts.status, existing);
  touchSession(sessionName);
  return artifacts.status;
}

function appendHandoff(sessionName, workerName, sectionTitle, content) {
  if (!sectionTitle) throw new Error('section title required');
  if (!content) throw new Error('content required');
  const artifacts = workerArtifacts(sessionName, workerName);
  const existing = readJson(artifacts.handoff) || buildHandoff({ sessionName, workerName });
  if (!Array.isArray(existing.notes)) existing.notes = [];
  existing.notes.push({
    section: String(sectionTitle).trim(),
    content: String(content).trim(),
    addedAt: timestamp()
  });
  writeJson(artifacts.handoff, existing);
  touchSession(sessionName);
  return artifacts.handoff;
}

/**
 * Finalize handoff. fields keys: summary, filesChanged, validation, followUps, stages.
 * - summary: string
 * - filesChanged: string[] | {path, action?, note?}[]
 * - validation: string
 * - followUps: string[]
 * - stages: { spec?: string, quality?: string }   (code-reviewer only)
 */
function completeHandoff(sessionName, workerName, fields = {}) {
  const artifacts = workerArtifacts(sessionName, workerName);
  const existing = readJson(artifacts.handoff) || buildHandoff({ sessionName, workerName });

  if (fields.summary !== undefined) existing.summary = String(fields.summary).trim() || null;
  if (fields.validation !== undefined) existing.validation = String(fields.validation).trim() || null;
  if (fields.filesChanged !== undefined) existing.filesChanged = normalizeFilesChanged(fields.filesChanged);
  if (fields.followUps !== undefined) existing.followUps = normalizeFollowUps(fields.followUps);
  if (fields.stages !== undefined) {
    const stages = {};
    if (fields.stages.spec) stages.spec = String(fields.stages.spec).trim();
    if (fields.stages.quality) stages.quality = String(fields.stages.quality).trim();
    if (Object.keys(stages).length > 0) existing.stages = stages;
  }

  existing.finalizedAt = timestamp();
  writeJson(artifacts.handoff, existing);
  touchSession(sessionName);
  return artifacts.handoff;
}

function normalizeFilesChanged(input) {
  if (Array.isArray(input)) return input;
  if (typeof input !== 'string') return [];
  // Accept newline- or comma-separated string for CLI ergonomics
  return input
    .split(/[\n,]/)
    .map(s => s.trim())
    .filter(Boolean);
}

function normalizeFollowUps(input) {
  if (Array.isArray(input)) return input;
  if (typeof input !== 'string') return [];
  return input
    .split(/\n/)
    .map(s => s.replace(/^[-*]\s*/, '').trim())
    .filter(Boolean);
}

// ─── Plan aggregation ───

function listWorkers(sessionName) {
  const dir = sessionDir(sessionName);
  if (!fs.existsSync(dir)) return [];
  return fs.readdirSync(dir, { withFileTypes: true })
    .filter(e => e.isDirectory())
    .map(e => e.name)
    .sort();
}

function buildPlan(sessionName) {
  const workers = listWorkers(sessionName).map(name => {
    const artifacts = workerArtifacts(sessionName, name);
    const task = readJson(artifacts.task);
    const status = readJson(artifacts.status);
    const handoff = readJson(artifacts.handoff);
    return {
      name,
      agent: (task && task.agent) || (handoff && handoff.agent) || 'unknown',
      state: (status && status.state) || 'not_started',
      lightweight: Boolean(status && status.lightweight),
      dependsOn: (task && Array.isArray(task.dependsOn)) ? task.dependsOn : [],
      objective: (task && task.objective) || undefined,
      finalizedAt: (handoff && handoff.finalizedAt) || null
    };
  });

  const completedSet = new Set(workers.filter(w => w.state === 'completed').map(w => w.name));
  const buckets = { ready: [], running: [], blocked: [], completed: [], failed: [], waiting: [] };
  for (const w of workers) {
    if (w.state === 'running') buckets.running.push(w.name);
    else if (w.state === 'blocked') buckets.blocked.push(w.name);
    else if (w.state === 'completed') buckets.completed.push(w.name);
    else if (w.state === 'failed') buckets.failed.push(w.name);
    else {
      const allDepsDone = w.dependsOn.every(d => completedSet.has(d));
      if (allDepsDone) buckets.ready.push(w.name);
      else buckets.waiting.push(w.name);
    }
  }

  return {
    schemaVersion: SCHEMA_VERSION,
    session: slugify(sessionName, 'session'),
    generatedAt: timestamp(),
    workers,
    buckets
  };
}

function refreshPlan(sessionName) {
  const plan = buildPlan(sessionName);
  writeJson(sessionPlanPath(sessionName), plan);
  return sessionPlanPath(sessionName);
}

// ─── Validation ───

const SCHEMA_FILES = {
  session: 'session.schema.json',
  plan: 'plan.schema.json',
  task: 'task.schema.json',
  handoff: 'handoff.schema.json',
  status: 'status.schema.json'
};

function getSchema(kind) {
  const file = SCHEMA_FILES[kind];
  if (!file) throw new Error(`unknown schema kind: ${kind}`);
  return loadSchema(path.join(SCHEMAS_ROOT, file));
}

function validateArtifact(kind, data) {
  const schema = getSchema(kind);
  return validateAgainstSchema(data, schema);
}

function validateSession(sessionName) {
  const errors = [];
  const meta = readJson(sessionMetaPath(sessionName));
  if (!meta) {
    errors.push({ file: relPosix(sessionMetaPath(sessionName)), problems: ['file missing'] });
  } else {
    const r = validateArtifact('session', meta);
    if (!r.valid) errors.push({ file: relPosix(sessionMetaPath(sessionName)), problems: r.errors });
  }

  const planFile = sessionPlanPath(sessionName);
  if (fs.existsSync(planFile)) {
    const plan = readJson(planFile);
    const r = validateArtifact('plan', plan);
    if (!r.valid) errors.push({ file: relPosix(planFile), problems: r.errors });
  }

  for (const worker of listWorkers(sessionName)) {
    const a = workerArtifacts(sessionName, worker);
    for (const kind of ['task', 'handoff', 'status']) {
      const file = a[kind];
      const data = readJson(file);
      if (!data) {
        errors.push({ file: relPosix(file), problems: ['file missing or unreadable'] });
        continue;
      }
      const r = validateArtifact(kind, data);
      if (!r.valid) errors.push({ file: relPosix(file), problems: r.errors });
    }
  }

  return errors;
}

module.exports = {
  // constants
  COORDINATION_ROOT,
  ROOT,
  SCHEMAS_ROOT,
  SCHEMA_VERSION,
  TERMINAL_STATES,
  VALID_STATES,
  // path helpers
  sessionDir,
  workerDir,
  workerArtifacts,
  sessionMetaPath,
  sessionPlanPath,
  // session ops
  initSession,
  readSessionMeta,
  writeSessionMeta,
  registerWorker,
  // worker ops
  createWorker,
  isLightweight,
  updateStatus,
  appendHandoff,
  completeHandoff,
  // plan
  listWorkers,
  buildPlan,
  refreshPlan,
  // validation
  validateArtifact,
  validateSession,
  // utils
  slugify,
  timestamp,
  relPosix,
  toPosix,
  readJson,
  writeJson
};
