---
name: pitfalls-maintainer
description: Update pitfalls.md at repo root whenever an error is encountered and fixed (self-heal or user-reported). On second failure, consult pitfalls-reader first. Create pitfalls.md if missing; add a dated entry with symptom/cause/fix/prevention.
---

# Pitfalls Maintainer

Keep a **single, standardized** `pitfalls.md` in the **root of every repo** to capture repeatable errors and the fix that worked.

## When to use

Use this workflow **immediately after**:

1. You hit an error and fixed it (including “I tried X, it failed, then Y worked”).
2. The user reports something is wrong and you fix it.
3. You notice a formatting/workflow gotcha that is likely to recur.

## Related skill (read before writing)

If you are seeing the **same/similar failure for the second time**, run the `pitfalls-reader` skill first to avoid duplicating entries and to reuse known fixes.

## Trigger heuristic (accepted standard)

Treat a problem as “the same/similar problem twice” if any of these are true:

1. The **same command/tool call fails twice**.
2. The **same error substring** appears twice.
3. You have **two failed attempts** in the same subsystem and you’re about to try a third.

## Guardrails

- Do **not** record secrets (tokens, credentials, internal-only sensitive data).
- Prefer **concise + actionable** over long narratives.
- If multiple attempts happened, capture the _final fix_ and the key lesson.

## Workflow

1. **Find** `pitfalls.md` at the repository root.
2. If it doesn’t exist, **create it** with this header:

   ```md
   # Pitfalls (errors + fixes)

   This file is a running log of small-but-annoying issues we’ve hit, plus the fix that worked.
   ```

3. **Add a new entry near the top** (reverse chronological), using this structure:

   ```md
   ## YYYY-MM-DD — <short title>

   ### Symptom

   <What did we observe? Error message? Wrong behavior?>

   ### Cause

   <Why it happened (or best hypothesis).>

   ### Fix

   <Exact steps that resolved it. Include commands, config, file paths, etc.>

   ### How to avoid next time

   <Rules of thumb, checks, or the “canonical way” to do it.>

   ### Evidence (optional)

   <Key outputs, links to tickets/PRs, screenshots, etc.>
   ```

4. If the fix affects specific files, list them under **Fix** (paths) and/or **Evidence**.
5. If the pitfall relates to a Jira/GitHub ticket, include the **key + URL** under Evidence.

6. **Before creating a brand-new entry**, quickly check whether a similar entry already exists.
   - If one exists, prefer **updating/expanding** it rather than adding a near-duplicate.

## Validation

- `pitfalls.md` exists at repo root.
- The new entry is readable, accurate, and actionable.
- The entry is near the top and uses consistent headings.

## Common failure modes

- **Formatting still broken after small edits** → rewrite the whole affected block in a single, consistent format.
- **Tool/API stores content in a different markup** → copy a known-good example from the same system/project and standardize to it.
