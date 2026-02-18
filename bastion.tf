module "bastion_public_ip" {
  count = var.deploy_bastion ? 1 : 0

  source  = "Azure/avm-res-network-publicipaddress/azurerm"
  version = "~> 0.2.0"

  name                = local.resource_names["bastion_public_ip"]
  resource_group_name = azurerm_resource_group.network.name
  location            = azurerm_resource_group.network.location
  tags                = var.tags

  allocation_method = "Static"
  sku               = "Standard"

  zones = ["1", "2", "3"]

  enable_telemetry = var.telemetry_enabled
}

module "bastion" {
  # count = var.deploy_bastion ? 1 : 0

  source  = "Azure/avm-res-network-bastionhost/azurerm"
  version = "~> 0.9.0"

  name      = local.resource_names["bastion"]
  parent_id = azurerm_resource_group.network.id
  location  = azurerm_resource_group.network.location

  copy_paste_enabled     = true
  file_copy_enabled      = false
  sku                    = "Standard"
  ip_connect_enabled     = false
  shareable_link_enabled = false
  tunneling_enabled      = true
  kerberos_enabled       = false

  #scale_units            = 2

  ip_configuration = {
    name                 = "bastion-ipconfig"
    create_public_ip     = false
    subnet_id            = module.virtualnetwork.subnets[local.subnet_names.azurebastion].resource_id
    public_ip_address_id = module.bastion_public_ip[0].public_ip_id
  }

  tags = var.tags

  enable_telemetry = var.telemetry_enabled

  // To enable Kerberos, deploy Bastion AFTER setting custom DNS
  // https://learn.microsoft.com/en-us/azure/bastion/kerberos-authentication-portal
  // depends_on = [azurerm_virtual_network_dns_servers.vnet_dns]
}

output "bastion_resource_id" {
  value = module.bastion.resource_id
}