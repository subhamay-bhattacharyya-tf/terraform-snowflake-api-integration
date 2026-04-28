# -----------------------------------------------------------------------------
# Terraform Snowflake API Integration Module - Outputs
# -----------------------------------------------------------------------------
# All outputs are maps keyed by the var.api_integration_configs map keys, so
# callers can look up attributes using the same logical identifier they
# supplied as input.
# -----------------------------------------------------------------------------

output "api_integration_names" {
  description = "Names of the created API integrations, keyed by config key."
  value       = { for k, v in snowflake_api_integration.this : k => v.name }
}

output "api_integration_fully_qualified_names" {
  description = "Fully qualified names of the API integrations, keyed by config key."
  value       = { for k, v in snowflake_api_integration.this : k => v.fully_qualified_name }
}

output "api_integrations" {
  description = "All API integration resources, keyed by config key. Marked sensitive because `api_key` may be present."
  value       = snowflake_api_integration.this
  sensitive   = true
}
