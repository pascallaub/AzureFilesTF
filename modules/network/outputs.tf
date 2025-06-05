output "subnet_id" {
  value = azurerm_subnet.private.id
}

output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "private_dns_zone_id" {
  value = azurerm_private_dns_zone.fileshare.id
}
