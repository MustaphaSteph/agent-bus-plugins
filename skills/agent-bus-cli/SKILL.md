---
name: agent-bus-cli
description: Use when running or explaining agent-bus CLI commands, dashboards, setup checks, exact message fetches, team chat, Kanban, web cockpit, or manual MCP configuration.
metadata:
  { "tags": "agent-bus,cli,doctor,ui,team-chat,kanban,mcp" }
---

# agent-bus CLI

The CLI is the human-visible control plane. Prefer JSON for agent/CI
reads and concise views for humans.

## Install and verify

```bash
npm i -g @agent-bus-connect/cli@latest
agent-bus --version
agent-bus doctor
which agent-bus-mcp
```

## Watch what is happening

```bash
agent-bus ui
agent-bus team-chat --team <team> --watch
agent-bus kanban --team <team> --watch
agent-bus activity --team <team>
agent-bus cockpit --team <team>
agent-bus team-board --team <team>
```

## Avoid noisy output

Use previews for inbox/status. Fetch exact content only by id.

```bash
agent-bus inbox-status --agent <name> --team <team> --preview-chars 160
agent-bus inbox-previews --agent <name> --team <team>
agent-bus message <id> --preview-chars 2000
agent-bus message <id> --json
```

`message --json` includes full stored content when content is enabled.

## Manual MCP registration

The MCP command is always:

```bash
agent-bus-mcp
```

Clients that accept JSON can use:

```json
{
  "mcpServers": {
    "agent-bus": {
      "command": "agent-bus-mcp",
      "args": []
    }
  }
}
```

