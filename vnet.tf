locals {
  subnet_names = {
    netapp       = "NetappSubnet"
    amlfs        = "AzureManagedLustreSubnet"
    slurmdb      = "SlurmDbSubnet"
    cyclecloud   = "CycleCloudSubnet"
    compute      = "ComputeSubnet"
    azurebastion = "AzureBastionSubnet"
    placeholder  = null # Setting the subnet name to null value will skip assignment of CIDR
  }
}

module "subnet_addrs" {
  source  = "hashicorp/subnets/cidr"
  version = "~> 1.0.0"

  base_cidr_block = local.conf_network_resources.vnet_address_space
  networks = [
    {
      name     = local.subnet_names.compute
      new_bits = 1
    },
    {
      name     = local.subnet_names.amlfs
      new_bits = 2
    },
    {
      name     = local.subnet_names.cyclecloud
      new_bits = 7
    },
    {
      name     = local.subnet_names.netapp
      new_bits = 4
    },
    {
      name     = local.subnet_names.slurmdb
      new_bits = 4
    },
    {
      name     = local.subnet_names.azurebastion
      new_bits = 4
    },
  ]
}

module "virtualnetwork" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "~> 0.10.0"

  // DO NOT SET DNS IPs HERE

  name                = local.resource_names["virtual_network"]
  resource_group_name = azurerm_resource_group.network.name
  location            = azurerm_resource_group.network.location

  address_space = [local.conf_network_resources.vnet_address_space, ]

  subnets = {
    "${local.subnet_names.compute}" = {
      name             = local.subnet_names.compute
      address_prefixes = [module.subnet_addrs.network_cidr_blocks[local.subnet_names.compute]]
      nat_gateway = var.deploy_natgw ? {
        id = module.nat_gateway[0].resource_id
      } : {}
      # route_table = var.deploy_firewall ? {
      #   id = module.rt[0].resource_id
      # } : {}
      # network_security_group = {
      # }
    }
    "${local.subnet_names.amlfs}" = {
      name             = local.subnet_names.amlfs
      address_prefixes = [module.subnet_addrs.network_cidr_blocks[local.subnet_names.amlfs]]
      # network_security_group = {
      # }
    }
    "${local.subnet_names.cyclecloud}" = {
      name             = local.subnet_names.cyclecloud
      address_prefixes = [module.subnet_addrs.network_cidr_blocks[local.subnet_names.cyclecloud]]
      nat_gateway = var.deploy_natgw ? {
        id = module.nat_gateway[0].resource_id
      } : {}
      # route_table = var.deploy_firewall ? {
      #   id = module.rt[0].resource_id
      # } : {}
      # network_security_group = {
      # }
    }
    "${local.subnet_names.netapp}" = {
      name             = local.subnet_names.netapp
      address_prefixes = [module.subnet_addrs.network_cidr_blocks[local.subnet_names.netapp]]
      # network_security_group = {
      #   id = module.nsg_domain_controller.resource.id
      # }
      delegation = [{
        name = "Microsoft.Netapp.volumes"
        service_delegation = {
          name = "Microsoft.Netapp/volumes"
        }
      }]
    }
    "${local.subnet_names.slurmdb}" = {
      name             = local.subnet_names.slurmdb
      address_prefixes = [module.subnet_addrs.network_cidr_blocks[local.subnet_names.slurmdb]]
      delegation = [{
        name = "Microsoft.DBforMySQL.flexibleServers"
        service_delegation = {
          name = "Microsoft.DBforMySQL/flexibleServers"
        }
      }]
      # route_table = var.deploy_firewall ? {
      #   id = module.rt[0].resource_id
      # } : {}
      # service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"]
    }
    "${local.subnet_names.azurebastion}" = {
      name             = local.subnet_names.azurebastion
      address_prefixes = [module.subnet_addrs.network_cidr_blocks[local.subnet_names.azurebastion]]
      # network_security_group = {
      # }
    }
  }

  enable_telemetry = var.telemetry_enabled

  tags = var.tags
}

# output "vnet_subnets" {
#   value = module.virtualnetwork.subnets
# }

# output "network_cidr_blocks" {
#   value = module.subnet_addrs.network_cidr_blocks
# }

# output "geo_codes" {
#   value = local.geo_codes_by_location
# }