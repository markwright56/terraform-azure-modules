# Storage Account Variables
variable "storage_account_name" {
  description = "The name of the storage account (ex: storageaccount)"
  type        = string
  validation {
    condition     = length(var.storage_account_name) >= 3 && length(var.storage_account_name) <= 24 && can(regex("^[a-z0-9]+$", var.storage_account_name))
    error_message = "Storage account name must be between 3 and 24 characters long and contain only lowercase letters and numbers."
  }
}

variable "resource_group_name" {
  description = "The resource group name where the storage account will be created"
  type        = string
}

variable "location" {
  description = "The location of the storage account"
  type        = string
}

variable "account_tier" {
  description = "The performance tier of the storage account (ex: Standard, Premium)"
  type        = string
  default     = "Standard"
  validation {
    condition     = contains(["Standard", "Premium"], var.account_tier)
    error_message = "Account tier must be either 'Standard' or 'Premium'."
  }
}

variable "account_replication_type" {
  description = "The replication strategy of the storage account (ex: ZRS,RAGRS)"
  type        = string
  default     = "LRS"
  validation {
    condition     = contains(["LRS", "ZRS", "GRS", "RAGRS", "GZRS", "RAGZRS"], var.account_replication_type)
    error_message = "Account replication type must be one of 'LRS', 'ZRS', 'GRS', 'RAGRS', 'GZRS' or 'RAGZRS'."
  }
}

variable "allow_nested_items_to_be_public" {
  description = "Allow or disallow nested items within this Account to opt into being public. Defaults to false"
  type        = bool
  default     = false
}

variable "cross_tenant_replication_enabled" {
  description = "Should cross Tenant replication be enabled? Defaults to false"
  type        = bool
  default     = false
}

variable "public_network_access_enabled" {
  description = "Whether the public network access is enabled? Defaults to true"
  type        = bool
  default     = true
}

# Managed Identity
variable "managed_identity" {
  description = "Managed identity configuration for the storage account"
  type = object({
    system_assigned          = optional(bool, false)
    user_assigned_identities = optional(set(string), [])
  })
  default = {}
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

# Azure Files Authentication
variable "azure_files_authentication" {
  description = "Details of the Azure Files authentication"
  type = object({
    use_authentication             = bool
    directory_type                 = optional(string, "AADKERB") # Options: AADDS, AAD, AADKERB
    default_share_level_permission = optional(string, "None")    # Options: None, StorageFileDataSmbShareReader, StorageFileDataSmbShareContributor, StorageFileDataSmbShareElevatedContributor
    active_directory = optional(object({
      use_active_directory = bool
      domain_name          = optional(string, " ") # The domain name
      domain_guid          = optional(string, " ") # The GUID of the domain
      domain_sid           = optional(string, " ") # The SID of the domain
      forest_name          = optional(string, " ") # The forest name
      netbios_domain_name  = optional(string, " ") # The NetBIOS name of the domain
      storage_sid          = optional(string, " ") # The storage SID
    }))
  })
  default = {
    use_authentication = false
  }
}

# Blob Properties
variable "blob_properties" {
  description = "Properties for the blob storage account"
  type = object({
    change_feed_enabled        = optional(bool, false) # Enable or disable change feed
    change_feed_retention_days = optional(number, 7)   # Number of days to retain change feed
    versioning_enabled         = optional(bool, false) # Enable or disable versioning
    container_delete_retention_policy = optional(object({
      enabled = optional(bool, false) # Enable or disable container delete retention policy
      days    = optional(number, 7)   # Number of days to retain deleted containers
    }))
    delete_retention_policy = optional(object({
      enabled          = optional(bool, false) # Enable or disable delete retention policy
      days             = optional(number, 7)   # Number of days to retain deleted blobs
      permanent_delete = optional(bool, false) # Enable or disable permanent delete
    }))
    restore_policy = optional(object({
      enabled = optional(bool, false) # Enable or disable restore policy
      days    = optional(number, 7)   # Number of days to retain deleted blobs for restore
    }))
  })
  default = null
  validation {
    condition     = (!(try(var.blob_properties.delete_retention_policy.permanent_delete, false) == true && try(var.blob_properties.restore_policy.enabled, false) == true))
    error_message = "Delete retention policy permanent delete cannot be set to true when restore policy is enabled."
  }
}

# Storage Blob Containers
variable "storage_blob_containers" {
  description = "A map of storage blob containers to be created with their access types"
  type        = map(any)
  default = {
    # "container1" = {
    #   name        = "container1"
    #   access_type = "private"
    # },
    # "container2" = {
    #   name        = "container2"
    #   access_type = "blob"
    # }
  }
  validation {
    condition     = alltrue([for container in var.storage_blob_containers : can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", container.name))])
    error_message = "All container names must start and end with a lowercase letter or number, and can contain hyphens in between."
  }
  validation {
    condition     = alltrue([for container in var.storage_blob_containers : length(container.name) >= 3 && length(container.name) <= 63])
    error_message = "All container names must be between 3 and 63 characters long."
  }
  validation {
    condition     = alltrue([for container in var.storage_blob_containers : contains(["private", "blob", "container"], container.access_type)])
    error_message = "Access type must be one of 'private', 'blob', or 'container'."
  }
}

# Storage File Shares 
variable "storage_file_shares" {
  description = "A map of storage file shares to be created with their quotas"
  type        = map(any)
  default = {
    # "share1" = {
    #   name  = "share1"
    #   quota = 512
    # },
    # "share2" = {
    #   name  = "share2"
    #   quota = 1024
    # }
  }
  validation {
    condition     = alltrue([for share in var.storage_file_shares : can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", share.name))])
    error_message = "All share names must start and end with a lowercase letter or number, and can contain hyphens in between."
  }
  validation {
    condition     = alltrue([for share in var.storage_file_shares : length(share.name) >= 3 && length(share.name) <= 63])
    error_message = "All share names must be between 3 and 63 characters long."
  }
}

# Storage Queues
variable "storage_queues" {
  description = "A list of storage queues to be created"
  type        = set(string)
  default = [
    # "queue1",
    # "queue2"
  ]
  validation {
    condition     = alltrue([for queue in var.storage_queues : can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", queue))])
    error_message = "All queue names must start and end with a lowercase letter or number, and can contain hyphens in between."
  }
  validation {
    condition     = alltrue([for queue in var.storage_queues : length(queue) >= 3 && length(queue) <= 63])
    error_message = "All queue names must be between 3 and 63 characters long."
  }
}

# Tags
variable "tags" {
  description = "A map of tags to be associated to all resources"
  type        = map(string)
  default     = {}
}
