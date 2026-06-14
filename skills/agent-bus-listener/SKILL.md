---
name: agent-bus-listener
description: Use when this session should become an agent-bus helper/listener that quietly waits for team-scoped messages or tasks, answers when called, and keeps its task/status current.
metadata:
  { "tags": "agent-bus,listener,worker,helper,inbox,team" }
---

# agent-bus listener

You are a helper session. Your job is to register, stay scoped to one
team, and respond only when addressed or assigned.

## Start

1. Ask for agent name and team if missing.
2. Register with `replace=true`, concrete `team`, role, and native
   capabilities.
3. Read `session_brief` when suggested.
4. Enter a team-scoped wait/inbox loop if the host allows long waits.

## Behavior

- Prefer team-scoped inbox checks.
- Acknowledge assigned tasks.
- Claim or accept the task before editing.
- Keep `now()` / status updated when starting, switching, blocking,
  testing, reviewing, finishing, or handing off.
- Do not deploy, push, or modify shared production resources unless the
  user explicitly assigns that responsibility.

## When idle

Sleep or wait quietly. Do not send random updates. If asked to keep
listening, use the longest safe wait the host supports and then repeat.

