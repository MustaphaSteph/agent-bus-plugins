#!/bin/sh
# agent-bus universal fallback installer.
#
# For agent clients that support the Agent Skills format but don't have a
# plugin marketplace (Kimi Code, Cursor, Gemini CLI, Goose, OpenCode,
# Junie, Amp, Kiro, fast-agent, ...), this script drops the root
# agent-bus skill pack into each tool's skills directory it can detect.
# By default it
# only verifies whether the CLI is present and prints the npm command.
# Pass --install-cli to install/upgrade the MCP server CLI via npm.
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
#   ./install.sh --install-cli           # also run npm i -g @agent-bus-connect/cli@latest
#
# Exit codes:
#   0 — installed somewhere (or dry-run completed)
#   1 — no skills directory detected and no --target given
#   2 — invalid usage

set -e

# ---- args ----

DRY_RUN=0
INSTALL_CLI=0
EXPLICIT_TARGET=""
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run|-n)
      DRY_RUN=1
      shift
      ;;
    --install|--install-cli)
      INSTALL_CLI=1
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

install_cli() {
  if ! command -v npm >/dev/null 2>&1; then
    printf "ERROR: npm is not on PATH; cannot install @agent-bus-connect/cli automatically\n" >&2
    exit 2
  fi
  printf "\nInstalling/upgrading @agent-bus-connect/cli@latest ...\n"
  npm i -g @agent-bus-connect/cli@latest
  hash -r 2>/dev/null || true
}

# ---- locate the source skills ----

# When run from a clone, the skill pack lives at skills/ next to this
# script. When piped over curl, fetch the plugin repo tarball so wrapper
# skills and the canonical agent-bus skill install together.
SCRIPT_DIR="$(cd "$(dirname "$0")" 2>/dev/null && pwd || pwd)"
SOURCE_SKILLS_DIR=""
TMP_SKILLS=""
cleanup() {
  if [ -n "$TMP_SKILLS" ] && [ -d "$TMP_SKILLS" ]; then
    rm -rf "$TMP_SKILLS"
  fi
}
trap cleanup EXIT INT HUP TERM

if [ -d "$SCRIPT_DIR/skills" ] && [ -f "$SCRIPT_DIR/skills/agent-bus/SKILL.md" ]; then
  SOURCE_SKILLS_DIR="$SCRIPT_DIR/skills"
elif [ -d "$SCRIPT_DIR/plugins/agent-bus/skills/agent-bus" ]; then
  TMP_SKILLS="$(mktemp -d 2>/dev/null || mktemp -d -t agent-bus-skills)"
  mkdir -p "$TMP_SKILLS/skills"
  cp -R "$SCRIPT_DIR/plugins/agent-bus/skills/agent-bus" "$TMP_SKILLS/skills/agent-bus"
  SOURCE_SKILLS_DIR="$TMP_SKILLS/skills"
elif [ -d "$SCRIPT_DIR/claude-code/plugins/agent-bus/skills/agent-bus" ]; then
  TMP_SKILLS="$(mktemp -d 2>/dev/null || mktemp -d -t agent-bus-skills)"
  mkdir -p "$TMP_SKILLS/skills"
  cp -R "$SCRIPT_DIR/claude-code/plugins/agent-bus/skills/agent-bus" "$TMP_SKILLS/skills/agent-bus"
  SOURCE_SKILLS_DIR="$TMP_SKILLS/skills"
else
  TMP_SKILLS="$(mktemp -d 2>/dev/null || mktemp -d -t agent-bus-skills)"
  TARBALL_URL="https://github.com/MustaphaSteph/agent-bus-plugins/archive/refs/heads/main.tar.gz"
  printf "Fetching latest agent-bus skill pack ...\n"
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$TARBALL_URL" -o "$TMP_SKILLS/agent-bus-plugins.tar.gz"
  elif command -v wget >/dev/null 2>&1; then
    wget -q -O "$TMP_SKILLS/agent-bus-plugins.tar.gz" "$TARBALL_URL"
  else
    printf "ERROR: neither curl nor wget available; cannot fetch the skill pack\n" >&2
    exit 2
  fi
  ( cd "$TMP_SKILLS" && tar -xzf agent-bus-plugins.tar.gz )
  SOURCE_SKILLS_DIR="$(find "$TMP_SKILLS" -type d -name "skills" -path "*/agent-bus-plugins-*/skills" | head -1)"
fi

if [ ! -f "$SOURCE_SKILLS_DIR/agent-bus/SKILL.md" ]; then
  printf "ERROR: could not locate the agent-bus skill pack\n" >&2
  printf "       looked in:\n" >&2
  printf "         %s/skills\n" "$SCRIPT_DIR" >&2
  printf "         %s/plugins/agent-bus/skills\n" "$SCRIPT_DIR" >&2
  exit 2
fi

SKILL_NAMES="$(find "$SOURCE_SKILLS_DIR" -mindepth 1 -maxdepth 1 -type d -exec sh -c '[ -f "$1/SKILL.md" ] && basename "$1"' sh {} \; | sort)"

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
  [ -d "$HOME/.kimi" ]     && printf "Kimi Code:%s/.kimi/skills\n"       "$HOME"
  [ -d "$HOME/.kimi-code" ] && printf "Kimi Code:%s/.kimi-code/skills\n" "$HOME"
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
  printf "  Claude Code, Codex, Kimi Code, Cursor, Gemini CLI, OpenCode, Goose, Junie, Amp, Kiro\n" >&2
  exit 1
fi

# ---- install ----

printf "agent-bus skill pack - source: %s\n" "$SOURCE_SKILLS_DIR"
printf "Skills:\n"
printf "%s\n" "$SKILL_NAMES" | while IFS= read -r NAME; do
  [ -n "$NAME" ] && printf "  - %s\n" "$NAME"
done
printf "\nWill install into:\n"
printf "%s\n" "$CANDS" | while IFS=":" read -r LABEL DIR; do
  printf "  - %-12s %s\n" "$LABEL" "$DIR"
done
[ "$DRY_RUN" = "1" ] && { printf "\n(dry-run) no files written.\n"; exit 0; }

if [ "$INSTALL_CLI" = "1" ]; then
  install_cli
fi

INSTALLED=0
printf "\n"
echo "$CANDS" | while IFS=":" read -r LABEL DIR; do
  mkdir -p "$DIR"
  printf "%s\n" "$SKILL_NAMES" | while IFS= read -r NAME; do
    [ -n "$NAME" ] || continue
    SRC="$SOURCE_SKILLS_DIR/$NAME"
    TARGET="$DIR/$NAME"
    rm -rf "$TARGET"
    cp -R "$SRC" "$TARGET"
    find "$TARGET/scripts" -type f -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
  done
  COUNT="$(printf "%s\n" "$SKILL_NAMES" | sed '/^$/d' | wc -l | tr -d ' ')"
  printf "  ✓ %s → %s (%s skills)\n" "$LABEL" "$DIR" "$COUNT"
done

# ---- next-step hints ----

cat <<'TIPS'

Next steps:

1. Install the MCP server binary once per machine if you haven't:

     npm i -g @agent-bus-connect/cli

   Or rerun this installer with:

     ./install.sh --install-cli

2. Register the agent-bus MCP server in each tool. The exact command
   differs per tool; the most common ones:

   - Claude Code:
       claude mcp add -s user agent-bus -- agent-bus-mcp

   - Codex CLI / Desktop:  edit ~/.codex/config.toml and add
       [mcp_servers.agent-bus]
       command = "/absolute/path/to/agent-bus-mcp"

   - Kimi Code:
       Prefer the plugin install:
         /plugins install https://github.com/MustaphaSteph/agent-bus-plugins
         /plugins mcp enable agent-bus agent-bus
         /reload
       Terminal fallback for Kimi builds that do not auto-enable MCP:
         kimi mcp add agent-bus -- agent-bus-mcp
         kimi mcp test agent-bus

   - Cursor / Gemini CLI / Goose / OpenCode / Junie / Amp / Kiro:
       see the tool's own MCP-server registration docs. The skill will
       work the moment any one of them has the agent-bus MCP loaded.

3. Verify the install in any new session by asking the agent:
     "List the agent-bus tools and call whois."

   If something's off, run the bundled setup-check script:
     <skills-dir>/agent-bus/scripts/check-setup.sh

   It validates node >= 20, agent-bus-mcp on PATH, and version. To let
   the checker install/upgrade the npm CLI explicitly, run:
     <skills-dir>/agent-bus/scripts/check-setup.sh --install-cli

For the turn-key plugin install (instead of the manual skill drop):

   - Claude Code: /plugin > Marketplaces > Add MustaphaSteph/agent-bus-plugins > install agent-bus
   - Codex:       codex plugin marketplace add MustaphaSteph/agent-bus-plugins
   - Kimi Code:   /plugins install https://github.com/MustaphaSteph/agent-bus-plugins

Source: https://github.com/MustaphaSteph/agent-bus
TIPS
