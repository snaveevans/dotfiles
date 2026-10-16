---
status: "accepted"
date: 2026-08-12
decision-makers:
  - "Tyler Evans"
consulted: []
informed: []
---

# Surface OpenCode processes in the Kitty pickers

## Context and Problem Statement

ADR-0004 added an agent-status column driven by `claude agents --json`, but
Claude Code isn't the only agentic coding tool in use - OpenCode is too, and
its sessions were invisible to `wt list` and `cmd+enter o` even though
they're running in the same worktrees.

OpenCode has no equivalent of `claude agents --json`. `opencode session list
--format json` only ever returns historical session metadata (`id`, `title`,
`created`, `updated`, `directory`) - every session it has ever seen, with no
field distinguishing "currently running" from "closed weeks ago," and
nothing describing what a live session is doing right now. There's no
`serve`/`attach` discovery mechanism either: each OpenCode instance can run
a local HTTP server, but nothing publishes which port a given project's
instance is listening on.

The one thing that is reliable: a running OpenCode session is a real OS
process (`~/.opencode/bin/opencode`, or wherever it's installed - a single
compiled binary, not a shell wrapper spawning children), and its working
directory is queryable the same way any process's is, via `lsof -d cwd`.

## Decision Drivers

- the user runs both tools day to day, and the whole point of the status
  column (ADR-0004) is deciding which project to jump back into - missing
  half the agentic sessions on the machine undermines that
- no data source exists that mirrors `claude agents --json`'s precision
  (kind, state/status) - the decision is between showing an honest,
  coarser signal or showing nothing at all
- `wt clean`'s live-session gate (ADR-0004) needs to know about OpenCode
  sessions too, for the same reason it needs to know about Claude ones: a
  worktree a session is actively sitting in shouldn't be deleted out from
  under it

## Considered Options

- Don't surface OpenCode at all - wait for it to ship something equivalent
  to `claude agents --json`
- Read OpenCode's on-disk session/storage files directly for a liveness
  signal (mirrors the earlier, rejected `~/.claude/jobs` approach from
  ADR-0004)
- Detect running `opencode` processes via the process table and resolve
  each one's cwd with `lsof -d cwd` (this decision)

## Decision Outcome

Chosen option: process-table detection. OpenCode's own storage
(`~/.local/share/opencode/storage`, `~/.local/state/opencode/locks/*.lock`)
was inspected directly rather than guessed at - the lock directory looked
promising (pid, hostname, createdAt) but a real lock found on this machine
belonged to a process that was no longer running, meaning "lock file exists"
doesn't mean "session is live" without also checking the pid, and the lock's
directory-hashed filename doesn't map back to a project path without
guessing the hash function. `ps` + `lsof` sidesteps both problems: a `ps`
listing only ever contains currently-running processes by definition, and
`lsof -a -p <pid> -d cwd -Fn` returns the process's actual resolved working
directory directly from the kernel, no hash reverse-engineering required.
Verified end-to-end with a real backgrounded process before relying on it in
the two implementations.

This decision means:

- a new catch-all `opencode` state, distinct from Claude Code's five
  (`working`/`blocked`/`failed`/`done`/`idle`), because there's no reliable
  way to tell a busy OpenCode session from one just sitting open waiting for
  input - claiming otherwise would be a precision the data doesn't support.
  Glyph: `◆ opencode`, ranked lowest priority (below `idle`), since it's the
  vaguest signal of any tier - if a Claude Code state is also present for the
  same worktree, that wins the label, though the `×N` count reflects both
- `wt list` and `cmd+enter o` union Claude and OpenCode jobs into the same
  match-and-rank pass, so a worktree running both tools shows one glyph (the
  higher-priority state) and a combined count
- `wt clean`'s live-session gate treats `opencode` the same as
  `working`/`blocked`/`idle`: a running OpenCode process blocks cleanup
- in `wt`, Claude and OpenCode detection are independent functions
  (`load_claude_jobs`, `load_opencode_jobs`) called from the same
  once-per-process `load_agent_jobs` dispatcher, so one tool being
  uninstalled or erroring never hides the other's jobs
- `kitty_selector.py` keeps `load_agent_jobs()` (Claude-only, unchanged) and
  adds a separate `load_opencode_jobs()`, combined at the one call site that
  needs both (`select_open_tab()`) - `wt list`'s own glyph is computed
  entirely in bash, so there was never a second Python call site to update

### Consequences

- Positive: both agentic tools in daily use are now visible in the same
  place, which is the entire premise of ADR-0004 - a status column that only
  covers half the agents running on the machine is misleading by omission.
- Positive: `wt clean` can no longer delete a worktree a live OpenCode
  process is sitting in, closing the same gap ADR-0004 closed for Claude
  Code.
- Negative: the `opencode` state is genuinely less informative than Claude
  Code's states - it means "a process is here," not "here's what it's
  doing." This is an intentional, disclosed limitation (the glyph, label,
  and this document all say so) rather than a false precision.
- Negative: another dependency on unversioned, undocumented behavior - this
  time the shape of `ps -eo pid,comm` and `lsof -Fn` output rather than a
  CLI's own JSON, and on OpenCode's binary being named `opencode` on the
  process table (true for the installed binary; would break for a
  differently-named build). Degrades to no glyph, not an error, same
  fallback posture as ADR-0004's dependency on `claude agents --json`.
- Negative: OpenCode's own subagent worktrees (created by plugins like
  oh-my-opencode under `~/.local/share/opencode/worktree/`, already excluded
  from `wt`'s own discovery - see docs/worktrees.md) run as separate
  processes with their own cwd inside those worktree paths, not the parent
  project's. A subagent working in one of those isn't reflected on the
  parent tab's status. Out of scope here: it would mean reverse-engineering
  an undocumented, third-party plugin's process/worktree relationship, for a
  case the primary ask (showing the main interactive OpenCode session the
  user is looking at) doesn't need.

## Confirmation

`scripts/test-wt.sh` adds fake `ps` and `lsof` binaries on `PATH`, alongside
the existing fake `claude`/`kitty` (same pattern: read a fixture file the
test points at via an env var, default to reporting nothing). Covers: a
running `opencode` process's cwd surfacing as `◆ opencode`; a non-opencode
process in the same `ps` listing being ignored (the comm-basename filter);
an opencode session sharing a worktree with a higher-priority Claude job
adding to the count without changing the winning label; and `wt clean`
skipping a worktree with a live `opencode` process until it's gone, mirroring
the existing `working`/`idle` clean-gate tests.

`scripts/test-kitty-selector.py` covers the same cases by monkeypatching
`subprocess.run` with a dispatcher keyed on `argv[0]` (`ps` vs. `lsof`),
since - unlike the Claude-only fake, which only ever stands in for one
command - `load_opencode_jobs()` makes two different calls through the same
patched function. Also covers a pid `lsof` can't resolve a cwd for (already
exited, or no permission) being dropped rather than reported with an empty
cwd.

Both `lsof -a -p <pid> -d cwd -Fn`'s field order (`p<pid>`, `fcwd`,
`n<path>`) and `ps -eo pid,comm` printing the full executable path (not a
truncated command name) were confirmed against this machine's real `lsof`/
`ps` before being relied on in the fakes and the implementation.
