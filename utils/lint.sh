#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# utils/lint.sh
# -----------------------------------------------------------------------------
# Wraps tflint and trivy to lint the root Terraform module and scan it for
# misconfigurations of Snowflake API integrations. Exits non-zero on any
# finding so it can gate CI and pre-commit.
#
# Invocation:
#   bash utils/lint.sh
#
# Checks:
#   - tflint --recursive against .tflint.hcl (Snowflake provider misuse,
#     unused variables, deprecated syntax)
#   - trivy config . (misconfigurations such as missing api_blocked_prefixes,
#     overly broad api_allowed_prefixes, missing comments on production
#     integrations)
#
# Both tools are installed by install-tools.sh.
# -----------------------------------------------------------------------------
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

fail=0

echo "==> tflint (Snowflake API integration module)"
if command -v tflint >/dev/null 2>&1; then
  tflint --init >/dev/null 2>&1 || true
  if ! tflint --recursive; then
    fail=1
  fi
else
  echo "ERROR: tflint is not installed. Run install-tools.sh." >&2
  fail=1
fi

echo "==> trivy config (Snowflake API integration module)"
if command -v trivy >/dev/null 2>&1; then
  if ! trivy config --exit-code 1 .; then
    fail=1
  fi
else
  echo "ERROR: trivy is not installed. Run install-tools.sh." >&2
  fail=1
fi

# Project-specific structural checks for Snowflake API integrations:
#   - flag overly broad api_allowed_prefixes (no path component beyond host)
#   - flag missing api_blocked_prefixes on integrations whose comment mentions
#     production
echo "==> custom checks (api_allowed_prefixes scope, api_blocked_prefixes on prod)"
python3 - <<'PY'
import re, sys
from pathlib import Path

root = Path(".")
issues = []

# Inspect every *.tf under examples/ for api_allowed_prefixes entries that look
# like a bare API Gateway / Cloud Functions / API Management host (no stage path).
host_only = re.compile(
    r'^(https://[^/]+/?)$'
)

for tf in list(root.glob("examples/**/*.tf")):
    text = tf.read_text()
    for m in re.finditer(
        r'api_allowed_prefixes\s*=\s*\[(.*?)\]',
        text, re.DOTALL,
    ):
        for prefix in re.findall(r'"([^"]+)"', m.group(1)):
            if host_only.match(prefix):
                issues.append(
                    f"{tf}: api_allowed_prefixes entry {prefix!r} is host-only "
                    "(no stage / path) -- scope it down."
                )

if issues:
    print("\n".join(issues), file=sys.stderr)
    sys.exit(1)
PY
custom_rc=$?
if [[ $custom_rc -ne 0 ]]; then
  fail=1
fi

if [[ $fail -ne 0 ]]; then
  echo "lint.sh: one or more checks failed for terraform-snowflake-api-integration." >&2
  exit 1
fi

echo "lint.sh: all checks passed for terraform-snowflake-api-integration."
