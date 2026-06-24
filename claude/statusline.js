#!/usr/bin/env node
"use strict";

const fs = require("fs");
const path = require("path");
const { spawn } = require("child_process");

const c = {
  yellow:  "\x1b[38;5;214m",
  green:   "\x1b[38;5;142m",
  red:     "\x1b[38;5;167m",
  orange:  "\x1b[38;5;208m",
  aqua:    "\x1b[38;5;108m",
  blue:    "\x1b[38;5;109m",
  gray:    "\x1b[38;5;241m",
  darkgray:"\x1b[38;5;239m",
  reset:   "\x1b[0m",
};

const sep = `${c.gray}│${c.reset}`;
const CLAUDE_DIR = path.join(process.env.HOME || process.env.USERPROFILE || "~", ".claude");
const USAGE_CACHE_PATH = path.join(CLAUDE_DIR, "usage-cache.json");
const REFRESH_SCRIPT = path.join(CLAUDE_DIR, "refresh-quota.js");
const REFRESH_LOCK = path.join(CLAUDE_DIR, ".refresh-lock");
const REFRESH_STALE_MS = 120000; // refresh every 2 minutes
const CACHE_MAX_AGE_MS = 600000; // show ?? if cache >10 minutes old

// --- File readers ---

function readJSON(filepath) {
  try { return JSON.parse(fs.readFileSync(filepath, "utf8")); }
  catch { return null; }
}

// Spawn background refresh if cache is stale and no refresh in progress
function maybeRefresh(cache) {
  const age = cache ? Date.now() - (cache.last_refresh_ms || 0) : Infinity;
  if (age <= REFRESH_STALE_MS) return;

  // Check lock to prevent concurrent refreshes
  try {
    const lockAge = Date.now() - fs.statSync(REFRESH_LOCK).mtimeMs;
    if (lockAge < 30000) return; // refresh already in progress
  } catch { /* no lock file, proceed */ }

  // Write lock before spawning
  try { fs.writeFileSync(REFRESH_LOCK, String(Date.now())); } catch {}

  try {
    const child = spawn(process.execPath, [REFRESH_SCRIPT], {
      detached: true,
      stdio: "ignore",
      windowsHide: true,
    });
    child.unref();
  } catch { /* ignore spawn errors */ }
}

// --- Main ---

let input = "";
process.stdin.setEncoding("utf8");
process.stdin.on("data", (chunk) => (input += chunk));
process.stdin.on("end", () => {
  let data;
  try { data = JSON.parse(input); } catch { data = {}; }

  // Model (+ reasoning effort, when the model supports it)
  const model = (data.model && data.model.display_name) || "…";
  const effort = data.effort && data.effort.level;
  let modelText = model;
  if (effort) {
    // Fold effort into the model's trailing parentheses (e.g. "Opus 4.8 (1M context)")
    modelText = /\)\s*$/.test(modelText)
      ? modelText.replace(/\)\s*$/, `, ${effort})`)
      : `${modelText} (${effort})`;
  }
  const modelStr = `${c.yellow}${modelText}${c.reset}`;

  // Context bar
  const pct = (data.context_window && data.context_window.used_percentage) || 0;
  const filled = Math.round(pct / 10);
  const barColor = pct > 80 ? c.red : pct > 50 ? c.yellow : c.green;
  const ctxBar = `${c.gray}Ctx:${c.reset} ${barColor}${"▓".repeat(filled)}${c.darkgray}${"░".repeat(10 - filled)}${c.reset} ${barColor}${Math.round(pct)}%${c.reset}`;

  // Quota bar from API usage cache
  const usageCache = readJSON(USAGE_CACHE_PATH);
  maybeRefresh(usageCache);

  let quotaStr;
  const cacheAge = usageCache ? Date.now() - (usageCache.last_refresh_ms || 0) : Infinity;
  if (usageCache && usageCache.five_hour && cacheAge < CACHE_MAX_AGE_MS) {
    const util = usageCache.five_hour.utilization;
    // API returns utilization as percentage (0-100)
    const qPct = Math.round(util);
    const qFilled = Math.min(10, Math.round(util / 10));
    const qColor = qPct > 80 ? c.red : qPct >= 50 ? c.yellow : c.green;
    const qBar = `${qColor}${"▓".repeat(qFilled)}${c.darkgray}${"░".repeat(10 - qFilled)}${c.reset}`;

    // Reset countdown
    let countdown = "";
    if (usageCache.five_hour.resets_at) {
      const resetMs = new Date(usageCache.five_hour.resets_at).getTime() - Date.now();
      if (resetMs > 0) {
        const resetH = Math.floor(resetMs / 3600000);
        const resetM = Math.floor((resetMs % 3600000) / 60000);
        countdown = resetH > 0 ? ` ${c.aqua}${resetH}h ${resetM}m${c.reset}` : ` ${c.aqua}${resetM}m${c.reset}`;
      }
    }

    quotaStr = `${c.gray}Quota:${c.reset} ${qBar} ${qColor}${qPct}%${c.reset}${countdown}`;
  } else {
    quotaStr = `${c.gray}Quota:${c.reset} ${c.darkgray}${"░".repeat(10)}${c.reset} ${c.darkgray}??%${c.reset}`;
  }

  // Cost (this session)
  const cost = (data.cost && data.cost.total_cost_usd) || 0;
  const costStr = `${c.gray}Cost:${c.reset} ${c.orange}$${cost.toFixed(2)}${c.reset}`;

  // Duration
  const ms = (data.cost && data.cost.total_duration_ms) || 0;
  const totalSec = Math.floor(ms / 1000);
  const mins = Math.floor(totalSec / 60);
  const secs = totalSec % 60;
  const durStr = `${c.gray}Time:${c.reset} ${c.aqua}${mins}m ${secs}s${c.reset}`;

  // Lines delta
  const added = (data.cost && data.cost.total_lines_added) || 0;
  const removed = (data.cost && data.cost.total_lines_removed) || 0;
  const linesStr = `${c.gray}Lines:${c.reset} ${c.green}+${added}${c.reset} ${c.red}-${removed}${c.reset}`;

  // Project dir
  const dir = (data.workspace && data.workspace.project_dir) || data.cwd || "~";
  const dirName = dir.replace(/\\/g, "/").split("/").pop() || dir;
  const dirStr = `${c.blue}${dirName}${c.reset}`;

  // --- Assemble statusline ---
  const sections = [
    modelStr,
    ctxBar,
    quotaStr,
    costStr,
    durStr,
    linesStr,
    dirStr,
  ];

  process.stdout.write(sections.join(` ${sep} `));
});
