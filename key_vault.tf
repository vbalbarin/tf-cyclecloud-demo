locals {
  // The secrets are conditionally generated,
  // so we need to handle creating the KV secrets conditionally
  vm_cc_tls_privatekey     = var.deploy_vm_cc ? { vm_cc_tls_privatekey = { name = "vm-cc-tls-privatekey" } } : {}
  vm_cc_tls_privatekey_val = var.deploy_vm_cc ? { vm_cc_tls_privatekey = tls_private_key.vm_cc.private_key_openssh } : {}

  vm_cc_tls_publickey     = var.deploy_vm_cc ? { vm_cc_tls_publickey = { name = "vm-cc-tls-publickey" } } : {}
  vm_cc_tls_publickey_val = var.deploy_vm_cc ? { vm_cc_tls_publickey = trimspace(tls_private_key.vm_cc.public_key_openssh) } : {}

  hpcadmin_password     = var.deploy_vm_cc ? { hpcadmin_password = { name = "hpcadmin-password" } } : {}
  hpcadmin_password_val = var.deploy_vm_cc ? { hpcadmin_password = random_password.vm_hpcadmin[0].result } : {}
}

module "key_vault" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "~> 0.10.1"

  // TODO: Use sophisticated naming module
  name                = local.resource_names["key_vault"]
  location            = azurerm_resource_group.support.location
  resource_group_name = azurerm_resource_group.support.name
  tags                = var.tags

  tenant_id = data.azurerm_client_config.current.tenant_id

  # These settings are acceptable because these are short-lived, throw-away sandbox environments
  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  public_network_access_enabled = true
  network_acls = {
    default_action = "Deny"
    bypass         = "AzureServices"

    # Must allow access from the local IP so that the passwords can be retrieved for use with Bastion
    ip_rules = local.paas_firewall_allowed_ip

    virtual_network_subnet_ids = [
      module.virtualnetwork.subnets[local.subnet_names.cyclecloud].resource_id
    ]
  }

  role_assignments = {
    # Allow the current user to access the Key Vault
    deployment_user_kv_admin = {
      role_definition_id_or_name = "Key Vault Administrator"
      principal_id               = data.azurerm_client_config.current.object_id
    }
  }

  secrets       = merge(local.vm_cc_tls_privatekey, local.vm_cc_tls_publickey, local.hpcadmin_password)
  secrets_value = merge(local.vm_cc_tls_privatekey_val, local.vm_cc_tls_publickey_val, local.hpcadmin_password_val)

  # secrets = {
  #   vm_cc_tls_privatekey = {
  #     name = "vm-cc-tls-privatekey"
  #   }
  #   vm_cc_tls_publickey = {
  #     name = "vm-cc-tls-publickey"
  #   }
  # }
  # secrets_value = {
  #   vm_cc_tls_privatekey = tls_private_key.vm_cc.private_key_openssh
  #   vm_cc_tls_publickey  = trimspace(tls_private_key.vm_cc.public_key_openssh)
  # }

  wait_for_rbac_before_secret_operations = {
    create = "60s"
  }

  enable_telemetry = var.telemetry_enabled
}