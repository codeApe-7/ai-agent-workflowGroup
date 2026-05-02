#!/usr/bin/env node
'use strict';

const fs = require('fs');
const path = require('path');
const {
  COORDINATION_ROOT,
  ROOT,
  sessionDir,
  workerArtifacts,
  createWorker,
  updateStatus,
  appendHandoff,
  completeHandoff,
  slugify,
  relPosix
} = require('./lib/orchestrator.cjs');

const COMMANDS = ['init', 'add-worker', 'status', 'set-status', 'append', 'complete', 'list', 'help'];

function usage() {
  console.log([
    'Usage:',
    '  node scripts/orchestration/session.js init <session-name>',
    '  node scripts/orchestration/session.cjs add-worker <session> <worker> --agent <name> --objective <text>',
    '                                                       [--context <line>]... [--deliverable <line>]... [--lightweight]',
    '  node scripts/orchestration/session.js set-status <session> <worker> <state> [--details <text>]',
    '  node scripts/orchestration/session.js append <session> <worker> <section> --content <text>',
    '  node scripts/orchestration/session.cjs complete <session> <worker>',
    '                                                       [--summary <md>] [--files <md>]',
    '                                                       [--validation <md>] [--follow-ups <md>]',
    '  node scripts/orchestration/session.js status <session>',
    '  node scripts/orchestration/session.js list',
    '',
    'States: not_started | running | blocked | completed | failed',
    `Coordination root: ${relPosix(COORDINATION_ROOT)}/`
  ].join('\n'));
}

const BOOLEAN_FLAGS = new Set(['lightweight']);

function parseFlags(args) {
  const flags = { context: [], deliverable: [] };
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
      if (key === 'context' || key === 'deliverable') {
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
  if (!name) throw new Error('session-name is required');
  const dir = sessionDir(name);
  fs.mkdirSync(dir, { recursive: true });
  const meta = path.join(dir, 'session.json');
  if (!fs.existsSync(meta)) {
    fs.writeFileSync(meta, JSON.stringify({
      name: slugify(name, 'session'),
      label: name,
      createdAt: new Date().toISOString()
    }, null, 2) + '\n', 'utf8');
  }
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
    context: flags.context,
    deliverables: flags.deliverable,
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
  const fields = {
    summary: flags.summary,
    files: flags.files,
    validation: flags.validation,
    followUps: flags['follow-ups']
  };
  const provided = Object.values(fields).some(v => v !== undefined && v !== null);
  if (!provided) {
    throw new Error('at least one of --summary | --files | --validation | --follow-ups is required');
  }
  const file = completeHandoff(session, worker, fields);
  console.log(relPosix(file));
}

function cmdStatus(session) {
  if (!session) throw new Error('session-name is required');
  const dir = sessionDir(session);
  if (!fs.existsSync(dir)) {
    console.log(`(no such session: ${session})`);
    return;
  }
  const workers = fs.readdirSync(dir, { withFileTypes: true })
    .filter(entry => entry.isDirectory())
    .map(entry => entry.name);
  const out = workers.map(worker => {
    const statusPath = workerArtifacts(session, worker).status;
    const content = fs.existsSync(statusPath) ? fs.readFileSync(statusPath, 'utf8') : '(missing)';
    const stateLine = content.split('\n').find(line => line.startsWith('- State:'));
    return `${worker}\t${stateLine ? stateLine.replace('- State:', '').trim() : '?'}`;
  });
  console.log(out.join('\n') || '(no workers)');
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
