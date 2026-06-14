---
name: agent-bus-read-first
description: START HERE when a user wants multiple AI coding sessions to coordinate through agent-bus, install the plugin, create a team, use the web cockpit, or decide whether to use MCP tools, CLI commands, listener sessions, tasks, memories, reviews, or final reports.
metadata:
  { "tags": "agent-bus,read-first,router,multi-agent,mcp,coordination" }
---

# agent-bus — read this first

agent-bus is a local SQLite-backed message bus for AI coding sessions on
the same machine. It connects Claude Code, Codex, Kimi, Cursor, Gemini
CLI, and any other MCP-capable client through one `agent-bus-mcp`
server and one `~/.agent-bus/bus.db` database.

Use the canonical `/agent-bus` skill for the detailed tool contract.
Use this skill to choose the right workflow quickly.

## Setup gate

Before doing bus work, verify the CLI/MCP binary exists:

```bash
agent-bus doctor
agent-bus --version
which agent-bus-mcp
```

If missing:

```bash
npm i -g @agent-bus-connect/cli@latest
```

Plugin installs do not run npm scripts. Kimi also explicitly does not
execute plugin code at install/session start; the npm CLI remains a
separate prerequisite.

## Route by user intent

| User intent | Use |
|---|---|
| "Create a team / make agents work together" | `/agent-bus-coordinator` |
| "This session should wait and answer" | `/agent-bus-listener` |
| "Which commands do I run?" | `/agent-bus-cli` |
| "How should we manage tasks/reviews/memory?" | `/agent-bus-workflows` |
| Any detailed MCP/tool behavior | `/agent-bus` |

## Best default model

Use **teams** as the work boundary. A team is the room for chat, task
boards, memories, and the web cockpit.

Default roles are descriptive, not hard-coded:

- `pm` or `coordinator`: plans, delegates, watches board honesty
- `designer`: proposes UI/UX direction
- `developer`: implements scoped work
- `verifier` or `reviewer`: tests, reviews, and approves
- `listener`: waits quietly for work

Agents can talk directly without a coordinator, but for serious repo
work a coordinator should create/claim tasks before edits start.

## MCP vs CLI

Use MCP tools from inside an agent session for live coordination:
register, send, ask, delegate, tasks, memories, decisions, reviews.

Use CLI commands for human-visible dashboards and exact inspection:

```bash
agent-bus ui
agent-bus team-chat --team <team> --watch
agent-bus kanban --team <team> --watch
agent-bus message <id> --json
agent-bus task-result <id>
agent-bus final-report --team <team>
```

## Completion rule

For implementation work, "done" should mean:

1. task exists and was claimed before editing
2. implementation finished
3. test evidence recorded
4. reviewer approved when review is required
5. final report says safe to commit/push

