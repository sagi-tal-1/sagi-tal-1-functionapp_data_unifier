output "storage_account_name" {
  value = azurerm_storage_account.static_website.name
}

output "storage_account_key" {
  value     = azurerm_storage_account.static_website.primary_access_key
  sensitive = true
}

output "static_website_url" {
  value = azurerm_storage_account.static_website.primary_web_endpoint
}

output "storage_account_id" {
  value = azurerm_storage_account.static_website.id
}