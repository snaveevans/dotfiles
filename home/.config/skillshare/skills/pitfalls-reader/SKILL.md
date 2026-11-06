---
name: pitfalls-reader
description: Consult pitfalls.md after the same/similar failure happens twice (same command/tool error twice, same error substring twice, or two failed attempts in same subsystem). Search pitfalls.md, apply known fix, then continue.
---

# Pitfalls Reader

Use this skill to stop “thrash” and reuse known fixes.

## Trigger (use on the _second_ failure)

Invoke this skill when **any** of the following is true:

1. The **same command/tool call fails twice**.
2. The **same error substring** appears twice.
3. You have **two failed attempts** in the same subsystem and you’re about to try a third.

Subsystem examples: git, apply_patch, Jira/Atlassian API, workspace scripts, markdown/frontmatter formatting.

## Workflow

1. Locate repo-root `pitfalls.md`.
   - If it doesn’t exist, stop and proceed normally.

2. Search `pitfalls.md` using:
   - The exact error text (or a distinctive substring)
   - Tool name + operation (e.g. “apply_patch verification failed”, “skill not found”, “Jira description formatting”)
   - 2–5 keywords describing the symptom

3. If you find a relevant entry:
   - Apply the recorded **Fix**.
   - Follow the **How to avoid next time** guidance.

4. Continue the original task.

5. If no relevant entry exists and you eventually fix the issue:
   - Use the `pitfalls-maintainer` skill to add a new entry (or extend an existing one).

## Output expectations

When you run this skill, respond with:

- Whether `pitfalls.md` existed.
- The best-matching entry title/date (if found).
- The fix you applied (or what you tried next if no match).
