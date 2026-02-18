# Random password generation for VM accounts using HashiCorp modules
# This file generates strong, unique passwords for VM accounts and stores them in Azure Key Vault

# Generate random password for domain controller admin account
resource "random_password" "vm_hpcadmin" {
  count = var.deploy_vm_cc ? 1 : 0

  length  = 16
  special = true
  upper   = true
  lower   = true
  numeric = true

  # Linux-safe
  override_special = "!@#$%^*()-_+="

  # Exclude characters that can cause issues in PowerShell/Windows
  # override_special = "!@#$%^&*()-_=+[]{}|;:,.<>?"

  # Ensure we have at least one of each character type
  min_upper   = 2
  min_lower   = 2
  min_numeric = 2
  min_special = 2
}

