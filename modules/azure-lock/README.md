# Module 'azure-lock'

Terraform module for adding edit or read-only locks to ALL resources within a named Resource Group.

The module defaults are to target all resources within a named resource group with the Tag and value `ConfigurationManagedBy=Terraform` and apply a `ReadOnly` lock.

To add new resources and apply the lock you may need to run `terraform apply` twice to ensure the lock is applied to the new resources.

To make changes to resources with locks applied, you will need to remove the lock first by changing the below `apply_locks` variable to `false` and run `terraform apply`.

To remove resource locks set the `apply_locks` variable to `false` and run `terraform apply`. It may error, but the locks will be removed. This is just an Azure quirk.

## Example Usage

*terraform.tfvars:*

```hcl
resource_group_name = "rg-just-testing-deleteme"

apply_locks = true # or false. If false, locks will be removed. If you need to make changes to resources with locks applied, you will need to remove the lock first by changing this variable to false and run terraform apply. After making your changes, set this variable back to true and run terraform apply to reapply the locks.
```

*variables.tf:*

```hcl
variable "resource_group_name" {
  description = "Name of the resource group "
  type        = string
  default     = ""
}

variable "apply_locks" {
  description = "Whether to apply resource locks"
  type        = bool
  default     = true
}
```

In your main Terraform configuration (e.g., `main.tf`), add the following block specifying the version and lock_level you would like to use:

*main.tf:*

```hcl
module "apply_locks" {
  count               = var.apply_locks ? 1 : 0
  source              = "git::https://github.com/markwright56/terraform-azure-modules.git//modules/azure-lock?ref=v1.0.0"
  resource_group_name = var.resource_group_name
  tag_name            = "ConfigurationManagedBy"
  tag_value           = "Terraform"
  lock_level          = "ReadOnly"  # or "CanNotDelete"
}

# test resource group
resource "azurerm_resource_group" "test" {
  name     = "rg-just-testing-deleteme"
  location = "UKsouth"
  tags = {
    ConfigurationManagedBy = "Terraform"
  }
}

# Simple test resource including lock
resource "azurerm_network_security_group" "test_with_lock" {
  name                = "test-nsg-deleteme"
  location            = azurerm_resource_group.test.location
  resource_group_name = azurerm_resource_group.test.name
  tags = {
    ConfigurationManagedBy = "Terraform"  # This tag is used to target the resource for application of the lock
  }
}

# Simple test resource excluding lock
resource "azurerm_network_security_group" "test_no_lock" {
  name                = "test-nsg-deleteme"
  location            = azurerm_resource_group.test.location
  resource_group_name = azurerm_resource_group.test.name
  tags = {
    ConfigurationManagedBy = "Terraform",
    exclude_lock = true  # This tag will exclude the resource from having a lock applied
  }
}
```
