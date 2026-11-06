# Framework Recipes

Use these patterns to stay consistent with the host stack.

## React (Vite/CRA)

- Keep presentational components separate from data-fetching containers when complexity grows.
- Prefer controlled form inputs when validation and inter-field logic matter.
- Extract repeated styles into reusable primitives instead of page-local duplication.
- Keep effects minimal and deterministic; avoid effect-driven rendering loops.

## Next.js (App Router)

- Keep server components as the default; use client components only for interactivity.
- Co-locate route-specific UI in route segments, but pull shared UI into `components/`.
- Handle loading and error through route-level boundaries where possible.
- Avoid moving server data logic into client components without necessity.

## Vue 3

- Use composables for shared stateful logic; keep templates focused on rendering.
- Prefer explicit prop/event contracts for reusable components.
- Avoid large single-file components by splitting reusable child components early.

## Styling systems

### Tailwind

- Use design tokens in config or CSS variables for colors, spacing, and typography.
- Consolidate repeated utility groups into components or utility functions.

### CSS Modules / SCSS

- Scope styles by component and avoid deep selector coupling.
- Use variables or mixins for tokenized values; avoid hardcoded one-off values.

### CSS-in-JS

- Keep style objects near component logic only when it improves maintainability.
- Share tokens from a centralized source to prevent drift.

## State and data UX

- Represent async states explicitly (`idle`, `loading`, `success`, `error`).
- Prefer optimistic UI only when rollback behavior is defined.
- Keep user-visible failures actionable with clear next steps.

## Accessibility defaults

- Use semantic landmarks and heading hierarchy.
- Ensure every input has a programmatic label.
- Preserve visible focus indicators and logical tab order.
