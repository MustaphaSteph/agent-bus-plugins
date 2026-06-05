# agent-bus (Claude Code plugin)

Local message bus for AI agent-to-agent communication. Installs the `agent-bus` MCP server (63 tools, including async asks, truncation-safe inbox previews, exact message fetches, team-scoped send/ask/delegation/boards, activity timelines, cockpit dashboards, visible current-work updates, and workflow Kanban), CLI/UI views including the Slack-style local `agent-bus ui` web cockpit and team chat, the universal coordinator skill, two slash commands, and a Stop hook for listener resilience.

## What you get after install

| Surface | Effect |
|---|---|
| **63 MCP tools + UI** | Messaging, ask/reply, async asks, truncation-safe inbox previews, exact message fetches, team-scoped send/ask/delegation/boards, Slack-style multi-project local web cockpit, activity timelines, cockpit dashboards, visible current-work updates, workflow Kanban, channels, capability/role routing, `directory`, project/area-scoped reads, first-class tasks, assignment, acknowledgements, task progress events, task result bundles, cancellation, review gates, handoffs, scope checks, status controls, decisions, memories, session briefs, and final reports. |
| **`/main <name>` slash command** | Primes a coordinator session to translate natural language ("ask the reviewer", "delegate this", "put worker-2 to sleep", "final merge report") into the right bus calls. No tool names to remember. |
| **`/listen <name>` slash command** | Turns a session into a silent helper that responds when called. |
| **`agent-bus` skill** | The cross-tool playbook bundled as an Agent Skill. Loads on demand via progressive disclosure. |
| **Stop hook** | Auto-resumes listener sessions that fall out of the inbox loop. Safe no-op for non-listener sessions. |

## Prerequisite

The plugin uses the `@agent-bus-connect/cli` npm package for the MCP binary. Install it once per machine before (or after) installing the plugin:

```bash
npm i -g @agent-bus-connect/cli
```

If you skip this, Claude Code may show an `ENOENT` MCP startup error
because it cannot find `agent-bus-mcp`. Install the package, verify
`which agent-bus-mcp`, then reconnect `/mcp` or restart Claude Code.
The plugin's own skill also prints a setup-check error in that case. It
can install or upgrade the CLI when explicitly run with:

```bash
~/.claude/skills/agent-bus/scripts/check-setup.sh --install-cli
```

If the setup checker still says the installed CLI is older than
required after installing `latest`, the plugin was released ahead of the
npm package. Check `npm view @agent-bus-connect/cli version`; publish
the required CLI version before releasing the plugin.

## Try it after install

Open two new Claude Code sessions.

**Terminal A** — the helper:
```
/listen helper-a
```

**Terminal B** — your main session:
```
/main me
```
Then naturally:
```
Ask helper-a what 17 × 23 is.
```

Terminal A receives, computes, replies. Terminal B prints "helper-a says: 391." No tool names typed.

## Repo

Source: <https://github.com/MustaphaSteph/agent-bus>
Plugin home: <https://github.com/MustaphaSteph/agent-bus-plugins>

## License

MIT.
