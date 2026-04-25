#!/usr/bin/env node
'use strict';

// Hook dispatcher —— 按事件类型路由到对应 checks。
// 每个 check 模块必须导出 { run(): Report, section: string }。
// 任一 FAIL → exit 2（错误回注 Claude 上下文）；仅 WARN → exit 0。

const { readJsonStdinSync } = require('./lib/runner.cjs');

const DISPATCH = {
  'post-edit': [
    require('./checks/claude-md-size.cjs'),
    require('./checks/empty-docs.cjs')
  ],
  stop: [
    require('./checks/structure.cjs'),
    require('./checks/claude-md-size.cjs'),
    require('./checks/empty-docs.cjs'),
    require('./checks/delegation-antipatterns.cjs'),
    require('./checks/workflow-state.cjs'),
    require('./checks/orchestration-artifacts.cjs')
  ],
  'subagent-stop': [
    require('./checks/structure.cjs'),
    require('./checks/orchestration-artifacts.cjs')
  ]
};

function main() {
  const [, , event] = process.argv;
  const checks = DISPATCH[event];
  if (!checks) {
    console.error(`unknown event: ${event}`);
    process.exit(1);
  }

  readJsonStdinSync();

  const sections = [];
  let hasFail = false;
  for (const check of checks) {
    const report = check.run();
    if (!report.hasAny()) continue;
    sections.push(report.render(check.section));
    if (report.hasFail()) hasFail = true;
  }

  if (sections.length === 0) process.exit(0);

  const output = sections.join('\n\n');
  if (hasFail) {
    console.error('Harness 检测到问题：');
    console.error('');
    console.error(output);
    console.error('');
    console.error('修复上述 [FAIL] 项后重试。');
    process.exit(2);
  }

  console.log(output);
  process.exit(0);
}

main();
