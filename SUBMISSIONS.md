# Submission drafts for Agent Skills registries

Ready-to-paste entries for each curated community list, with the
exact format each list requires and a brief note on when to submit.

The general rule across all curated lists: **don't submit a brand-new
project**. Most lists explicitly reject submissions without prior
adoption. Wait for at least one of:

- ≥50 npm weekly downloads on `@agent-bus-connect/cli`, or
- ≥25 GitHub stars on `MustaphaSteph/agent-bus`, or
- ≥3 unrelated users opening issues / discussing the project, or
- 30+ days since first public release

Then revisit and submit the entries below.

---

## VoltAgent / awesome-agent-skills

Repo: <https://github.com/VoltAgent/awesome-agent-skills>
Gate: "Give your skill time to mature and gain users before submitting."

**Section to add to:** `## Community Skills` → `### Productivity`
or `### Other` (whichever the maintainer prefers — both are reasonable).

**Entry (one line, ≤10-word description):**

```markdown
- **[MustaphaSteph/agent-bus](https://github.com/MustaphaSteph/agent-bus)** - Local message bus for AI agent-to-agent coordination
```

---

## alirezarezvani / claude-skills

Repo: <https://github.com/alirezarezvani/claude-skills>
Gate: implied curation — wait for adoption.

Per their README, entries are grouped by domain. agent-bus fits under
**Engineering** or **Productivity / Agent Orchestration**.

**Entry:**

```markdown
### agent-bus
Local SQLite-backed message bus that lets multiple Claude Code, Codex,
and Cursor sessions talk to each other on the same machine.
Bundles MCP server + cross-tool Agent Skill + slash commands.
Install: `npm i -g @agent-bus-connect/cli`
Repo: https://github.com/MustaphaSteph/agent-bus
Plugins: https://github.com/MustaphaSteph/agent-bus-plugins
```

---

## Hashgraph-Online / awesome-codex-plugins

Repo: <https://github.com/hashgraph-online/awesome-codex-plugins>
Gate: live registry at <https://hol.org/registry/plugins>. Submit
when the agent-bus-plugins repo has its first proper release tag.

**Entry (per the existing awesome-list pattern):**

```markdown
- **[MustaphaSteph/agent-bus-plugins](https://github.com/MustaphaSteph/agent-bus-plugins)** — Local message bus plugin: bundles agent-bus MCP server (56 tools), coordinator skill, Stop hook for listener resilience. `codex plugin marketplace add MustaphaSteph/agent-bus-plugins`
```

---

## Anthropic / claude-plugins-official

Repo: <https://github.com/anthropics/claude-plugins-official>
Gate: this is Anthropic's curated marketplace; entries are admitted
via a PR but adoption + quality bar is high. Realistic milestone:
≥100 stars on agent-bus + working plugin demo video.

**Entry (per claude-plugins-official's `marketplace.json` schema):**

```json
{
  "name": "agent-bus",
    "description": "Local message bus for AI agent-to-agent communication. 56 MCP tools across messaging, team-scoped send/ask/boards, channels, capability routing, conversation threads, first-class tasks, task events, result bundles, cancellation, status boards, decisions, memories, session briefs, review gates, and final reports. Lets multiple Claude Code, Codex, and Cursor sessions on the same machine collaborate via a single SQLite file. Ships the universal `agent-bus` Agent Skill plus /main and /listen slash commands.",
  "author": {
    "name": "Mustapha Achtaou"
  },
  "category": "productivity",
  "source": {
    "source": "git-subdir",
    "url": "https://github.com/MustaphaSteph/agent-bus-plugins.git",
    "path": "claude-code/plugins/agent-bus",
    "ref": "<release-tag-here>",
    "sha": "<sha-here>"
  },
  "homepage": "https://github.com/MustaphaSteph/agent-bus"
}
```

Pre-PR checklist for this one:

- [ ] Cut a real release tag on `agent-bus-plugins` (e.g. `v0.12.0`)
- [ ] Fill in `ref` and `sha`
- [ ] Working demo video or animated GIF in the agent-bus-plugins README
- [ ] Stars / install metrics proving usage

---

## agentskills.io (the spec maintainers)

Repo: <https://github.com/agentskills/agentskills>
Gate: this is the spec repo, not a registry. No PR needed. Instead,
open a brief Discussion when we have adoption to put agent-bus on
their radar.

**Discussion title:** `agent-bus — cross-tool agent IPC built on Agent Skills`

**Body:**

> Wanted to put this on the spec maintainers' radar. `agent-bus` is a
> local message bus for AI agent-to-agent coordination across Claude
> Code, Codex, Cursor, and other MCP-aware tools. It ships:
>
> - An MCP server (`@agent-bus-connect/cli` on npm, 56 tools)
> - A universal `agent-bus` Agent Skill that translates natural
>   language ("ask the reviewer", "delegate this") into the right
>   tool calls
> - Codex and Claude Code plugin marketplaces that bundle everything
> - A universal `install.sh` fallback for tools without plugin systems
>
> Source: <https://github.com/MustaphaSteph/agent-bus>
> Plugins: <https://github.com/MustaphaSteph/agent-bus-plugins>
>
> Happy to discuss if there's interest in linking to it from the
> agentskills.io clients page (currently it lists products like
> Claude Code and Cursor; agent-bus is a layer *on top of* them
> rather than a peer, but the cross-tool nature might make it
> noteworthy).

---

## Tracking submitted state

When a submission goes through, update this section:

| Registry | Status | Date | Notes |
|---|---|---|---|
| VoltAgent/awesome-agent-skills | not submitted | — | wait for maturity |
| alirezarezvani/claude-skills | not submitted | — | wait for maturity |
| hashgraph-online/awesome-codex-plugins | not submitted | — | needs release tag |
| anthropics/claude-plugins-official | not submitted | — | high bar |
| agentskills/agentskills (Discussion) | not submitted | — | wait for first users |
