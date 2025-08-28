# Create network security group (NSG) with optional inbound and outbound rules
resource "azurerm_network_security_group" "nsg" {
  name                = var.nsg_name
  resource_group_name = var.resource_group_name
  location            = var.location

  tags = var.tags
}

# Create inbound security rules
resource "azurerm_network_security_rule" "inbound_rules" {
  for_each = { for rule in var.inbound_rules : rule.name => rule }

  resource_group_name                        = var.resource_group_name
  network_security_group_name                = azurerm_network_security_group.nsg.name
  name                                       = each.value.override_standard_naming ? each.value.name : "${each.value.access}${each.value.name}Inbound"
  description                                = each.value.description
  direction                                  = "Inbound"
  access                                     = each.value.access
  priority                                   = each.value.priority
  protocol                                   = each.value.protocol
  source_address_prefix                      = each.value.source_address_prefix != null ? each.value.source_address_prefix : each.value.source_address_prefixes != null ? null : "*"
  source_address_prefixes                    = each.value.source_address_prefixes
  source_application_security_group_ids      = each.value.source_application_security_group_ids
  source_port_range                          = each.value.source_port_range != null ? each.value.source_port_range : each.value.source_port_ranges != null ? null : "*"
  source_port_ranges                         = each.value.source_port_ranges
  destination_address_prefix                 = each.value.destination_address_prefix != null ? each.value.destination_address_prefix : each.value.destination_address_prefixes != null ? null : "*"
  destination_address_prefixes               = each.value.destination_address_prefixes
  destination_application_security_group_ids = each.value.destination_application_security_group_ids
  destination_port_range                     = each.value.destination_port_range != null ? each.value.destination_port_range : each.value.destination_port_ranges != null ? null : "*"
  destination_port_ranges                    = each.value.destination_port_ranges

  depends_on = [azurerm_network_security_group.nsg]
}

# Create outbound security rules
resource "azurerm_network_security_rule" "outbound_rules" {
  for_each = { for rule in var.outbound_rules : rule.name => rule }

  resource_group_name                        = var.resource_group_name
  network_security_group_name                = azurerm_network_security_group.nsg.name
  name                                       = each.value.override_standard_naming ? each.value.name : "${each.value.access}${each.value.name}Outbound"
  description                                = each.value.description
  direction                                  = "Outbound"
  access                                     = each.value.access
  priority                                   = each.value.priority
  protocol                                   = each.value.protocol
  source_address_prefix                      = each.value.source_address_prefix != null ? each.value.source_address_prefix : each.value.source_address_prefixes != null ? null : "*"
  source_address_prefixes                    = each.value.source_address_prefixes
  source_application_security_group_ids      = each.value.source_application_security_group_ids
  source_port_range                          = each.value.source_port_range != null ? each.value.source_port_range : each.value.source_port_ranges != null ? null : "*"
  source_port_ranges                         = each.value.source_port_ranges
  destination_address_prefix                 = each.value.destination_address_prefix != null ? each.value.destination_address_prefix : each.value.destination_address_prefixes != null ? null : "*"
  destination_address_prefixes               = each.value.destination_address_prefixes
  destination_application_security_group_ids = each.value.destination_application_security_group_ids
  destination_port_range                     = each.value.destination_port_range != null ? each.value.destination_port_range : each.value.destination_port_ranges != null ? null : "*"
  destination_port_ranges                    = each.value.destination_port_ranges

  depends_on = [azurerm_network_security_group.nsg]
}
