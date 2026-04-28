# Basic Example - Single AWS API Gateway Integration

The minimum viable usage of the `terraform-snowflake-api-integration` module:
a single AWS API Gateway integration provisioned through the `api_integrations`
map input.

## What this example demonstrates

- Calling the module with a single-entry `api_integrations` map
- Setting `api_provider = "aws_api_gateway"` and supplying `api_aws_role_arn`
- Scoping the integration to specific API Gateway stages via `api_allowed_prefixes`
- Reading `api_aws_iam_user_arn` and `api_aws_external_id` outputs to wire up
  the IAM trust policy on the AWS side

## Cloud-side trust setup

This example assumes that an IAM role (the value of `api_aws_role_arn`) has
already been created on the AWS side. After `terraform apply`, the role's
trust policy must be updated so that:

- `Principal.AWS` is the value of `api_aws_iam_user_arns["aws_api_gw"]`
- The condition `sts:ExternalId` equals `api_aws_external_ids["aws_api_gw"]`

Both values are emitted as outputs after the apply.

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

| Name             | Description                                    | Type            | Required |
| ---------------- | ---------------------------------------------- | --------------- | -------- |
| api_integrations | Map of Snowflake API integrations to create.   | map(object)     | yes      |

## Outputs

| Name                      | Description                                                                          |
| ------------------------- | ------------------------------------------------------------------------------------ |
| api_integration_ids       | Map of integration map keys to Snowflake API integration IDs.                        |
| api_integration_names     | Map of integration map keys to Snowflake API integration names.                      |
| api_integration_providers | Map of integration map keys to the `api_provider` of each integration.               |
| api_aws_iam_user_arns     | Map of integration map keys to the Snowflake-managed IAM user ARN.                   |
| api_aws_external_ids      | Map of integration map keys to the Snowflake-managed external ID. (sensitive)        |
