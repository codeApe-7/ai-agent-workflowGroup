'use strict';

const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..', '..', '..');

function readJsonStdinSync() {
  try {
    const raw = fs.readFileSync(0, 'utf8');
    if (!raw.trim()) return {};
    return JSON.parse(raw);
  } catch (_error) {
    return {};
  }
}

function createReport() {
  const issues = [];
  return {
    fail(msg, fix) {
      issues.push({ level: 'FAIL', msg, fix });
    },
    warn(msg, fix) {
      issues.push({ level: 'WARN', msg, fix });
    },
    hasFail() {
      return issues.some(i => i.level === 'FAIL');
    },
    hasAny() {
      return issues.length > 0;
    },
    render(section) {
      if (issues.length === 0) return '';
      const lines = [`--- ${section} ---`];
      for (const i of issues) {
        lines.push(`[${i.level}] ${i.msg}`);
        if (i.fix) lines.push(`[FIX] ${i.fix}`);
      }
      return lines.join('\n');
    }
  };
}

function relPosix(p) {
  return path.relative(ROOT, p).split(path.sep).join('/');
}

function fileExists(p) {
  try {
    return fs.statSync(path.resolve(ROOT, p)).isFile();
  } catch (_error) {
    return false;
  }
}

function dirExists(p) {
  try {
    return fs.statSync(path.resolve(ROOT, p)).isDirectory();
  } catch (_error) {
    return false;
  }
}

function readFileSafe(p) {
  try {
    return fs.readFileSync(path.resolve(ROOT, p), 'utf8');
  } catch (_error) {
    return null;
  }
}

module.exports = {
  ROOT,
  readJsonStdinSync,
  createReport,
  relPosix,
  fileExists,
  dirExists,
  readFileSafe
};
