resource "azurerm_storage_account" "storage" {
  name                       = "${var.prefix}fileshare"
  resource_group_name        = var.resource_group_name
  location                   = var.location
  account_tier               = "Standard"
  account_replication_type   = "LRS"
  https_traffic_only_enabled = true

  network_rules {
    default_action             = "Deny"
    virtual_network_subnet_ids = [var.subnet_id]
  }

  tags = {
    environment = var.prefix
  }
}

resource "azurerm_storage_share" "share" {
  name               = "data"
  storage_account_id = azurerm_storage_account.storage.id
  quota              = 100
}

resource "azurerm_private_endpoint" "fileshare_pe" {
  name                = "${var.prefix}-fileshare-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = "fileshare-psc"
    private_connection_resource_id = azurerm_storage_account.storage.id
    subresource_names              = ["file"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [var.private_dns_zone_id]
  }
}
