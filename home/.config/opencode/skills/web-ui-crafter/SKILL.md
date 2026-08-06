---
name: web-ui-crafter
description: Implement production-grade web UI in existing codebases. Use when asked to build or redesign web components/pages, improve responsive behavior, strengthen accessibility, or polish a web app's visual system.
compatibility: opencode
metadata:
  audience: frontend-developers
  domain: web-ui
---

# Web UI Crafter

Implement intentional, production-ready web UI without generic aesthetics.

## Safe defaults

- Preserve the existing design system, component conventions, and project architecture when present.
- If no system exists, define a clear visual direction before coding (type scale, color tokens, spacing rhythm, interaction style).
- Build mobile-first, then expand to tablet and desktop.
- Implement loading, empty, error, and validation states for each user-facing surface.
- Default to accessible semantic markup, keyboard support, visible focus states, and sufficient contrast.

## Inputs to collect

Collect only what is needed to ship:

- target surface (component, page, or flow)
- framework and styling stack
- constraints (deadline, browser support, performance budget, design-system rules)
- success criteria (what must be true when complete)

If details are missing, proceed using safe defaults and existing repo patterns.

## Workflow

1. Inspect current UI architecture.
   - Find shared components, tokens, layout patterns, and state handling conventions.
   - Detect whether the app already has design primitives to reuse.

2. Define implementation direction.
   - Choose the smallest vertical slice that proves the feature.
   - Select composition strategy (extend existing primitives vs add new reusable primitives).

3. Implement the core experience.
   - Build the primary path first.
   - Keep code modular and avoid one-off styles when reusable patterns are appropriate.

4. Add state completeness.
   - Implement loading, empty, error, success, and form validation states where relevant.
   - Ensure copy and affordances make next actions obvious.

5. Harden responsiveness and accessibility.
   - Verify behavior at common breakpoints and with long content.
   - Ensure keyboard navigation, focus management, labels, and screen-reader semantics.

6. Polish interaction and visual quality.
   - Add meaningful motion only where it improves comprehension or feedback.
   - Avoid generic defaults; keep visual choices intentional and consistent.

7. Validate and report.
   - Run project checks/tests if available.
   - Report what changed, what was verified, and any remaining tradeoffs.

## Validation

Use `references/ui-quality-checklist.md` as the acceptance gate.

Minimum pass criteria:

- no broken responsive layouts on core breakpoints
- complete interactive states for modified surfaces
- keyboard + focus behavior works end-to-end
- UI matches existing system or the defined direction consistently

## Failure modes

- Symptom: New UI looks inconsistent with the app.
  - Fix: Re-check shared tokens/primitives and refactor to reuse them.

- Symptom: Feature works on desktop but fails on mobile.
  - Fix: Rebuild layout from mobile-first constraints and retest breakpoints.

- Symptom: UI appears polished but is hard to use with keyboard/screen reader.
  - Fix: Add semantic roles/labels, improve focus order, and test with keyboard-only flow.

- Symptom: Motion feels distracting.
  - Fix: Reduce animation count and duration; keep only high-signal transitions.

## Reference files

- `references/framework-recipes.md` for stack-specific implementation patterns.
- `references/ui-quality-checklist.md` for final quality checks.
