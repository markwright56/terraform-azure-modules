# Key Vault Variables
variable "key_vault_name" {
  description = "The name of the key vault (ex: storageaccount)"
  type        = string
  validation {
    condition     = length(var.key_vault_name) >= 3 && length(var.key_vault_name) <= 24 && can(regex("^[a-zA-Z0-9-]+$", var.key_vault_name))
    error_message = "Key vault name must be between 3 and 24 characters long and contain only  letters, numbers and dashes."
  }
}

variable "resource_group_name" {
  description = "The resource group name where the key vault will be created"
  type        = string
}

variable "location" {
  description = "The location of the key vault"
  type        = string
}

variable "tenant_id" {
  description = "The Tenant ID for the Key Vault. If not supplied defaults to the Tenant ID of the authenticated AzureRM client"
  type        = string
  default     = ""
  validation {
    condition     = var.tenant_id == "" || can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.tenant_id))
    error_message = "Tenant ID must be a valid GUID."
  }
}

variable "sku_name" {
  description = "The SKU name of the Key Vault. Possible values are 'standard' and 'premium'. Defaults to 'standard'"
  type        = string
  default     = "standard"
  validation {
    condition     = contains(["standard", "premium"], var.sku_name)
    error_message = "SKU name must be either 'standard' or 'premium'."
  }
}

variable "soft_delete_retention_days" {
  description = "The number of days that deleted key vaults are retained. Defaults to 7"
  type        = number
  default     = 7
  validation {
    condition     = var.soft_delete_retention_days >= 7 && var.soft_delete_retention_days <= 90
    error_message = "Soft delete retention days must be between 7 and 90."
  }
}

variable "public_network_access_enabled" {
  description = "Is public network access enabled for this Key Vault? Defaults to true"
  type        = bool
  default     = true
}

variable "purge_protection_enabled" {
  description = "Is purge protection enabled for this Key Vault? Defaults to true"
  type        = bool
  default     = true
}

# Access Policies
# Either access policies or RBAC must be used to manage access to the Key Vault
variable "enable_rbac_authorization" {
  description = "Enable RBAC authorization for the Key Vault. If true, access policies will be ignored. Defaults to false"
  type        = bool
  default     = false
}

variable "access_policies" {
  description = "A map of access policies to be applied to the Key Vault"
  type = map(object({
    object_id      = string
    application_id = optional(string, null)
    permissions = object({
      certificates = optional(set(string), [])
      keys         = optional(set(string), [])
      secrets      = optional(set(string), [])
      storage      = optional(set(string), [])
    })
  }))
  default = {}
  validation {
    condition     = var.enable_rbac_authorization ? length(var.access_policies) == 0 : true
    error_message = "Access policies cannot be set when RBAC authorization is enabled."
  }
  validation {
    condition     = alltrue([for policy in var.access_policies : setintersection(policy.permissions.certificates, ["Backup", "Create", "Delete", "DeleteIssuers", "Get", "GetIssuers", "Import", "List", "ListIssuers", "ManageContacts", "ManageIssuers", "Purge", "Recover", "Restore", "SetIssuers", "Update"]) == policy.permissions.certificates])
    error_message = "Certificate permissions can only contain the following values: 'Backup', 'Create', 'Delete', 'DeleteIssuers', 'Get', 'GetIssuers', 'Import', 'List', 'ListIssuers', 'ManageContacts', 'ManageIssuers', 'Purge', 'Recover', 'Restore', 'SetIssuers', 'Update'."
  }
  validation {
    condition     = alltrue([for policy in var.access_policies : setintersection(policy.permissions.keys, ["Backup", "Create", "Decrypt", "Delete", "Encrypt", "Get", "Import", "List", "Purge", "Recover", "Restore", "Sign", "UnwrapKey", "Update", "Verify", "WrapKey", "Release", "Rotate", "GetRotationPolicy", "SetRotationPolicy"]) == policy.permissions.keys])
    error_message = "Key permissions can only contain the following values: 'Backup', 'Create', 'Decrypt', 'Delete', 'Encrypt', 'Get', 'Import', 'List', 'Purge', 'Recover', 'Restore', 'Sign', 'UnwrapKey', 'Update', 'Verify', 'WrapKey', 'Release', 'Rotate', 'GetRotationPolicy', 'SetRotationPolicy'."
  }
  validation {
    condition     = alltrue([for policy in var.access_policies : setintersection(policy.permissions.secrets, ["Backup", "Delete", "Get", "List", "Purge", "Recover", "Restore", "Set"]) == policy.permissions.secrets])
    error_message = "Secret permissions can only contain the following values: 'Backup', 'Delete','Get','List','Purge', 'Recover', 'Restore', 'Set'."
  }
  validation {
    condition     = alltrue([for policy in var.access_policies : setintersection(policy.permissions.storage, ["Backup", "Delete", "DeleteSAS", "Get", "GetSAS", "List", "ListSAS", "Purge", "Recover", "RegenerateKey", "Restore", "Set", "SetSAS", "Update"]) == policy.permissions.storage])
    error_message = "Storage permissions can only contain the following values: 'Backup', 'Delete', 'DeleteSAS', 'Get', 'GetSAS', 'List', 'ListSAS', 'Purge', 'Recover', 'RegenerateKey', 'Restore', 'Set', 'SetSAS', 'Update'."
  }
}

# Diagnostics
variable "diagnostic_settings" {
  description = "A map of diagnostic settings to be created for the Key Vault"
  type = map(object({
    name                           = optional(string, null)
    log_categories                 = optional(set(string), [])
    log_groups                     = optional(set(string), ["AllLogs"])
    metric_categories              = optional(set(string), ["AllMetrics"])
    event_hub_resource_id          = optional(string, null)
    event_hub_name                 = optional(string, null)
    log_analytics_destination_type = optional(string, "Dedicated")
    log_analytics_workspace_id     = optional(string, null)
    storage_account_id             = optional(string, null)
  }))
  default = {}
  validation {
    condition = alltrue([
      for setting in var.diagnostic_settings :
      setting.event_hub_resource_id != null ||
      setting.log_analytics_workspace_id != null ||
      setting.storage_account_id != null
    ])
    error_message = "At least one of event_hub_resource_id, log_analytics_workspace_id, or storage_account_id must be provided for each diagnostic setting."
  }
}

# Network Rules
variable "network_rules" {
  description = "Network rules for the storage account"
  type = object({
    enable_network_rules       = optional(bool, false) # If true, network rules are enforced
    default_action             = optional(string, "Deny")
    bypass                     = optional(set(string), ["AzureServices"])
    ip_rules                   = optional(set(string), [])
    virtual_network_subnet_ids = optional(set(string), [])
  })
  validation {
    condition     = var.network_rules.enable_network_rules == false ? true : contains(["Deny", "Allow"], var.network_rules.default_action)
    error_message = "If network rules are enabled, default_action must be either 'Deny' or 'Allow'."
  }
  validation {
    condition     = var.network_rules.enable_network_rules == false ? true : contains(["AzureServices", "None"], var.network_rules.bypass)
    error_message = "If network rules are enabled, bypass must be either 'AzureServices' or 'None'."
  }
}

# Tags
variable "tags" {
  description = "A map of tags to be associated to all resources"
  type        = map(string)
  default     = {}
}
