resource "azurerm_role_assignment" "storage_account_contributor" {
  scope                            = module.storage.resource_id
  role_definition_name             = "Storage Account Contributor"
  principal_id                     = data.azurerm_client_config.current.object_id
  skip_service_principal_aad_check = false
}

module "storage" {
  source = "Azure/avm-res-storage-storageaccount/azurerm"
  version = "~> 0.5.0"

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
      name                  = "cyclecloud"
      container_access_type = "private"
    }
  }

  network_rules = {
    bypass         = ["AzureServices"]
    default_action = "Deny"
    ip_rules       = [data.http.runner_ip[0].response_body]
    virtual_network_subnet_ids = [
      module.virtualnetwork.subnets[local.subnet_names.cyclecloud].resource_id,
      module.virtualnetwork.subnets[local.subnet_names.compute].resource_id
    ]
  }

  enable_telemetry = var.telemetry_enabled
}