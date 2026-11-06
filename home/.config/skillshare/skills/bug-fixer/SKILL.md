---
name: bug-fixer
description: Debug and fix software defects with a disciplined workflow. Use when asked to investigate a bug, fix a regression, or resolve failing behavior by reproducing the issue, adding a failing test, and implementing a verified fix.
compatibility: opencode
metadata:
  audience: developers
  domain: debugging
---

# Bug Fixer

Apply a repeatable red-green-fix workflow: reproduce first, prove with a test, then fix.

## Safe defaults

- Do not implement fixes without a reproducible failure.
- Prefer the smallest test level that reliably catches the bug.
- Keep fixes narrow; avoid unrelated refactors.
- Preserve public behavior unless the bug is caused by incorrect behavior.
- If reproduction cannot be automated, document exact manual repro steps before code changes.

## Inputs to collect

- observed symptom and expected behavior
- environment details (runtime, OS, version, config, flags)
- failing logs/errors and where they appear
- known scope (single module, cross-service, UI-only, data-related)

If any input is missing, infer from repository evidence and proceed with explicit assumptions.

## Workflow

1. Reproduce the bug.
   - Identify deterministic repro steps and run them.
   - Capture exact failure signal (error, assertion mismatch, screenshot diff, status code).

2. Choose test level.
   - Select unit, integration, or e2e based on where the defect manifests and what boundary must be protected.
   - Use `references/test-level-selection.md` when uncertain.

3. Add a failing regression test.
   - Write the smallest stable test that fails for the current bug.
   - Ensure the test fails for the right reason.

4. Confirm red state.
   - Run the new test in isolation and verify failure before any fix.

5. Implement the minimal fix.
   - Change only relevant logic.
   - Keep interfaces stable unless required.

6. Confirm green state.
   - Re-run the new test and related test scope.
   - Run broader checks proportional to risk.

7. Verify no collateral damage.
   - Re-run original repro steps.
   - Check nearby paths likely impacted by the change.

8. Report outcome.
   - State root cause, what test was added, what was changed, and what was verified.
   - Note any residual risk or follow-up hardening work.

## Validation

Minimum acceptance:

- deterministic reproduction documented
- regression test added and observed failing before fix
- regression test passing after fix
- related tests and checks completed
- root cause and fix rationale documented

## Failure modes

- Symptom: Fix applied but bug cannot be reproduced.
  - Fix: Stop and establish deterministic repro first.

- Symptom: Test passes but production bug remains.
  - Fix: Raise test level or adjust test boundary to match real failure path.

- Symptom: Test is flaky.
  - Fix: Remove timing/network nondeterminism, stabilize fixtures, then re-verify red-green cycle.

- Symptom: Fix causes unrelated regressions.
  - Fix: Narrow scope, restore behavior, and add targeted coverage for impacted edge paths.

## Reference files

- `references/test-level-selection.md` for choosing between unit, integration, and e2e tests.
