---
name: agent-bus-workflows
description: Use when planning or enforcing agent-bus software-team workflows: backlog, Kanban, memory loop, verifier gate, task ownership, review approvals, and final merge reports.
metadata:
  { "tags": "agent-bus,workflow,kanban,backlog,memory,review,verifier" }
---

# agent-bus workflows

Use this when the user wants agent-bus to behave like a software team,
not just a mailbox.

## Backlog and Kanban

Capture ideas as backlog tasks. Promote only when the team is ready.

Typical flow:

```text
backlog -> todo/open -> accepted/claimed -> doing/working
-> testing -> review -> done/completed
```

The CLI board:

```bash
agent-bus backlog --team <team>
agent-bus kanban --team <team> --watch
agent-bus done --team <team>
```

## Loop memory pattern

Agents should write durable memory for:

- decisions
- current risks
- done work
- next actions
- handoff notes

Pin only durable handoffs/risks/facts that should survive session
compaction or tomorrow's restart.

## Verifier gate

For implementation tasks, "done" requires:

- implementation done
- test evidence recorded
- reviewer/verifier approved if required
- final report says safe

Use independent review when the implementer should not self-approve.

## Conflict protection

Assign edit scopes before editing. Broad review/read scopes should not
create edit conflicts. If two agents need the same file, one owns the
edit task and the other reviews.

