resource "azurerm_resource_group" "network" {
  name     = local.resource_names["resource_group_network"]
  location = var.location

  tags = var.tags
}

resource "azurerm_resource_group" "cyclecloud_orchestrator" {
  name     = local.resource_names["resource_group_cyclecloud_orchestrator"]
  location = var.location

  tags = var.tags
}

resource "azurerm_resource_group" "cyclecloud_compute" {
  name     = local.resource_names["resource_group_cyclecloud_compute"]
  location = var.location

  tags = var.tags
}

resource "azurerm_resource_group" "support" {
  name     = local.resource_names["resource_group_support"]
  location = var.location

  tags = var.tags
}