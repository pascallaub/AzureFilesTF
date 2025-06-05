module "network" {
  source      = "../../modules/network"
  project     = var.project
  environment = var.environment
  location    = var.location
}

module "storage" {
  source              = "../../modules/storage"
  prefix              = "${var.project}${var.environment}"
  location            = var.location
  resource_group_name = module.network.resource_group_name
  subnet_id           = module.network.subnet_id
  private_dns_zone_id = module.network.private_dns_zone_id
}
