# Create storage account
resource "azurerm_storage_account" "storage" {
  name                             = var.storage_account_name
  resource_group_name              = var.resource_group_name
  location                         = var.location
  account_kind                     = var.account_kind
  account_tier                     = var.account_tier
  account_replication_type         = var.account_replication_type
  cross_tenant_replication_enabled = var.cross_tenant_replication_enabled
  access_tier                      = var.access_tier
  https_traffic_only_enabled       = var.https_traffic_only_enabled
  min_tls_version                  = var.min_tls_version
  allow_nested_items_to_be_public  = var.allow_nested_items_to_be_public
  shared_access_key_enabled        = var.shared_access_key_enabled
  public_network_access_enabled    = var.public_network_access_enabled
  default_to_oauth_authentication  = var.default_to_oauth_authentication
  large_file_share_enabled         = var.large_file_share_enabled

  dynamic "custom_domain" {
    for_each = var.custom_domain != null ? [var.custom_domain] : []
    content {
      name          = custom_domain.value.name
      use_subdomain = try(custom_domain.value.use_subdomain, false)
    }
  }

  dynamic "identity" {
    for_each = var.managed_identity.system_assigned || length(var.managed_identity.user_assigned_identities) > 0 ? [var.managed_identity] : []
    content {
      type         = identity.value.system_assigned && length(identity.value.user_assigned_identities) > 0 ? "SystemAssigned, UserAssigned" : identity.value.system_assigned ? "SystemAssigned" : "UserAssigned"
      identity_ids = try(identity.value.user_assigned_identities, [])
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

  dynamic "queue_properties" {
    for_each = var.queue_properties != null ? [var.queue_properties] : []
    content {
      logging {
        delete                = queue_properties.value.logging.delete
        read                  = queue_properties.value.logging.read
        write                 = queue_properties.value.logging.write
        version               = queue_properties.value.logging.version
        retention_policy_days = queue_properties.value.logging.retention_days
      }
      minute_metrics {
        enabled               = queue_properties.value.minute_metrics_enabled
        version               = queue_properties.value.minute_metrics_version
        retention_policy_days = queue_properties.value.minute_metrics_retention_days
        include_apis          = queue_properties.value.minute_metrics_include_apis
      }
      hour_metrics {
        enabled               = queue_properties.value.hour_metrics_enabled
        version               = queue_properties.value.hour_metrics_version
        retention_policy_days = queue_properties.value.hour_metrics_retention_days
        include_apis          = queue_properties.value.hour_metrics_include_apis
      }
    }
  }

  dynamic "static_website" {
    for_each = var.static_website.enabled ? [var.static_website] : []
    content {
      index_document     = static_website.value.index_document
      error_404_document = static_website.value.error_404_document
    }
  }

  dynamic "share_properties" {
    for_each = var.share_properties != null ? [var.share_properties] : []
    content {
      retention_policy {
        days = share_properties.value.retention_days
      }
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
