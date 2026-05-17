#!/bin/sh
# agent-bus Stop hook handler for Claude Code.
#
# On every turn-end, this script:
#   1. Bails silently if `agent-bus` CLI isn't on PATH (no-op when not installed).
#   2. Reads Claude Code's hook JSON from stdin to find session_id and the
#      stop_hook_active flag.
#   3. If stop_hook_active is true (we already blocked once this turn), exit 0
#      to avoid an infinite loop.
#   4. Looks up this session's listener marker file (written by `agent-bus
#      mark-listening` from inside the /listen slash command).
#   5. If a marker exists, delegates to `agent-bus poll-inbox` which decides
#      whether to emit a Stop-hook block-decision (keep listening) or exit 0
#      (return control to the user).
#
# In every "I don't apply here" case, this script silently exits 0 — never
# blocks Claude when it shouldn't.

set -e

# 1. Bus CLI not installed → no-op.
if ! command -v agent-bus >/dev/null 2>&1; then
  exit 0
fi

# 2. Read hook stdin.
INPUT="$(cat 2>/dev/null || true)"

# 3. Loop guard.
if printf '%s' "$INPUT" | grep -q '"stop_hook_active"[[:space:]]*:[[:space:]]*true'; then
  exit 0
fi

# Find session_id. Claude Code passes it on stdin; CLAUDE_SESSION_ID env is the fallback.
SESSION_ID="$(printf '%s' "$INPUT" | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
if [ -z "$SESSION_ID" ] && [ -n "${CLAUDE_SESSION_ID:-}" ]; then
  SESSION_ID="$CLAUDE_SESSION_ID"
fi
if [ -z "$SESSION_ID" ]; then
  exit 0
fi

# 4. Listener marker lookup.
LISTENER_DIR="${AGENT_BUS_DIR:-$HOME/.agent-bus}/listeners"
MARKER="$LISTENER_DIR/$SESSION_ID.json"
if [ ! -f "$MARKER" ]; then
  exit 0
fi

AGENT="$(sed -n 's/.*"agent"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$MARKER" | head -1)"
if [ -z "$AGENT" ]; then
  exit 0
fi

# 5. Delegate to agent-bus poll-inbox (it writes the Stop-hook decision JSON to stdout).
exec agent-bus poll-inbox --agent "$AGENT" --session "$SESSION_ID"
