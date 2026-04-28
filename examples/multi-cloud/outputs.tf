# -----------------------------------------------------------------------------
# Terraform Snowflake API Integration Module - Multi-Cloud Example Outputs
# -----------------------------------------------------------------------------
# Re-exports every output map from the root module. Downstream cloud-side
# trust setup (AWS IAM trust policy, Azure admin consent, etc.) reads these
# values to wire each integration's identity into its target cloud.
# -----------------------------------------------------------------------------

output "api_integration_ids" {
  description = "Map of integration map keys to Snowflake API integration IDs."
  value       = module.snowflake_api_integration.api_integration_ids
}

output "api_integration_names" {
  description = "Map of integration map keys to Snowflake API integration names."
  value       = module.snowflake_api_integration.api_integration_names
}

output "api_integration_providers" {
  description = "Map of integration map keys to the `api_provider` of each integration."
  value       = module.snowflake_api_integration.api_integration_providers
}

output "api_aws_iam_user_arns" {
  description = "Map of integration map keys to the Snowflake-managed IAM user ARN. Pin this in your AWS-side IAM trust policy."
  value       = module.snowflake_api_integration.api_aws_iam_user_arns
}

output "api_aws_external_ids" {
  description = "Map of integration map keys to the Snowflake-managed external ID. Pin this in your AWS-side IAM trust policy condition."
  value       = module.snowflake_api_integration.api_aws_external_ids
  sensitive   = true
}

output "azure_consent_urls" {
  description = "Map of integration map keys to the Azure admin consent URL for the multi-tenant app."
  value       = module.snowflake_api_integration.azure_consent_urls
}

output "azure_multi_tenant_app_names" {
  description = "Map of integration map keys to the Azure multi-tenant app name created for each integration."
  value       = module.snowflake_api_integration.azure_multi_tenant_app_names
}
