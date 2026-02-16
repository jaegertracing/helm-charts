#!/bin/bash
# Script to check for new Jaeger Docker Hub releases and update Chart.yaml
# Can be run standalone for testing or via the GitHub Actions workflow
#
# This script updates:
#   - appVersion field in Chart.yaml
#   - artifacthub.io/images annotation to keep it in sync with appVersion
#   - Chart version (via bump-chart-version.sh)
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
  exit 0
fi

# --- 4. Print summary about appVersion update ---
echo "Update needed: appVersion change from ${CURRENT_APP_VERSION} to ${LATEST_TAG}."

if [[ "$DRY_RUN" == "true" ]]; then
  echo "=============================================="
  echo "DRY RUN MODE - No changes will be made"
  echo "=============================================="
  echo "Changes that would be made:"
  echo "  - appVersion: ${CURRENT_APP_VERSION} -> ${LATEST_TAG}"
  echo "  - artifacthub.io/images annotation: jaegertracing/jaeger:${CURRENT_APP_VERSION} -> jaegertracing/jaeger:${LATEST_TAG}"
  echo "  - Chart version will be bumped (minor)"
  echo "=============================================="
  exit 0
fi

# --- 5. Execute the update ---
echo "Updating ${CHART_PATH}..."

# Update appVersion
sed -i "s/^appVersion:.*/appVersion: ${LATEST_TAG}/" "$CHART_PATH"

# Update the artifacthub.io/images annotation to use the new version
# This ensures the annotation stays in sync with appVersion and provides
# accurate metadata to Artifact Hub about the Docker image version
sed -i "s|image: jaegertracing/jaeger:.*|image: jaegertracing/jaeger:${LATEST_TAG}|" "$CHART_PATH"

# Get the script directory (where this script is located)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Call bump-chart-version.sh to update chart version
"${SCRIPT_DIR}/bump-chart-version.sh" --bump-minor

echo "Update complete."
