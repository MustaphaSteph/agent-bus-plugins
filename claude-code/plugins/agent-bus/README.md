# agent-bus (Claude Code plugin)

Local message bus for AI agent-to-agent communication. Installs the `agent-bus` MCP server (56 tools, including team-scoped send/ask/boards), the universal coordinator skill, two slash commands, and a Stop hook for listener resilience.

## What you get after install

| Surface | Effect |
|---|---|
| **56 MCP tools** | Messaging, ask/reply, team-scoped send/ask/boards, channels, capability/role routing, `directory`, project/area-scoped reads, first-class tasks, assignment, acknowledgements, task progress events, task result bundles, cancellation, review gates, handoffs, scope checks, status controls, decisions, memories, session briefs, and final reports. |
| **`/main <name>` slash command** | Primes a coordinator session to translate natural language ("ask the reviewer", "delegate this", "put worker-2 to sleep", "final merge report") into the right bus calls. No tool names to remember. |
| **`/listen <name>` slash command** | Turns a session into a silent helper that responds when called. |
| **`agent-bus` skill** | The cross-tool playbook bundled as an Agent Skill. Loads on demand via progressive disclosure. |
| **Stop hook** | Auto-resumes listener sessions that fall out of the inbox loop. Safe no-op for non-listener sessions. |

## Prerequisite

The plugin uses the `@agent-bus-connect/cli` npm package for the MCP binary. Install it once per machine before (or after) installing the plugin:

```bash
npm i -g @agent-bus-connect/cli
```

If you skip this, every bus tool call will fail until you install. The plugin's own skill prints a clear setup-check error in that case. It can also install or upgrade the CLI when explicitly run with:

```bash
~/.claude/skills/agent-bus/scripts/check-setup.sh --install-cli
```

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
