# CHANGELOG

This file tracks each version tag to record the additions and changes made.

Using this file will indicate which version to include on the source reference element.

## v1.0.8 - 2026-01-20

Update storage-account module.

Add more variables and configuration properties such as share_properties and custom_domain.

## v1.0.7 - 2025-12-18

Update storage-account module.  Add access_tier variable to both account and file shares.

Change blob and file share variable definitions to specific map objects rather than map(any).

## v1.0.6 - 2025-10-31

Update nsg module to make inbound and outbound rule variable map objects rather than set.  This allows for merging of common and custom rules in the source repository.

## v1.0.5 - 2025-08-28

Add nsg module.

## v1.0.4 - 2025-08-22

Add key-vault module.

## v1.0.3 - 2025-08-22

Update storage-account module variable validation and readme file.

## v1.0.1 - 2025-07-29

Add storage-account module.

## v1.0.0 - 2025-07-21

Initial commit to include azure-locks module.
