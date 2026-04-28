# -----------------------------------------------------------------------------
# Terraform Snowflake Module Template - Basic Example Main
# -----------------------------------------------------------------------------
# This example demonstrates how to create a single Snowflake warehouse.
# -----------------------------------------------------------------------------

module "warehouse" {
  source = "../.."

  warehouse_configs = var.warehouse_configs
}
