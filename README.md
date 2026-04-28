# Terraform Snowflake API Integration Module

![Release](https://github.com/subhamay-bhattacharyya-tf/terraform-snowflake-api-integration/actions/workflows/ci.yaml/badge.svg)&nbsp;![Snowflake](https://img.shields.io/badge/Snowflake-29B5E8?logo=snowflake&logoColor=white)&nbsp;![Commit Activity](https://img.shields.io/github/commit-activity/t/subhamay-bhattacharyya-tf/terraform-snowflake-api-integration)&nbsp;![Last Commit](https://img.shields.io/github/last-commit/subhamay-bhattacharyya-tf/terraform-snowflake-api-integration)&nbsp;![Release Date](https://img.shields.io/github/release-date/subhamay-bhattacharyya-tf/terraform-snowflake-api-integration)&nbsp;![Repo Size](https://img.shields.io/github/repo-size/subhamay-bhattacharyya-tf/terraform-snowflake-api-integration)&nbsp;![File Count](https://img.shields.io/github/directory-file-count/subhamay-bhattacharyya-tf/terraform-snowflake-api-integration)&nbsp;![Issues](https://img.shields.io/github/issues/subhamay-bhattacharyya-tf/terraform-snowflake-api-integration)&nbsp;![Top Language](https://img.shields.io/github/languages/top/subhamay-bhattacharyya-tf/terraform-snowflake-api-integration)&nbsp;![Custom Endpoint](https://img.shields.io/endpoint?url=https://gist.githubusercontent.com/bsubhamay/e69b8c605f94271ea3441aabb7e8820b/raw/terraform-snowflake-api-integration.json?)

A Terraform module for creating and managing Snowflake API integrations
across AWS API Gateway (public, private, GovCloud public, GovCloud private),
Azure API Management, and Google API Gateway. Provisions one or more
`snowflake_api_integration` resources from a single map-based input.

> **Note on `git_https_api`:** The `snowflakedb/snowflake` provider does not
> currently expose `git_https_api` as a value for `api_provider` (see the
> [provider's resource doc](https://github.com/snowflakedb/terraform-provider-snowflake/blob/main/docs/resources/api_integration.md)).
> Snowflake Git API integrations (used by Streamlit-in-Snowflake) must be
> managed outside this module until the provider adds support.

## Features

- Map-based configuration for creating one or many API integrations in a
  single module call
- Supports the six provider variants accepted by `snowflake_api_integration`:
  `aws_api_gateway`, `aws_private_api_gateway`, `aws_gov_api_gateway`,
  `aws_gov_private_api_gateway`, `azure_api_management`, `google_api_gateway`
- Built-in input validation: `api_provider` enum (case-insensitive),
  required `api_aws_role_arn` for AWS variants (with ARN format check),
  required `azure_tenant_id` + `azure_ad_application_id` for Azure,
  required `google_audience` for GCP
- Outputs keyed by integration identifier for cross-resource lookup
- Cloud-side IAM roles, Azure AD applications, and GCP service accounts are
  intentionally **not** managed here -- they live in their respective cloud
  provider modules and are referenced by ARN / tenant ID / audience

## Usage

### Single AWS API Gateway integration

```hcl
module "snowflake_api_integration" {
  source = "github.com/subhamay-bhattacharyya-tf/terraform-snowflake-api-integration?ref=main"

  api_integration_configs = {
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
      comment = "API integration for external functions via AWS API Gateway."
    }
  }
}
```

### Multi-cloud (AWS + Azure + GCP) in one module call

```hcl
module "snowflake_api_integration" {
  source = "github.com/subhamay-bhattacharyya-tf/terraform-snowflake-api-integration?ref=main"

  api_integration_configs = {
    aws_api_gw = {
      name             = "AWS_API_INT"
      api_provider     = "aws_api_gateway"
      api_aws_role_arn = "arn:aws:iam::123456789012:role/snowflake-api-role"
      api_allowed_prefixes = [
        "https://abc123.execute-api.us-east-1.amazonaws.com/prod/",
      ]
    }
    azure_api_mgmt = {
      name                    = "AZURE_API_INT"
      api_provider            = "azure_api_management"
      azure_tenant_id         = "00000000-0000-0000-0000-000000000000"
      azure_ad_application_id = "11111111-1111-1111-1111-111111111111"
      api_allowed_prefixes = [
        "https://contoso-api.azure-api.net/external/",
      ]
    }
    gcp_api_gw = {
      name            = "GCP_API_INT"
      api_provider    = "google_api_gateway"
      google_audience = "snowflake-external-functions"
      api_allowed_prefixes = [
        "https://us-central1-my-project.cloudfunctions.net/snowflake-external-functions/",
      ]
    }
  }
}
```

The map key (`aws_api_gw`, `azure_api_mgmt`, `gcp_api_gw`) is a logical
Terraform identifier used in `for_each` and in output maps; the actual
Snowflake API integration name (e.g. `AWS_API_INT`) lives inside the
object as the `name` field. This separation lets the same Terraform
identifier survive a Snowflake-side rename without forcing a destroy /
create.

## Examples

| Example                                       | Description                                                                                        |
| --------------------------------------------- | -------------------------------------------------------------------------------------------------- |
| [aws-api-gateway](examples/aws-api-gateway)   | Single AWS API Gateway integration. Reference for new users learning the module's input shape.     |
| [multi-cloud](examples/multi-cloud)           | AWS + Azure + GCP integrations in a single module call. Reference for the multi-provider use case. |

<!-- BEGIN_TF_DOCS -->
## Resources

| Name                                                                                                                                  | Type     |
| ------------------------------------------------------------------------------------------------------------------------------------- | -------- |
| [snowflake_api_integration.this](https://registry.terraform.io/providers/snowflakedb/snowflake/latest/docs/resources/api_integration) | resource |

## Inputs

| Name                                                                                                       | Description                                                                                                                                                  | Type                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       | Default | Required |
| ---------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------- | :------: |
| <a name="input_api_integration_configs"></a> [api\_integration\_configs](#input\_api\_integration\_configs) | Map of configuration objects for Snowflake API integrations. The map key is a logical Terraform identifier; the actual Snowflake API integration name is the `name` field. | <pre>map(object({<br/>    name                 = string<br/>    api_provider         = string<br/>    api_allowed_prefixes = list(string)<br/>    api_blocked_prefixes = optional(list(string), [])<br/>    enabled              = optional(bool, true)<br/>    comment              = optional(string, null)<br/><br/>    api_aws_role_arn = optional(string, null)<br/><br/>    azure_tenant_id         = optional(string, null)<br/>    azure_ad_application_id = optional(string, null)<br/><br/>    google_audience = optional(string, null)<br/><br/>    api_key = optional(string, null)<br/>  }))</pre> | `{}`    |    no    |

## Outputs

| Name                                                                                                                                              | Description                                                                                                              |
| ------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------ |
| <a name="output_api_integration_names"></a> [api\_integration\_names](#output\_api\_integration\_names)                                           | Names of the created API integrations, keyed by config key.                                                              |
| <a name="output_api_integration_fully_qualified_names"></a> [api\_integration\_fully\_qualified\_names](#output\_api\_integration\_fully\_qualified\_names) | Fully qualified names of the API integrations, keyed by config key.                                                |
| <a name="output_api_integrations"></a> [api\_integrations](#output\_api\_integrations)                                                            | All API integration resources, keyed by config key. Marked sensitive because `api_key` may be present.                   |
<!-- END_TF_DOCS -->

## Validation

The module validates inputs and provides descriptive error messages for:

- Empty or invalid Snowflake API integration `name` (must be a valid
  Snowflake unquoted identifier)
- `api_provider` not in the supported enum (`aws_api_gateway`,
  `aws_private_api_gateway`, `aws_gov_api_gateway`,
  `aws_gov_private_api_gateway`, `azure_api_management`,
  `google_api_gateway`)
- `api_allowed_prefixes` empty
- AWS variant missing `api_aws_role_arn`, or `api_aws_role_arn` not a
  valid IAM role ARN (`arn:aws[-partition]:iam::<12-digit>:role/<name>`)
- Azure provider missing `azure_tenant_id` or `azure_ad_application_id`
- GCP provider missing `google_audience`

## Testing

The module includes Terratest-based integration tests that create real
Snowflake API integrations, assert outputs, and destroy on teardown.

```bash
cd tests
go mod tidy
go test -v -timeout 30m -run TestSnowflakeApiIntegrationAws
```

Required environment variables for testing:

| Variable                      | Description                                                          |
| ----------------------------- | -------------------------------------------------------------------- |
| `SNOWFLAKE_ORGANIZATION_NAME` | Snowflake organization name                                          |
| `SNOWFLAKE_ACCOUNT_NAME`      | Snowflake account name                                               |
| `SNOWFLAKE_ACCOUNT`           | Target Snowflake account identifier                                  |
| `SNOWFLAKE_USER`              | Snowflake username with `CREATE INTEGRATION`                         |
| `SNOWFLAKE_ROLE`              | Snowflake role used for the test session                             |
| `SNOWFLAKE_WAREHOUSE`         | Snowflake warehouse used for the test session                        |
| `SNOWFLAKE_PRIVATE_KEY`       | Snowflake private key for key-pair authentication (PEM)              |
| `TEST_AWS_ROLE_ARN`           | Pre-created IAM role ARN for the AWS API Gateway example             |
| `TEST_AZURE_TENANT_ID`        | Azure AD tenant ID used by the multi-cloud example                   |
| `TEST_AZURE_AD_APP_ID`        | Azure AD multi-tenant application ID used by the multi-cloud example |
| `TEST_GCP_AUDIENCE`           | GCP audience string used by the multi-cloud example                  |

## CI/CD Configuration

The CI workflow runs on:

- Push to `main`, `feature/**`, and `bug/**` branches (when `*.tf`,
  `examples/**`, `tests/**`, `utils/**`, or `README.md` change)
- Pull requests to `main` (same path filters)
- Manual workflow dispatch

The workflow runs the following jobs:

| Job                                   | Description                                                                                        |
| ------------------------------------- | -------------------------------------------------------------------------------------------------- |
| `terraform-validate`                  | `fmt -check`, `init`, `validate` on the root module; runs `utils/lint.sh` (tflint + trivy)         |
| `examples-validate`                   | `init` + `validate` on `examples/aws-api-gateway` and `examples/multi-cloud`                       |
| `docs-drift`                          | Regenerates README tables via `utils/generate-docs.sh` + `utils/align-md-tables.py`; fails on diff |
| `snowflake-api-integration-terratest` | Real Snowflake integration test (`TestSnowflakeApiIntegrationAws`); refreshes the README badge     |
| `generate-changelog`                  | `git-cliff` runs on non-main branches                                                              |
| `semantic-release`                    | Runs only on `main`; refreshes the README badge with the new version                               |

The CI workflow uses the following GitHub repository / organization variables:

| Variable                      | Description                                                          | Default |
| ----------------------------- | -------------------------------------------------------------------- | ------- |
| `TERRAFORM_VERSION`           | Terraform version for CI jobs                                        | `1.5.0` |
| `GO_VERSION`                  | Go version for Terratest                                             | `1.22`  |
| `SNOWFLAKE_ORGANIZATION_NAME` | Snowflake organization name                                          | -       |
| `SNOWFLAKE_ACCOUNT_NAME`      | Snowflake account name                                               | -       |
| `SNOWFLAKE_ACCOUNT`           | Target Snowflake account identifier                                  | -       |
| `SNOWFLAKE_USER`              | Snowflake username (must have `CREATE INTEGRATION`)                  | -       |
| `SNOWFLAKE_ROLE`              | Snowflake role used for the test session                             | -       |
| `SNOWFLAKE_WAREHOUSE`         | Snowflake warehouse used for the test session                        | -       |
| `TEST_AWS_ROLE_ARN`           | IAM role ARN used by the AWS API Gateway example                     | -       |
| `TEST_AZURE_TENANT_ID`        | Azure AD tenant ID used by the multi-cloud example                   | -       |
| `TEST_AZURE_AD_APP_ID`        | Azure AD multi-tenant application ID used by the multi-cloud example | -       |
| `TEST_GCP_AUDIENCE`           | GCP audience string used by the multi-cloud example                  | -       |

The following GitHub secrets are required:

| Secret                  | Description                                                                    | Required |
| ----------------------- | ------------------------------------------------------------------------------ | -------- |
| `SNOWFLAKE_PRIVATE_KEY` | Snowflake private key for key-pair authentication (PEM)                        | Yes      |
| `BADGE_GIST_ID`         | Secret gist ID hosting `terraform-snowflake-api-integration.json`              | Yes      |
| `GIST_TOKEN`            | GitHub PAT with `gist` scope, used by `utils/update-badge.sh` to edit the gist | Yes      |

## License

MIT License - See [LICENSE](LICENSE) for details.
