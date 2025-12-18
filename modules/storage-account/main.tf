# Create storage account
resource "azurerm_storage_account" "storage" {
  name                             = var.storage_account_name
  resource_group_name              = var.resource_group_name
  location                         = var.location
  account_kind                     = var.account_kind
  access_tier                      = var.access_tier
  account_tier                     = var.account_tier
  account_replication_type         = var.account_replication_type
  allow_nested_items_to_be_public  = var.allow_nested_items_to_be_public
  cross_tenant_replication_enabled = var.cross_tenant_replication_enabled
  public_network_access_enabled    = var.public_network_access_enabled

  dynamic "identity" {
    for_each = var.managed_identity.system_assigned || length(var.managed_identity.user_assigned_identities) > 0 ? [var.managed_identity] : []
    content {
      type         = identity.value.system_assigned && length(identity.value.user_assigned_identities) > 0 ? "SystemAssigned, UserAssigned" : identity.value.system_assigned ? "SystemAssigned" : "UserAssigned"
      identity_ids = try(identity.value.user_assigned_identities, [])
    }
  }

  dynamic "network_rules" {
    for_each = var.network_rules.enable_network_rules ? [var.network_rules] : []
    content {
      default_action             = var.network_rules.default_action
      bypass                     = var.network_rules.bypass
      ip_rules                   = var.network_rules.ip_rules
      virtual_network_subnet_ids = var.network_rules.virtual_network_subnet_ids
    }
  }

  dynamic "azure_files_authentication" {
    for_each = var.azure_files_authentication.use_authentication == true ? [var.azure_files_authentication] : []
    content {
      directory_type                 = azure_files_authentication.value.directory_type
      default_share_level_permission = azure_files_authentication.value.default_share_level_permission

      dynamic "active_directory" {
        for_each = azure_files_authentication.value.active_directory.use_active_directory == true ? [azure_files_authentication.value.active_directory] : []
        content {
          domain_name         = active_directory.value.domain_name
          domain_guid         = active_directory.value.domain_guid
          domain_sid          = active_directory.value.domain_sid
          forest_name         = active_directory.value.forest_name
          netbios_domain_name = active_directory.value.netbios_domain_name
          storage_sid         = active_directory.value.storage_sid
        }
      }
    }
  }

  dynamic "blob_properties" {
    for_each = var.blob_properties != null ? [var.blob_properties] : []
    content {
      change_feed_enabled           = blob_properties.value.change_feed_enabled
      change_feed_retention_in_days = blob_properties.value.change_feed_retention_days
      versioning_enabled            = blob_properties.value.versioning_enabled

      dynamic "container_delete_retention_policy" {
        for_each = blob_properties.value.container_delete_retention_policy.enabled ? [blob_properties.value.container_delete_retention_policy] : []
        content {
          days = container_delete_retention_policy.value.days
        }
      }

      dynamic "delete_retention_policy" {
        for_each = blob_properties.value.delete_retention_policy.enabled ? [blob_properties.value.delete_retention_policy] : []
        content {
          days                     = delete_retention_policy.value.days
          permanent_delete_enabled = delete_retention_policy.value.permanent_delete_enabled
        }
      }

      dynamic "restore_policy" {
        for_each = blob_properties.value.restore_policy.enabled ? [blob_properties.value.restore_policy] : []
        content {
          days = restore_policy.value.days
        }
      }
    }
  }

  tags = var.tags
}

# Create blob containers
resource "azurerm_storage_container" "container" {
  for_each              = var.storage_blob_containers
  name                  = each.value.name
  storage_account_id    = azurerm_storage_account.storage.id
  container_access_type = try(each.value.access_type, "private")

  depends_on = [azurerm_storage_account.storage]
}

# Create file shares
resource "azurerm_storage_share" "file_share" {
  for_each           = var.storage_file_shares
  name               = each.value.name
  storage_account_id = azurerm_storage_account.storage.id
  quota              = try(each.value.quota, null)
  access_tier        = try(each.value.access_tier, "Hot")

  depends_on = [azurerm_storage_account.storage]
}

# Create queues
resource "azurerm_storage_queue" "queue" {
  for_each           = var.storage_queues
  name               = each.value
  storage_account_id = azurerm_storage_account.storage.id

  depends_on = [azurerm_storage_account.storage]
}
