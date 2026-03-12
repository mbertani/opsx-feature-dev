#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION_FILE="$SCRIPT_DIR/UPSTREAM_VERSION"

# Locate the Claude plugins cache
CLAUDE_DIR="${XDG_CONFIG_HOME:-$HOME/.claude}"
CACHE_DIR="$CLAUDE_DIR/plugins/cache/claude-plugins-official/feature-dev"

if [[ ! -d "$CACHE_DIR" ]]; then
  echo "ERROR: Official feature-dev plugin not found in cache."
  echo "       Expected: $CACHE_DIR"
  echo ""
  echo "Make sure the feature-dev plugin is installed:"
  echo "  claude plugin install feature-dev"
  exit 1
fi

# Find the most recently modified version in cache
UPSTREAM_DIR=$(ls -dt "$CACHE_DIR"/*/ 2>/dev/null | head -1)

if [[ -z "$UPSTREAM_DIR" ]]; then
  echo "ERROR: No cached versions found in $CACHE_DIR"
  exit 1
fi

UPSTREAM_HASH=$(basename "$UPSTREAM_DIR")

# Read the last synced version
LAST_SYNCED="(unknown)"
if [[ -f "$VERSION_FILE" ]]; then
  LAST_SYNCED=$(grep '^UPSTREAM_HASH=' "$VERSION_FILE" | cut -d= -f2)
fi

echo "=== opsx-feature-dev: upstream comparison ==="
echo ""
echo "  Local plugin:     $SCRIPT_DIR"
echo "  Last synced from: $LAST_SYNCED"
echo "  Upstream latest:  $UPSTREAM_HASH"
echo ""

if [[ "$LAST_SYNCED" == "$UPSTREAM_HASH" ]]; then
  echo "  Version: UP TO DATE (same hash)"
else
  echo "  Version: NEW UPSTREAM VERSION AVAILABLE"
fi

echo ""

# ── Compare agents ──────────────────────────────────────────────

HAS_AGENT_CHANGES=false
HAS_CMD_CHANGES=false

echo "--- Agents ---"
echo ""

for agent in code-explorer code-architect code-reviewer; do
  local_file="$SCRIPT_DIR/agents/$agent.md"
  upstream_file="$UPSTREAM_DIR/agents/$agent.md"

  if [[ ! -f "$upstream_file" ]]; then
    echo "  SKIP  $agent (not in upstream)"
    continue
  fi
  if [[ ! -f "$local_file" ]]; then
    echo "  NEW   $agent exists upstream but not locally"
    HAS_AGENT_CHANGES=true
    continue
  fi

  if diff -q "$local_file" "$upstream_file" &>/dev/null; then
    echo "  OK    $agent (identical)"
  else
    echo "  DIFF  $agent"
    HAS_AGENT_CHANGES=true
  fi
done

# Check for new agents upstream that we don't have
for upstream_file in "$UPSTREAM_DIR"/agents/*.md; do
  [[ -f "$upstream_file" ]] || continue
  agent=$(basename "$upstream_file" .md)
  if [[ ! -f "$SCRIPT_DIR/agents/$agent.md" ]]; then
    echo "  NEW   $agent (exists upstream, missing locally)"
    HAS_AGENT_CHANGES=true
  fi
done

echo ""

# ── Compare command ─────────────────────────────────────────────

echo "--- Command ---"
echo ""

UPSTREAM_CMD="$UPSTREAM_DIR/commands/feature-dev.md"
LOCAL_CMD="$SCRIPT_DIR/commands/feature-dev.md"

if [[ -f "$UPSTREAM_CMD" ]]; then
  if diff -q "$LOCAL_CMD" "$UPSTREAM_CMD" &>/dev/null; then
    echo "  OK    feature-dev.md (identical)"
  else
    echo "  DIFF  feature-dev.md (expected - yours has OpenSpec integration)"
    HAS_CMD_CHANGES=true
  fi
else
  echo "  SKIP  upstream command not found"
fi

echo ""

# ── Summary ─────────────────────────────────────────────────────

if [[ "$HAS_AGENT_CHANGES" == false && "$HAS_CMD_CHANGES" == false ]]; then
  echo "No changes detected. Your plugin is in sync with upstream."
  if [[ "$LAST_SYNCED" != "$UPSTREAM_HASH" ]]; then
    echo "Updating UPSTREAM_VERSION to $UPSTREAM_HASH (files identical)."
    cat > "$VERSION_FILE" <<VEOF
# Hash of the official feature-dev plugin version that agents were last synced from.
# Updated by update-from-upstream.sh after applying upstream changes.
UPSTREAM_HASH=$UPSTREAM_HASH
VEOF
  fi
  exit 0
fi

echo "=== Changes detected ==="
echo ""

if [[ "$HAS_AGENT_CHANGES" == true ]]; then
  echo "To see agent diffs:"
  echo ""

  for agent in code-explorer code-architect code-reviewer; do
    local_file="$SCRIPT_DIR/agents/$agent.md"
    upstream_file="$UPSTREAM_DIR/agents/$agent.md"
    if [[ -f "$local_file" && -f "$upstream_file" ]]; then
      if ! diff -q "$local_file" "$upstream_file" &>/dev/null; then
        echo "  diff \"$local_file\" \"$upstream_file\""
      fi
    fi
  done

  echo ""
  echo "To apply upstream agent changes (review diffs first!):"
  echo ""

  for agent in code-explorer code-architect code-reviewer; do
    upstream_file="$UPSTREAM_DIR/agents/$agent.md"
    if [[ -f "$upstream_file" ]]; then
      if [[ ! -f "$SCRIPT_DIR/agents/$agent.md" ]] || ! diff -q "$SCRIPT_DIR/agents/$agent.md" "$upstream_file" &>/dev/null; then
        echo "  cp \"$upstream_file\" \"$SCRIPT_DIR/agents/$agent.md\""
      fi
    fi
  done

  echo ""
fi

if [[ "$HAS_CMD_CHANGES" == true ]]; then
  echo "To see command diff:"
  echo "  diff \"$LOCAL_CMD\" \"$UPSTREAM_CMD\""
  echo ""
  echo "NOTE: The command file will always differ (OpenSpec integration)."
  echo "      Review for workflow changes you may want to incorporate."
  echo ""
fi

# ── Apply flag ──────────────────────────────────────────────────

if [[ "${1:-}" == "--apply" ]]; then
  echo "Applying upstream agent changes..."
  echo ""

  for agent in code-explorer code-architect code-reviewer; do
    upstream_file="$UPSTREAM_DIR/agents/$agent.md"
    local_file="$SCRIPT_DIR/agents/$agent.md"
    if [[ -f "$upstream_file" ]]; then
      if [[ ! -f "$local_file" ]] || ! diff -q "$local_file" "$upstream_file" &>/dev/null; then
        cp "$upstream_file" "$local_file"
        echo "  Updated $agent.md"
      fi
    fi
  done

  # Update version file
  cat > "$VERSION_FILE" <<VEOF
# Hash of the official feature-dev plugin version that agents were last synced from.
# Updated by update-from-upstream.sh after applying upstream changes.
UPSTREAM_HASH=$UPSTREAM_HASH
VEOF

  echo ""
  echo "Done. UPSTREAM_VERSION updated to $UPSTREAM_HASH."
  echo "Review changes with 'git diff' and commit when satisfied."
else
  echo "Run with --apply to copy upstream agents automatically:"
  echo "  ./update-from-upstream.sh --apply"
fi
