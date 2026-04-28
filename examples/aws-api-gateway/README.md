# AWS API Gateway Example - Single Integration

The minimum viable usage of the `terraform-snowflake-api-integration` module:
a single AWS API Gateway integration provisioned through the
`api_integration_configs` map input.

## What this example demonstrates

- Calling the module with a single-entry `api_integration_configs` map
- Setting `api_provider = "aws_api_gateway"` and supplying `api_aws_role_arn`
- Scoping the integration to specific API Gateway stages via
  `api_allowed_prefixes` and excluding admin paths via `api_blocked_prefixes`
- Reading `api_aws_iam_user_arn` and `api_aws_external_id` (from the
  sensitive `api_integrations` output) to wire up the IAM trust policy on
  the AWS side

## Cloud-side trust setup

This example assumes that an IAM role (the value of `api_aws_role_arn`) has
already been created on the AWS side. After `terraform apply`, the role's
trust policy must be updated so that:

- `Principal.AWS` is `module.snowflake_api_integration.api_integrations["aws_api_gw"].api_aws_iam_user_arn`
- The condition `sts:ExternalId` equals
  `module.snowflake_api_integration.api_integrations["aws_api_gw"].api_aws_external_id`

Both values are populated after the apply.

## Usage

```hcl
module "snowflake_api_integration" {
  source = "../.."

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
      comment = "API integration for external functions via AWS API Gateway (prod + dev stages)."
    }
  }
}
```

## Inputs

| Name                    | Description                                  | Type        | Required |
| ----------------------- | -------------------------------------------- | ----------- | -------- |
| api_integration_configs | Map of Snowflake API integrations to create. | map(object) | yes      |

## Outputs

| Name                                  | Description                                                                         |
| ------------------------------------- | ----------------------------------------------------------------------------------- |
| api_integration_names                 | Names of the created API integrations, keyed by config key.                         |
| api_integration_fully_qualified_names | Fully qualified names of the API integrations, keyed by config key.                 |
| api_integrations                      | All API integration resources, keyed by config key. (sensitive -- contains api_key) |
