#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# utils/generate-docs.sh
# -----------------------------------------------------------------------------
# Runs terraform-docs against the root module and rewrites the auto-generated
# Inputs / Outputs / Resources tables in README.md. Idempotent -- running on
# a clean tree produces no diff.
#
# Invocation:
#   bash utils/generate-docs.sh
#
# Used by:
#   - Local development before committing changes to *.tf
#   - pre-commit hook chain
#   - CI doc-drift check
#
# After running this script, also run utils/align-md-tables.py to re-pipe-
# align the regenerated tables (markdownlint MD060).
# -----------------------------------------------------------------------------
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

if ! command -v terraform-docs >/dev/null 2>&1; then
  echo "ERROR: terraform-docs is not installed. Run install-tools.sh or install it manually." >&2
  exit 1
fi

echo "Refreshing terraform-docs tables in README.md for terraform-snowflake-api-integration..."
terraform-docs markdown table \
  --output-file README.md \
  --output-mode inject \
  --hide modules,providers,requirements \
  .

echo "Done. Run 'bash utils/align-md-tables.py' next to enforce MD060 alignment."
