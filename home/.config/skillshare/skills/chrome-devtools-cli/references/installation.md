# Installation (dotfiles adaptation)

No install needed. Every command in the parent skill runs through npx, which
fetches `chrome-devtools-mcp` on first use:

```sh
npx -y -p chrome-devtools-mcp@latest chrome-devtools status
```

Upstream installs it globally (`npm i -g chrome-devtools-mcp`); this copy
uses the npx form instead so no global package or PATH change is required.
When refreshing from upstream, re-apply that substitution
(`s/^chrome-devtools /npx -y -p chrome-devtools-mcp@latest chrome-devtools /`
plus backticked mentions).
