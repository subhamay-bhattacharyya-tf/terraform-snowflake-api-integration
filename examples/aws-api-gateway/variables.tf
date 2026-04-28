# -----------------------------------------------------------------------------
# Terraform Snowflake API Integration Module - AWS API Gateway Example Vars
# -----------------------------------------------------------------------------
# Single AWS API Gateway integration. Override `api_integration_configs` from
# the command line / tfvars to change the integration name, role ARN, or
# allowed prefixes. Defaults are provided so `terraform validate` works
# without any input.
# -----------------------------------------------------------------------------

variable "api_integration_configs" {
  description = "Map of Snowflake API integrations to create."
  type = map(object({
    name                 = string
    api_provider         = string
    api_allowed_prefixes = list(string)
    api_blocked_prefixes = optional(list(string), [])
    enabled              = optional(bool, true)
    comment              = optional(string, null)

    api_aws_role_arn = optional(string, null)

    azure_tenant_id         = optional(string, null)
    azure_ad_application_id = optional(string, null)

    google_audience = optional(string, null)

    api_key = optional(string, null)
  }))
  default = {
    aws_api_gw = {
      name             = "AWS_API_INT"
      api_provider     = "aws_api_gateway"
      api_aws_role_arn = "arn:aws:iam::123456789012:role/snowflake-api-role"

      api_allowed_prefixes = [
        "https://abc123.execute-api.us-east-1.amazonaws.com/prod/",
        "https://abc123.execute-api.us-east-1.amazonaws.com/dev/",
      ]

      api_blocked_prefixes = [
        "https://abc123.execute-api.us-east-1.amazonaws.com/prod/admin/",
      ]

      enabled = true
      comment = "API integration for external functions via AWS API Gateway (prod + dev stages)."
    }
  }
}

# Snowflake authentication variables
variable "snowflake_organization_name" {
  description = "Snowflake organization name"
  type        = string
  default     = null
}

variable "snowflake_account_name" {
  description = "Snowflake account name"
  type        = string
  default     = null
}

variable "snowflake_user" {
  description = "Snowflake username"
  type        = string
  default     = null
}

variable "snowflake_role" {
  description = "Snowflake role"
  type        = string
  default     = null
}

variable "snowflake_private_key" {
  description = "Snowflake private key for key-pair authentication"
  type        = string
  sensitive   = true
  default     = null
}
