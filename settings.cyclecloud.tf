# Configure custom network resources settings
locals {

  service_ports = {
    all     = ["0-65535"]
    bastion = ["8080", "5701"]
    https   = ["443"]
    http    = ["80"]
    ssh     = ["22"]
    lustre  = ["988", "1019-1023"]
    # 111: portmapper, 635: mountd, 2049: nfsd, 4045: nlockmgr, 4046: status, 4049: rquotad
    nfs = ["111", "635", "2049", "4045", "4046", "4049"]
    #  HTTPS, AMQP
    cyclecloud = ["9443", "5672"]
    mysql      = ["3306", "33060"]
    ssh_rdp    = ["22", "3389"]
  }

  conf_network_resources = {

    subscription_id    = var.workload_subscription_id
    vnet_address_space = var.vnet_address_space
    location           = lower(var.location)
    reg                = var.resource_name_location_short

    # Create a custom tags input
    //tags = var.network_resources_tags
  }
}