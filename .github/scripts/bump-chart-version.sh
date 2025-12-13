#!/bin/bash
# Script to bump the chart version in Chart.yaml
# Used by renovatebot postUpgradeTasks to bump chart version on dependency updates
# Used by update-jaeger-version.sh to bump chart version on app version updates
#
# Usage: ./bump-chart-version.sh [--dry-run] [--bump-minor]
#
# Options:
#   --dry-run      Skip making changes (just print what would be done)
#   --bump-minor   Bump minor version instead of patch (e.g., 4.0.0 -> 4.1.0)
#   --print-only   Only print the new version number (for scripting)
#
# Environment variables:
#   DRY_RUN - Set to 'true' to skip making changes (same as --dry-run flag)

set -eo pipefail

CHART_PATH="charts/jaeger/Chart.yaml"
BUMP_TYPE="patch"
PRINT_ONLY="false"

# Parse command line arguments
for arg in "$@"; do
  case $arg in
    --dry-run)
      DRY_RUN="true"
      shift
      ;;
    --bump-minor)
      BUMP_TYPE="minor"
      shift
      ;;
    --print-only)
      PRINT_ONLY="true"
      DRY_RUN="true"  # print-only implies dry-run
      shift
      ;;
  esac
done

# Default DRY_RUN to false if not set
DRY_RUN="${DRY_RUN:-false}"

# Skip verbose output in print-only mode
if [[ "$PRINT_ONLY" != "true" ]]; then
  if [[ "$BUMP_TYPE" == "minor" ]]; then
    echo "Bumping chart minor version in ${CHART_PATH}..."
  else
    echo "Bumping chart patch version in ${CHART_PATH}..."
  fi
fi

# --- 1. Verify Chart.yaml exists ---
if [[ ! -f "$CHART_PATH" ]]; then
  echo "Error: Chart file '${CHART_PATH}' not found. Exiting."
  exit 1
fi

# --- 2. Get the current version from Chart.yaml ---
CURRENT_CHART_VERSION=$(grep '^version:' "$CHART_PATH" | sed 's/version: *//' | tr -d '"') || true

if [[ -z "$CURRENT_CHART_VERSION" ]]; then
  if [[ "$PRINT_ONLY" != "true" ]]; then
    echo "Error: Could not extract version from '${CHART_PATH}'. Exiting."
  fi
  exit 1
fi

if [[ "$PRINT_ONLY" != "true" ]]; then
  echo "   -> Current chart version in ${CHART_PATH} is: ${CURRENT_CHART_VERSION}"
fi

# --- 2. Validate current version format (X.Y.Z) ---
if ! [[ "$CURRENT_CHART_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  if [[ "$PRINT_ONLY" != "true" ]]; then
    echo "Error: Current chart version '${CURRENT_CHART_VERSION}' does not match expected format X.Y.Z. Exiting."
  fi
  exit 1
fi

# --- 3. Calculate new chart version (bump patch or minor version) ---
# Parse the current chart version (e.g., 4.1.0 -> major=4, minor=1, patch=0)
IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_CHART_VERSION"

if [[ "$BUMP_TYPE" == "minor" ]]; then
  # Bump minor version and reset patch to 0 (e.g., 4.0.0 -> 4.1.0)
  NEW_MINOR=$((MINOR + 1))
  NEW_CHART_VERSION="${MAJOR}.${NEW_MINOR}.0"
else
  # Bump patch version (e.g., 4.1.0 -> 4.1.1)
  NEW_PATCH=$((PATCH + 1))
  NEW_CHART_VERSION="${MAJOR}.${MINOR}.${NEW_PATCH}"
fi

if [[ "$PRINT_ONLY" == "true" ]]; then
  # Print only mode: just output the new version
  echo "${NEW_CHART_VERSION}"
  exit 0
fi

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

# Update version using a safer sed command with mixed quoting
sed -i 's/^version: *'"${ESCAPED_CURRENT}"'$/version: '"${NEW_CHART_VERSION}"'/' "$CHART_PATH"

echo "Successfully updated chart version to ${NEW_CHART_VERSION}"
