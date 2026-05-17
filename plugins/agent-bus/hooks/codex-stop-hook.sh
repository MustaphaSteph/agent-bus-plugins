#!/bin/sh
# Codex Stop hook for agent-bus listener resilience.
#
# Codex passes hook context via stdin (JSON). We read it, look for the
# session_id, and call `agent-bus poll-inbox` to decide whether to keep
# the agent in the listener loop or let it return control to the user.
#
# Safe no-op when:
#   - agent-bus CLI is not on PATH
#   - the session has no listener marker (i.e. this session never ran /listen)
#   - stop_hook_active is already true (avoid loops)
#   - any unexpected error
#
# Opt-in: Codex only invokes plugin-bundled hooks when
#         [features].plugin_hooks = true in ~/.codex/config.toml.

set -e

# Bail quietly if the bus CLI isn't installed.
if ! command -v agent-bus >/dev/null 2>&1; then
  exit 0
fi

# Read hook JSON from stdin. Codex sends an object with
# session_id and stop_hook_active among other fields.
INPUT="$(cat 2>/dev/null || true)"

# If stop_hook_active is already true, exit silently to avoid loops.
if printf '%s' "$INPUT" | grep -q '"stop_hook_active"[[:space:]]*:[[:space:]]*true'; then
  exit 0
fi

# Extract session_id (best-effort, POSIX-portable).
SESSION_ID="$(printf '%s' "$INPUT" | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"

# Fall back to CODEX_SESSION_ID env if stdin parsing failed.
if [ -z "$SESSION_ID" ] && [ -n "${CODEX_SESSION_ID:-}" ]; then
  SESSION_ID="$CODEX_SESSION_ID"
fi

if [ -z "$SESSION_ID" ]; then
  exit 0
fi

# Look up the agent name this session registered as a listener for.
# This is written by `agent-bus mark-listening --session <id> --agent <name>`
# during the /listen flow. If no marker exists, this session isn't in
# listener mode and we should not resume anything.
LISTENER_DIR="${AGENT_BUS_DIR:-$HOME/.agent-bus}/listeners"
MARKER="$LISTENER_DIR/$SESSION_ID.json"
if [ ! -f "$MARKER" ]; then
  exit 0
fi

AGENT="$(sed -n 's/.*"agent"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$MARKER" | head -1)"
if [ -z "$AGENT" ]; then
  exit 0
fi

# Delegate to agent-bus poll-inbox; it prints a Stop-hook decision JSON
# to stdout if it wants to block (i.e. keep listening) and exits 0 otherwise.
exec agent-bus poll-inbox --agent "$AGENT" --session "$SESSION_ID"
