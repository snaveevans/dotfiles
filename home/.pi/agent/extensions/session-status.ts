/**
 * Write this Pi session's live state so `wt` and the Kitty tab picker can
 * show it the same way they show Claude Code. Pi has no `claude agents --json`
 * equivalent, and a `pi` process is just `node` on the process table, so the
 * only reliable signal is one we publish ourselves.
 *
 * Each interactive session writes ~/.pi/agent/status/<pid>.json and removes
 * it on shutdown. Readers treat a dead pid as gone, so a crash can't leave a
 * stale "working" glyph behind.
 */
import { mkdirSync, renameSync, unlinkSync, writeFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

type SessionState = "working" | "idle";

const STATUS_DIR = join(homedir(), ".pi", "agent", "status");
const STATUS_FILE = join(STATUS_DIR, `${process.pid}.json`);

function writeStatus(ctx: ExtensionContext, state: SessionState): void {
  if (ctx.mode !== "tui") {
    return;
  }

  mkdirSync(STATUS_DIR, { recursive: true });

  const payload = `${JSON.stringify({
    pid: process.pid,
    cwd: ctx.cwd,
    state,
    updatedAt: Date.now(),
  })}\n`;
  const tmp = `${STATUS_FILE}.${process.pid}.tmp`;

  writeFileSync(tmp, payload);
  renameSync(tmp, STATUS_FILE);
}

function clearStatus(): void {
  try {
    unlinkSync(STATUS_FILE);
  } catch {
    // already gone, or never written (print/rpc mode)
  }
}

function currentState(ctx: ExtensionContext): SessionState {
  return ctx.isIdle() ? "idle" : "working";
}

export default function (pi: ExtensionAPI) {
  pi.on("session_start", async (_event, ctx) => {
    writeStatus(ctx, currentState(ctx));
  });

  pi.on("agent_start", async (_event, ctx) => {
    writeStatus(ctx, "working");
  });

  // agent_end can still be followed by a retry, compaction, or queued
  // follow-up. agent_settled is the "Pi will not continue on its own" hook.
  pi.on("agent_settled", async (_event, ctx) => {
    writeStatus(ctx, currentState(ctx));
  });

  pi.on("session_shutdown", async () => {
    clearStatus();
  });
}
