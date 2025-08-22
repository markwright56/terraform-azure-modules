# Module 'key-vault'

Terraform module for creating a key vault.

Allows for creating of access policies and diagnostic settings.

To be added:

- RBAC role assignments
- Key generation
- Secret generation

For added sucurity when using key vaults the following provider block is recommended before calling this module.

```hcl
provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
  }
}
```

## Inputs

### Required

|Name                    |Description                                               |Type       |
|------------------------|----------------------------------------------------------|-----------|
|resource_group_name     |Name of Resource Group where the new VM should be created.|string     |
|location                |The Azure Region in which all resources should be created.|string     |
|key_vault_name          |The name of the storage account name (ex: storageaccount).|string     |

### Optional

|Name                          |Description                                                                                 |Type                  |Default         |
|------------------------------|--------------------------------------------------------------------------------------------|----------------------|----------------|
|tenant_id                     |The Azure tenant id used with the key vault. If not supplied will use the `azurerm_client_config` data source.        |string           |""      |
|sku_name                      |The SKU name of the Key Vault. Possible values are 'standard' and 'premium'.                |string                |"standard"      |
|soft_delete_retention_days    |The number of days that deleted key vaults are retained.                                    |number                |7               |
|public_network_access_enabled |Is public network access enabled for this Key Vault?                                        |bool                  |true            |
|purge_protection_enabled      |Is purge protection enabled for this Key Vault?                                             |bool                  |true            |
|enable_rbac_authorization     |Enable RBAC authorization for the Key Vault. If true, access policies will be ignored.      |bool                  |false           |
|access_policies               |A map of access policies to be applied to the Key Vault.                                    |map(object)(see below)|null            |
|diagnostic_settings           |A map of diagnostic settings to be created for the Key Vault.                               |map(object)(see below)|null            |
|network_rules                 |Configure network rules for storage account                                                 |object(see below)     |null            |
|tags                          |Tags to set on the resources.                                                               |map(string)           |{}              |

### Access policies

Optional map of objects to define access policies for the key vault.

If variable `enable_rbac_authorization` is set to true then these access policies will be ignored.

Requires `object_id` of a user, service principla or security group to grant access.

Optional `application_id` of an application in azure active directory.

Permissions are defined as lists within the permissions object.

- `certificates`
- `keys`
- `secrets`
- `storage`

Format example.

```hcl
  access_policies = {
    platform_access = {
      object_id          = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" # GUID of platform object on entra
      permissions = {
        keys    = ["Get", "WrapKey", "UnwrapKey"]
        secrets = ["Get", "List", "Set"]
      }
    }
  }
```

### Diagnostic settings

Defines the diagnostic settings to be tracked by Azure.

Requires one option from `event_hub_resource_id`, `log_analytics_workspace_id` or `storage_account_id` to be defined.

If `name` is not defined then the default value of `diag-{key_vault_name}` will be used on all settings.

If no explicit log or metric options are selected then `AllLogs` and `AllMetrics` will be added.

Format example to record all logs and metrics to a log analytics workspace.

```hcl
  diagnostic_settings = {
    diagnostics = {
      log_analytics_workspace_id = var.log_analytics_id
    }
  }
```

### Network rules

Optional object to configure network rules on the key vault.

The first value in the object is the `enable_network_rules` variable which defaults to `false`.  In this way if no variable is set then this feature will not be enabled.
If `enable_network_rules` is set to true then the rules will be applied with the default values unless otherwise defined.

Format example with default values shown.

```hcl
  network_rules = {
    enable_network_rules       = true
    default_action             = "Deny"            # Options: Deny, Allow
    bypass                     = ["AzureServices"] # Options: None, AzureServices, Logging, Metrics
    ip_rules                   = []                # List of public IPv4 IP addresses or IP ranges in CIDR format to allow access.
    virtual_network_subnet_ids = []                # List of virtual network subnet ids to allow access.
  }
```

## Outputs

|Name                         |Description                                         |
|-----------------------------|----------------------------------------------------|
|key_vault_name               |The name of the key vault created.                  |
|key_vault_id                 |The ID of the key vault created.                    |

## Example Usage

*terraform.tfvars:*

```hcl
resource_group_name      = "rg-just-testing-deleteme"
location                 = "UKSouth"
key_vault_name           = "kvtesting"

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

variable "key_vault_name" {
  description = "The name of the key vault"
  type        = string
}

... (other variables)

variable "common_tags" {
  description = "Tags to set on the resources."
  type        = map(string)
  default     = {}
}
```

In your main Terraform configuration (e.g., `main.tf`), add the following block specifying the source version and the variables required to define the storage account:

*main.tf:*

```hcl
# define key vault feature settings
provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
  }
}

# test resource group
resource "azurerm_resource_group" "test" {
  name     = var.resource_group_name
  location = var.location

  tags = merge(var.common_tags, {
    #AdditionalTagNameHere = "tag value here"
  })
}

# add log analytics
resource "azurerm_log_analytics_workspace" "test" {
  name                = "LogAnalytics-${var.resource_group_name}"
  resource_group_name = azurerm_resource_group.test.name
  location            = var.location

  tags = merge(var.common_tags, {
    #AdditionalTagNameHere = "tag value here"
  })
}

# test key vault #
## create standard key vault with single user access to secrets and full diagnostics
module "test_key_vault" {
  source = "git::https://github.com/markwright56/terraform-azure-modules.git//modules/key-vault?ref=v1.0.4"

  key_vault_name             = var.key_vault_name
  resource_group_name        = azurerm_resource_group.test.name
  location                   = var.location
  soft_delete_retention_days = 30

  access_policies = {
    platform_access = {
      object_id          = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" # GUID of platform object on entra
      permissions = {
        secrets = ["Get", "List", "Set", "Delete", "Purge"]
      }
    }
  }

  diagnostic_settings = {
    diagnostics = {
      log_analytics_workspace_id = azurerm_log_analytics_workspace.test.id
    }
  }
  
  tags = merge(var.common_tags, {
    #AdditionalTagNameHere = "tag value here"
  })
}

```
