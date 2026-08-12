#!/usr/bin/env python3
"""Exercises the pure agent-status functions in kitty_selector.py.

kitty_selector.py imports `kitty.boss`, which only exists inside Kitty's
bundled Python runtime, so that module is stubbed out here rather than
running this under Kitty itself.
"""
import sys
import os
import json
import types
import importlib.util


def fail(message):
    print(f"Test failed: {message}", file=sys.stderr)
    sys.exit(1)


def main():
    selector_path, tmp_dir = sys.argv[1], sys.argv[2]

    fake_kitty = types.ModuleType("kitty")
    fake_boss = types.ModuleType("kitty.boss")
    fake_boss.Boss = type("Boss", (), {})
    sys.modules["kitty"] = fake_kitty
    sys.modules["kitty.boss"] = fake_boss

    spec = importlib.util.spec_from_file_location("kitty_selector", selector_path)
    ks = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(ks)

    jobs_dir = os.path.join(tmp_dir, "jobs")
    fixtures = {
        "job1": {"cwd": "/repo-a/feature", "state": "working"},
        "job2": {"cwd": "/repo-a/feature/sub/dir", "state": "blocked"},
        "job3": {"cwd": "/dotfiles", "state": "done"},
    }
    for name, data in fixtures.items():
        os.makedirs(os.path.join(jobs_dir, name))
        with open(os.path.join(jobs_dir, name, "state.json"), "w") as f:
            json.dump(data, f)

    os.environ["CLAUDE_JOBS_DIR"] = jobs_dir
    jobs = ks.load_agent_jobs()
    if len(jobs) != 3:
        fail(f"expected 3 jobs, got {jobs}")

    status = ks.agent_status_for("/repo-a/feature", jobs)
    if status != "⏸ needs input ×2":
        fail(
            "a nested job should count toward its ancestor worktree and "
            f"blocked should outrank working, got: {status!r}"
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

    # A missing jobs directory should degrade to no jobs, not raise.
    os.environ["CLAUDE_JOBS_DIR"] = os.path.join(tmp_dir, "does-not-exist")
    if ks.load_agent_jobs():
        fail("a missing jobs directory should yield no jobs, not raise")

    print("kitty_selector agent-status assertions passed")


if __name__ == "__main__":
    main()
