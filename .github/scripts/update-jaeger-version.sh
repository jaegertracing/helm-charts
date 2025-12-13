#!/bin/bash
# Script to check for new Jaeger Docker Hub releases and update Chart.yaml
# Can be run standalone for testing or via the GitHub Actions workflow
#
# Usage: ./update-jaeger-version.sh [--dry-run]
#
# Environment variables:
#   DRY_RUN - Set to 'true' to skip making changes (same as --dry-run flag)
#   GITHUB_OUTPUT - If set, outputs will be written for GitHub Actions

set -eo pipefail

DOCKER_IMAGE="jaegertracing/jaeger"
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

echo "1. Checking latest Docker tag for ${DOCKER_IMAGE}..."

# --- 1. Get the latest semantic version tag by checking the digest of the 'latest' tag ---
echo "   -> Fetching image digest for 'latest' tag..."
# Get all digests from the 'latest' tag (multi-platform images have multiple digests)
LATEST_RESPONSE=$(curl -sf "https://registry.hub.docker.com/v2/repositories/${DOCKER_IMAGE}/tags/latest")
if [[ $? -ne 0 || -z "$LATEST_RESPONSE" ]]; then
  echo "Error: Failed to fetch 'latest' tag from Docker Hub. Exiting."
  exit 1
fi

LATEST_DIGESTS=$(echo "$LATEST_RESPONSE" | jq -r '.images[].digest | select(. != null)')

if [[ -z "$LATEST_DIGESTS" ]]; then
  echo "Error: Could not retrieve valid digests for the 'latest' tag. Exiting."
  exit 1
fi
echo "   -> Latest digests found:"
echo "$LATEST_DIGESTS" | head -3

# Fetch a list of tags and filter to find the one that:
# 1. Has any digest matching the 'latest' tag digests.
# 2. Matches the semantic version pattern (e.g., 2.39.0).
echo "   -> Searching through tags for a semantic version matching these digests..."
TAGS_JSON=$(curl -sf "https://registry.hub.docker.com/v2/repositories/${DOCKER_IMAGE}/tags?page_size=100")
if [[ $? -ne 0 || -z "$TAGS_JSON" ]]; then
  echo "Error: Failed to fetch tags from Docker Hub. Exiting."
  exit 1
fi

# Convert digests to a JSON array for jq comparison
DIGESTS_ARRAY=$(echo "$LATEST_DIGESTS" | jq -R -s 'split("\n") | map(select(length > 0))')

LATEST_TAG=$(echo "$TAGS_JSON" | \
  jq -r --argjson digests "$DIGESTS_ARRAY" '
    .results[] | 
    select(.images | map(.digest) | any(. as $d | $digests | index($d))) | 
    .name' | \
  grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | \
  head -n 1)

if [[ -z "$LATEST_TAG" ]]; then
  echo "Error: Could not find a matching semantic version tag in the first 100 results. Exiting."
  exit 1
fi

echo "   -> Latest available version is: ${LATEST_TAG}"

# --- 2. Get the current appVersion and version from Chart.yaml using grep/sed ---
CURRENT_APP_VERSION=$(grep '^appVersion:' "$CHART_PATH" | sed 's/appVersion: *//' | tr -d '"')
CURRENT_CHART_VERSION=$(grep '^version:' "$CHART_PATH" | sed 's/version: *//' | tr -d '"')

echo "   -> Current appVersion in ${CHART_PATH} is: ${CURRENT_APP_VERSION}"
echo "   -> Current chart version in ${CHART_PATH} is: ${CURRENT_CHART_VERSION}"

# --- 3. Compare and determine if update is needed ---
if [[ "$LATEST_TAG" == "$CURRENT_APP_VERSION" ]]; then
  echo "Versions match. No update needed."
  if [[ -n "$GITHUB_OUTPUT" ]]; then
    echo "update_needed=false" >> "$GITHUB_OUTPUT"
  fi
  if [[ "$DRY_RUN" == "true" ]]; then
    echo "=============================================="
    echo "DRY RUN MODE - No changes needed"
    echo "=============================================="
  fi
  exit 0
fi

echo "Update needed: appVersion change from ${CURRENT_APP_VERSION} to ${LATEST_TAG}."

# --- 4. Bump chart version (using bump-chart-version.sh) ---
echo "Calculating new chart version..."

# Get the script directory (where this script is located)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Run bump-chart-version.sh to calculate new version
NEW_CHART_VERSION=$("${SCRIPT_DIR}/bump-chart-version.sh" --print-only --bump-minor)

if [[ -z "$NEW_CHART_VERSION" ]]; then
  echo "Error: Could not calculate new chart version. Exiting."
  exit 1
fi

echo "   -> New chart version will be: ${NEW_CHART_VERSION}"

# Set outputs for GitHub Actions
if [[ -n "$GITHUB_OUTPUT" ]]; then
  echo "update_needed=true" >> "$GITHUB_OUTPUT"
  echo "latest_tag=${LATEST_TAG}" >> "$GITHUB_OUTPUT"
  echo "current_app_version=${CURRENT_APP_VERSION}" >> "$GITHUB_OUTPUT"
  echo "current_chart_version=${CURRENT_CHART_VERSION}" >> "$GITHUB_OUTPUT"
  echo "new_chart_version=${NEW_CHART_VERSION}" >> "$GITHUB_OUTPUT"
fi

# --- 5. Handle dry run mode ---
if [[ "$DRY_RUN" == "true" ]]; then
  echo "=============================================="
  echo "DRY RUN MODE - No changes will be made"
  echo "=============================================="
  echo "Update IS needed:"
  echo "  - appVersion: ${CURRENT_APP_VERSION} -> ${LATEST_TAG}"
  echo "  - version: ${CURRENT_CHART_VERSION} -> ${NEW_CHART_VERSION}"
  echo "=============================================="
  exit 0
fi

# --- 6. Update Chart.yaml ---
echo "Updating ${CHART_PATH}..."

# Update appVersion
sed -i "s/^appVersion:.*/appVersion: ${LATEST_TAG}/" "$CHART_PATH"

# Update chart version using bump-chart-version.sh
"${SCRIPT_DIR}/bump-chart-version.sh" --bump-minor

echo "Updated ${CHART_PATH}:"
cat "$CHART_PATH"
