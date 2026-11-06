---
name: muse-mcp-mirror
description: Mirror skillshare MCP declarations into Muse Code settings after any MCP add, change, or removal. Use when MCP servers change and Muse Code must keep working with the same tools.
---

# Muse MCP Mirror

skillshare does not write Muse Code's MCP config. After changing MCP
servers in the skillshare source, mirror the change into Muse Code by hand.

## Workflow

1. Update the declaration in `~/.config/skillshare/config.yaml` (`mcp.servers`).
2. Run `skillshare sync mcp` for the supported clients.
3. If a new keyed server was added, add its Bitwarden item and the matching
   merge stanza in `project_muse_mcp` inside `scripts/refresh-secrets.sh`
   first. The script injects `CONTEXT7_API_KEY` and `BRAVE_API_KEY` itself,
   so never paste those literals by hand.
4. Run `scripts/refresh-secrets.sh` to project the keys into
   `~/.config/muse/settings.json`. It preserves every other key and never
   writes a `mcp_servers` key next to `mcpServers`.
5. For a server the script does not know yet, merge it by hand:
   - `command`/`args`/`env` becomes `type: "stdio"` with the same fields.
   - `url`/`headers` becomes `type: "streamable-http"` with `url` and `headers`.
   - Always add `"mode": "optional"` so a failing server cannot block startup.
   - Muse Code does not expand `${VAR}`: ask the user for the literal value,
     write it only when supplied, and leave the server out rather than write
     the reference.
6. Re-read the file to confirm the saved result. Remind that MCP changes
   apply on the next Muse Code launch.
