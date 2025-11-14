resource "random_string" "unique_name" {
  length  = 3
  special = false
  upper   = false
  numeric = false
}

data "azurerm_client_config" "current" {}

locals {
  user_principals    = [data.azurerm_client_config.current.object_id]
  managed_identities = var.system_assigned_managed_id == "" ? [] : [var.system_assigned_managed_id]
  any_principals     = toset(concat(local.user_principals, local.managed_identities))
}


resource "azurerm_role_assignment" "storage_account_contributor" {
  for_each                         = local.user_principals
  scope                            = module.storage.resource_id
  role_definition_name             = "Storage Account Contributor"
  principal_id                     = each.key
  skip_service_principal_aad_check = false
}

resource "azurerm_role_assignment" "storage_blob_data_contributor" {
  for_each                         = local.any_principals
  scope                            = module.storage.containers["tfstate"].id
  role_definition_name             = "Storage Blob Data Contributor"
  principal_id                     = each.key
  skip_service_principal_aad_check = false
}

module "storage" {
  source = "Azure/avm-res-storage-storageaccount/azurerm"

  name                = local.resource_names["storage_account_cyclecloud_locker"]
  location            = azurerm_resource_group.support.location
  resource_group_name = azurerm_resource_group.support.name

  account_replication_type          = "LRS"
  default_to_oauth_authentication   = true
  infrastructure_encryption_enabled = true
  shared_access_key_enabled         = true
  public_network_access_enabled     = true

  containers = {
    locker = {
      name                  = "locker"
      container_access_type = "private"
    }
  }

  network_rules = {
    bypass         = ["AzureServices"]
    default_action = "Deny"
    ip_rules       = [data.http.runner_ip.response_body]
    virtual_network_subnet_ids = [
        
    ]
  }

  enable_telemetry = var.telemetry_enabled
}