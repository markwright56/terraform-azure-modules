### Load resource group and all curent resources deployed ###
data "azurerm_resource_group" "project_rg" {
  name = var.resource_group_name
}

data "azurerm_resources" "project_resources" {
  resource_group_name = data.azurerm_resource_group.project_rg.name
}

### Apply lock to resources based on tag status ###
resource "azurerm_management_lock" "lock" {
  for_each = {
    for resource in data.azurerm_resources.project_resources.resources :
    resource.id => resource if resource.tags != null && lookup(resource.tags, var.tag_name, null) == var.tag_value && !(lookup(resource.tags, "exclude_lock", false))
  }

  name       = "terraform-lock"
  scope      = each.value.id
  lock_level = var.lock_level
  notes      = "This resource is managed by Terraform. Do not modify or delete from the Azure portal."
}