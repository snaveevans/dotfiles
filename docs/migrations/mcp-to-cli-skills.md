# MCP to CLI Skills Migration

All former shared MCP servers now run as CLI tools behind agent skills.
No MCP entries remain in `home/.config/skillshare/config.yaml`,
`home/.config/opencode/opencode.jsonc`, or Muse settings (the refresh
script deletes leftovers when present).

## Skills and their update path

| Skill(s) | Source | Refresh command |
|---|---|---|
| `find-docs` | [context7](https://github.com/upstash/context7) via `skillshare install upstash/context7 -s find-docs` (official skill) | Re-apply the `-y` flag on every `npx ctx7@latest` invocation below |
| `bx` | [brave-search-skills](https://github.com/brave/brave-search-skills) via `skillshare install brave/brave-search-skills -s bx` (official `bx` skill: `context` replaces `llm-context`, `web`/`news` replace the search skills, `answers` replaces the `answers` skill) | Re-apply the npx/key adaptation below |
| `playwright-cli`, `playwright-component-testing`, `playwright-trace` | `npx playwright init-skills --loop claude` output, adopted into source | Re-run the generator, diff, copy changed files into source |
| `chrome-devtools-cli` | [chrome-devtools-mcp](https://github.com/ChromeDevTools/chrome-devtools-mcp) `skills/chrome-devtools-cli`, adapted to npx | Re-fetch `SKILL.md` + `references/`, re-apply the npx substitution below |

## Adaptations re-applied on every vendor update

- `bx` assumes a global `bx` binary and `BRAVE_SEARCH_API_KEY`. This copy
  adds a repo-adaptation note at the top of `SKILL.md`: run everything via
  `npx -y @brave/brave-search-cli@1.7.0` (no global install), keyed by this
  repo's canonical `BRAVE_API_KEY` (exported by
  `scripts/refresh-secrets.sh` from Bitwarden), which `bx` accepts via its
  `BRAVE_API_KEY` fallback. Re-apply on every vendor update.
- `chrome-devtools-cli` assumes a global `chrome-devtools` command.
  This copy rewrites invocations to
  `npx -y -p chrome-devtools-mcp@latest chrome-devtools ...` (plus
  `references/installation.md`), so no global install is needed.

## Retired without replacement

- `ios-simulator` MCP entries removed from every surface; the
  `ios-rebuild-validate` skill (which only invoked `ios-simulator_*`
  tools) and the `muse-mcp-mirror` skill (which mirrored MCPs into Muse)
  were deleted from the skill source. All restorable from git history.

## Known gaps vs MCP

- No one-shot `browser_fill_form` in either browser CLI.
- `chrome-devtools` `wait_for` has no CLI equivalent.
- `brave_summarizer` is deprecated upstream; use `bx answers` instead
  (requires an Answers-capable plan — without one the API returns
  `OPTION_NOT_IN_PLAN`, and `bx context` is the fallback).
- Playwright CLI sessions default to headless with a 1-hour idle timeout.
