# NSG Variables
variable "nsg_name" {
  description = "The name of the network security group"
  type        = string
  validation {
    condition     = can(regex("^[A-Za-z0-9_](?:[A-Za-z0-9_.-]{0,78}[A-Za-z0-9_])?$", var.nsg_name))
    error_message = "The name must be between 1 and 80 characters long, can only contain alphanumeric characters, underscores, hyphens, and periods, and must start and end with an alphanumeric character."
  }
}

variable "resource_group_name" {
  description = "The resource group name where the network security group will be created"
  type        = string
}

variable "location" {
  description = "The location of the network security group"
  type        = string
}

# Inbound Security Rules
variable "inbound_rules" {
  description = "A set of inbound security rules to be applied to the network security group"
  type = set(object({
    name                                       = string
    override_standard_naming                   = optional(bool, false)
    description                                = string
    access                                     = string
    priority                                   = number
    protocol                                   = string
    source_address_prefix                      = optional(string)
    source_address_prefixes                    = optional(set(string))
    source_application_security_group_ids      = optional(set(string))
    source_port_range                          = optional(string)
    source_port_ranges                         = optional(set(string))
    destination_address_prefix                 = optional(string)
    destination_address_prefixes               = optional(set(string))
    destination_application_security_group_ids = optional(set(string))
    destination_port_range                     = optional(string)
    destination_port_ranges                    = optional(set(string))
  }))
  default = []
  validation {
    condition     = alltrue([for rule in var.inbound_rules : contains(["Allow", "Deny"], rule.access)])
    error_message = "Each inbound rule 'access' must be 'Allow' or 'Deny'."
  }
  validation {
    condition     = alltrue([for rule in var.inbound_rules : contains(["Tcp", "Udp", "Icmp", "*"], rule.protocol)])
    error_message = "Each inbound rule 'protocol' must be 'Tcp', 'Udp', 'Icmp', or '*'."
  }
  validation {
    condition     = alltrue([for rule in var.inbound_rules : rule.priority >= 100 && rule.priority <= 4096])
    error_message = "Each inbound rule 'priority' must be between 100 and 4096."
  }
  validation {
    condition     = length(var.inbound_rules) == length(distinct([for rule in var.inbound_rules : rule.priority]))
    error_message = "Each inbound rule must have a unique priority."
  }
}

# Outbound Security Rules
variable "outbound_rules" {
  description = "A set of outbound security rules to be applied to the network security group"
  type = set(object({
    name                                       = string
    override_standard_naming                   = optional(bool, false)
    description                                = string
    access                                     = string
    priority                                   = number
    protocol                                   = string
    source_address_prefix                      = optional(string)
    source_address_prefixes                    = optional(set(string))
    source_application_security_group_ids      = optional(set(string))
    source_port_range                          = optional(string)
    source_port_ranges                         = optional(set(string))
    destination_address_prefix                 = optional(string)
    destination_address_prefixes               = optional(set(string))
    destination_application_security_group_ids = optional(set(string))
    destination_port_range                     = optional(string)
    destination_port_ranges                    = optional(set(string))
  }))
  default = []
  validation {
    condition     = alltrue([for rule in var.outbound_rules : contains(["Allow", "Deny"], rule.access)])
    error_message = "Each outbound rule 'access' must be 'Allow' or 'Deny'."
  }
  validation {
    condition     = alltrue([for rule in var.outbound_rules : contains(["Tcp", "Udp", "Icmp", "*"], rule.protocol)])
    error_message = "Each outbound rule 'protocol' must be 'Tcp', 'Udp', 'Icmp', or '*'."
  }
  validation {
    condition     = alltrue([for rule in var.outbound_rules : rule.priority >= 100 && rule.priority <= 4096])
    error_message = "Each outbound rule 'priority' must be between 100 and 4096."
  }
  validation {
    condition     = length(var.outbound_rules) == length(distinct([for rule in var.outbound_rules : rule.priority]))
    error_message = "Each outbound rule must have a unique priority."
  }
}

# Tags
variable "tags" {
  description = "A map of tags to be associated to all resources"
  type        = map(string)
  default     = {}
}
