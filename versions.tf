# -----------------------------------------------------------------------------
# Terraform Snowflake Module Template - Versions
# -----------------------------------------------------------------------------
# This file specifies the required Terraform version and provider versions
# for the module.
# -----------------------------------------------------------------------------

terraform {
  required_version = ">= 1.3.0"

  required_providers {
    snowflake = {
      source  = "snowflakedb/snowflake"
      version = ">= 0.87.0"
    }
  }
}
