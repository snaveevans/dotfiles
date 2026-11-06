---
name: github-cli
description: Use GitHub CLI `gh` for GitHub-specific tasks: pull requests, issues, reviews, comments, Actions runs and workflows, releases, checks, repo metadata, and GitHub URL inspection. Prefer `gh` or `gh api` whenever the task is about GitHub rather than local git.
---

# GitHub CLI

Use this skill whenever the task is about GitHub objects or GitHub-hosted workflows, not just local Git state.

## Safe defaults

- Prefer `gh` for GitHub work: PRs, issues, reviews, comments, labels, notifications, releases, checks, Actions, repo metadata, and GitHub URLs.
- Use plain `git` only for local repository operations such as branching, staging, commits, rebases, and diffs.
- Default to the repo in the current checkout. If the task targets another repo, pass `-R owner/repo` explicitly.
- Prefer structured output with `--json`, `--jq`, or `gh api` when you need fields to summarize or compare.
- If a command needs a long body, comment, or PR description, use a heredoc instead of fragile inline quoting.

## Trigger examples

- "Create or update a GitHub pull request"
- "Review PR comments or checks on GitHub"
- "Open, comment on, label, or close an issue"
- "Inspect a GitHub URL for a PR, issue, release, workflow run, or repo"
- "Check GitHub Actions runs, workflow logs, releases, tags, or repo settings"

## Workflow

1. Establish GitHub context.
   - Derive `owner/repo` from the current repo, the user request, or a GitHub URL.
   - If auth or permissions are uncertain, run `gh auth status` before retrying failed write operations.

2. Choose the smallest matching `gh` command family.
   - `gh pr` for pull requests, reviews, checks, and PR comments.
   - `gh issue` for issues, labels, assignees, and issue comments.
   - `gh run` and `gh workflow` for GitHub Actions runs, logs, reruns, and dispatches.
   - `gh release` for releases and attached artifacts.
   - `gh repo` for repository metadata, forks, clones, and settings-adjacent info.
   - `gh search` for cross-repo search.
   - `gh api` when higher-level commands do not expose the needed field or mutation.

3. Prefer read commands before write commands.
   - Inspect current state with `view`, `list`, `status`, `checks`, or `run view` before editing.
   - When mutating GitHub state, perform only the exact requested action.

4. Use URL-aware handling.
   - If a `gh` subcommand accepts a GitHub URL directly, use it.
   - Otherwise extract `owner/repo` and the object number or id, then pass `-R owner/repo`.

5. Fall back to `gh api` instead of non-GitHub tools.
   - Use `gh api repos/...`, `gh api graphql`, and `--paginate` for GitHub-specific data that is awkward or unavailable elsewhere.
   - Prefer this over browser scraping or generic web fetches when the source of truth is GitHub.

6. Verify and report.
   - For reads, summarize the relevant state, ids, URLs, reviewers, checks, or run conclusions.
   - For writes, verify with a follow-up `gh ... view`, `gh ... list`, or `gh ... checks` command and report the resulting URL or object id.

## Validation

- The command targets the correct repo and GitHub object.
- `gh` is the primary interface for GitHub-specific operations.
- Structured fields are used when accuracy matters.
- Mutations are followed by a verification step.
- The response includes the key artifact created or inspected: PR number, issue number, run id, release tag, or URL.

## Failure modes

- Auth failure: run `gh auth status`; if needed, tell the user authentication is required before continuing.
- Wrong repo context: rerun with `-R owner/repo` instead of assuming the current checkout.
- Missing field in a high-level command: switch to `--json`, `--jq`, or `gh api`.
- Complex body text breaks quoting: rerun the `gh` command with a heredoc.
- GitHub URL is ambiguous: parse the URL into repo plus object number/id, then use the matching `gh` namespace.

## Reference files

- `references/common-commands.md` for high-signal command patterns.
