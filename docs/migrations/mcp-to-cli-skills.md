# MCP to CLI Skills Migration

All former shared MCP servers now run as CLI tools behind agent skills.
No MCP entries remain in `home/.config/skillshare/config.yaml`,
`home/.config/opencode/opencode.jsonc`, or Muse settings (the refresh
script deletes leftovers when present).

## Skills and their update path

| Skill(s) | Source | Refresh command |
|---|---|---|
| `find-docs` | Hand-written from [Context7 CLI docs](https://context7.com/docs/clients/cli) | Re-check the docs page; `ctx7` flags are stable |
| `web-search`, `news-search`, `llm-context`, `answers` | [brave-search-skills](https://github.com/brave/brave-search-skills) via `skillshare install brave/brave-search-skills -s 'web-search,news-search,llm-context,answers'` | `skillshare update --all`, then re-apply the key rename below |
| `playwright-cli`, `playwright-component-testing`, `playwright-trace` | `npx playwright init-skills --loop claude` output, adopted into source | Re-run the generator, diff, copy changed files into source |
| `chrome-devtools-cli` | [chrome-devtools-mcp](https://github.com/ChromeDevTools/chrome-devtools-mcp) `skills/chrome-devtools-cli`, adapted to npx | Re-fetch `SKILL.md` + `references/`, re-apply the npx substitution below |

## Adaptations re-applied on every vendor update

- Brave skills reference `BRAVE_SEARCH_API_KEY` upstream; this repo's
  canonical name is `BRAVE_API_KEY` (exported by
  `scripts/refresh-secrets.sh` from Bitwarden). Rename on adopt and on
  every update.
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
- `brave_summarizer` is deprecated upstream; use the `answers` skill.
- Playwright CLI sessions default to headless with a 1-hour idle timeout.
