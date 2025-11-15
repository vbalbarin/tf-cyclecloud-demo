module "umi_locker" {
  source  = "Azure/avm-res-managedidentity-userassignedidentity/azurerm"
  version = "0.3.4"

  name                = local.resource_names["userassigned_managed_identity_locker"]
  location            = azurerm_resource_group.support.location
  resource_group_name = azurerm_resource_group.support.name

  enable_telemetry = var.telemetry_enabled

  tags = var.tags
}

output "userassigned_managed_identity_locker_resourceid" {
  value = module.umi_locker.resource.id
}

resource "azurerm_role_assignment" "storage_blob_data_reader" {
  scope                            = module.storage.resource_id
  role_definition_name             = "Storage Blob Data Reader"
  principal_id                     = module.umi_locker.principal_id
  skip_service_principal_aad_check = false
}