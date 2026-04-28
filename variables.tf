# -----------------------------------------------------------------------------
# Terraform Snowflake API Integration Module - Variables
# -----------------------------------------------------------------------------
# Single map-based input. The map key is a logical Terraform identifier used
# in for_each and in output maps. The actual Snowflake API integration name
# lives inside the object as the `name` field.
# -----------------------------------------------------------------------------

variable "api_integration_configs" {
  description = "Map of configuration objects for Snowflake API integrations. The map key is a logical Terraform identifier; the actual Snowflake API integration name is the `name` field."

  type = map(object({
    name                 = string
    api_provider         = string
    api_allowed_prefixes = list(string)
    api_blocked_prefixes = optional(list(string), [])
    enabled              = optional(bool, true)
    comment              = optional(string, null)

    # AWS variants only (aws_api_gateway, aws_private_api_gateway,
    # aws_gov_api_gateway, aws_gov_private_api_gateway)
    api_aws_role_arn = optional(string, null)

    # Azure only
    azure_tenant_id         = optional(string, null)
    azure_ad_application_id = optional(string, null)

    # Google only
    google_audience = optional(string, null)

    # Optional, sensitive -- used by some providers
    api_key = optional(string, null)
  }))

  # NOTE: this variable is intentionally NOT marked `sensitive = true`. Even
  # though individual entries may set `api_key`, marking the variable sensitive
  # would taint var.api_integration_configs and Terraform forbids sensitive
  # values as `for_each` keys (see main.tf). The sensitive output below
  # (`api_integrations`) shields the underlying resource from logging instead.
  default = {}

  validation {
    condition     = alltrue([for k, v in var.api_integration_configs : length(v.name) > 0])
    error_message = "Each API integration must have a non-empty `name`."
  }

  validation {
    condition = alltrue([
      for k, v in var.api_integration_configs :
      can(regex("^[A-Za-z_][A-Za-z0-9_]*$", v.name))
    ])
    error_message = "Each API integration `name` must be a valid Snowflake unquoted identifier (letters, digits, underscores; cannot start with a digit)."
  }

  validation {
    condition = alltrue([
      for k, v in var.api_integration_configs :
      contains(
        [
          "aws_api_gateway",
          "aws_private_api_gateway",
          "aws_gov_api_gateway",
          "aws_gov_private_api_gateway",
          "azure_api_management",
          "google_api_gateway",
        ],
        lower(v.api_provider)
      )
    ])
    error_message = "`api_provider` must be one of: aws_api_gateway, aws_private_api_gateway, aws_gov_api_gateway, aws_gov_private_api_gateway, azure_api_management, google_api_gateway (case-insensitive)."
  }

  validation {
    condition     = alltrue([for k, v in var.api_integration_configs : length(v.api_allowed_prefixes) > 0])
    error_message = "Each API integration must have at least one entry in `api_allowed_prefixes`."
  }

  # Conditional: AWS variants require api_aws_role_arn matching an IAM role ARN.
  validation {
    condition = alltrue([
      for k, v in var.api_integration_configs :
      !startswith(lower(v.api_provider), "aws_") || (
        v.api_aws_role_arn != null &&
        can(regex("^arn:aws[a-z\\-]*:iam::\\d{12}:role/.+", v.api_aws_role_arn))
      )
    ])
    error_message = "AWS API integrations (aws_*) require `api_aws_role_arn` matching `arn:aws[-partition]:iam::<12-digit-account>:role/<role-name>`."
  }

  # Conditional: Azure requires both tenant id and AD application id.
  validation {
    condition = alltrue([
      for k, v in var.api_integration_configs :
      lower(v.api_provider) != "azure_api_management" || (
        v.azure_tenant_id != null && v.azure_ad_application_id != null
      )
    ])
    error_message = "Azure API Management integrations require both `azure_tenant_id` and `azure_ad_application_id`."
  }

  # Conditional: Google requires google_audience.
  validation {
    condition = alltrue([
      for k, v in var.api_integration_configs :
      lower(v.api_provider) != "google_api_gateway" || (
        v.google_audience != null && length(v.google_audience) > 0
      )
    ])
    error_message = "Google API Gateway integrations require `google_audience`."
  }
}
