#!/bin/sh
# sync-skill.sh — vendor skills/agent-bus/ from the agent-bus repo into
# every plugin skill surface so Codex, Claude Code, Kimi, Cursor, and
# generic Agent Skills installs ship the same skill body.
#
# Two modes:
#   1. CI / release  (default)       Pull from a pinned ref of MustaphaSteph/agent-bus.
#   2. Local dev     SYNC_SOURCE=… pull from a local clone (faster iteration).
#
# Drift gate:
#   --check          Verify vendored copy matches the source; exit non-zero on drift.
#
# Output:
#   skills/agent-bus/                      <- root/universal skill body
#   plugins/agent-bus/skills/agent-bus/    <- Codex plugin skill body
#   claude-code/plugins/agent-bus/skills/agent-bus/
#   .sync-version                          <- source path + ref + timestamp

set -e

DEFAULT_PINNED_TAG="main"
DEFAULT_REPO_URL="https://github.com/MustaphaSteph/agent-bus.git"
SKILL_SUBPATH="skills/agent-bus"

# Vendored copies live in the root skill tree and in both legacy plugin
# bodies. All must match the source; sync writes/checks each one.
PLUGIN_SKILL_DIRS="skills/agent-bus plugins/agent-bus/skills/agent-bus claude-code/plugins/agent-bus/skills/agent-bus"

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
  git -c advice.detachedHead=false clone --depth 1 --branch "$TAG" --quiet "$REPO_URL" "$TMP_DIR/agent-bus" >/dev/null
  SOURCE_LABEL="ref:$TAG"
  SOURCE_REF="$(cd "$TMP_DIR/agent-bus" && git rev-parse --short HEAD)"
  SOURCE_DIRTY=""
  SOURCE_PATH="$TMP_DIR/agent-bus/$SKILL_SUBPATH"
fi

if [ ! -f "$SOURCE_PATH/SKILL.md" ]; then
  printf "ERROR: source skill missing SKILL.md at %s\n" "$SOURCE_PATH" >&2
  exit 2
fi

# ---- 2. Check mode: diff source vs each vendored copy ----

if [ "$CHECK_MODE" = "1" ]; then
  ANY_DRIFT=0
  for D in $PLUGIN_SKILL_DIRS; do
    if [ ! -d "$D" ]; then
      printf "DRIFT: vendored skill missing at %s\n" "$D" >&2
      ANY_DRIFT=1
      continue
    fi
    if ! diff -r -q "$SOURCE_PATH" "$D" >/dev/null 2>&1; then
      printf "DRIFT: vendored skill at %s differs from %s\n" "$D" "$SOURCE_LABEL" >&2
      diff -r "$SOURCE_PATH" "$D" >&2 || true
      ANY_DRIFT=1
      continue
    fi
    printf "OK: %s matches %s (%s)\n" "$D" "$SOURCE_LABEL" "$SOURCE_REF"
  done
  [ "$ANY_DRIFT" = "0" ] && exit 0 || exit 1
fi

# ---- 3. Sync into every vendored copy ----

for D in $PLUGIN_SKILL_DIRS; do
  rm -rf "$D"
  mkdir -p "$(dirname "$D")"
  cp -R "$SOURCE_PATH" "$D"
  # Re-apply executable bit on scripts the cp may have dropped
  find "$D/scripts" -type f -name "*.sh" -exec chmod +x {} \;
done

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
