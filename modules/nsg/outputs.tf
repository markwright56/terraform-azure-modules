output "nsg_id" {
  description = "The network security group id"
  value       = azurerm_network_security_group.nsg.id
}

output "nsg_name" {
  description = "The network security group name"
  value       = azurerm_network_security_group.nsg.name
}
