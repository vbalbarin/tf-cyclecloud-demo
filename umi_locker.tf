module "avm-res-managedidentity-userassignedidentity" {
  source  = "Azure/avm-res-managedidentity-userassignedidentity/azurerm"
  version = "0.3.4"

  name                = local.resource_names["userassigned_managed_identity_locker"]
  location            = azurerm_resource_group.support.location
  resource_group_name = azurerm_resource_group.support.name

  enable_telemetry = var.telemetry_enabled

  tags = var.tags
}

output "userassigned_managed_identity_locker_resourceid" {
  value = module.avm-res-managedidentity-userassignedidentity.resource.id
}