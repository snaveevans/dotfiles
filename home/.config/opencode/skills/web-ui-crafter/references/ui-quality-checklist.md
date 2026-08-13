# UI Quality Checklist

Use this checklist before considering implementation complete.

## 1) Scope completion

- Primary user flow is fully implemented.
- All modified surfaces include loading, empty, error, and success states where relevant.
- Validation behavior exists for all user inputs.

## 2) Visual consistency

- Typography, spacing, and color usage match existing tokens or defined system rules.
- Component states (default/hover/focus/disabled/error) are visually coherent.
- No ad hoc style values that conflict with the surrounding UI.

## 3) Responsiveness

- Layout works on common mobile, tablet, and desktop widths.
- Long text and dynamic content do not break layout.
- Touch targets are usable on mobile.

## 4) Accessibility

- Semantic HTML and landmarks are used.
- Keyboard navigation works across the full flow.
- Focus order is logical and visible.
- Inputs have labels, errors are announced clearly, and contrast is sufficient.

## 5) Interaction quality

- Feedback is immediate for user actions.
- Motion supports comprehension and is not distracting.
- Disabled and error states explain how to proceed.

## 6) Code quality

- Reusable UI primitives are extracted where duplication appears.
- Component interfaces are clear and minimal.
- New code follows existing file organization and naming conventions.

## 7) Verification

- Project lint/type/test commands were run when available.
- Any unverified assumptions are documented in the final report.
