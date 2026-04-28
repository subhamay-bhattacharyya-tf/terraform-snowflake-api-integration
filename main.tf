# -----------------------------------------------------------------------------
# Terraform Snowflake API Integration Module - Main
# -----------------------------------------------------------------------------
# Creates one snowflake_api_integration per entry in var.api_integration_configs.
# Cloud-side IAM roles, Azure AD applications, and GCP service accounts are
# intentionally NOT managed here -- they live in their respective cloud
# provider modules and are referenced by ARN / tenant ID / audience.
# -----------------------------------------------------------------------------

resource "snowflake_api_integration" "this" {
  for_each = var.api_integration_configs

  name                 = each.value.name
  api_provider         = lower(each.value.api_provider)
  api_allowed_prefixes = each.value.api_allowed_prefixes
  api_blocked_prefixes = each.value.api_blocked_prefixes
  enabled              = each.value.enabled
  comment              = each.value.comment

  api_aws_role_arn        = each.value.api_aws_role_arn
  azure_tenant_id         = each.value.azure_tenant_id
  azure_ad_application_id = each.value.azure_ad_application_id
  google_audience         = each.value.google_audience
  api_key                 = each.value.api_key
}
