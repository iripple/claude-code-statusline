#!/usr/bin/env node
// Auto-configure Claude Code's statusLine to this plugin's bundled script.
// Runs on SessionStart. A user's own (non-plugin) statusLine is left untouched.
const fs = require('fs');
const os = require('os');
const path = require('path');

const root = process.env.CLAUDE_PLUGIN_ROOT || path.resolve(__dirname, '..');
const cfgDir = process.env.CLAUDE_CONFIG_DIR || path.join(os.homedir(), '.claude');
const settingsPath = path.join(cfgDir, 'settings.json');

const isWin = process.platform === 'win32';
const script = path.join(root, isWin ? 'statusline.ps1' : 'statusline.sh');
const command = isWin
  ? `powershell -ExecutionPolicy Bypass -File "${script}"`
  : `bash "${script}"`;

let settings = {};
try {
  settings = JSON.parse(fs.readFileSync(settingsPath, 'utf8').replace(/^﻿/, ''));
} catch (e) { /* missing or invalid -> start fresh */ }

const current = (settings.statusLine && settings.statusLine.command) || '';
const ours = current.includes('claude-code-statusline');

// Set ours only if there is none yet, or the existing one is already ours
// (refreshes the path after a version bump). Never clobber a user's own line.
if (!settings.statusLine || ours) {
  settings.statusLine = { type: 'command', command };
  try {
    fs.mkdirSync(cfgDir, { recursive: true });
    fs.writeFileSync(settingsPath, JSON.stringify(settings, null, 2) + '\n');
  } catch (e) { /* best effort */ }
}
