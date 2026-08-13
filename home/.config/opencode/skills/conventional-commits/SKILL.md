---
name: conventional-commits
description: ALWAYS enforce Conventional Commits format for ALL git commits. Every commit message MUST use type(scope): subject structure, optional body/footer, and issue references.
---

# Conventional Commits

## Safe defaults

- Use `type: subject` when no scope is needed.
- Keep subject in imperative mood, lowercase start, no trailing period.
- Keep subject <= 72 characters.
- Use `fix` for bug fixes, `feat` for user-facing functionality, `docs` for documentation-only changes, `refactor` for behavior-preserving code changes, `test` for test-only updates, `chore` for maintenance.

## Workflow

1. Inspect staged and unstaged changes with `git status` and `git diff`.
2. Decide whether the change is user-facing (`feat`/`fix`) or internal (`refactor`/`test`/`chore`/`docs`).
3. Choose optional scope from the main area touched (for example: `api`, `ui`, `build`, `auth`).
4. Draft the header as `<type>(<scope>): <subject>` or `<type>: <subject>`.
5. Add a body when useful to explain why the change exists and tradeoffs made.
6. Add footer entries for references and breaking changes:
   - `BREAKING CHANGE: <impact and migration>` when behavior/contracts change.
   - `Refs: #<id>` or `Closes: #<id>` when linked issues exist.
7. Commit with `git commit -m "<header>"` for header-only commits, or use multiple `-m` flags for body/footer.

## Validation

- Header matches Conventional Commits grammar.
- Type is one of: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`.
- Subject is concise, imperative, and does not end with a period.
- If breaking change exists, include `!` in header or `BREAKING CHANGE:` footer.

## Failure modes

- Wrong type selection: recategorize by intent (feature vs fix vs maintenance) before committing.
- Subject too vague: rewrite to describe outcome (for example `fix: handle null session in login callback`).
- Multiple unrelated changes in one commit: split into separate commits with distinct types/scopes.
