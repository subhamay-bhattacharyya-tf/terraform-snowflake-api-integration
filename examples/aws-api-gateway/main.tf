# -----------------------------------------------------------------------------
# Terraform Snowflake API Integration Module - AWS API Gateway Example Main
# -----------------------------------------------------------------------------
# Demonstrates a single AWS API Gateway integration -- the minimum viable
# usage of the module. The Snowflake-managed IAM user ARN and external ID
# (needed for the AWS-side IAM trust policy) live on each resource as
# api_aws_iam_user_arn and api_aws_external_id; they are surfaced via the
# sensitive api_integrations output.
# -----------------------------------------------------------------------------

module "snowflake_api_integration" {
  source = "../.."

  api_integration_configs = var.api_integration_configs
}
