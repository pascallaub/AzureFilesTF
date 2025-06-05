output "storage_account_name" {
  value = azurerm_storage_account.storage.name
}

output "share_name" {
  value = azurerm_storage_share.share.name
}
