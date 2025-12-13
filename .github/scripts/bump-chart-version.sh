#!/bin/bash
# Script to bump the chart patch version in Chart.yaml
# Used by renovatebot postUpgradeTasks to bump chart version on dependency updates
#
# Usage: ./bump-chart-version.sh [--dry-run]
#
# Environment variables:
#   DRY_RUN - Set to 'true' to skip making changes (same as --dry-run flag)

set -eo pipefail

CHART_PATH="charts/jaeger/Chart.yaml"

# Parse command line arguments
for arg in "$@"; do
  case $arg in
    --dry-run)
      DRY_RUN="true"
      shift
      ;;
  esac
done

# Default DRY_RUN to false if not set
DRY_RUN="${DRY_RUN:-false}"

echo "Bumping chart patch version in ${CHART_PATH}..."

# --- 1. Verify Chart.yaml exists ---
if [[ ! -f "$CHART_PATH" ]]; then
  echo "Error: Chart file '${CHART_PATH}' not found. Exiting."
  exit 1
fi

# --- 2. Get the current version from Chart.yaml ---
CURRENT_CHART_VERSION=$(grep '^version:' "$CHART_PATH" | sed 's/version: *//' | tr -d '"')

echo "   -> Current chart version in ${CHART_PATH} is: ${CURRENT_CHART_VERSION}"

# --- 2. Validate current version format (X.Y.Z) ---
if ! [[ "$CURRENT_CHART_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Error: Current chart version '${CURRENT_CHART_VERSION}' does not match expected format X.Y.Z. Exiting."
  exit 1
fi

# --- 3. Calculate new chart version (bump patch version) ---
# Parse the current chart version (e.g., 4.1.0 -> major=4, minor=1, patch=0)
IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_CHART_VERSION"
NEW_PATCH=$((PATCH + 1))
NEW_CHART_VERSION="${MAJOR}.${MINOR}.${NEW_PATCH}"

echo "   -> New chart version will be: ${NEW_CHART_VERSION}"

# --- 4. Handle dry run mode ---
if [[ "$DRY_RUN" == "true" ]]; then
  echo "=============================================="
  echo "DRY RUN MODE - No changes will be made"
  echo "=============================================="
  echo "Chart version bump:"
  echo "  - version: ${CURRENT_CHART_VERSION} -> ${NEW_CHART_VERSION}"
  echo "=============================================="
  exit 0
fi

# --- 5. Update Chart.yaml using sed ---
echo "Updating ${CHART_PATH}..."

# Escape any special characters in versions for sed (though semver should only have digits and dots)
ESCAPED_CURRENT=$(echo "$CURRENT_CHART_VERSION" | sed 's/[.]/\\./g')
ESCAPED_NEW=$(echo "$NEW_CHART_VERSION" | sed 's/[.]/\\./g')

# Update version
sed -i "s/^version: *${ESCAPED_CURRENT}$/version: ${NEW_CHART_VERSION}/" "$CHART_PATH"

echo "Successfully updated chart version to ${NEW_CHART_VERSION}"
