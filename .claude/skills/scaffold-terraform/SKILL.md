---
name: scaffold-terraform
description: Use this skill to scaffold the standard Terraform module structure for `terraform-snowflake-api-integration`. Trigger when the user wants to create or restore the root-level Terraform config files (`main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`), bootstrap the `examples/`, `tests/`, or `utils/` directories, or generate boilerplate for a new Snowflake API integration example. Also trigger when the user says "scaffold", "bootstrap", "set up the module", "regenerate the structure", or "generate the terraform files" — even if they don't mention specific filenames.
---

# scaffold-terraform — terraform-snowflake-api-integration

Scaffold the standard structure for the `terraform-snowflake-api-integration` Terraform module. This module is **flat** (root-level `*.tf` files, no `modules/` subdirectory) and provisions only `snowflake_api_integration` resources via a single `api_integrations` map input consumed by `for_each`.

This skill is the canonical reference for what every scaffolded file should contain, what conventions every example must follow, and what cross-file invariants must hold. Use it whenever generating boilerplate so the output is consistent with the rest of the repository and with `CLAUDE.md`.

## When to use this skill

Trigger this skill when the user wants to:

- Create the four root Terraform files from scratch (`main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`)
- Restore or align files that have drifted from the standard layout
- Bootstrap a new example under `examples/` (e.g. `examples/aws-only/`, `examples/azure-only/`)
- Bootstrap a new Terratest file under `tests/` to cover a new example
- Bootstrap a new helper script under `utils/`
- Regenerate the entire structure after a destructive change

Do **not** trigger this skill for unrelated work — IAM trust policy edits (which live in cloud-side modules), external function definitions (out of scope for this module), CI workflow tweaks, or README-only edits.

## Module shape

The module is a single flat Terraform module rooted at the repository root. Files live at the root, **not** under `modules/`.

```text
.
├── main.tf            # Creates snowflake_api_integration resources via for_each over var.api_integrations
├── variables.tf       # Defines var.api_integrations — map(object({...})) with validation blocks
├── outputs.tf         # Exposes maps of integration attributes keyed by var.api_integrations map keys
├── versions.tf        # Pins required Terraform and Snowflake provider versions
├── examples/
│   ├── basic/         # Single AWS API Gateway integration
│   └── multi-cloud/   # AWS + Azure + GCP integrations in one module call
├── tests/
│   ├── snowflake_api_integration_basic_test.go
│   └── helpers_test.go
└── utils/
    ├── generate-docs.sh
    ├── lint.sh
    ├── align-md-tables.py
    └── update-badge.sh
```

## Root-level Terraform files

### `versions.tf`

Pin required Terraform and Snowflake provider versions. Always emit this first — it constrains what the rest of the module can use.

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

### `variables.tf`

Defines a single map-based input named `api_integrations`. Every field on the object lives here, every constraint lives in a `validation` block here.

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

Validation rules to always include:

- `name` is non-empty
- `api_provider` is one of the three allowed enum values
- `api_allowed_prefixes` has at least one entry
- Provider-specific required fields are present (AWS → `api_aws_role_arn`, Azure → `azure_tenant_id` + `azure_ad_application_id`, GCP → `google_audience`)
- (Optional) `api_aws_role_arn` matches the IAM role ARN pattern, `azure_tenant_id` is a UUID — add when stricter validation is requested

### `main.tf`

Creates `snowflake_api_integration` resources via `for_each` over `var.api_integrations`. Keep this file thin — no inline external functions, no IAM resources, no `count`, no nested modules.

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

### `outputs.tf`

Expose maps keyed by the `var.api_integrations` map keys, so downstream callers can look up attributes by the same logical identifier they used as input. Outputs include both Snowflake-side identifiers and the cloud-side identity values that downstream IAM trust policies need.

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

## Examples

Every example under `examples/` must:

- Be self-contained (its own `terraform`, `provider`, and module call blocks)
- Call the root module via `source = "../.."` — never copy the resource inline
- Use the `api_integrations` map input — never inline `snowflake_api_integration` resources
- Include a short `README.md` explaining what it demonstrates and the cloud-side trust setup it assumes
- Validate cleanly via `terraform init -backend=false && terraform validate`

### Standard scaffold for a new example

```hcl
# examples/<name>/main.tf
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
    # Map key is a logical Terraform identifier
    example_integration = {
      name             = "EXAMPLE_API_INT"
      api_provider     = "aws_api_gateway"
      api_aws_role_arn = "arn:aws:iam::123456789012:role/snowflake-api-role"

      api_allowed_prefixes = [
        "https://abc123.execute-api.us-east-1.amazonaws.com/prod/",
      ]

      enabled = true
      comment = "Describe what this example demonstrates."
    }
  }
}
```

### `examples/basic/`

Single AWS API Gateway integration. Single-entry `api_integrations` map. The reference for new users learning the module's input shape and the Snowflake → AWS trust-policy handshake.

### `examples/multi-cloud/`

AWS + Azure + GCP integrations in a single module call. Three-entry `api_integrations` map, each entry using a different `api_provider`. Demonstrates the map-based, multi-provider use case and shows how to read the per-cloud identity outputs (`api_aws_iam_user_arn`, `azure_consent_url`, etc.) to drive downstream cloud-side trust setup.

## Tests

Every Terratest file under `tests/` must:

- Live under `tests/` (plural), never `test/`
- Use the helpers in `helpers_test.go` for setup, teardown, and assertions
- Target one of the configurations under `examples/` as its working directory
- Clean up via `defer terraform.Destroy(...)` — failures must not leak API integrations into the target Snowflake account
- Reference Snowflake API integrations in test names, log messages, and assertion errors

### Standard scaffold for a new test file

```go
// tests/<example>_test.go
package tests

import (
    "testing"

    "github.com/gruntwork-io/terratest/modules/terraform"
    "github.com/stretchr/testify/assert"
)

func TestSnowflakeApiIntegration<Example>(t *testing.T) {
    t.Parallel()

    opts := buildTerraformOptions(t, "../examples/<example>")
    defer terraform.Destroy(t, opts)

    terraform.InitAndApply(t, opts)

    // 1. Output assertions
    ids := terraform.OutputMap(t, opts, "api_integration_ids")
    assert.NotEmpty(t, ids)

    names := terraform.OutputMap(t, opts, "api_integration_names")

    // 2. Snowflake-side verification via helpers
    db := newSnowflakeClient(t)
    defer db.Close()

    for _, name := range names {
        assertApiIntegrationExists(t, db, name)
        assertApiIntegrationEnabled(t, db, name, true)
    }

    // 3. Idempotency
    plan := terraform.InitAndPlan(t, opts)
    assert.Contains(t, plan, "No changes")
}
```

The helper contract (`buildTerraformOptions`, `newSnowflakeClient`, `assertApiIntegrationExists`, `assertApiIntegrationProvider`, `assertApiIntegrationEnabled`, `assertApiIntegrationDestroyed`, `uniqueSuffix`) is fixed — do not reinvent these per test.

## Utility scripts

Every script under `utils/` must:

- Be runnable from the repository root
- Be idempotent (no diff on a clean tree when run twice)
- Exit non-zero on failure so it can gate CI and pre-commit
- Reference Snowflake API integrations in user-facing output

The four standard scripts are `generate-docs.sh`, `lint.sh`, `align-md-tables.py`, and `update-badge.sh` — see `CLAUDE.md` for what each one does and when it's invoked. New scripts should follow the same shape: a header comment describing purpose and invocation, strict mode (`set -euo pipefail` for bash), and a final success or failure log line.

`lint.sh` carries an extra responsibility for this module: it must flag overly broad `api_allowed_prefixes` (e.g. an entire API Gateway domain without a stage path) and integrations missing `api_blocked_prefixes` on production-tagged entries.

## Cross-file invariants

After scaffolding any file, the following must hold:

- `variables.tf` declares exactly one variable named `api_integrations` of type `map(object({...}))`
- `main.tf` contains exactly one resource block: `resource "snowflake_api_integration" "this"` with `for_each = var.api_integrations`
- `outputs.tf` declares output map names that match what `tests/helpers_test.go` reads (`api_integration_ids`, `api_integration_names`, `api_integration_providers`, `api_aws_iam_user_arns`, `api_aws_external_ids`, `azure_consent_urls`, `azure_multi_tenant_app_names`)
- `api_aws_external_ids` is marked `sensitive = true` — it's part of the IAM trust policy condition and shouldn't surface in plan output
- `versions.tf` is the only place that pins Terraform or provider versions — examples must inherit, not redeclare with different versions
- Every example's `source = "../.."` resolves to the repository root (not `../../modules/<name>`)
- `package.json` `name` field equals `terraform-snowflake-api-integration`
- `README.md` headings are unique (markdownlint MD024) and all GFM tables are pipe-aligned (MD060) — run `utils/generate-docs.sh` then `utils/align-md-tables.py` after any change to `variables.tf` / `outputs.tf` / `main.tf`

## Quick checklist before declaring scaffolding complete

- [ ] `terraform fmt -check -recursive` passes
- [ ] `terraform init -backend=false && terraform validate` passes at the repo root
- [ ] Each `examples/*` directory passes `terraform init -backend=false && terraform validate`
- [ ] `utils/generate-docs.sh` runs cleanly and `utils/align-md-tables.py` produces no diff on `README.md`
- [ ] `pre-commit run --all-files` passes
- [ ] No leftover references to the upstream template (e.g. `terraform-aws-dynamodb`, `terraform-snowflake-view`, `tables`, `autoscaling`, `views`, `s3_config`) anywhere in the scaffolded files