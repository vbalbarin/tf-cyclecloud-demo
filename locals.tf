locals {
  subscription_id = var.workload_subscription_id
  location        = lower(var.location)

}

# Calculate resource names
locals {
  name_replacements = {
    workload       = var.resource_name_workload
    environment    = var.resource_name_environment
    location       = var.location
    location_short = var.resource_name_location_short == "" ? local.geo_codes_by_location[var.location] : var.resource_name_location_short
    uniqueness     = random_string.unique_name.id
    sequence       = format("%02d", var.resource_name_sequence_start)
  }

  resource_names = { for key, value in var.resource_name_templates : key => templatestring(value, local.name_replacements) }

  paas_firewall_allowed_ip = length(var.remote_access_ip) > 0 ? [var.remote_access_ip] : [data.http.runner_ip[0].response_body]
}
