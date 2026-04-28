# -----------------------------------------------------------------------------
# Terraform Snowflake API Integration Module - Multi-Cloud Example Versions
# -----------------------------------------------------------------------------
# Inherits Terraform / provider version bounds from the root module.
# Provider configuration uses key-pair (JWT) authentication.
#
# Required environment variables:
#   SNOWFLAKE_ORGANIZATION_NAME - Snowflake organization name
#   SNOWFLAKE_ACCOUNT_NAME      - Snowflake account name
#   SNOWFLAKE_USER              - Snowflake username
#   SNOWFLAKE_ROLE              - Snowflake role with CREATE INTEGRATION
#   SNOWFLAKE_PRIVATE_KEY       - Snowflake private key (PEM format)
# -----------------------------------------------------------------------------

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    snowflake = {
      source  = "Snowflake-Labs/snowflake"
      version = ">= 0.95.0, < 1.0.0"
    }
  }
}

provider "snowflake" {
  organization_name = var.snowflake_organization_name
  account_name      = var.snowflake_account_name
  user              = var.snowflake_user
  role              = var.snowflake_role
  authenticator     = "SNOWFLAKE_JWT"
  private_key       = var.snowflake_private_key
}
