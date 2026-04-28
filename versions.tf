# -----------------------------------------------------------------------------
# Terraform Snowflake API Integration Module - Versions
# -----------------------------------------------------------------------------
# Pins the Terraform CLI version and the Snowflake provider version that the
# module is tested against. Examples inherit these constraints via the module
# call; do not redeclare provider versions in example configurations with
# different bounds.
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
