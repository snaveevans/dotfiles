---
description: Review a PR or the current branch diff (uses the pr-review skill)
---

Use the `pr-review` skill to review $ARGUMENTS.

If no argument was given, review the current branch against `main`.

When the target is a PR, the review posts its verdict — approved or changes requested —
as a comment on that PR. Add "don't post" to the invocation to keep it in-session.
