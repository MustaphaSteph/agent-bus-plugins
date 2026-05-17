# agent-bus plugins

Codex and Claude Code plugins that bundle:

- The **agent-bus MCP server** ([`@agent-bus-connect/cli`](https://www.npmjs.com/package/@agent-bus-connect/cli)) — 20 tools for agent-to-agent messaging, tasks, channels, capability routing.
- The **universal `agent-bus` Agent Skill** — natural-language coordinator playbook ("ask the reviewer", "delegate this", "get a second opinion") that translates intent into tool calls without users naming tools or parameters.
- Optional **Stop hook** for listener resilience (Claude Code: on by default; Codex: opt-in).

Source code for the bus itself lives at <https://github.com/MustaphaSteph/agent-bus>.

## Prerequisites

Install the bus binary once per machine:

```bash
npm i -g @agent-bus-connect/cli
```

That puts `agent-bus` (CLI) and `agent-bus-mcp` (MCP stdio server) on your PATH. Plugins below assume both are available.

## Install in Codex (CLI + Desktop)

```bash
codex plugin marketplace add MustaphaSteph/agent-bus-plugins
codex plugin install agent-bus
```

The Codex marketplace lives at the repo root (`.agents/plugins/marketplace.json`), so no `--sparse` flag needed.

**Hooks note:** the listener-resume Stop hook ships **disabled by default**. To opt in, edit `~/.codex/config.toml`:

```toml
[features]
plugin_hooks = true
```

Then re-install or reload the plugin. Without the hook, listener mode still works via the long-blocking `inbox(wait_s=110)` call alone — the hook is purely a recovery path for sessions that fall out of the loop.

## Install in Claude Code

```
/plugin
> Marketplaces
> Add MustaphaSteph/agent-bus-plugins
> Install agent-bus
```

The marketplace manifest lives at `.claude-plugin/marketplace.json` at the repo root, so the bare `owner/repo` form works without flags.

The plugin bundles:

- The agent-bus MCP server (declared via the `@agent-bus-connect/cli` npm binary — install it once with `npm i -g @agent-bus-connect/cli`)
- The `agent-bus` skill (cross-tool coordinator playbook)
- `/main <name>` slash command — primes a coordinator session to talk to the bus in natural language
- `/listen <name>` slash command — turns a session into a passive helper that responds when called
- Always-on Stop hook for listener resilience (Claude Code doesn't gate plugin hooks the way Codex does)

## Verify

After install, in any new session:

```
List the agent-bus MCP tools and call whois.
```

You should see all 20 tools and (if no agents are registered yet) an empty agent list.

If something's off, run the skill's setup checker:

```bash
~/.claude/skills/agent-bus/scripts/check-setup.sh        # Claude Code
~/.codex/skills/agent-bus/scripts/check-setup.sh         # Codex
```

That validates Node ≥ 20, `agent-bus-mcp` on PATH, and that the installed CLI version satisfies the skill's `requires` field.

## Repo layout

```
.
├── .agents/plugins/marketplace.json   ← Codex marketplace at root
├── plugins/agent-bus/                 ← Codex plugin body
│   ├── .codex-plugin/plugin.json
│   ├── .mcp.json                       (command: agent-bus-mcp)
│   ├── hooks/hooks.json                (disabled by default)
│   └── skills/agent-bus/               (vendored from main repo)
├── .claude-plugin/marketplace.json    ← Claude Code marketplace at root
├── claude-code/plugins/agent-bus/     ← Claude Code plugin body
│   ├── .claude-plugin/plugin.json
│   ├── commands/{main,listen}.md
│   ├── hooks/hooks.json
│   ├── hooks-handlers/stop-hook.sh
│   └── skills/agent-bus/              (vendored, same content as Codex copy)
├── scripts/sync-skill.sh              ← vendors skill into BOTH plugin paths
├── .sync-version                       ← what tag/commit the vendored skill came from
├── package.json
│
│   # Coming in later phases:
└── install.sh                         ← universal fallback for tools without plugin systems (Phase 4)
```

## Versioning

The skill is **vendored**, not git-submoduled. Single canonical copy lives in the [main `agent-bus` repo](https://github.com/MustaphaSteph/agent-bus/tree/main/skills/agent-bus) at the tag listed in `.sync-version`. CI fails any PR that ships a vendored copy that drifts from the pinned tag.

Bumping the skill means:

1. Update + commit + tag in the main repo.
2. In this repo, bump the pinned tag in `scripts/sync-skill.sh`.
3. Run `npm run sync-skill`.
4. Commit the regenerated `plugins/agent-bus/skills/agent-bus/` and `.sync-version`.
5. Push.

For local dev iteration without tagging, use `npm run sync-skill:dev` (reads from `../agent-bus/`).

## Troubleshooting

| Symptom | Fix |
|---|---|
| `agent-bus-mcp: command not found` after plugin install | Run `npm i -g @agent-bus-connect/cli` first. The plugin requires the bus binary to already be on PATH. |
| Skill installed but tools not visible | Open a NEW session — Claude Code / Codex read MCP config at session start. |
| Codex Stop hook doesn't trigger | Check `[features].plugin_hooks = true` in `~/.codex/config.toml` and reload the plugin. Without that flag, plugin-bundled hooks are inert in Codex. |
| Setup check exit non-zero | Read the printed install hint; the script's exit message tells you exactly what's missing. |

## License

MIT.
