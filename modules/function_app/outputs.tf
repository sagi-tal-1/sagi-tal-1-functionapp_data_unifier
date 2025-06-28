output "function_app_name" {
  value = azurerm_linux_function_app.main.name
}

output "function_app_url" {
  value = azurerm_linux_function_app.main.default_hostname
}

output "function_storage_account_name" {
  value = azurerm_storage_account.function_storage.name
}

output "uploads_container_name" {
  value = azurerm_storage_container.uploads.name
}