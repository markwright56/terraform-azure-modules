# Terraform Azure Modules

This repository contains shared modules that can be referenced by other terraform deployment repositories.

## Application Overview

Collection of standard modules for use in terraform deployment repositories.

By creating a single core repository of shared modules, future updates and developments can more easily be circulated.

Use of commit tags both when updating this repository and when referencing the modules ensures updates will not cause unexpected and possibly breaking changes.

### Modules included

* Azure Lock

### Module updates

All updates to the module repository should be made via pull request in to the main branch.  This ensures changes are reviewed before being merged.

When pull requests are merged, the github workflow 'tag-merge' is triggered to add a new tag to the commit by incrementing the patch element of the current tag.  In this way all new commits to the main branch are tracked and ensures new updates do not cause unexpected results for existing repositories using the modules.

Tags can also be manually added using the git commands below:

```bash
# Add a tag using the git tag command
git tag -a v1.1.0 // the standard nomenclature should be used 

# You can also include a description as part of the tag
git tag -a v1.1.0 -m "update to compute module"

# Tags by default are not included in standard push operations so to deploy to GitHub include the following
git push origin --tags

```

### Example usage

Specific information is contained in the Readme files for each module.

To use a module in a parent repository the source element should be included.

```hcl
# Sample module entry
module "apply_locks" {
  source = "git::https://github.com/markwright56/terraform-azure-modules.git//modules/azure-lock?ref=v1.0.0"
  ...
}
```

The format of the source url is defined in 3 parts:

1. The root url for this repository (always)
   * `git::https://github.com/markwright56/terraform-azure-modules.git`
2. The sub-folder for the module required (e.g.)
   * `//modules/azure-lock`
3. The tag reference for the version (e.g.)
   * `?ref=v1.0.0`

## Directory Structure

Each module is contained within it's own sub folder under the `modules` parent folder.  The sub-folder is then referenced directly from the parent repository.

```bash
.
|-- modules                   # Modules parent folder
|   |-- azure-lock            # Azure lock module sub folder
|   |   |-- main.tf           # Main configuration file for azure lock module
|   |   |-- README.md         # README file for azure lock module
|   |   |-- variables.tf      # Input variables file for azure lock module
|-- .gitignore                # Git ignore file
|-- CHANGELOG.md              # Changelog file
|-- README.md                 # This file

```
