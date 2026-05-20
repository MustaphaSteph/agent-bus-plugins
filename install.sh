#!/bin/sh
# agent-bus universal fallback installer.
#
# For agent clients that support the Agent Skills format but don't have a
# plugin marketplace (Cursor, Gemini CLI, Goose, OpenCode, Junie, Amp,
# Kiro, fast-agent, …), this script drops the canonical `agent-bus`
# skill into each tool's skills directory it can detect. It does NOT
# install the MCP server itself — that's a separate npm step, which the
# script prints at the end.
#
# Usage:
#
#   curl -fsSL https://raw.githubusercontent.com/MustaphaSteph/agent-bus-plugins/main/install.sh | sh
#
# or, after cloning the repo:
#
#   ./install.sh                         # detect every supported tool, install to each
#   ./install.sh --target ~/.cursor/skills  # force a specific destination
#   ./install.sh --dry-run               # print plan, change nothing
#
# Exit codes:
#   0 — installed somewhere (or dry-run completed)
#   1 — no skills directory detected and no --target given
#   2 — invalid usage

set -e

# ---- args ----

DRY_RUN=0
EXPLICIT_TARGET=""
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run|-n)
      DRY_RUN=1
      shift
      ;;
    --target)
      shift
      if [ -z "${1:-}" ]; then
        printf "ERROR: --target requires a path\n" >&2
        exit 2
      fi
      EXPLICIT_TARGET="$1"
      shift
      ;;
    --target=*)
      EXPLICIT_TARGET="${1#--target=}"
      shift
      ;;
    -h|--help)
      sed -n '2,30p' "$0"
      exit 0
      ;;
    *)
      printf "ERROR: unknown argument '%s'\n" "$1" >&2
      exit 2
      ;;
  esac
done

# ---- locate the source skill ----

# When run from a clone, the skill lives at skills/agent-bus next to this
# script. When piped over curl, we need to fetch the skill tarball.
SCRIPT_DIR="$(cd "$(dirname "$0")" 2>/dev/null && pwd || pwd)"
SOURCE_SKILL=""
TMP_SKILL=""
cleanup() {
  if [ -n "$TMP_SKILL" ] && [ -d "$TMP_SKILL" ]; then
    rm -rf "$TMP_SKILL"
  fi
}
trap cleanup EXIT INT HUP TERM

if [ -d "$SCRIPT_DIR/skills/agent-bus" ]; then
  # We're at the main repo root.
  SOURCE_SKILL="$SCRIPT_DIR/skills/agent-bus"
elif [ -d "$SCRIPT_DIR/plugins/agent-bus/skills/agent-bus" ]; then
  # We're at the plugins repo root.
  SOURCE_SKILL="$SCRIPT_DIR/plugins/agent-bus/skills/agent-bus"
elif [ -d "$SCRIPT_DIR/claude-code/plugins/agent-bus/skills/agent-bus" ]; then
  SOURCE_SKILL="$SCRIPT_DIR/claude-code/plugins/agent-bus/skills/agent-bus"
else
  # curl-piped invocation — fetch the skill from GitHub.
  TMP_SKILL="$(mktemp -d 2>/dev/null || mktemp -d -t agent-bus-skill)"
  TARBALL_URL="https://github.com/MustaphaSteph/agent-bus/archive/refs/heads/main.tar.gz"
  printf "Fetching latest agent-bus skill ...\n"
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$TARBALL_URL" -o "$TMP_SKILL/agent-bus.tar.gz"
  elif command -v wget >/dev/null 2>&1; then
    wget -q -O "$TMP_SKILL/agent-bus.tar.gz" "$TARBALL_URL"
  else
    printf "ERROR: neither curl nor wget available; cannot fetch the skill\n" >&2
    exit 2
  fi
  ( cd "$TMP_SKILL" && tar -xzf agent-bus.tar.gz )
  SOURCE_SKILL="$(find "$TMP_SKILL" -type d -name "agent-bus" -path "*/skills/agent-bus" | head -1)"
fi

if [ ! -f "$SOURCE_SKILL/SKILL.md" ]; then
  printf "ERROR: could not locate the canonical agent-bus skill\n" >&2
  printf "       looked in:\n" >&2
  printf "         %s/skills/agent-bus\n" "$SCRIPT_DIR" >&2
  printf "         %s/plugins/agent-bus/skills/agent-bus\n" "$SCRIPT_DIR" >&2
  exit 2
fi

# ---- targets ----

# Each candidate is "displayname:absolute_skills_dir".
# A tool is selected when its parent config dir exists (so we don't
# blindly create directories for tools the user hasn't installed).

candidates() {
  if [ -n "$EXPLICIT_TARGET" ]; then
    printf "explicit:%s\n" "$EXPLICIT_TARGET"
    return 0
  fi
  [ -d "$HOME/.claude" ]   && printf "Claude Code:%s/.claude/skills\n"   "$HOME"
  [ -d "$HOME/.codex" ]    && printf "Codex:%s/.codex/skills\n"          "$HOME"
  [ -d "$HOME/.cursor" ]   && printf "Cursor:%s/.cursor/skills\n"        "$HOME"
  [ -d "$HOME/.gemini" ]   && printf "Gemini CLI:%s/.gemini/skills\n"    "$HOME"
  [ -d "$HOME/.opencode" ] && printf "OpenCode:%s/.opencode/skills\n"    "$HOME"
  [ -d "$HOME/.goose" ]    && printf "Goose:%s/.goose/skills\n"          "$HOME"
  [ -d "$HOME/.junie" ]    && printf "Junie:%s/.junie/skills\n"          "$HOME"
  [ -d "$HOME/.amp" ]      && printf "Amp:%s/.amp/skills\n"              "$HOME"
  [ -d "$HOME/.kiro" ]     && printf "Kiro:%s/.kiro/skills\n"            "$HOME"
  # The last test above may evaluate false under set -e; explicit
  # return 0 keeps the function from propagating that exit status to
  # the command substitution.
  return 0
}

CANDS="$(candidates || true)"
if [ -z "$CANDS" ]; then
  printf "No skills-aware tool config dir detected under \$HOME.\n" >&2
  printf "Re-run with --target /path/to/skills/dir to install anyway, or install one of:\n" >&2
  printf "  Claude Code, Codex, Cursor, Gemini CLI, OpenCode, Goose, Junie, Amp, Kiro\n" >&2
  exit 1
fi

# ---- install ----

printf "agent-bus skill — source: %s\n" "$SOURCE_SKILL"
printf "\nWill install into:\n"
printf "%s\n" "$CANDS" | while IFS=":" read -r LABEL DIR; do
  printf "  - %-12s %s\n" "$LABEL" "$DIR/agent-bus"
done
[ "$DRY_RUN" = "1" ] && { printf "\n(dry-run) no files written.\n"; exit 0; }

INSTALLED=0
printf "\n"
echo "$CANDS" | while IFS=":" read -r LABEL DIR; do
  TARGET="$DIR/agent-bus"
  mkdir -p "$DIR"
  rm -rf "$TARGET"
  cp -R "$SOURCE_SKILL" "$TARGET"
  find "$TARGET/scripts" -type f -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
  printf "  ✓ %s → %s\n" "$LABEL" "$TARGET"
done

# ---- next-step hints ----

cat <<'TIPS'

Next steps:

1. Install the MCP server binary once per machine if you haven't:

     npm i -g @agent-bus-connect/cli

2. Register the agent-bus MCP server in each tool. The exact command
   differs per tool; the most common ones:

   - Claude Code:
       claude mcp add -s user agent-bus -- agent-bus-mcp

   - Codex CLI / Desktop:  edit ~/.codex/config.toml and add
       [mcp_servers.agent-bus]
       command = "/absolute/path/to/agent-bus-mcp"

   - Cursor / Gemini CLI / Goose / OpenCode / Junie / Amp / Kiro:
       see the tool's own MCP-server registration docs. The skill will
       work the moment any one of them has the agent-bus MCP loaded.

3. Verify the install in any new session by asking the agent:
     "List the agent-bus tools and call whois."

   If something's off, run the bundled setup-check script:
     <skills-dir>/agent-bus/scripts/check-setup.sh

   It validates node >= 20, agent-bus-mcp on PATH, and version.

For the turn-key plugin install (instead of the manual skill drop):

   - Claude Code: /plugin > Marketplaces > Add MustaphaSteph/agent-bus-plugins > install agent-bus
   - Codex:       codex plugin marketplace add MustaphaSteph/agent-bus-plugins

Source: https://github.com/MustaphaSteph/agent-bus
TIPS
