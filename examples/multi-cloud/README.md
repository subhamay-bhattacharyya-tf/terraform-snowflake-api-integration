# Multi-Cloud Example - AWS + Azure + GCP API Integrations

Provisions AWS, Azure, and GCP API integrations in a single module call.
Demonstrates the map-based, multi-provider use case for the
`terraform-snowflake-api-integration` module.

## What this example demonstrates

- One `api_integrations` map with three entries, each using a different
  `api_provider`
- AWS entry: `api_aws_role_arn` + AWS API Gateway prefixes
- Azure entry: `azure_tenant_id` + `azure_ad_application_id` + Azure
  API Management prefixes
- GCP entry: `google_audience` + Cloud Functions prefixes
- Reading the per-cloud identity outputs (`api_aws_iam_user_arn` /
  `api_aws_external_id` for AWS, `azure_consent_url` /
  `azure_multi_tenant_app_name` for Azure) to drive downstream cloud-side
  trust setup

## Cloud-side trust setup

This example assumes the cloud-side identities already exist:

- **AWS** — an IAM role (whose ARN is the value of `api_aws_role_arn`) with
  a trust policy that will be updated post-apply to trust the
  Snowflake-managed IAM user (`api_aws_iam_user_arn`) under condition
  `sts:ExternalId = api_aws_external_id`
- **Azure** — an Azure AD tenant (`azure_tenant_id`) and a multi-tenant
  application (`azure_ad_application_id`) registered to the API
  Management instance. After apply, an admin must visit the
  `azure_consent_url` to grant consent
- **GCP** — a Cloud Functions / Cloud Run target whose IAM allows
  invocation by the audience (`google_audience`) supplied to the
  integration

## Usage

```hcl
module "snowflake_api_integration" {
  source = "../.."

  api_integrations = {
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
        "https://us-central1-my-project.cloudfunctions.net/",
      ]
    }
  }
}
```

## Inputs

| Name             | Description                                                              | Type        | Required |
| ---------------- | ------------------------------------------------------------------------ | ----------- | -------- |
| api_integrations | Map of Snowflake API integrations to create across AWS, Azure, and GCP.  | map(object) | yes      |

## Outputs

| Name                         | Description                                                                       |
| ---------------------------- | --------------------------------------------------------------------------------- |
| api_integration_ids          | Map of integration map keys to Snowflake API integration IDs.                     |
| api_integration_names        | Map of integration map keys to Snowflake API integration names.                   |
| api_integration_providers    | Map of integration map keys to the `api_provider` of each integration.            |
| api_aws_iam_user_arns        | Map of integration map keys to the Snowflake-managed IAM user ARN.                |
| api_aws_external_ids         | Map of integration map keys to the Snowflake-managed external ID. (sensitive)     |
| azure_consent_urls           | Map of integration map keys to the Azure admin consent URL.                       |
| azure_multi_tenant_app_names | Map of integration map keys to the Azure multi-tenant app name.                   |
