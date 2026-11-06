---
name: find-docs
description: Look up library and framework documentation with the ctx7 CLI or the Context7 REST API. Use for API usage questions, version-specific behavior, or code examples from indexed docs. Never use for local project code.
---

# Find Docs

Query Context7 without an MCP server. Requires `CONTEXT7_API_KEY` in the
environment (projected by `scripts/refresh-secrets.sh`); never paste the key.

## Preferred: ctx7 CLI (via npx, no install needed)

```bash
# One-step question, libraries picked for you
npx -y ctx7 search "<question>" [--library <name-or-id>] [--language <lang>] [--json]

# Resolve a library name to an ID first
npx -y ctx7 library <name> "<what you are trying to do>"

# Query one library's docs with its ID
npx -y ctx7 docs <library-id> "<single focused question>" [--language <lang>] [--json]
```

Pick the result with the closest name, most snippets, and High reputation;
IDs look like `/org/project`. Prefer `--json` and parse with `jq`.

## Fallback: REST with curl

Same key as a `Bearer` header:

```bash
# One-step search
curl -s 'https://context7.com/api/v3/search?query=<q>' \
  -H "Authorization: Bearer $CONTEXT7_API_KEY"

# Resolve then fetch
curl -s 'https://context7.com/api/v2/libs/search?libraryName=<name>&query=<q>' \
  -H "Authorization: Bearer $CONTEXT7_API_KEY"
curl -s 'https://context7.com/api/v2/context?libraryId=<id>&query=<q>' \
  -H "Authorization: Bearer $CONTEXT7_API_KEY"
```

## Notes

- Keep the question to one concept per query; cache answers for hours.
- `ctx7 setup` can install a vendor skill, but always choose `--cli` mode and
  never let it configure MCP or browser OAuth.
