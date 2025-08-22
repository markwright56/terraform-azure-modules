# Create key vault
resource "azurerm_key_vault" "key_vault" {
  name                          = var.key_vault_name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  tenant_id                     = var.tenant_id != "" ? var.tenant_id : data.azurerm_client_config.current.tenant_id
  sku_name                      = var.sku_name
  public_network_access_enabled = var.public_network_access_enabled
  purge_protection_enabled      = var.purge_protection_enabled
  soft_delete_retention_days    = var.soft_delete_retention_days

  dynamic "network_rules" {
    for_each = var.network_rules.enable_network_rules ? [var.network_rules] : []
    content {
      default_action             = var.network_rules.default_action
      bypass                     = var.network_rules.bypass
      ip_rules                   = var.network_rules.ip_rules
      virtual_network_subnet_ids = var.network_rules.virtual_network_subnet_ids
    }
  }

  tags = var.tags
}

# Add access policies if RBAC is not enabled
# These are added outside of the key vault resource to allow addition policies to be added in other modules
resource "azurerm_key_vault_access_policy" "access_policies" {
  for_each = var.enable_rbac_authorization ? {} : var.access_policies

  key_vault_id = azurerm_key_vault.key_vault.id
  tenant_id    = var.tenant_id != "" ? var.tenant_id : data.azurerm_client_config.current.tenant_id
  object_id    = each.value.object_id

  key_permissions         = each.value.permissions.keys
  secret_permissions      = each.value.permissions.secrets
  certificate_permissions = each.value.permissions.certificates
  storage_permissions     = each.value.permissions.storage

  depends_on = [azurerm_key_vault.key_vault]
}

# Add diagnostics
resource "azurerm_monitor_diagnostic_setting" "key_vault_diagnostics" {
  for_each                       = var.diagnostic_settings
  name                           = each.value.name != null ? each.value.name : "diag-${azurerm_key_vault.key_vault.name}"
  target_resource_id             = azurerm_key_vault.key_vault.id
  eventhub_authorization_rule_id = each.value.event_hub_resource_id
  eventhub_name                  = each.value.event_hub_name
  log_analytics_workspace_id     = each.value.log_analytics_workspace_id
  log_analytics_destination_type = each.value.log_analytics_destination_type
  storage_account_id             = each.value.storage_account_id

  dynamic "enabled_log" {
    for_each = each.value.log_categories
    content {
      category = enabled_log.value
    }
  }
  dynamic "enabled_log" {
    for_each = each.value.log_groups
    content {
      category_group = enabled_log.value
    }
  }
  dynamic "metric" {
    for_each = each.value.metric_categories
    content {
      category = metric.value
      enabled  = true
    }
  }

  depends_on = [azurerm_key_vault.key_vault]
}
