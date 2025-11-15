module "vm_cc" {
  count = var.deploy_vm_cc ? 1 : 0

  source  = "Azure/avm-res-compute-virtualmachine/azurerm"
  version = "~> 0.20.0"

  name                = local.resource_names["vm_cyclecloud_orchestrator"]
  resource_group_name = azurerm_resource_group.cyclecloud_orchestrator.name
  location            = azurerm_resource_group.cyclecloud_orchestrator.location

  tags = var.tags

  account_credentials = {
    admin_credentials = {
      username                           = "srvadmin"
      ssh_keys                           = [tls_private_key.vm_cc.public_key_openssh]
      generate_admin_password_or_ssh_key = false
    }
  }

  os_type                    = "Linux"
  sku_size                   = "Standard_D4as_v6"
  zone                       = null
  encryption_at_host_enabled = false

  extensions = {}

  source_image_reference = {
    publisher = "almalinux"
    offer     = "almalinux-x86_64"
    sku       = "8-gen2"
    version   = "8.10.2025090501"
  }

  os_disk = {
    name                 = "OSDisk"
    create_option        = "FromImage"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }


  data_disk_managed_disks = {
    disk1 = {
      name = "disk-${local.resource_names["vm_cyclecloud_orchestrator"]}-lun0"
      # create_option        = "FromImage"
      storage_account_type = "Premium_LRS"
      disk_size_gb         = 512
      lun                  = 0
      caching              = "None"
    }
  }

  managed_identities = {
    system_assigned = true
  }

  network_interfaces = {
    network_interface_1 = {
      // TODO: Use naming module
      name = "nic-${local.resource_names["vm_cyclecloud_orchestrator"]}-01"
      ip_configurations = {
        ip_configuration_1 = {
          name                          = "ipconfig1"
          private_ip_subnet_resource_id = module.virtualnetwork.subnets[local.subnet_names.cyclecloud].resource_id
          private_ip_address_allocation = "Static"
          private_ip_address            = cidrhost(module.virtualnetwork.subnets[local.subnet_names.cyclecloud].resource.body.properties.addressPrefixes[0], 4)
        }
      }
    }
  }

  role_assignments_system_managed_identity = {
    role_assignment_1 = {
      scope_resource_id          = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
      role_definition_id_or_name = azurerm_role_definition.cyclecloud_orchestrator.role_definition_resource_id
      description                = "Assign the Cycle Cloud Orchestrator to this VM"
      principal_type             = "ServicePrincipal"
    }
    role_assignment_2 = {
      scope_resource_id          = module.storage.resource_id
      role_definition_id_or_name = "Storage Blob Data Contributor"
      description                = "Assign Blob Storage Contributor to this VM over CycleCloud locker"
      principal_type             = "ServicePrincipal"
    }
  }

  enable_telemetry = var.telemetry_enabled

  depends_on = []
}
output "vm_cc_resourceid" {
  value = module.vm_cc[0].resource_id
}

output "vm_cc_managedid" {
  value = module.vm_cc[0].system_assigned_mi_principal_id
}