#!/usr/bin/env python3
"""Exercises the pure agent-status functions in kitty_selector.py.

kitty_selector.py imports `kitty.boss`, which only exists inside Kitty's
bundled Python runtime, so that module is stubbed out here rather than
running this under Kitty itself. `load_agent_jobs` shells out to
`claude agents --json`, so `subprocess.run` is monkeypatched rather than
actually invoking the CLI - this keeps the test hermetic and fast, and
lets it exercise session shapes (interactive vs. background) without
depending on what's actually running on the machine.
"""
import sys
import os
import json
import types
import importlib.util


def fail(message):
    print(f"Test failed: {message}", file=sys.stderr)
    sys.exit(1)


def fake_subprocess_run(sessions):
    """A stand-in for subprocess.run that returns `sessions` as claude
    agents --json would, ignoring whatever command was actually passed."""

    class FakeResult:
        stdout = json.dumps(sessions)

    def run(*args, **kwargs):
        return FakeResult()

    return run


def fake_opencode_processes(pid_to_cwd):
    """A stand-in for subprocess.run that answers the `ps` and `lsof` calls
    load_opencode_jobs() makes, keyed off argv[0] since - unlike the claude
    fake above - both commands go through the same subprocess.run patch in
    one test run. `ps -eo pid,comm` lists a real (non-opencode) process
    alongside each opencode pid, so the comm-basename filter is exercised
    too, not just the happy path."""

    class FakeResult:
        def __init__(self, stdout):
            self.stdout = stdout

    def run(args, **kwargs):
        if args[0] == "ps":
            lines = ["  PID COMM", "1 /sbin/launchd"]
            lines += [f"{pid} /Users/tyler.evans/.opencode/bin/opencode" for pid in pid_to_cwd]
            return FakeResult("\n".join(lines))
        if args[0] == "lsof":
            pid = args[args.index("-p") + 1]
            cwd = pid_to_cwd.get(pid)
            if cwd is None:
                return FakeResult("")
            return FakeResult(f"p{pid}\nfcwd\nn{cwd}")
        raise AssertionError(f"unexpected command: {args}")

    return run


def main():
    selector_path = sys.argv[1]

    fake_kitty = types.ModuleType("kitty")
    fake_boss = types.ModuleType("kitty.boss")
    fake_boss.Boss = type("Boss", (), {})
    sys.modules["kitty"] = fake_kitty
    sys.modules["kitty.boss"] = fake_boss

    spec = importlib.util.spec_from_file_location("kitty_selector", selector_path)
    ks = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(ks)

    # find_claude() only matters on a real machine with a real filesystem -
    # stub it so load_agent_jobs() always proceeds to the (also stubbed)
    # subprocess.run below, regardless of whether this machine happens to
    # have claude installed at one of find_claude()'s hardcoded locations.
    ks.find_claude = lambda: "claude"

    sessions = [
        {"cwd": "/repo-a/feature", "kind": "background", "state": "working"},
        {"cwd": "/repo-a/feature/sub/dir", "kind": "background", "state": "blocked"},
        {"cwd": "/dotfiles", "kind": "background", "state": "done"},
        # An interactive session reports `status`, not `state`, and uses a
        # different vocabulary (busy/waiting/idle/shell) that has to be
        # translated - this one should be invisible on its own (idle) but
        # still count as a job when unioned with the others below.
        {"cwd": "/repo-a/feature", "kind": "interactive", "status": "idle"},
    ]
    ks.subprocess.run = fake_subprocess_run(sessions)

    jobs = ks.load_agent_jobs()
    if len(jobs) != 4:
        fail(f"expected 4 jobs (idle interactive sessions still count), got {jobs}")

    status = ks.agent_status_for("/repo-a/feature", jobs)
    if status != "⏸ needs input ×3":
        fail(
            "a nested job should count toward its ancestor worktree, blocked "
            f"should outrank working and idle, got: {status!r}"
        )

    status = ks.agent_status_for("/dotfiles", jobs)
    if status != "✓ done":
        fail(f"an exact cwd match should report its state, got: {status!r}")

    status = ks.agent_status_for("/repo-a/other", jobs)
    if status is not None:
        fail(f"a path with no matching job cwd should report no status, got: {status!r}")

    status = ks.agent_status_for("/repo-a/feature-extra", jobs)
    if status is not None:
        fail(f"a worktree whose name is a prefix of another's should not match it, got: {status!r}")

    # An interactive session on its own (nothing higher-priority sharing its
    # cwd) should surface its idle status rather than disappearing outright -
    # this is what "there's an agent here, but it's not doing anything right
    # now" looks like, distinct from no session at all (no status).
    idle_only = [("/repo-a/idle-tab", "idle")]
    status = ks.agent_status_for("/repo-a/idle-tab", idle_only)
    if status != "○ idle":
        fail(f"a lone idle session should still show a (low-priority) status, got: {status!r}")

    # A window sitting bare at $HOME must never be a match anchor: every
    # job's cwd is a descendant of home, so treating it as one would make a
    # tab parked at home look like it's running every job on the machine.
    home = os.path.expanduser("~").rstrip("/")
    status = ks.agent_status_for_paths([home], jobs)
    if status is not None:
        fail(f"a window sitting at $HOME should never match any job, got: {status!r}")

    # A split-pane tab with one window at $HOME and another at a real
    # project directory should report only the real project's jobs - this
    # reproduces the bug where a stray home-anchored pane made an entire
    # tab's status look like every job on the machine was running in it.
    status = ks.agent_status_for_paths([home, "/dotfiles"], jobs)
    if status != "✓ done":
        fail(
            "a home-anchored window sharing a tab with a real project "
            f"window should not pull in unrelated jobs, got: {status!r}"
        )

    # ~/workspace (and ~/worktrees) are container roots: a job nested inside
    # one of their repos belongs to that repo, not to the container itself,
    # so a tab sitting bare at the container should only see a job whose cwd
    # is exactly that path - not the ones nested under it.
    os.environ["WT_WORKSPACE"] = "/workspace"
    os.environ["WT_ROOT"] = "/worktrees"
    container_jobs = [
        ("/workspace/prism-ui", "blocked"),
        ("/workspace/prism-header", "blocked"),
        ("/workspace", "working"),
    ]

    status = ks.agent_status_for_paths(["/workspace"], container_jobs)
    if status != "● working":
        fail(f"a tab at a container root should only see a job at the root itself, got: {status!r}")

    status = ks.agent_status_for_paths(["/workspace/prism-ui"], container_jobs)
    if status != "⏸ needs input":
        fail(f"descendant matching should still work inside a repo under the container, got: {status!r}")

    del os.environ["WT_WORKSPACE"]
    del os.environ["WT_ROOT"]

    # claude not being installed, timing out, or emitting bad JSON should
    # degrade to no jobs, not raise - this data source is best-effort.
    def raising_run(*args, **kwargs):
        raise FileNotFoundError("claude not found")

    ks.subprocess.run = raising_run
    if ks.load_agent_jobs():
        fail("a missing claude binary should yield no jobs, not raise")

    # find_claude() returning nothing (claude isn't installed anywhere
    # find_claude() checks, including plain PATH) should short-circuit to no
    # jobs without even attempting a subprocess call.
    ks.find_claude = lambda: None
    if ks.load_agent_jobs():
        fail("find_claude() finding nothing should yield no jobs, not raise")

    # OpenCode has no session-status API to shell out to, so
    # load_opencode_jobs() goes through `ps` + `lsof` instead - a distinct
    # code path from load_agent_jobs() above, exercised here with its own
    # fake `subprocess.run`.
    ks.subprocess.run = fake_opencode_processes({"501": "/repo-a/feature"})
    opencode_jobs = ks.load_opencode_jobs()
    if opencode_jobs != [("/repo-a/feature", "opencode")]:
        fail(
            "load_opencode_jobs() should resolve a running opencode process's "
            f"cwd via lsof and report it as the catch-all 'opencode' state, got: {opencode_jobs!r}"
        )

    # A pid lsof can't resolve a cwd for (already exited, or no permission)
    # should be dropped rather than reported with an empty/missing cwd.
    ks.subprocess.run = fake_opencode_processes({"501": None})
    if ks.load_opencode_jobs():
        fail("a pid lsof can't resolve a cwd for should yield no job, not an empty-cwd entry")

    # Merged with a Claude job on the same path, the more specific Claude
    # state should still win - "opencode" is a last-resort catch-all, not a
    # real activity signal, so it shouldn't outrank a confirmed working job.
    ks.subprocess.run = fake_opencode_processes({"501": "/repo-a/feature"})
    opencode_jobs = ks.load_opencode_jobs()
    merged = jobs + opencode_jobs
    status = ks.agent_status_for("/repo-a/feature", merged)
    if status != "⏸ needs input ×4":
        fail(
            "an opencode session sharing a path with higher-priority Claude "
            f"jobs should add to the count without changing the winning state, got: {status!r}"
        )

    # On its own, with no Claude job at all, the opencode session should
    # still surface - "there's an agent here" beats no status at all, the
    # same reasoning as the lone-idle-session case above.
    status = ks.agent_status_for("/repo-a/feature", opencode_jobs)
    if status != "◆ opencode":
        fail(f"a lone opencode session should still show a status, got: {status!r}")

    # `cmd+enter o`'s ordering reads `active_tab_history` straight off the
    # `kitty @ ls` payload the caller already fetched - no extra subprocess
    # calls. Build a fake payload shaped like that JSON: one OS window, the
    # focused tab flagged, and a history tuple in kitty's own oldest-to-
    # newest insertion order.
    ls_data = [
        {
            "is_focused": True,
            "active_tab_history": (10, 40, 20),
            "tabs": [
                {"id": 10, "is_focused": False},
                {"id": 20, "is_focused": False},
                {"id": 30, "is_focused": True},
                {"id": 40, "is_focused": False},
            ],
        }
    ]
    current_id, history = ks._current_tab_and_history(ls_data)
    if current_id != 30 or history != [20, 40, 10]:
        fail(
            "expected the focused tab (30) and its history reversed to "
            f"newest-switched-away-from first, got current={current_id!r} history={history!r}"
        )

    # No tab flagged is_focused (shouldn't happen in practice, but the
    # picker must still degrade to plain alphabetical rather than raise).
    current_id, history = ks._current_tab_and_history([{"is_focused": True, "tabs": []}])
    if current_id is not None or history:
        fail(f"expected no current tab / history when nothing is focused, got {current_id!r} {history!r}")

    by_id = {
        10: ("alpha", None),
        20: ("beta", "working"),
        30: ("gamma", None),
        40: ("delta", None),  # not covered by history - e.g. a second OS window
    }

    ordered = ks._order_tabs_by_recency(by_id, current_id=30, history=[20, 10])
    expected = [("beta", "working"), ("alpha", None), ("gamma", None), ("delta", None)]
    if ordered != expected:
        fail(
            "expected most-recently-used first (20, then 10), current tab "
            f"(30) last, then the uncovered leftover (40) alphabetically, got: {ordered!r}"
        )

    # kitty only records history on switch-*away*, so a tab you left once
    # and later returned to can still carry a stale entry in `history` even
    # while it's also the current tab - that must not produce a duplicate
    # row for the same tab.
    ordered = ks._order_tabs_by_recency(by_id, current_id=30, history=[20, 30, 10])
    if ordered != expected:
        fail(f"expected the current tab's stale history entry to be deduped, not repeated, got: {ordered!r}")

    # No history at all (e.g. a freshly started Kitty, nothing switched yet)
    # should reproduce the old plain-alphabetical ordering exactly.
    ordered = ks._order_tabs_by_recency(by_id, current_id=None, history=[])
    expected = [("alpha", None), ("beta", "working"), ("delta", None), ("gamma", None)]
    if ordered != expected:
        fail(f"expected alphabetical fallback with no history, got: {ordered!r}")

    print("kitty_selector agent-status assertions passed")


if __name__ == "__main__":
    main()
