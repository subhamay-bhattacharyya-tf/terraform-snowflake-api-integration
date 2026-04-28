# Multiple Warehouses Example

This example demonstrates how to create multiple Snowflake warehouses using a single module call with a map of configurations.

## Usage

```hcl
module "warehouses" {
  source = "../.."

  warehouse_configs = {
    "adhoc_wh" = {
      name                      = "SN_TEST_ADHOC_WH"
      warehouse_size            = "X-SMALL"
      warehouse_type            = "STANDARD"
      auto_resume               = true
      auto_suspend              = 60
      initially_suspended       = true
      min_cluster_count         = 1
      max_cluster_count         = 1
      scaling_policy            = "STANDARD"
      enable_query_acceleration = false
      comment                   = "Development and sandbox warehouse for ad-hoc queries."
    }
    "load_wh" = {
      name                      = "SN_TEST_LOAD_WH"
      warehouse_size            = "X-SMALL"
      warehouse_type            = "STANDARD"
      auto_resume               = true
      auto_suspend              = 60
      initially_suspended       = true
      min_cluster_count         = 1
      max_cluster_count         = 1
      scaling_policy            = "STANDARD"
      enable_query_acceleration = false
      comment                   = "Dedicated ingestion warehouse for loading files."
    }
    "transform_wh" = {
      name                      = "SN_TEST_TRANSFORM_WH"
      warehouse_size            = "SMALL"
      warehouse_type            = "STANDARD"
      auto_resume               = true
      auto_suspend              = 120
      initially_suspended       = true
      min_cluster_count         = 1
      max_cluster_count         = 2
      scaling_policy            = "STANDARD"
      enable_query_acceleration = true
      comment                   = "ETL/ELT warehouse for transformations."
    }
  }
}
```

## Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| warehouse_configs | Map of warehouse configuration objects | map(object) | yes |

## Outputs

| Name | Description |
|------|-------------|
| warehouse_names | The names of the created warehouses |
| warehouse_fully_qualified_names | The fully qualified names of the warehouses |
| warehouse_sizes | The sizes of the warehouses |
| warehouse_states | The states of the warehouses |
| warehouses | All warehouse resources |
