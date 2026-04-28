# -----------------------------------------------------------------------------
# Terraform Snowflake API Integration Module - Outputs
# -----------------------------------------------------------------------------
# All outputs are maps keyed by the var.api_integrations map keys, so callers
# can look up attributes using the same logical identifier they supplied as
# input. Cloud-side identity outputs (AWS IAM user ARN / external ID, Azure
# consent URL, etc.) are required for downstream IAM trust policy setup.
# -----------------------------------------------------------------------------

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
