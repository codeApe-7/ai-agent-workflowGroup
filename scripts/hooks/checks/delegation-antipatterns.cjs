'use strict';

const fs = require('fs');
const path = require('path');
const { createReport, ROOT, relPosix } = require('../lib/runner.cjs');

const SCAN_DIRS = ['docs', 'skills', '.claude'];
const EXCLUDE_FILES = new Set([
  'docs/rules/agents.md',
  'docs/red-flags.md',
  'scripts/hooks/checks/delegation-antipatterns.cjs'
]);

const PATTERNS = [
  {
    re: /\.dev-agents\//g,
    fix: '旧目录已移除；使用 .orchestration/<session>/<worker>/ 或 docs/PROJECT_CONTEXT.md'
  },
  {
    re: /\.orchestration\/(ella|jarvis|kyle)\//g,
    fix: '禁止按角色建协调目录；worker 应按职能（planner/architect/code-reviewer...）命名'
  },
  {
    re: /(读取|加载|load|read)[^\n]{0,20}\.claude\/agents\/[a-z-]+\.md[^\n]{0,20}(你的角色|角色|persona|role)/gi,
    fix: 'Claude Code 原生已自动加载 agent frontmatter，prompt 里不要再让 agent 读自己的定义'
  }
];

function walk(dir, acc = []) {
  let entries;
  try {
    entries = fs.readdirSync(dir, { withFileTypes: true });
  } catch (_error) {
    return acc;
  }
  for (const entry of entries) {
    if (entry.name.startsWith('.') && entry.name !== '.claude') continue;
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      if (entry.name === 'node_modules' || entry.name === 'everything-claude-code') continue;
      walk(full, acc);
    } else if (entry.isFile() && (full.endsWith('.md') || full.endsWith('.toml'))) {
      acc.push(full);
    }
  }
  return acc;
}

function run() {
  const report = createReport();
  const files = SCAN_DIRS.flatMap(dir => walk(path.join(ROOT, dir)));
  for (const file of files) {
    const rel = relPosix(file);
    if (EXCLUDE_FILES.has(rel)) continue;
    const content = fs.readFileSync(file, 'utf8');
    for (const { re, fix } of PATTERNS) {
      re.lastIndex = 0;
      if (re.test(content)) {
        report.fail(`${rel}: 命中反模式 /${re.source}/`, fix);
      }
    }
  }
  return report;
}

module.exports = { run, section: '派遣契约反模式检查' };
