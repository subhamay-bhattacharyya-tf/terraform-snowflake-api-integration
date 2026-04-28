# -----------------------------------------------------------------------------
# Terraform Snowflake API Integration Module - Variables
# -----------------------------------------------------------------------------
# Single map-based input. The map key is a logical Terraform identifier used
# in for_each and in output maps. The actual Snowflake API integration name
# lives inside the object as the `name` field.
# -----------------------------------------------------------------------------

variable "api_integrations" {
  description = "Map of Snowflake API integrations to create. Map key is a logical Terraform identifier; the actual Snowflake API integration name is the `name` field."

  type = map(object({
    name                 = string
    api_provider         = string
    api_allowed_prefixes = list(string)
    api_blocked_prefixes = optional(list(string), [])
    enabled              = optional(bool, true)
    comment              = optional(string, null)

    # AWS API Gateway
    api_aws_role_arn = optional(string, null)

    # Azure API Management
    azure_tenant_id         = optional(string, null)
    azure_ad_application_id = optional(string, null)

    # Google Cloud
    google_audience = optional(string, null)
  }))

  default = {}

  validation {
    condition     = alltrue([for k, v in var.api_integrations : length(v.name) > 0])
    error_message = "Each API integration must have a non-empty `name`."
  }

  validation {
    condition = alltrue([
      for k, v in var.api_integrations :
      can(regex("^[A-Za-z_][A-Za-z0-9_]*$", v.name))
    ])
    error_message = "Each API integration `name` must be a valid Snowflake unquoted identifier (letters, digits, underscores; cannot start with a digit)."
  }

  validation {
    condition = alltrue([
      for k, v in var.api_integrations :
      contains(["aws_api_gateway", "azure_api_management", "google_api_gateway"], v.api_provider)
    ])
    error_message = "`api_provider` must be one of: aws_api_gateway, azure_api_management, google_api_gateway."
  }

  validation {
    condition     = alltrue([for k, v in var.api_integrations : length(v.api_allowed_prefixes) > 0])
    error_message = "Each API integration must have at least one entry in `api_allowed_prefixes`."
  }

  validation {
    condition = alltrue([
      for k, v in var.api_integrations :
      v.api_provider != "aws_api_gateway" || (v.api_aws_role_arn != null && length(v.api_aws_role_arn) > 0)
    ])
    error_message = "AWS API Gateway integrations require `api_aws_role_arn`."
  }

  validation {
    condition = alltrue([
      for k, v in var.api_integrations :
      v.api_provider != "aws_api_gateway" || v.api_aws_role_arn == null ||
      can(regex("^arn:aws[a-zA-Z-]*:iam::[0-9]{12}:role/.+$", v.api_aws_role_arn))
    ])
    error_message = "`api_aws_role_arn` must be a valid IAM role ARN (e.g. arn:aws:iam::123456789012:role/my-role)."
  }

  validation {
    condition = alltrue([
      for k, v in var.api_integrations :
      v.api_provider != "azure_api_management" || (
        v.azure_tenant_id != null && v.azure_ad_application_id != null
      )
    ])
    error_message = "Azure API Management integrations require both `azure_tenant_id` and `azure_ad_application_id`."
  }

  validation {
    condition = alltrue([
      for k, v in var.api_integrations :
      v.api_provider != "azure_api_management" || v.azure_tenant_id == null ||
      can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", v.azure_tenant_id))
    ])
    error_message = "`azure_tenant_id` must be a valid UUID (e.g. 00000000-0000-0000-0000-000000000000)."
  }

  validation {
    condition = alltrue([
      for k, v in var.api_integrations :
      v.api_provider != "google_api_gateway" || (v.google_audience != null && length(v.google_audience) > 0)
    ])
    error_message = "Google API Gateway integrations require `google_audience`."
  }
}
