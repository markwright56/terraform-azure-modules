# Module 'storage-account'

Terraform module for creating storage account.

By default public access will be granted unless the `network_rules.enable_network_rules` variable is set to true.  When this is true then public access is restricted and access can be limited to defined `ip_rules` and/or `virtual_network_subnet_ids`.  Access is allowed by default for other "AzureServices".

When connecting the storage account to a subnet, ensure the subnet has the Microsoft.Storage service endpoint enabled.
`service_endpoints    = ["Microsoft.Storage"]`

Optionally create blob containers, file shares and queues based upon variable maps provided.

## Inputs

### Required

|Name                    |Description                                               |Type       |
|------------------------|----------------------------------------------------------|-----------|
|resource_group_name     |Name of Resource Group where the new VM should be created.|string     |
|location                |The Azure Region in which all resources should be created.|string     |
|storage_account_name    |The name of the storage account name (ex: storageaccount).|string     |

### Optional

|Name                            |Description                                                                 |Type                  |Default         |
|--------------------------------|----------------------------------------------------------------------------|----------------------|----------------|
|account_kind                    |The account kind of the storage account (ex: StorageV2, BlobStorage)        |string                |"StorageV2"     |
|account_tier                    |The performance tier of the storage account (ex: Standard, Premium).        |string                |"Standard"      |
|account_replication_type        |The replication strategy of the storage account (ex: ZRS,RAGRS).            |string                |"LRS"           |
|cross_tenant_replication_enabled|Should cross Tenant replication be enabled?                                 |bool                  |false           |
|access_tier                     |The access tier of the storage account (ex: Hot, Cold).                     |string                |"Hot"           |
|https_traffic_only_enabled      |Is https traffic only enabled?                                              |bool                  |true            |
|min_tls_version                 |The minimum TLS version required for requests to the storage account        |string                |"TLS1_2"        |
|allow_nested_items_to_be_public |Allow or disallow nested items within this Account to opt into being public.|bool                  |false           |
|shared_access_key_enabled       |Whether the shared access key is enabled?                                   |bool                  |true            |
|public_network_access_enabled   |Whether the public network access is enabled?                               |bool                  |true            |
|default_to_oauth_authentication |Whether the default authentication method is OAuth                          |bool                  |false           |
|large_file_share_enabled        |Whether large file shares are enabled?                                      |bool                  |false           |
|custom_domain                   |The custom domain name to associate with the storage account                |object(see below)     |null            |
|managed_identity                |Configure managed identity access for storage account                       |object(see below)     |null            |
|blob_properties                 |Configure properties for the blob storage account                           |object(see below)     |null            |
|queue_properties                |Configure properties for the queue storage account                          |object(see below)     |null            |
|static_website                  |Static website configuration                                                |object(see below)     |null            |
|share_properties                |Configure properties for the file share                                     |object(see below)     |null            |
|network_rules                   |Configure network rules for storage account                                 |object(see below)     |null            |
|azure_files_authentication      |Configure active directory authentication for file stores                   |object(see below)     |null            |
|storage_blob_containers         |A map of storage blob containers to be created                              |map(object)(see below)|{}              |
|storage_file_shares             |A map of storage file shares to be created                                  |map(object)(see below)|{}              |
|storage_queues                  |A map of storage queues to be created                                       |map(object)(see below)|{}              |
|tags                            |A map of tags to be associated to all resources                             |map(string)           |{}              |

#### Custom Domain

Optional object to configure custom domain for the storage account.

Example usage.

```hcl
  custom_domain = {
    name = "storage.company.com"
    use_sub_domain = false
  }
```

#### Managed Identity

Optional object to configure managed identity access on the storage account.

Managed identity can be either `SystemAssigned`, `UserAssigned` or `SystemAssigned, UserAssigned`.

If `SystemAssigned` identity is required simply set the `system_assigned` value to `true`.
If `UserAssigned` identities are required then provide these ids as a list as the `user_assigned_identities` value.

Example usage.

```hcl
  managed_identity = {
    system_assigned          = true
    user_assigned_identities = []
  }
```

#### Blob Properties

Optional object to configure additional properties for blob container in the storage account.  If this object is omitted all the defaults will be used.

Format example.

```hcl
  blob_properties = {
    change_feed_enabled        = true # Enable or disable change feed - defaults to false.
    change_feed_retention_days = 7    # Number of days to retain change feed.  The possible values are between 1 and 146000 days.
    versioning_enabled         = true # Enable or disable versioning - defaults to false.
    container_delete_retention_policy = {
      enabled = true # Enable or disable container delete retention policy - defaults to false.
      days    = 7    # Number of days to retain deleted containers.  The possible values are between 1 and 365 days.
    }
    delete_retention_policy = {
      enabled          = true  # Enable or disable delete retention policy - defaults to false.
      days             = 7     # Number of days to retain deleted blobs.  The possible values are between 1 and 365 days.
      permanent_delete = false # Enable or disable permanent delete. See note below.
    }
    restore_policy = {
      enabled = true # Enable or disable restore policy - defaults to false.
      days    = 7    # Number of days to retain deleted blobs for restore.  The possible values are between 1 and 365 days.
    }
  }
  ```

Note: If a restore_policy is enabled, delete_retention_policy.permanent_delete must be false.

#### Queue Properties

Optional object to configure properties on the storage queues.  Consists of 3 objects for `logging`, `minute_metrics` and `hour_metrics`.

Example format.

```hcl
  queue_properties = {
    logging = {
      delete = true
      read = true
      write = true
      version = "1.0"
      retention_days = 30
    }
    minute_metrics = {
      enabled = true
      version = "1.0"
      retention_days = 15
      include_apis = false
    }
    hour_metrics = {
      enabled = true
      version = "1.0"
      retention_days = 15
      include_apis = false
    }
  }
```

#### Static Website

Optional object to configure static website.  If `enabled` is set to true then a blob container called `$web` will be created on the storage account.

Example usage.

```hcl
  static_website = {
    enabled = true
    index_document = "index.html"
    error_document = "404.html"
  }
```

#### Share Properties

Optional object to configure file share properties.  Currently only the deleted file retention days value is configurable.

Example usage.

```hcl
  share_properties = {
    retention_days = 30
  }
```

#### Network rules

Optional object to configure network rules on the storage account.

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

#### Azure Files Authentication

Optional object to configure active directory authentication on the files shares.

The first value in the object is the `use_authentication` variable which defaults to `false`.  In this way if no variable is set then this feature will not be enabled.
If `use_authentication` is set to `true` then this feature is enabled.  
To include defined active directory settings the variable `use_active_directory` within the `active-directory` object must also be set to `true`.  When set this will also use the default OC domain as shown.

Format example shows all options with default values.  

```hcl
  azure_files_authentication = {
    use_authentication             = true
    directory_type                 = "AADKERB" # Options: AADDS, AAD, AADKERB
    default_share_level_permission = "None" # Options: None, StorageFileDataSmbShareReader, StorageFileDataSmbShareContributor, StorageFileDataSmbShareElevatedContributor
    active_directory = {
      use_active_directory = true
      domain_name          = "mycomany.root.local"                  # The domain name for Azure Files authentication
      domain_guid          = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" # The GUID of the domain
      domain_sid           = " "                                    # The SID of the domain
      forest_name          = " "                                    # The forest name for Azure Files authentication
      netbios_domain_name  = " "                                    # The NetBIOS name of the domain
      storage_sid          = " "                                    # The storage SID for Azure Files authentication
    }
  }
```

If all the defaults are valid then the variable block only needs the following.

```hcl
  azure_files_authentication = {
    use_authentication = true
    active_directory = {
      use_active_directory = true
    }
  }
```

### Storage blob containers

Optional map of container names with associated access type.
Variable named `storage_blob_containers` with a set of key:value pairs for each container with

* name is the container name
* access type is one of - "private", "blob", "container".  Will default to "private".

Format

```hcl
  storage_blob_containers = {
    "stcontainername1" = {
      name        = lower("stcontainername1")
      access_type = "private"
    },
    "stcontainername2" = {
      name        = lower("stcontainername2")
      access_type = "private"
    }
  }
```

### Storage file shares

Optional map of file share names with associated quota.
Variable name `storage_file_shares` with a set of key:value pairs for each file share with

* name is the file share name
* quota as a number of GB
* access_tier as one of "Hot", "Cool" or "TransactionOptimized".  Will default to "Hot".

Format

```hcl
  storage_file_shares = {
    "filesharename1" = {
      name  = lower("filesharename1")
      quota = 512
    },
    "filesharename2" = {
      name  = lower("filesharename2")
      quota = 1024
    }
  }
```

### Storage queues

Optional list of queue names.
Variable name `storage_queues` with list of names to be associated with queues.

Format

```hcl
  storage_queues = [
    "queuename1",
    "queuename2"
  ]
```

## Outputs

|Name                         |Description                                               |
|-----------------------------|----------------------------------------------------------|
|storage_account_name         |The name of the storage account created.                  |
|storage_account_id           |The ID of the storage account created.                    |
|storage_account_access_key   |The primary access key of the storage account created.    |
|storage_blob_container_names |List of the names of the blob containers created.         |
|storage_file_share_names     |List of the names of the storage file shares.             |
|storage_queue_names          |List of the names of the storage queues.                  |
|storage_account_fqdn_map     |The fully qualified domain names (FQDN) for the storage account endpoints as a key:value map with the following keys.|
|                             |blob                                                      |
|                             |file                                                      |
|                             |queue                                                     |
|                             |table                                                     |
|                             |web                                                       |
|                             |dfs                                                       |

## Example Usage

*terraform.tfvars:*

```hcl
resource_group_name      = "rg-just-testing-deleteme"
location                 = "UKSouth"
storage_account_name     = "sttestingstorage"

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

variable "storage_account_name" {
  description = "The name of the storage account name (ex: storageaccount)"
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
# test resource group
resource "azurerm_resource_group" "test" {
  name     = var.resource_group_name
  location = var.location

  tags = merge(var.common_tags, {
    #AdditionalTagNameHere = "tag value here"
  })
}

# test subnet #
resource "azurerm_subnet" "test" {
  name                 = var.subnet_name
  resource_group_name  = data.azurerm_virtual_network.test.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.test.name
  address_prefixes     = var.subnet_prefixes
  service_endpoints    = ["Microsoft.Storage"]  ## Ensure this is included when connecting a stroage account to this subnet
}

# test storage account #
## Create storage account with default Standard, LRS.  Connected to a single subnet.
## Add a single blob storage container and single fileshare
module "test_storage_account" {
  source = "git::https://github.com/markwright56/terraform-azure-modules.git//modules/storage-account?ref=v1.0.7"

  storage_account_name       = var.storage_account_name
  resource_group_name        = azurerm_resource_group.test.name
  location                   = var.location
  network_rules              = {
    enable_network_rules       = true
    virtual_network_subnet_ids = [azurerm_subnet.test.id]
  }
  blob_storage_containers    = {
    "stcon-${var.storage_account_name}-1" = {
      name        = lower("stcon-${var.storage_account_name}-1")
      access_type = "private"
    }
  }
  storage_file_shares = {
    "fshare-${var.storage_account_name}-1" = {
      name  = lower("fshare-${var.storage_account_name}-1")
      quota = 100
      access_tier = "TransactionOptimized"
    }
  }
  
  tags = merge(var.common_tags, {
    #AdditionalTagNameHere = "tag value here"
  })
}

```
