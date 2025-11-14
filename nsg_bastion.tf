locals {
  // TODO: Consider generating from a custom map with only the source, port, and protocol
  nsg_rules_bastion_subnet = {
    # Inbound base_bastion_nsg_rules [310, 400)

    "AllowBastionControlPlaneIn" = {
      name                       = "AllowBastionControlPlaneIn"
      priority                   = 310
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      destination_port_ranges    = local.service_ports["https"]
      source_address_prefix      = "GatewayManager"
      destination_address_prefix = "*"
      source_port_range          = "*"
    }
    "AllowBastionDataPlaneIn" = {
      name                       = "AllowBastionDataPlaneIn"
      priority                   = 320
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      destination_port_ranges    = local.service_ports["bastion"]
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "VirtualNetwork"
      source_port_range          = "*"
    }
    "AllowAzureLoadBalancerBastionIn" = {
      name                       = "AllowAzureLoadBalancerBastionIn"
      priority                   = 330
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      destination_port_ranges    = local.service_ports["https"]
      source_address_prefix      = "AzureLoadBalancer"
      destination_address_prefix = "*"
      source_port_range          = "*"
    }

    # Outbound base_bastion_nsg_rules [310, 400)
    "AllowSshRdpBastionTgtVmOut" = {
      name                       = "AllowSshRdpBastionTgtVmOut"
      priority                   = 310
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "*"
      destination_port_ranges    = local.service_ports["ssh_rdp"]
      source_address_prefix      = "*"
      destination_address_prefix = "VirtualNetwork"
      source_port_range          = "*"
    }

    "AllowBastionDataPlaneOut" = {
      name                       = "AllowBastionDataPlaneOut"
      priority                   = 320
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "*"
      destination_port_ranges    = local.service_ports["bastion"]
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "VirtualNetwork"
      source_port_range          = "*"
    }

    "AllowBastionAzureCloudOut" = {
      name                       = "AllowBastionAzureCloudOut"
      priority                   = 330
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      destination_port_ranges    = local.service_ports["https"]
      source_address_prefix      = "*"
      destination_address_prefix = "AzureCloud"
      source_port_range          = "*"
    }

    "AllowBastionInternetOut" = {
      name                       = "AllowBastionInternetOut"
      priority                   = 340
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "*"
      destination_port_ranges    = local.service_ports["http"]
      source_address_prefix      = "*"
      destination_address_prefix = "Internet"
      source_port_range          = "*"
    }
  }
}

# This is the module call
module "nsg_domain_controller_subnet" {
  source  = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version = "~> 0.5.0"

  name                = local.resource_names["network_security_group_bastion"]
  resource_group_name = azurerm_resource_group.network.name
  location            = azurerm_resource_group.network.location

  tags = var.tags

  security_rules = local.nsg_rules_bastion_subnet

  enable_telemetry = var.telemetry_enabled
}
