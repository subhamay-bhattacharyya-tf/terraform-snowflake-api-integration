# template-spec.md — terraform-snowflake-api-integration

This document is the **canonical specification** for every file the `scaffold-terraform` skill emits in this repository. The `SKILL.md` describes *when* and *why* to scaffold; this file describes *exactly what* the scaffolded files must contain — field by field, line by line, where it matters.

When `SKILL.md` and `template-spec.md` disagree on a literal value, **this file wins**. Treat it as the source of truth for templates.

---

## 1. Repository identity

| Field                    | Value                                                                              |
|--------------------------|------------------------------------------------------------------------------------|
| Repo name                | `terraform-snowflake-api-integration`                                              |
| Repo owner / org         | `subhamay-bhattacharyya-tf`                                                        |
| Full slug                | `subhamay-bhattacharyya-tf/terraform-snowflake-api-integration`                    |
| Module shape             | Flat — root-level `*.tf` files, no `modules/` subdirectory                         |
| Snowflake resource type  | `snowflake_api_integration` only                                                   |
| Out of scope             | External functions, IAM roles, Azure AD apps, GCP service accounts, trust policies |
| Module input             | Single `map(object({...}))` named `api_integrations`, consumed via `for_each`      |
| Supported providers      | `aws_api_gateway`, `azure_api_management`, `google_api_gateway`                    |
| Badge gist JSON filename | `terraform-snowflake-api-integration.json`                                         |

Every scaffolded file must be self-consistent with this table. If a scaffolded file references a different repo name, owner, or input variable name, it is **broken** and must be regenerated.

---

## 2. File inventory

The scaffolder emits exactly the following files. Anything else is either a user-edited file (preserved as-is) or an error.

| Path                                                                                                                                                | Purpose                                                          | Owner   |
|-----------------------------------------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------|---------|
| `versions.tf`                                                                                                                                       | Pin Terraform and Snowflake provider versions                    | Skill   |
| `variables.tf`                                                                                                                                      | Declare `var.api_integrations` with validation blocks            | Skill   |
| `main.tf`                                                                                                                                           | Single `snowflake_api_integration.this` resource with `for_each` | Skill   |
| `outputs.tf`                                                                                                                                        | Seven output maps keyed by `var.api_integrations` keys           | Skill   |
| `examples/basic/main.tf`                                                                                                                            | Single AWS API Gateway integration                               | Skill   |
| `examples/basic/README.md`                                                                                                                          | What the example demonstrates                                    | Skill   |
| `examples/multi-cloud/main.tf`                                                                                                                      | AWS + Azure + GCP integrations in one module call                | Skill   |
| `examples/multi-cloud/README.md`                                                                                                                    | What the example demonstrates                                    | Skill   |
| `tests/snowflake_api_integration_basic_test.go`                                                                                                     | Terratest covering `examples/basic/`                             | Skill   |
| `tests/helpers_test.go`                                                                                                                             | Shared test helpers (fixed contract)                             | Skill   |
| `utils/generate-docs.sh`                                                                                                                            | Refresh terraform-docs tables in `README.md`                     | Skill   |
| `utils/lint.sh`                                                                                                                                     | tflint + trivy wrapper                                           | Skill   |
| `utils/align-md-tables.py`                                                                                                                          | Align all GFM tables in `README.md` (MD060)                      | Skill   |
| `utils/update-badge.sh`                                                                                                                             | Update shields.io custom-endpoint gist JSON                      | Skill   |
| `package.json` / `package-lock.json`                                                                                                                | semantic-release config; `name` must equal repo name             | User    |
| `README.md`                                                                                                                                         | Generated content (auto-doc tables) + hand-written prose         | Mixed   |
| `CHANGELOG.md`                                                                                                                                      | Auto-generated by semantic-release / git-cliff                   | Tooling |
| `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `LICENSE`, `.editorconfig`, `.gitignore`, `.pre-commit-config.yaml`, `.releaserc.json`, `install-tools.sh` | Repo hygiene; preserved as-is once scaffolded                    | User    |

---

## 3. `versions.tf` — exact spec

```hcl
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    snowflake = {
      source  = "Snowflake-Labs/snowflake"
      version = ">= 0.95.0, < 1.0.0"
    }
  }
}
```

**Hard requirements:**

- Exactly one `terraform { ... }` block
- Exactly one provider declared: `snowflake`
- `source` must be `Snowflake-Labs/snowflake` (not `snowflakedb/snowflake` until the repo migrates)
- `version` must use a range with both lower and upper bounds — never an unpinned `>= x.y.z` alone
- `required_version` for Terraform itself is `>= 1.5.0` (matches the lowest version that supports `optional()` defaults in object types)

**Forbidden:**

- Any `provider "snowflake" { ... }` block — provider configuration belongs in examples and consumers, not in the module
- Any `backend` block — modules never declare backends
- Any cloud provider (`aws`, `azurerm`, `google`) — this module only manages Snowflake-side resources; cloud-side trust setup lives in caller modules

---

## 4. `variables.tf` — exact spec

The module declares **exactly one** variable: `api_integrations`.

```hcl
variable "api_integrations" {
  description = "Map of Snowflake API integrations to create. Map key is a logical Terraform identifier; the actual Snowflake API integration name is the `name` field."

  type = map(object({
    name                    = string
    api_provider            = string
    api_allowed_prefixes    = list(string)
    api_blocked_prefixes    = optional(list(string), [])
    enabled                 = optional(bool, true)
    comment                 = optional(string, null)

    # AWS API Gateway
    api_aws_role_arn        = optional(string, null)

    # Azure API Management
    azure_tenant_id         = optional(string, null)
    azure_ad_application_id = optional(string, null)

    # Google Cloud
    google_audience         = optional(string, null)
  }))

  default = {}

  validation {
    condition     = alltrue([for k, v in var.api_integrations : length(v.name) > 0])
    error_message = "Each API integration must have a non-empty `name`."
  }

  validation {
    condition = alltrue([
      for k, v in var.api_integrations :
      contains(["aws_api_gateway", "azure_api_management", "google_api_gateway"], v.api_provider)
    ])
    error_message = "`api_provider` must be one of: aws_api_gateway, azure_api_management, google_api_gateway."
  }

  validation {
    condition     = alltrue([for k, v in var.api_integrations : length(v.api_allowed_prefixes) > 0])
    error_message = "Each API integration must have at least one entry in `api_allowed_prefixes`."
  }

  validation {
    condition = alltrue([
      for k, v in var.api_integrations :
      v.api_provider != "aws_api_gateway" || (v.api_aws_role_arn != null && length(v.api_aws_role_arn) > 0)
    ])
    error_message = "AWS API Gateway integrations require `api_aws_role_arn`."
  }

  validation {
    condition = alltrue([
      for k, v in var.api_integrations :
      v.api_provider != "azure_api_management" || (
        v.azure_tenant_id != null && v.azure_ad_application_id != null
      )
    ])
    error_message = "Azure API Management integrations require both `azure_tenant_id` and `azure_ad_application_id`."
  }

  validation {
    condition = alltrue([
      for k, v in var.api_integrations :
      v.api_provider != "google_api_gateway" || (v.google_audience != null && length(v.google_audience) > 0)
    ])
    error_message = "Google API Gateway integrations require `google_audience`."
  }
}
```

**Field-level spec:**

| Field                     | Type           | Required                 | Default | Notes                                                                     |
|---------------------------|----------------|--------------------------|---------|---------------------------------------------------------------------------|
| `name`                    | `string`       | Yes                      | —       | Actual Snowflake integration name; conventionally upper-case              |
| `api_provider`            | `string`       | Yes                      | —       | One of `aws_api_gateway`, `azure_api_management`, `google_api_gateway`    |
| `api_allowed_prefixes`    | `list(string)` | Yes (≥ 1)                | —       | HTTPS endpoint prefixes Snowflake is allowed to invoke                    |
| `api_blocked_prefixes`    | `list(string)` | No                       | `[]`    | HTTPS endpoint prefixes Snowflake is forbidden from invoking              |
| `enabled`                 | `bool`         | No                       | `true`  | When `false`, integration exists but cannot be used by external functions |
| `comment`                 | `string`       | No                       | `null`  | Free-text description; required by `lint.sh` for production usage         |
| `api_aws_role_arn`        | `string`       | Yes for AWS, else null   | `null`  | IAM role ARN that Snowflake assumes; AWS only                             |
| `azure_tenant_id`         | `string`       | Yes for Azure, else null | `null`  | Azure AD tenant ID; Azure only                                            |
| `azure_ad_application_id` | `string`       | Yes for Azure, else null | `null`  | Azure AD multi-tenant application ID; Azure only                          |
| `google_audience`         | `string`       | Yes for GCP, else null   | `null`  | GCP audience string; GCP only                                             |

**Forbidden in this file:**

- Any variable other than `api_integrations` (no `database`, `region`, `tags` top-level vars)
- Any `validation` block that references resources or data sources — validation is pure on `var.api_integrations` only
- Any `sensitive = true` flag on the variable itself — the input shape is not secret; only specific *outputs* are sensitive

---

## 5. `main.tf` — exact spec

```hcl
resource "snowflake_api_integration" "this" {
  for_each = var.api_integrations

  name                    = each.value.name
  api_provider            = each.value.api_provider
  api_allowed_prefixes    = each.value.api_allowed_prefixes
  api_blocked_prefixes    = each.value.api_blocked_prefixes
  enabled                 = each.value.enabled
  comment                 = each.value.comment

  # AWS API Gateway
  api_aws_role_arn        = each.value.api_aws_role_arn

  # Azure API Management
  azure_tenant_id         = each.value.azure_tenant_id
  azure_ad_application_id = each.value.azure_ad_application_id

  # Google Cloud
  google_audience         = each.value.google_audience
}
```

**Hard requirements:**

- Exactly one resource block, with the local name `this`
- `for_each = var.api_integrations` — never `count`, never a hand-written list
- Field assignments map 1:1 to the object schema in `variables.tf`
- Provider-specific fields (AWS / Azure / GCP) are always passed through — when `null`, the provider ignores them; the validation rules in `variables.tf` ensure the right fields are populated for the right `api_provider`
- No `lifecycle` blocks unless a specific drift problem requires it (and then it must be commented inline explaining why)

**Forbidden:**

- Inline external function resources (`snowflake_external_function`) — those live in a separate caller module
- Inline IAM resources (`aws_iam_role`, `azuread_application`, `google_service_account`) — cloud-side trust setup is the caller's responsibility
- Data sources for cloud identities — those are caller responsibilities
- `depends_on` — `for_each` over an input map produces correct dependency ordering by itself

---

## 6. `outputs.tf` — exact spec

```hcl
output "api_integration_ids" {
  description = "Map of integration map keys to Snowflake API integration IDs."
  value       = { for k, v in snowflake_api_integration.this : k => v.id }
}

output "api_integration_names" {
  description = "Map of integration map keys to Snowflake API integration names."
  value       = { for k, v in snowflake_api_integration.this : k => v.name }
}

output "api_integration_providers" {
  description = "Map of integration map keys to the `api_provider` of each integration."
  value       = { for k, v in snowflake_api_integration.this : k => v.api_provider }
}

# AWS-specific outputs (null for non-AWS providers)
output "api_aws_iam_user_arns" {
  description = "Map of integration map keys to the Snowflake-managed IAM user ARN. Pin this in your AWS-side IAM trust policy."
  value       = { for k, v in snowflake_api_integration.this : k => try(v.api_aws_iam_user_arn, null) }
}

output "api_aws_external_ids" {
  description = "Map of integration map keys to the Snowflake-managed external ID. Pin this in your AWS-side IAM trust policy condition."
  value       = { for k, v in snowflake_api_integration.this : k => try(v.api_aws_external_id, null) }
  sensitive   = true
}

# Azure-specific outputs (null for non-Azure providers)
output "azure_consent_urls" {
  description = "Map of integration map keys to the Azure admin consent URL for the multi-tenant app. Visit each URL once per integration."
  value       = { for k, v in snowflake_api_integration.this : k => try(v.azure_consent_url, null) }
}

output "azure_multi_tenant_app_names" {
  description = "Map of integration map keys to the Azure multi-tenant app name created for each integration."
  value       = { for k, v in snowflake_api_integration.this : k => try(v.azure_multi_tenant_app_name, null) }
}
```

**Hard requirements:**

- Exactly seven outputs, with these exact names — `tests/helpers_test.go` reads them by name
- Every output is a `map(...)` keyed by `var.api_integrations` map keys (never a list, never a single value)
- Every output has a non-empty `description`
- Cloud-specific outputs use `try(v.<attr>, null)` so they return `null` for integrations that don't apply (e.g. an Azure integration's `api_aws_iam_user_arn` is `null`)
- `api_aws_external_ids` **must** be marked `sensitive = true` — it's a trust-policy secret

**Forbidden:**

- Outputs that expose raw resource objects (`output "api_integrations" { value = snowflake_api_integration.this }`) — too brittle, tests pin against attribute-level outputs
- `sensitive = true` on `api_integration_ids`, `api_integration_names`, `api_integration_providers`, `api_aws_iam_user_arns`, `azure_consent_urls`, `azure_multi_tenant_app_names` — these are not secrets and need to be readable in plan output for downstream IAM trust setup

---

## 7. Example spec

Every directory under `examples/` follows the same template. Below is the canonical `main.tf`; the literal values in the `api_integrations` map are the only thing that varies between examples.

```hcl
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    snowflake = {
      source  = "Snowflake-Labs/snowflake"
      version = ">= 0.95.0, < 1.0.0"
    }
  }
}

provider "snowflake" {}

module "snowflake_api_integration" {
  source = "../.."

  api_integrations = {
    # ↓ example-specific entries go here
  }
}
```

**Hard requirements for every example:**

- `source = "../.."` — resolves to the repo root, never `../../modules/<name>`
- `terraform` and `required_providers` blocks must match `versions.tf` exactly (same lower/upper bounds)
- `provider "snowflake" {}` is empty — auth comes from env vars (`SNOWFLAKE_ACCOUNT`, `SNOWFLAKE_USER`, etc.) so the same example runs in every developer's account and in CI without edits
- An accompanying `README.md` (≤ 30 lines) explains: what the example demonstrates, what cloud-side identities it assumes exist, what allowed prefixes are configured, and how to run it
- `terraform init -backend=false && terraform validate` must pass

### 7.1 `examples/basic/` — exact spec

`api_integrations` map content:

```hcl
api_integrations = {
  aws_api_gw = {
    name             = "AWS_API_INT"
    api_provider     = "aws_api_gateway"
    api_aws_role_arn = "arn:aws:iam::123456789012:role/snowflake-api-role"

    api_allowed_prefixes = [
      "https://abc123.execute-api.us-east-1.amazonaws.com/prod/",
      "https://abc123.execute-api.us-east-1.amazonaws.com/dev/",
    ]

    api_blocked_prefixes = [
      "https://abc123.execute-api.us-east-1.amazonaws.com/prod/admin/",
    ]

    enabled = true
    comment = "API integration for external functions via AWS API Gateway (prod + dev stages)."
  }
}
```

**Constraints:**

- Exactly one entry
- `api_provider = "aws_api_gateway"` (the entire point of the basic example)
- `api_aws_role_arn` must be present and ARN-shaped (validated by `variables.tf`)
- The README must call out that the AWS IAM role with this ARN must already exist with a trust policy referencing the Snowflake-managed IAM user — those values come from `terraform output api_aws_iam_user_arns` and `api_aws_external_ids` post-apply

### 7.2 `examples/multi-cloud/` — exact spec

`api_integrations` map content:

```hcl
api_integrations = {
  aws_api_gw = {
    name             = "AWS_API_INT"
    api_provider     = "aws_api_gateway"
    api_aws_role_arn = "arn:aws:iam::123456789012:role/snowflake-api-role"

    api_allowed_prefixes = [
      "https://abc123.execute-api.us-east-1.amazonaws.com/prod/",
    ]

    enabled = true
    comment = "AWS API Gateway integration."
  }

  azure_apim = {
    name                    = "AZURE_API_INT"
    api_provider            = "azure_api_management"
    azure_tenant_id         = "00000000-0000-0000-0000-000000000000"
    azure_ad_application_id = "11111111-1111-1111-1111-111111111111"

    api_allowed_prefixes = [
      "https://my-apim.azure-api.net/external-functions/",
    ]

    enabled = true
    comment = "Azure API Management integration."
  }

  gcp_api_gw = {
    name            = "GCP_API_INT"
    api_provider    = "google_api_gateway"
    google_audience = "my-snowflake-audience"

    api_allowed_prefixes = [
      "https://my-cloud-function.cloudfunctions.net/external-functions/",
    ]

    enabled = true
    comment = "GCP Cloud Functions integration."
  }
}
```

**Constraints:**

- Exactly three entries, one per supported `api_provider`
- AWS entry: `api_aws_role_arn` populated; Azure / GCP entry-specific fields **must not** be set
- Azure entry: both `azure_tenant_id` and `azure_ad_application_id` populated; AWS / GCP entry-specific fields **must not** be set
- GCP entry: `google_audience` populated; AWS / Azure entry-specific fields **must not** be set
- The README must list, per entry, what cloud-side trust setup the caller is expected to complete after `terraform apply` (IAM trust policy for AWS, admin consent URL for Azure, audience binding for GCP)

---

## 8. Test file spec

### 8.1 `tests/snowflake_api_integration_basic_test.go` — required structure

```go
package tests

import (
    "testing"

    "github.com/gruntwork-io/terratest/modules/terraform"
    "github.com/stretchr/testify/assert"
)

func TestSnowflakeApiIntegrationBasic(t *testing.T) {
    t.Parallel()

    opts := buildTerraformOptions(t, "../examples/basic")
    defer terraform.Destroy(t, opts)

    terraform.InitAndApply(t, opts)

    // 1. Output assertions
    ids := terraform.OutputMap(t, opts, "api_integration_ids")
    assert.Len(t, ids, 1)
    assert.Contains(t, ids, "aws_api_gw")

    names := terraform.OutputMap(t, opts, "api_integration_names")
    providers := terraform.OutputMap(t, opts, "api_integration_providers")
    assert.Equal(t, "AWS_API_GATEWAY", providers["aws_api_gw"])

    // AWS identity outputs must be non-empty for AWS provider
    iamUsers := terraform.OutputMap(t, opts, "api_aws_iam_user_arns")
    assert.Regexp(t, `^arn:aws:iam::\d+:user/`, iamUsers["aws_api_gw"])

    // 2. Snowflake-side verification
    db := newSnowflakeClient(t)
    defer db.Close()

    assertApiIntegrationExists(t, db, names["aws_api_gw"])
    assertApiIntegrationProvider(t, db, names["aws_api_gw"], "AWS_API_GATEWAY")
    assertApiIntegrationEnabled(t, db, names["aws_api_gw"], true)

    // 3. Idempotency
    plan := terraform.InitAndPlan(t, opts)
    assert.Contains(t, plan, "No changes")
}
```

**Hard requirements:**

- `package tests`
- `t.Parallel()` at the top of every top-level test
- `defer terraform.Destroy(t, opts)` is set up **before** `InitAndApply` — never after
- All Snowflake-side assertions go through helpers (`assertApiIntegrationExists`, `assertApiIntegrationProvider`, `assertApiIntegrationEnabled`, `assertApiIntegrationDestroyed`) — never raw SQL inline
- Map-key assertions check both length and exact key membership
- The `api_aws_external_ids` output is **never logged or printed** in tests — it's marked sensitive in the module and helpers must respect that

### 8.2 `tests/helpers_test.go` — fixed contract

Helpers must expose **exactly these symbols** with **exactly these signatures**:

```go
func buildTerraformOptions(t *testing.T, exampleDir string) *terraform.Options
func newSnowflakeClient(t *testing.T) *sql.DB
func assertApiIntegrationExists(t *testing.T, db *sql.DB, name string)
func assertApiIntegrationProvider(t *testing.T, db *sql.DB, name string, expectedProvider string)
func assertApiIntegrationEnabled(t *testing.T, db *sql.DB, name string, expected bool)
func assertApiIntegrationDestroyed(t *testing.T, db *sql.DB, name string)
func uniqueSuffix(t *testing.T) string
```

**Constraints on helpers:**

- No test logic — helpers are pure setup, teardown, and assertion primitives
- Every helper takes `*testing.T` and uses `t.Fatalf` / `t.Helper()` so failures point at the calling test, not the helper
- `buildTerraformOptions` injects `SNOWFLAKE_*` env vars and the cloud-side `TEST_*` env vars (`TEST_AWS_ROLE_ARN`, `TEST_AZURE_TENANT_ID`, `TEST_AZURE_AD_APP_ID`, `TEST_GCP_AUDIENCE`) into `opts.Vars`, plus a `uniqueSuffix(t)`-derived integration-name suffix
- `newSnowflakeClient` opens a single `*sql.DB` per test, scoped to `SNOWFLAKE_ROLE` (which must hold `CREATE INTEGRATION`) and `SNOWFLAKE_WAREHOUSE`, with a context timeout
- Snowflake-side assertions use `SHOW API INTEGRATIONS LIKE '<name>'` (case-insensitive) to verify presence, provider, and enabled state — never raw `INFORMATION_SCHEMA` queries

---

## 9. Utility script spec

Every script under `utils/` must satisfy:

| Constraint           | Bash scripts                                | Python scripts                                                     |
|----------------------|---------------------------------------------|--------------------------------------------------------------------|
| Strict mode          | `set -euo pipefail` on line 1 after shebang | `from __future__ import annotations` + explicit `sys.exit()` codes |
| Idempotent           | Re-running on a clean tree produces no diff | Same                                                               |
| Exit codes           | `0` success, non-zero failure               | Same                                                               |
| Header comment       | Purpose + invocation + required env vars    | Same (module docstring)                                            |
| User-facing strings  | Reference "Snowflake API integrations"      | Same                                                               |
| Repo-root invocation | `bash utils/<name>.sh`                      | `python utils/<name>.py`                                           |

### 9.1 `generate-docs.sh`

- Wraps `terraform-docs markdown table --output-file README.md --output-mode inject .`
- Re-invokes `align-md-tables.py` immediately after
- Fails if `terraform-docs` binary is missing (no silent skip)

### 9.2 `lint.sh`

- Runs `tflint --recursive` first, then `trivy config .`
- Exits with the **first** non-zero exit code (does not aggregate)
- Project-specific tflint config lives at `.tflint.hcl`; trivy config inline at the script top
- **Module-specific check**: must flag overly broad `api_allowed_prefixes` (e.g. an entry that is just `https://<domain>/` with no path) and integrations missing `api_blocked_prefixes` on entries whose comment contains `prod` / `production`

### 9.3 `align-md-tables.py`

- Parses `README.md` with `markdown-it-py` (or equivalent), pads every cell in every table to its column max width, writes back in place
- Verifies post-write that every row in every table has identical `|` positions; fails with a diff if not

### 9.4 `update-badge.sh`

- Reads `BADGE_GIST_ID` from env (required)
- Builds the JSON payload: `{ "schemaVersion": 1, "label": "...", "message": "...", "color": "..." }`
- Writes to `terraform-snowflake-api-integration.json` in the gist via `gh gist edit`
- Fails if `gh` CLI is not authenticated

---

## 10. Cross-file invariants (always check before declaring scaffolding done)

1. **Variable name** — `variables.tf` declares exactly one variable, named `api_integrations`. No other variable exists at the root level.
2. **Resource name** — `main.tf` contains exactly one resource: `snowflake_api_integration.this` with `for_each = var.api_integrations`.
3. **Output names** — `outputs.tf` declares exactly seven outputs: `api_integration_ids`, `api_integration_names`, `api_integration_providers`, `api_aws_iam_user_arns`, `api_aws_external_ids`, `azure_consent_urls`, `azure_multi_tenant_app_names`. These names are also referenced literally in `tests/snowflake_api_integration_basic_test.go`.
4. **Sensitive output** — `api_aws_external_ids` is the **only** output marked `sensitive = true`. Any other output marked sensitive is a bug.
5. **Module source paths** — every example uses `source = "../.."` and resolves to the repo root.
6. **Provider pin parity** — `versions.tf` and every `examples/*/main.tf` declare the **same** Snowflake provider source and the **same** version range. A mismatch is a bug.
7. **Helper contract parity** — every test under `tests/` uses only the helpers listed in §8.2; if a test needs a new assertion, the new helper goes in `helpers_test.go`, not inline in the test file.
8. **`package.json` name** — equals `terraform-snowflake-api-integration`. `package-lock.json` `name` field equals the same.
9. **`CONTRIBUTING.md`** — references `terraform-snowflake-api-integration` and links its **Reporting Issues** section to this repo's issues page.
10. **`README.md` headings** — every heading text is unique across the document (markdownlint MD024). Every GFM table is pipe-aligned (MD060).
11. **Provider enum parity** — the three values in the `api_provider` validation block in `variables.tf` exactly match the three keys in `examples/multi-cloud/main.tf` and the provider names used by `assertApiIntegrationProvider` in tests.
12. **No leftover template references** — search the entire scaffolded tree for `terraform-aws-dynamodb`, `terraform-aws-s3`, `terraform-snowflake-view`, `views`, `tables`, `autoscaling`, `s3_config`, `gcs_`. Any hit is a regeneration bug.

---

## 11. Drift detection

After scaffolding, run all of the following. **Every command must exit `0`.**

```bash
terraform fmt -check -recursive
terraform init -backend=false && terraform validate
( cd examples/basic && terraform init -backend=false && terraform validate )
( cd examples/multi-cloud && terraform init -backend=false && terraform validate )
bash utils/lint.sh
bash utils/generate-docs.sh && python utils/align-md-tables.py
git diff --exit-code README.md       # docs must be in sync
pre-commit run --all-files
```

If any of these fails on a freshly-scaffolded tree, the scaffolder produced inconsistent output — fix `template-spec.md` (this file) first, then regenerate.
