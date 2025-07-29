output "storage_account_name" {
  description = "The name of the storage account created"
  value       = azurerm_storage_account.storage.name
}

output "storage_account_id" {
  description = "The ID of the storage account created"
  value       = azurerm_storage_account.storage.id
}

output "storage_account_access_key" {
  description = "The primary access key of the storage account created"
  value       = azurerm_storage_account.storage.primary_access_key
}

output "storage_blob_container_names" {
  description = "The names of the blob containers created"
  value       = [for container in azurerm_storage_container.container : container.name]
}

output "storage_file_share_names" {
  description = "The names of the storage file shares"
  value       = [for share in azurerm_storage_share.file_share : share.name]
}

output "storage_queue_names" {
  description = "The names of the storage queues"
  value       = [for queue in azurerm_storage_queue.queue : queue.name]
}

output "storage_account_fqdn_map" {
  description = "The fully qualified domain names (FQDN) for the storage account endpoints"
  value = {
    blob  = try("https://${azurerm_storage_account.storage.primary_blob_endpoint}", null)
    file  = try("https://${azurerm_storage_account.storage.primary_file_endpoint}", null)
    queue = try("https://${azurerm_storage_account.storage.primary_queue_endpoint}", null)
    table = try("https://${azurerm_storage_account.storage.primary_table_endpoint}", null)
    web   = try("https://${azurerm_storage_account.storage.primary_web_endpoint}", null)
    dfs   = try("https://${azurerm_storage_account.storage.primary_dfs_endpoint}", null)
  }
}
