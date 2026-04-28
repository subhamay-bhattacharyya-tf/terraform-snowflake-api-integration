# -----------------------------------------------------------------------------
# Terraform Snowflake API Integration Module - Multi-Cloud Example Main
# -----------------------------------------------------------------------------
# Provisions AWS + Azure + GCP API integrations in a single module call,
# demonstrating the map-based, multi-provider use case.
# -----------------------------------------------------------------------------

module "snowflake_api_integration" {
  source = "../.."

  api_integrations = var.api_integrations
}
