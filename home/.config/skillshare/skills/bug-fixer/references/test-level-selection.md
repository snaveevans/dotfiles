# Test Level Selection

Pick the lowest test level that reliably captures the defect.

## Unit test

Use when:

- bug is in pure logic, parsing, mapping, or validation
- dependencies can be mocked without hiding the failure

Pros:

- fastest feedback
- easiest to isolate root cause

Avoid when:

- bug depends on framework wiring, database behavior, or real integration boundaries

## Integration test

Use when:

- bug appears across module boundaries
- bug involves database queries, API handlers, message queues, caching, or framework configuration

Pros:

- better confidence in real wiring
- catches boundary regressions unit tests miss

Avoid when:

- failure is purely local logic and integration setup adds noise

## End-to-end (e2e) test

Use when:

- bug is user-visible and depends on full stack behavior
- failure requires UI flow, network orchestration, auth/session state, or client-server interaction

Pros:

- highest fidelity to user impact
- validates real runtime behavior

Avoid when:

- lower-level tests can cover the issue with less flakiness and cost

## Escalation rule

Start at the lowest likely level. Escalate only if:

- the lower-level test cannot reproduce the failure path
- reproducing requires real boundaries that mocks hide
- confidence remains insufficient for the risk profile

## Stability checks for regression tests

- deterministic fixtures and seeded data
- explicit waits/time control for async behavior
- no hidden dependency on test order
- clear assertion on the actual failure signal
