variable "workload_subscription_id" {
  type = string
}


variable "system_assigned_managed_id" {
  default     = ""
  type        = string
  description = "System assigned managed identity that will be given access to the Terraform state file. If empty, a user assigned managed identity will be created."
}

variable "location" {
  type        = string
  description = "The location/region where the resources will be created. Must be in the short form (e.g. 'uksouth')"
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.location))
    error_message = "The location must only contain lowercase letters, numbers, and hyphens"
  }
  validation {
    condition     = length(var.location) <= 20
    error_message = "The location must be 20 characters or less"
  }
}

variable "resource_name_location_short" {
  type        = string
  description = "The short name segment for the location. If left blank, this will be calculated using Azure/avm-utl-regions/azurerm."
  default     = ""
  validation {
    condition     = length(var.resource_name_location_short) == 0 || can(regex("^[a-z]+$", var.resource_name_location_short))
    error_message = "The short name segment for the location must only contain lowercase letters"
  }
  validation {
    condition     = length(var.resource_name_location_short) <= 3
    error_message = "The short name segment for the location must be 3 characters or less"
  }
}

variable "resource_name_workload" {
  type        = string
  description = "The name segment for the workload"
  default     = "dema"
  validation {
    condition     = can(regex("^[a-z0-9]+$", var.resource_name_workload))
    error_message = "The name segment for the workload must only contain lowercase letters and numbers"
  }
  validation {
    condition     = length(var.resource_name_workload) <= 4
    error_message = "The name segment for the workload must be 4 characters or less"
  }
}

variable "resource_name_environment" {
  type        = string
  description = "The name segment for the environment"
  default     = "dem"
  validation {
    condition     = can(regex("^[a-z0-9]+$", var.resource_name_environment))
    error_message = "The name segment for the environment must only contain lowercase letters and numbers"
  }
  validation {
    condition     = length(var.resource_name_environment) <= 4
    error_message = "The name segment for the environment must be 4 characters or less"
  }
}

variable "resource_name_sequence_start" {
  type        = number
  description = "The number to use for the resource names"
  default     = 1
  validation {
    condition     = var.resource_name_sequence_start >= 1 && var.resource_name_sequence_start <= 999
    error_message = "The number must be between 1 and 999"
  }
}


variable "resource_name_templates" {
  type        = map(string)
  description = "A map of resource names to use"
  default = {
    resource_group_state                   = "rg-$${workload}-tfstate-$${environment}-$${location_short}-$${sequence}"
    storage_account                        = "sto$${workload}$${environment}$${location_short}$${sequence}$${uniqueness}"
    storage_account_cyclecloud_locker      = "sto$${workload}lkr$${environment}$${location_short}$${sequence}$${uniqueness}"
    resource_group_identity                = "rg-$${workload}-identity-$${environment}-$${location_short}-$${sequence}"
    resource_group_network                 = "rg-$${workload}-network-$${environment}-$${location_short}-$${sequence}"
    resource_group_domain_controller       = "rg-$${workload}-dc-$${environment}-$${location_short}-$${sequence}"
    resource_group_domain_member           = "rg-$${workload}-dm-$${environment}-$${location_short}-$${sequence}"
    resource_group_cyclecloud_orchestrator = "rg-$${workload}-orchestrator-$${environment}-$${location_short}-$${sequence}"
    resource_group_cyclecloud_compute      = "rg-$${workload}-compute-$${environment}-$${location_short}-$${sequence}"
    user_assigned_managed_identity         = "umi-$${workload}-$${environment}-$${location_short}-$${sequence}"

    # resource_group_agents             = "rg-$${workload}-agents-$${environment}-$${location_short}-$${sequence}"
    virtual_network = "vnet-$${workload}-$${environment}-$${location_short}-$${sequence}"

    network_security_group_domain_controller = "nsg-$${workload}-dc-$${environment}-$${location_short}-$${sequence}"
    network_security_group_domain_member     = "nsg-$${workload}-dm-$${environment}-$${location_short}-$${sequence}"
    network_security_group_bastion           = "nsg-$${workload}-bastion-$${environment}-$${location_short}-$${sequence}"

    bastion               = "bastion-$${workload}-$${environment}-$${location_short}-$${sequence}"
    bastion_public_ip     = "pip-bastion-$${workload}-$${environment}-$${location_short}-$${sequence}"
    nat_gateway           = "nat-$${workload}-$${environment}-$${location_short}-$${sequence}"
    nat_gateway_public_ip = "pip-nat-$${workload}-$${environment}-$${location_short}-$${sequence}"

    resource_group_support = "rg-$${workload}-support-$${environment}-$${location_short}-$${sequence}"
    key_vault              = "kv-$${workload}-$${environment}-$${location_short}-$${sequence}"

    vm_cyclecloud_orchestrator = "vm-$${workload}-$${environment}-$${sequence}"
    vm_domain_controller       = "dc-$${workload}-$${environment}-$${sequence}"
    vm_domain_member           = "dm-$${workload}-$${environment}-$${sequence}"

    userassigned_managed_identity_locker = "umi-$${workload}-locker-$${environment}-$${location_short}-$${sequence}"
    # storage_account_private_endpoint  = "pe-sto-$${workload}-$${environment}-$${location_short}-$${sequence}"
    # agent_compute_postfix             = "$${workload}-$${environment}-$${location_short}-$${sequence}"
    # container_instance_prefix         = "aci-$${workload}-$${environment}-$${location_short}"
    # container_registry                = "acr$${workload}$${environment}$${location_short}$${sequence}$${uniqueness}"
    # project                           = "$${workload}-$${environment}"
    # repository_main                   = "$${workload}-$${environment}-main"
    # repository_template               = "$${workload}-$${environment}-template"
    # agent_pool                        = "agent-pool-$${workload}-$${environment}"
    # group                             = "group-$${workload}-$${environment}-approvers"
  }
}

variable "vnet_address_space" {
  default = "10.0.0.0/22"
  type    = string
}

variable "deploy_bastion" {
  type    = bool
  default = true
}

variable "deploy_natgw" {
  type    = bool
  default = true
}

variable "remote_access_ip" {
  type    = string
  default = ""
}

variable "deploy_vm_cc" {
  type    = bool
  default = true
}


# az vm image list --location canadacentral \
#  --publisher almalinux --offer almalinux-x86_64 \
#  --sku 9-gen2 --all -otable

variable "vm_cc_image_reference" {
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  default = {
    publisher = "almalinux"
    offer     = "almalinux-x86_64"
    sku       = "9-gen2"
    version   = "9.6.202505220"
  }
}

variable "cyclecloud8_ver" {
  type    = string
  default = "8.8.1-3561"
}

variable "deploy_dc" {
  type    = bool
  default = false
}

variable "deploy_dm" {
  type    = bool
  default = false
}

variable "domain_name" {
  type    = string
  default = "sandbox.local"
}

variable "domain_netbios_name" {
  type    = string
  default = "SANDBOX"
}

variable "vm_dc_sku" {
  type    = string
  default = "Standard_D2ads_v6"
}

variable "telemetry_enabled" {
  default = false
  type    = bool
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to apply to all resources."
  default     = {}
}