#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# utils/update-badge.sh
# -----------------------------------------------------------------------------
# Updates the shields.io custom-endpoint gist JSON file
# (terraform-snowflake-api-integration.json) hosted as a secret gist. Used to
# keep the README's coverage / test-status / version badge in sync with the
# latest CI run.
#
# Invocation:
#   BADGE_GIST_ID=<gist-id> bash utils/update-badge.sh \
#     --label "tests" --message "passing" --color "brightgreen"
#
# Used by:
#   - terratest CI job after a successful Snowflake API integration test
#   - semantic-release job after a new version is published
#
# Requires:
#   - gh CLI authenticated (gh auth status)
#   - BADGE_GIST_ID env var set to the secret gist ID
# -----------------------------------------------------------------------------
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

gist_file="terraform-snowflake-api-integration.json"
label=""
message=""
color="blue"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --label)   label="$2"; shift 2 ;;
    --message) message="$2"; shift 2 ;;
    --color)   color="$2"; shift 2 ;;
    *)         echo "Unknown flag: $1" >&2; exit 2 ;;
  esac
done

if [[ -z "${BADGE_GIST_ID:-}" ]]; then
  echo "ERROR: BADGE_GIST_ID env var is required (the secret gist hosting ${gist_file})." >&2
  exit 1
fi

if [[ -z "$label" || -z "$message" ]]; then
  echo "ERROR: --label and --message are required." >&2
  exit 2
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "ERROR: gh CLI is not installed." >&2
  exit 1
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

cat >"${tmp}/${gist_file}" <<EOF
{
  "schemaVersion": 1,
  "label": "${label}",
  "message": "${message}",
  "color": "${color}"
}
EOF

echo "Updating badge gist ${BADGE_GIST_ID} (${gist_file}) for terraform-snowflake-api-integration..."
gh gist edit "${BADGE_GIST_ID}" --add "${tmp}/${gist_file}"

echo "update-badge.sh: badge gist updated."
