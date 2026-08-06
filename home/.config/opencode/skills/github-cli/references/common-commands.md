# Common `gh` command patterns

Use these as starting points and adapt flags as needed.

## Pull requests

- View a PR: `gh pr view 123 --json number,title,state,author,reviewDecision,url`
- View changed files: `gh pr diff 123`
- Check PR status: `gh pr checks 123`
- List open PRs: `gh pr list --state open`
- Create a PR: `gh pr create --title "..." --body "..."`
- Review a PR: `gh pr review 123 --approve --body "Looks good"`
- Comment on a PR: `gh pr comment 123 --body "..."`

## Issues

- View an issue: `gh issue view 123 --json number,title,state,assignees,labels,url`
- List issues: `gh issue list --state open`
- Create an issue: `gh issue create --title "..." --body "..."`
- Comment on an issue: `gh issue comment 123 --body "..."`
- Edit labels or assignees: `gh issue edit 123 --add-label bug --add-assignee mona`

## Actions

- List workflow runs: `gh run list`
- View a run: `gh run view 123456789 --log-failed`
- Rerun a failed job or run: `gh run rerun 123456789`
- List workflows: `gh workflow list`
- Dispatch a workflow: `gh workflow run build.yml`

## Releases

- List releases: `gh release list`
- View a release: `gh release view v1.2.3`
- Create a release: `gh release create v1.2.3 --notes "..."`
- Download release assets: `gh release download v1.2.3`

## Repositories and search

- View repo info: `gh repo view owner/repo --json name,description,defaultBranchRef,url`
- Fork a repo: `gh repo fork owner/repo`
- Search PRs: `gh search prs --owner owner --state open --json number,title,url`
- Search issues: `gh search issues --owner owner --state open --json number,title,url`

## API fallback

- REST: `gh api repos/owner/repo/pulls/123`
- GraphQL: `gh api graphql -f query='query { viewer { login } }'`
- Paginate: `gh api repos/owner/repo/issues --paginate`

## Multi-line bodies

Use a heredoc for comments, issue bodies, or PR descriptions:

```bash
gh pr comment 123 --body "$(cat <<'EOF'
Thanks for the update.

- Verified locally
- Left one follow-up suggestion
EOF
)"
```
