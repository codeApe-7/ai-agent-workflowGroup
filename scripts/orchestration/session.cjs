#!/usr/bin/env node
'use strict';

const fs = require('fs');
const path = require('path');
const {
  COORDINATION_ROOT,
  ROOT,
  sessionDir,
  workerArtifacts,
  initSession,
  createWorker,
  updateStatus,
  appendHandoff,
  completeHandoff,
  refreshPlan,
  buildPlan,
  validateSession,
  readJson,
  slugify,
  relPosix
} = require('./lib/orchestrator.cjs');

const COMMANDS = ['init', 'add-worker', 'status', 'set-status', 'append', 'complete', 'plan', 'validate', 'list', 'help'];

function usage() {
  console.log([
    'Usage:',
    '  node scripts/orchestration/session.cjs init <session>',
    '  node scripts/orchestration/session.cjs add-worker <session> <worker> --agent <name> --objective <text>',
    '                                                  [--context <line>]... [--deliverable <line>]...',
    '                                                  [--depends-on <worker>]... [--lightweight]',
    '  node scripts/orchestration/session.cjs set-status <session> <worker> <state> [--details <text>]',
    '  node scripts/orchestration/session.cjs append <session> <worker> <section> --content <text>',
    '  node scripts/orchestration/session.cjs complete <session> <worker>',
    '                                                  [--summary <text>] [--validation <text>]',
    '                                                  [--files <newline-or-comma-separated>]',
    '                                                  [--follow-ups <newline-separated>]',
    '                                                  [--stage-spec <text>] [--stage-quality <text>]',
    '  node scripts/orchestration/session.cjs status <session>',
    '  node scripts/orchestration/session.cjs plan <session>      # refresh and print plan.json',
    '  node scripts/orchestration/session.cjs validate <session>  # validate all artifacts against schemas',
    '  node scripts/orchestration/session.cjs list',
    '',
    'States: not_started | running | blocked | completed | failed',
    `Coordination root: ${relPosix(COORDINATION_ROOT)}/`,
    'Schemas:           schemas/orchestration/'
  ].join('\n'));
}

const BOOLEAN_FLAGS = new Set(['lightweight']);
const REPEATABLE_FLAGS = new Set(['context', 'deliverable', 'depends-on']);

function parseFlags(args) {
  const flags = {};
  for (const k of REPEATABLE_FLAGS) flags[k] = [];
  const positional = [];
  for (let i = 0; i < args.length; i += 1) {
    const arg = args[i];
    if (arg.startsWith('--')) {
      const key = arg.slice(2);
      if (BOOLEAN_FLAGS.has(key)) {
        flags[key] = true;
        continue;
      }
      const value = args[i + 1];
      if (REPEATABLE_FLAGS.has(key)) {
        flags[key].push(value);
      } else {
        flags[key] = value;
      }
      i += 1;
    } else {
      positional.push(arg);
    }
  }
  return { flags, positional };
}

function cmdInit(name) {
  if (!name) throw new Error('session name is required');
  const dir = initSession(name);
  console.log(relPosix(dir));
}

function cmdAddWorker(session, worker, flags) {
  if (!session || !worker) throw new Error('session and worker names are required');
  if (!flags.agent) throw new Error('--agent is required');
  if (!flags.objective) throw new Error('--objective is required');
  const artifacts = createWorker({
    sessionName: session,
    workerName: worker,
    agent: flags.agent,
    objective: flags.objective,
    context: flags.context || [],
    deliverables: flags.deliverable || [],
    dependsOn: flags['depends-on'] || [],
    lightweight: Boolean(flags.lightweight)
  });
  const out = {
    handoff: relPosix(artifacts.handoff),
    status: relPosix(artifacts.status)
  };
  if (!artifacts.lightweight) out.task = relPosix(artifacts.task);
  if (artifacts.lightweight) out.lightweight = true;
  console.log(JSON.stringify(out, null, 2));
}

function cmdSetStatus(session, worker, state, flags) {
  if (!session || !worker || !state) throw new Error('session, worker, state are required');
  const file = updateStatus(session, worker, state, flags.details || '');
  console.log(relPosix(file));
}

function cmdAppend(session, worker, section, flags) {
  if (!session || !worker || !section) throw new Error('session, worker, section are required');
  if (!flags.content) throw new Error('--content is required');
  const file = appendHandoff(session, worker, section, flags.content);
  console.log(relPosix(file));
}

function cmdComplete(session, worker, flags) {
  if (!session || !worker) throw new Error('session and worker names are required');
  const fields = {};
  if (flags.summary !== undefined) fields.summary = flags.summary;
  if (flags.validation !== undefined) fields.validation = flags.validation;
  if (flags.files !== undefined) fields.filesChanged = flags.files;
  if (flags['follow-ups'] !== undefined) fields.followUps = flags['follow-ups'];
  const stages = {};
  if (flags['stage-spec'] !== undefined) stages.spec = flags['stage-spec'];
  if (flags['stage-quality'] !== undefined) stages.quality = flags['stage-quality'];
  if (Object.keys(stages).length > 0) fields.stages = stages;

  if (Object.keys(fields).length === 0) {
    throw new Error('at least one of --summary | --validation | --files | --follow-ups | --stage-spec | --stage-quality is required');
  }
  const file = completeHandoff(session, worker, fields);
  console.log(relPosix(file));
}

function cmdStatus(session) {
  if (!session) throw new Error('session name is required');
  const dir = sessionDir(session);
  if (!fs.existsSync(dir)) {
    console.log(`(no such session: ${session})`);
    return;
  }
  const plan = buildPlan(session);
  if (plan.workers.length === 0) {
    console.log('(no workers)');
    return;
  }
  const lines = plan.workers.map(w => {
    const lw = w.lightweight ? ' [lightweight]' : '';
    const dep = w.dependsOn.length > 0 ? ` ⟵ ${w.dependsOn.join(',')}` : '';
    return `${w.name}\t${w.state}${lw}${dep}`;
  });
  console.log(lines.join('\n'));
  console.log('');
  console.log(`ready: ${plan.buckets.ready.join(', ') || '∅'}`);
  console.log(`running: ${plan.buckets.running.join(', ') || '∅'}`);
  console.log(`blocked: ${plan.buckets.blocked.join(', ') || '∅'}`);
  console.log(`waiting: ${plan.buckets.waiting.join(', ') || '∅'}`);
  console.log(`completed: ${plan.buckets.completed.join(', ') || '∅'}`);
  if (plan.buckets.failed.length > 0) console.log(`failed: ${plan.buckets.failed.join(', ')}`);
}

function cmdPlan(session) {
  if (!session) throw new Error('session name is required');
  const file = refreshPlan(session);
  console.log(relPosix(file));
  console.log(JSON.stringify(readJson(file), null, 2));
}

function cmdValidate(session) {
  if (!session) throw new Error('session name is required');
  const errors = validateSession(session);
  if (errors.length === 0) {
    console.log(`✔ session '${slugify(session, 'session')}' artifacts conform to schemas/orchestration/*.schema.json`);
    return;
  }
  console.error(`✖ ${errors.length} file(s) failed validation:`);
  for (const e of errors) {
    console.error(`  ${e.file}`);
    for (const p of e.problems) console.error(`    - ${p}`);
  }
  process.exit(1);
}

function cmdList() {
  if (!fs.existsSync(COORDINATION_ROOT)) {
    console.log('(no sessions)');
    return;
  }
  const sessions = fs.readdirSync(COORDINATION_ROOT, { withFileTypes: true })
    .filter(entry => entry.isDirectory() && !entry.name.startsWith('.'))
    .map(entry => entry.name);
  console.log(sessions.join('\n') || '(no sessions)');
}

function main() {
  const [, , command, ...rest] = process.argv;
  if (!command || command === 'help' || !COMMANDS.includes(command)) {
    usage();
    process.exit(command && command !== 'help' ? 1 : 0);
  }
  const { flags, positional } = parseFlags(rest);
  try {
    switch (command) {
      case 'init':
        cmdInit(positional[0]);
        break;
      case 'add-worker':
        cmdAddWorker(positional[0], positional[1], flags);
        break;
      case 'set-status':
        cmdSetStatus(positional[0], positional[1], positional[2], flags);
        break;
      case 'append':
        cmdAppend(positional[0], positional[1], positional[2], flags);
        break;
      case 'complete':
        cmdComplete(positional[0], positional[1], flags);
        break;
      case 'status':
        cmdStatus(positional[0]);
        break;
      case 'plan':
        cmdPlan(positional[0]);
        break;
      case 'validate':
        cmdValidate(positional[0]);
        break;
      case 'list':
        cmdList();
        break;
      default:
        usage();
        process.exit(1);
    }
  } catch (error) {
    console.error(`error: ${error.message}`);
    process.exit(1);
  }
}

main();
