# -----------------------------------------------------------------------------
# Terraform Snowflake Module Template - Multiple Warehouses Example Main
# -----------------------------------------------------------------------------
# This example demonstrates how to create multiple Snowflake warehouses using
# a map of configurations.
# -----------------------------------------------------------------------------

module "warehouses" {
  source = "../.."

  warehouse_configs = var.warehouse_configs
}
