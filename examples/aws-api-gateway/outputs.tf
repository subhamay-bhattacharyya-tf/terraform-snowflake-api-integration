# -----------------------------------------------------------------------------
# Terraform Snowflake API Integration Module - AWS API Gateway Example Outs
# -----------------------------------------------------------------------------
# Surfaces the module's output maps so downstream tooling (and Terratest) can
# read them. The Snowflake-managed IAM user ARN and external ID required for
# the AWS-side IAM trust policy are exposed via the sensitive
# `api_integrations` output (look up `api_aws_iam_user_arn` and
# `api_aws_external_id` per resource).
# -----------------------------------------------------------------------------

output "api_integration_names" {
  description = "Names of the created API integrations, keyed by config key."
  value       = module.snowflake_api_integration.api_integration_names
}

output "api_integration_fully_qualified_names" {
  description = "Fully qualified names of the API integrations, keyed by config key."
  value       = module.snowflake_api_integration.api_integration_fully_qualified_names
}

output "api_integrations" {
  description = "All API integration resources, keyed by config key. Marked sensitive because api_key may be present and api_aws_external_id is sensitive."
  value       = module.snowflake_api_integration.api_integrations
  sensitive   = true
}
