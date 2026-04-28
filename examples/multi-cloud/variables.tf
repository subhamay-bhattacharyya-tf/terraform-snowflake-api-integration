# -----------------------------------------------------------------------------
# Terraform Snowflake API Integration Module - Multi-Cloud Example Variables
# -----------------------------------------------------------------------------
# Provisions one AWS, one Azure, and one GCP API integration in a single
# module call. Defaults are placeholder identifiers so the example validates
# without input; override the entire `api_integration_configs` map (or
# individual fields via tfvars) for a real apply.
# -----------------------------------------------------------------------------

variable "api_integration_configs" {
  description = "Map of Snowflake API integrations to create across AWS, Azure, and GCP."
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
      ]

      enabled = true
      comment = "AWS API Gateway integration."
    }
    azure_api_mgmt = {
      name                    = "AZURE_API_INT"
      api_provider            = "azure_api_management"
      azure_tenant_id         = "00000000-0000-0000-0000-000000000000"
      azure_ad_application_id = "11111111-1111-1111-1111-111111111111"

      api_allowed_prefixes = [
        "https://contoso-api.azure-api.net/external/",
      ]

      enabled = true
      comment = "Azure API Management integration for external functions."
    }
    gcp_api_gw = {
      name            = "GCP_API_INT"
      api_provider    = "google_api_gateway"
      google_audience = "snowflake-external-functions"

      api_allowed_prefixes = [
        "https://us-central1-my-project.cloudfunctions.net/snowflake-external-functions/",
      ]

      enabled = true
      comment = "GCP Cloud Functions integration for external functions."
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
