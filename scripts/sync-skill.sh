#!/bin/sh
# sync-skill.sh — vendor skills/agent-bus/ from the agent-bus repo into
# plugins/agent-bus/skills/agent-bus/ so both Codex and Claude Code plugins
# ship the same skill body.
#
# Two modes:
#   1. CI / release  (default)       Pull from a pinned tag of MustaphaSteph/agent-bus.
#   2. Local dev     SYNC_SOURCE=… pull from a local clone (faster iteration).
#
# Drift gate:
#   --check          Verify vendored copy matches the source; exit non-zero on drift.
#
# Output:
#   plugins/agent-bus/skills/agent-bus/   <- vendored skill body
#   .sync-version                          <- source path + ref + timestamp

set -e

DEFAULT_PINNED_TAG="v0.4.1"
DEFAULT_REPO_URL="https://github.com/MustaphaSteph/agent-bus.git"
SKILL_SUBPATH="skills/agent-bus"
PLUGIN_SKILL_DIR="plugins/agent-bus/skills/agent-bus"

CHECK_MODE=0
if [ "${1:-}" = "--check" ]; then
  CHECK_MODE=1
fi

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

# ---- 1. Resolve the source ----

if [ -n "${SYNC_SOURCE:-}" ]; then
  if [ ! -d "$SYNC_SOURCE/$SKILL_SUBPATH" ]; then
    printf "ERROR: SYNC_SOURCE='%s' does not contain '%s'\n" "$SYNC_SOURCE" "$SKILL_SUBPATH" >&2
    exit 2
  fi
  SOURCE_LABEL="local:$SYNC_SOURCE"
  SOURCE_REF="$(cd "$SYNC_SOURCE" && git rev-parse --short HEAD 2>/dev/null || echo 'unknown')"
  SOURCE_DIRTY="$(cd "$SYNC_SOURCE" && (git diff --quiet --ignore-submodules HEAD 2>/dev/null && echo '' || echo 'dirty'))"
  SOURCE_PATH="$SYNC_SOURCE/$SKILL_SUBPATH"
else
  TAG="${SYNC_TAG:-$DEFAULT_PINNED_TAG}"
  REPO_URL="${SYNC_REPO:-$DEFAULT_REPO_URL}"
  TMP_DIR=".tmp/sync-skill-$$"
  trap 'rm -rf "$TMP_DIR"' EXIT INT HUP TERM
  mkdir -p "$TMP_DIR"
  printf "Fetching agent-bus@%s from %s ...\n" "$TAG" "$REPO_URL"
  git clone --depth 1 --branch "$TAG" --quiet "$REPO_URL" "$TMP_DIR/agent-bus" >/dev/null
  SOURCE_LABEL="tag:$TAG"
  SOURCE_REF="$(cd "$TMP_DIR/agent-bus" && git rev-parse --short HEAD)"
  SOURCE_DIRTY=""
  SOURCE_PATH="$TMP_DIR/agent-bus/$SKILL_SUBPATH"
fi

if [ ! -f "$SOURCE_PATH/SKILL.md" ]; then
  printf "ERROR: source skill missing SKILL.md at %s\n" "$SOURCE_PATH" >&2
  exit 2
fi

# ---- 2. Check mode: diff source vs vendored ----

if [ "$CHECK_MODE" = "1" ]; then
  if [ ! -d "$PLUGIN_SKILL_DIR" ]; then
    printf "DRIFT: vendored skill missing at %s\n" "$PLUGIN_SKILL_DIR" >&2
    exit 1
  fi
  if ! diff -r -q "$SOURCE_PATH" "$PLUGIN_SKILL_DIR" >/dev/null 2>&1; then
    printf "DRIFT: vendored skill differs from %s\n" "$SOURCE_LABEL" >&2
    diff -r "$SOURCE_PATH" "$PLUGIN_SKILL_DIR" >&2 || true
    exit 1
  fi
  printf "OK: vendored skill matches %s (%s)\n" "$SOURCE_LABEL" "$SOURCE_REF"
  exit 0
fi

# ---- 3. Sync ----

rm -rf "$PLUGIN_SKILL_DIR"
mkdir -p "$(dirname "$PLUGIN_SKILL_DIR")"
cp -R "$SOURCE_PATH" "$PLUGIN_SKILL_DIR"

# Re-apply executable bit on scripts the tar/cp may have dropped
find "$PLUGIN_SKILL_DIR/scripts" -type f -name "*.sh" -exec chmod +x {} \;

# ---- 4. Write .sync-version ----

TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
cat > .sync-version <<EOF
{
  "source": "$SOURCE_LABEL",
  "ref": "$SOURCE_REF",
  "dirty": "$SOURCE_DIRTY",
  "skill_path": "$SKILL_SUBPATH",
  "synced_at": "$TS"
}
EOF

printf "synced skill from %s (%s%s) at %s\n" \
  "$SOURCE_LABEL" \
  "$SOURCE_REF" \
  "$( [ -n "$SOURCE_DIRTY" ] && printf ', %s' "$SOURCE_DIRTY" )" \
  "$TS"
