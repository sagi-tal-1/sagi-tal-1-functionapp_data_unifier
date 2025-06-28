output "sql_server_name" {
  value = azurerm_mssql_server.main.name
}

output "sql_server_fqdn" {
  value = azurerm_mssql_server.main.fully_qualified_domain_name
}

output "cosmos_account_name" {
  value = azurerm_cosmosdb_account.main.name
}

output "cosmos_endpoint" {
  value = azurerm_cosmosdb_account.main.endpoint
}

output "cosmos_primary_key" {
  value     = azurerm_cosmosdb_account.main.primary_key
  sensitive = true
}

output "table_storage_name" {
  value = azurerm_storage_account.table_storage.name
}

output "table_storage_connection_string" {
  value     = azurerm_storage_account.table_storage.primary_connection_string
  sensitive = true
}

output "mongodb_account_name" {
  value = azurerm_cosmosdb_account.mongodb.name
}

output "mongodb_endpoint" {
  value = azurerm_cosmosdb_account.mongodb.endpoint
}

output "mongodb_connection_string" {
  value     = azurerm_cosmosdb_account.mongodb.primary_mongodb_connection_string
  sensitive = true
}