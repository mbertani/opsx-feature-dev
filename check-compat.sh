#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPAT_FILE="$SCRIPT_DIR/OPENSPEC_COMPAT"

# Read tested version
if [[ ! -f "$COMPAT_FILE" ]]; then
  echo "ERROR: OPENSPEC_COMPAT file not found at $COMPAT_FILE"
  exit 1
fi
TESTED_VERSION=$(grep '^TESTED_VERSION=' "$COMPAT_FILE" | cut -d= -f2)

# Check openspec is installed
if ! command -v openspec &>/dev/null; then
  echo "ERROR: openspec CLI not found. Install it first:"
  echo "  https://github.com/openspec-dev/openspec"
  exit 1
fi

INSTALLED_VERSION=$(openspec --version 2>/dev/null || echo "unknown")

echo "=== opsx-feature-dev compatibility check ==="
echo ""
echo "  Plugin tested with:  openspec $TESTED_VERSION"
echo "  Installed version:   openspec $INSTALLED_VERSION"
echo ""

if [[ "$INSTALLED_VERSION" == "$TESTED_VERSION" ]]; then
  echo "  Status: MATCH - versions are identical"
elif [[ "$INSTALLED_VERSION" == "unknown" ]]; then
  echo "  Status: WARNING - could not determine installed version"
else
  echo "  Status: MISMATCH - versions differ, checking CLI commands..."
fi

echo ""
echo "--- Verifying CLI commands used by feature-dev ---"
echo ""

CMDS=(
  "openspec new change --help"
  "openspec status --help"
  "openspec instructions --help"
  "openspec list --help"
)

ALL_OK=true
for cmd in "${CMDS[@]}"; do
  if $cmd &>/dev/null; then
    echo "  OK   $cmd"
  else
    echo "  FAIL $cmd"
    ALL_OK=false
  fi
done

echo ""

if [[ "$ALL_OK" == true ]]; then
  echo "All CLI commands available."
  if [[ "$INSTALLED_VERSION" != "$TESTED_VERSION" ]]; then
    echo ""
    echo "Version differs but commands work. To confirm full compatibility:"
    echo "  1. Run /opsx-feature-dev:feature-dev on a test change"
    echo "  2. Verify artifact generation uses correct templates"
    echo "  3. Update OPENSPEC_COMPAT: TESTED_VERSION=$INSTALLED_VERSION"
  fi
else
  echo "WARNING: Some commands failed. Check the openspec changelog:"
  echo "  https://github.com/openspec-dev/openspec/releases"
  echo ""
  echo "The feature-dev command may need updating for openspec $INSTALLED_VERSION."
fi
