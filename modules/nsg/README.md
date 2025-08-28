# Module 'nsg'

Terraform module for creating NSG (Network Security Group) and associated Inbound and Outbound network rules.

## Inputs

### Required

|Name                    |Description                                                |Type       |
|------------------------|-----------------------------------------------------------|-----------|
|resource_group_name     |Name of Resource Group where the new NSG should be created.|string     |
|location                |The Azure Region in which the new NSG should be created.   |string     |
|nsg_name                |The name of the network security group.                    |string     |

### Optional

|Name                    |Description                                          |Type               |Default         |
|------------------------|-----------------------------------------------------|-------------------|----------------|
|inbound_rules           |Object list of inbound_rules (see below).            |set(object({}))    |[]              |
|outbound_rules          |Object list of outbound_rules (see below).           |set(object({}))    |[]              |
|tags                    |Tags to set on the resources.                        |map(string)        |{}              |

### Inbound and Outbound rule objects

Optional lists of inbound and outbound rules to apply to the NSG.
NOTE: the name of the network rule will be standardised to contain the 3 elements `access` `name` `direction` e.g. 'AllowSQLInbound'. To create a custom rule name set the `override_standard_naming` variable to `true` and pass the full name required.

#### Required

|Name           |Description                                                                            |Type       |
|---------------|---------------------------------------------------------------------------------------|-----------|
|name           |Rule name (see note above about naming standardisation).                               |string     |
|description    |A description for this rule.                                                           |string     |
|access         |Alow or deny traffic. Values are `Allow` or `Deny`.                                    |string     |
|priority       |Defines the order of the rules. Each rule must have unique value between 100 and 4096. |number     |
|protocol       |Network protocol this rule applies to. Values are `Tcp`, `Udp`, `Icmp`, or `*`.        |string     |

#### Optional

|Name                                       |Description                                                |Type        |Default   |
|-------------------------------------------|-----------------------------------------------------------|------------|----------|
|override_standard_naming                   |Boolean to control if custom name should be applied.       |bool        |false     |
|source_address_prefix                      |CIDR or source IP range or `*` to match any IP. Tags such as `VirtualNetwork`, `AzureLoadBalancer` and `Internet` can also be used.|string      |See note  |
|source_address_prefixes                    |List of source address prefixes. Tags may not be used.     |set(string) |null      |
|source_application_security_group_ids      |A List of source Application Security Group IDs.           |set(string) |null      |
|source_port_range                          |Source Port or Range. Integer or range between `0` and `65535`.|string      |See note  |
|source_port_ranges                         |List of source ports or port ranges.                       |set(string) |null      |
|destination_address_prefix                 |CIDR or destination IP range or `*` to match any IP. Tags such as `VirtualNetwork`, `AzureLoadBalancer` and `Internet` can also be used.|string      |See note  |
|destination_address_prefixes               |List of destination address prefixes. Tags may not be used.|set(string) |null      |
|destination_application_security_group_ids |A List of destination Application Security Group IDs.      |set(string) |null      |
|destination_port_range                     |Destination Port or Range. Integer or range between `0` and `65535`.|string      |See note  |
|destination_port_ranges                    |List of destination ports or port ranges.                  |set(string) |null      |

Note: Where single or list options are available, one or other can be entered but not both.  If neither are entered the `*` match all option will be used as default.

Format

```hcl
  inbound_rules = [
    {
      # RDP
      name                   = "RDP"
      description            = "Allow Remote Desktop Protocol (RDP) inbound connectivity"
      access                 = "Allow"
      priority               = 110
      protocol               = "Tcp"
      source_address_prefix  = "10.0.0.0/8"
      destination_port_range = "3389"
    },
    {
      # Deny all other inbound traffic
      name        = "All"
      description = "Block all other inbound traffic"
      access      = "Deny"
      priority    = 4000
      protocol    = "*"
    }
  ]
```

## Outputs

|Name               |Description                           |
|-------------------|--------------------------------------|
|nsg_id             |The network security group id.        |
|nsg_name           |The network security group name.      |

## Example Usage

*terraform.tfvars:*

```hcl
resource_group_name      = "rg-just-testing-deleteme"
location                 = "UKSouth"
nsg_name                 = "nsg-just-testing-deleteme"

... (other variables)

common_tags = {
  ApplicationName        = "Name of application"           # Application associated with VM
  ConfigurationManagedBy = "Terraform"                     # Indicate Terraform managed resource
  TerraformRepo          = "Name of repository"            # Name of repository managing resource
  ... (list of common tags)
}
```

*variables.tf:*

```hcl
variable "resource_group_name" {
  description = "Name of the resource group."
  type        = string
}

variable "location" {
  description = "The Azure Region in which all resources should be created."
  type        = string
}

variable "nsg_name" {
  description = "The name of the network security group"
  type        = string
}

... (other variables)

variable "common_tags" {
  description = "Tags to set on the resources."
  type        = map(string)
  default     = {}
}
```

In your main Terraform configuration (e.g., `main.tf`), add the following block specifying the source version and the variables required to define the nsg and rules:

*main.tf:*

```hcl
# test resource group
resource "azurerm_resource_group" "test" {
  name     = var.resource_group_name
  location = var.location

  tags = merge(var.common_tags, {
    #AdditionalTagNameHere = "tag value here"
  })
}

# test nsg and rules #
## Create network security group with inbound and outbound rules
module "nsg_test" {
  source = "git::https://github.com/markwright56/terraform-azure-modules.git//modules/nsg?ref=v1.0.5"

  nsg_name            = var.nsg_name
  resource_group_name = azurerm_resource_group.test.name
  location            = var.location
  
  tags = merge(var.common_tags, {
    #AdditionalTagNameHere = "tag value here"
  })

  inbound_rules = [
    {
      # RDP
      name                   = "RDP"
      description            = "Allow Remote Desktop Protocol (RDP) inbound connectivity"
      access                 = "Allow"
      priority               = 110
      protocol               = "Tcp"
      source_address_prefix  = "10.0.0.0/8"
      destination_port_range = "3389"
    },
    {
      # Deny all other inbound traffic
      name        = "All"
      description = "Block all other inbound traffic"
      access      = "Deny"
      priority    = 4000
      protocol    = "*"
    }
  ]

  outbound_rules = [
    {
      # Web Traffic
      name                    = "WebTraffic"
      description             = "Allow outbound web traffic to the internet"
      access                  = "Allow"
      priority                = 100
      protocol                = "Tcp"
      destination_port_ranges = ["80", "443"]
    },
    {
      # Deny all other outbound traffic
      name        = "All"
      description = "Block all other outbound traffic"
      access      = "Deny"
      priority    = 4000
      protocol    = "*"
    }
  ]
}

```
