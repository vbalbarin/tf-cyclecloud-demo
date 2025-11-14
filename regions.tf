module "az_regions" {
  # source           = "Azure/avm-utl-regions/azurerm//examples/default"
  source           = "Azure/avm-utl-regions/azurerm"
  version          = "~> 0.9.0"
  enable_telemetry = var.telemetry_enabled
}

locals {
  geo_codes_by_location = {
    for region in module.az_regions.regions :
    region.name => region.geo_code
  }
}