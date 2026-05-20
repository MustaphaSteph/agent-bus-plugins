# agent-bus plugins

<p>
  <a href="https://github.com/MustaphaSteph/agent-bus"><img src="https://img.shields.io/badge/agent--bus-source-2563eb.svg" alt="agent-bus source" /></a>
  <a href="https://www.npmjs.com/package/@agent-bus-connect/cli"><img src="https://img.shields.io/npm/v/@agent-bus-connect/cli.svg?label=npm%20agent-bus" alt="npm version" /></a>
  <a href="https://agentskills.io"><img src="https://img.shields.io/badge/Agent_Skills-compatible-2563eb.svg" alt="Agent Skills compatible" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/github/license/MustaphaSteph/agent-bus-plugins.svg" alt="license" /></a>
</p>

Codex and Claude Code plugins that bundle:

- The **agent-bus MCP server** ([`@agent-bus-connect/cli`](https://www.npmjs.com/package/@agent-bus-connect/cli)) — 34 tools for agent-to-agent messaging, tasks, channels, capability routing, status boards, decisions, memories, session briefs, and final reports.
- The **universal `agent-bus` Agent Skill** — natural-language coordinator playbook ("ask the reviewer", "delegate this", "get a second opinion", "put worker-2 to sleep", "final merge report") that translates intent into tool calls without users naming tools or parameters.
- Optional **Stop hook** for listener resilience (Claude Code: on by default; Codex: opt-in).

Source code for the bus itself lives at <https://github.com/MustaphaSteph/agent-bus>.

## Prerequisites

Install the bus binary once per machine:

```bash
npm i -g @agent-bus-connect/cli
```

That puts `agent-bus` (CLI) and `agent-bus-mcp` (MCP stdio server) on your PATH. Plugins below verify both are available through the bundled setup checker. They do not silently install npm packages; run the checker or installer with `--install-cli` when you want it to fix a missing or old CLI.

## Install in Codex (CLI + Desktop)

Step 1 — add the marketplace:

```bash
codex plugin marketplace add MustaphaSteph/agent-bus-plugins
```

The Codex marketplace lives at the repo root (`.agents/plugins/marketplace.json`), so no `--sparse` flag needed.

Step 2 — install the `agent-bus` plugin from Codex's plugin UI (in Codex CLI's interactive mode or Codex Desktop's plugin panel). Current Codex CLI builds expose only `codex plugin marketplace add/upgrade/remove` from the shell — the actual `install` action happens inside the agent UI. Once a future Codex CLI build ships a `codex plugin install <name>` subcommand, this step will also be runnable from a script.

**Hooks note:** the listener-resume Stop hook ships **disabled by default**. To opt in, edit `~/.codex/config.toml`:

```toml
[features]
plugin_hooks = true
```

Then re-install or reload the plugin. Without the hook, listener mode still works via the long-blocking `inbox(wait_s=110)` call alone — the hook is purely a recovery path for sessions that fall out of the loop.

## Install in Cursor / Gemini CLI / Goose / OpenCode / Junie / Amp / Kiro / others

If your tool supports the open [Agent Skills](https://agentskills.io) format but doesn't have a plugin marketplace, use the universal installer:

```bash
curl -fsSL https://raw.githubusercontent.com/MustaphaSteph/agent-bus-plugins/main/install.sh | sh
```

It auto-detects every supported tool's config directory under `$HOME` and drops the canonical `agent-bus` skill into each one's `skills/` folder. Then prints the per-tool MCP-server registration hints so you can finish wiring up the bus.

Options:

```bash
./install.sh --dry-run                    # show plan, change nothing
./install.sh --target ~/.cursor/skills    # force a specific destination
./install.sh --install-cli                 # also install/upgrade the npm CLI
```

The skill needs the bus binary too. Install once with `npm i -g @agent-bus-connect/cli`, or pass `--install-cli` to this installer.

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

You should see all 34 tools and (if no agents are registered yet) an empty agent list.

If something's off, run the skill's setup checker:

```bash
~/.claude/skills/agent-bus/scripts/check-setup.sh        # Claude Code
~/.codex/skills/agent-bus/scripts/check-setup.sh         # Codex
```

That validates Node ≥ 20, `agent-bus-mcp` on PATH, and that the installed CLI version satisfies the skill's `requires` field.
To install/upgrade the CLI from the checker explicitly:

```bash
~/.claude/skills/agent-bus/scripts/check-setup.sh --install-cli
~/.codex/skills/agent-bus/scripts/check-setup.sh --install-cli
```

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
├── install.sh                         ← universal fallback for skills-aware tools
├── scripts/sync-skill.sh              ← vendors skill into BOTH plugin paths
├── .sync-version                       ← what tag/commit the vendored skill came from
└── package.json
```

## Versioning

The skill is **vendored**, not git-submoduled. Single canonical copy lives in the [main `agent-bus` repo](https://github.com/MustaphaSteph/agent-bus/tree/main/skills/agent-bus) at the ref listed in `.sync-version`. CI fails any PR that ships a vendored copy that drifts from the pinned ref.

Bumping the skill means:

1. Update + commit the skill in the main repo.
2. In this repo, bump the pinned ref in `scripts/sync-skill.sh` when needed.
3. Run `npm run sync-skill`.
4. Commit the regenerated `plugins/agent-bus/skills/agent-bus/` and `.sync-version`.
5. Push.

For local dev iteration without tagging, use `npm run sync-skill:dev` (reads from `../agent-bus/`).

## Troubleshooting

| Symptom | Fix |
|---|---|
| `agent-bus-mcp: command not found` after plugin install | Run `npm i -g @agent-bus-connect/cli` first. The plugin requires the bus binary to already be on PATH. |
| Setup checker says CLI is missing or old | Run `<skills-dir>/agent-bus/scripts/check-setup.sh --install-cli` to install/upgrade via npm. |
| Skill installed but tools not visible | Open a NEW session — Claude Code / Codex read MCP config at session start. |
| Codex Stop hook doesn't trigger | Check `[features].plugin_hooks = true` in `~/.codex/config.toml` and reload the plugin. Without that flag, plugin-bundled hooks are inert in Codex. |
| Setup check exit non-zero | Read the printed install hint; the script's exit message tells you exactly what's missing. |

## License

MIT.
