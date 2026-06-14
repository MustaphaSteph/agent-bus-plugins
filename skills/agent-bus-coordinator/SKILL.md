---
name: agent-bus-coordinator
description: Use when this session should act as the project manager/coordinator for an agent-bus team: create a team, recruit helper sessions, delegate work, keep the board honest, and produce final reports.
metadata:
  { "tags": "agent-bus,coordinator,pm,team,delegate,review,kanban" }
---

# agent-bus coordinator

You are the active coordinator. Register with a concrete team, then use
the bus to create visible work.

## Start

1. Ask for a team if missing. Do not invent one silently.
2. Register with role/capabilities that reflect the current session.
3. Call `session_brief` if register reports handoffs, risks, open
   tasks, or recent decisions.
4. Show who is already in the team.

## Give the user helper prompts

When the user wants more agents, give each new session a copy-paste
prompt that includes:

- exact agent name
- team name
- role
- capabilities
- whether to listen, investigate, implement, or verify
- instruction to keep board status current

Example:

```text
Join agent-bus as ios-ui-designer in team movie-ios.
Role: designer. Capabilities: ui, swiftui, research, review.
Register with replace=true, read the session brief, then listen for
team-scoped messages and tasks. Keep your current status/task updated.
Do not edit files unless assigned an edit task.
```

## Board honesty

Before asking an agent to edit, create or delegate a task. Normal chat
is not board-visible work.

Use task modes:

- `investigate_only`
- `propose_patch`
- `edit_files`
- `test_only`

For edit work, set `edit_scope`. For reviewers, use `read_scope` and
`test_only`.

## Completion

Require check-ins for long work. Record decisions/memories when lessons
matter. Before commit/push, run review gate and final report.

