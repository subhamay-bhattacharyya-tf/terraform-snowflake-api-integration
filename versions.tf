# -----------------------------------------------------------------------------
# Terraform Snowflake API Integration Module - Versions
# -----------------------------------------------------------------------------
# Pins the Terraform CLI version and the Snowflake provider version that the
# module is tested against. Examples inherit these constraints via the module
# call; do not redeclare provider versions in example configurations with
# different bounds.
#
# The Snowflake provider was renamed from `Snowflake-Labs/snowflake` to
# `snowflakedb/snowflake` at v1.0.0. Callers upgrading from a 0.x pin must run
# `terraform state replace-provider Snowflake-Labs/snowflake snowflakedb/snowflake`.
# -----------------------------------------------------------------------------

terraform {
  required_version = ">= 1.3.0"

  required_providers {
    snowflake = {
      source  = "snowflakedb/snowflake"
      version = ">= 1.0.0"
    }
  }
}
