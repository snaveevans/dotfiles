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

    # A missing jobs directory should degrade to no jobs, not raise.
    os.environ["CLAUDE_JOBS_DIR"] = os.path.join(tmp_dir, "does-not-exist")
    if ks.load_agent_jobs():
        fail("a missing jobs directory should yield no jobs, not raise")

    print("kitty_selector agent-status assertions passed")


if __name__ == "__main__":
    main()
