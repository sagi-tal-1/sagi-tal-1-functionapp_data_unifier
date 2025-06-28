# SQL Server
resource "azurerm_mssql_server" "main" {
  name                         = var.databases.sql_server.name
  resource_group_name          = var.resource_group_name
  location                     = var.location
  version                      = var.databases.sql_server.version
  administrator_login          = var.databases.sql_server.administrator_login
  administrator_login_password = var.databases.sql_server.administrator_login_password

  tags = var.tags
}

# SQL Databases
resource "azurerm_mssql_database" "main" {
  for_each = var.databases.sql_server.databases
  
  name      = each.value.name
  server_id = azurerm_mssql_server.main.id
  collation = each.value.collation

  tags = var.tags
}

# SQL Firewall rule to allow Azure services
resource "azurerm_mssql_firewall_rule" "azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# Cosmos DB Account
resource "azurerm_cosmosdb_account" "main" {
  name                = var.databases.cosmos_db.name
  location            = var.location
  resource_group_name = var.resource_group_name
  offer_type          = var.databases.cosmos_db.offer_type
  kind                = var.databases.cosmos_db.kind

  consistency_policy {
    consistency_level = var.databases.cosmos_db.consistency_policy.consistency_level
  }

  geo_location {
    location          = var.location
    failover_priority = 0
  }

  tags = var.tags
}

# Cosmos DB SQL Databases
resource "azurerm_cosmosdb_sql_database" "main" {
  for_each = var.databases.cosmos_db.databases
  
  name                = each.value.name
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.main.name
  throughput          = each.value.throughput
}

# Cosmos DB SQL Containers
resource "azurerm_cosmosdb_sql_container" "main" {
  for_each = merge([
    for db_name, db_config in var.databases.cosmos_db.databases : {
      for container_name, container_config in db_config.containers : 
      "${db_name}_${container_name}" => merge(container_config, {
        database_name = db_name
      })
    }
  ]...)

  name                = each.value.name
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.main.name
  database_name       = azurerm_cosmosdb_sql_database.main[each.value.database_name].name
  partition_key_paths  = [each.value.partition_key]
  throughput          = each.value.throughput
}

# # Table Storage Account
# resource "azurerm_storage_account" "table_storage" {
#   name                     = var.databases.table_storage.name
#   resource_group_name      = var.resource_group_name
#   location                 = var.location
#   account_tier             = var.databases.table_storage.account_tier
#   account_replication_type = var.databases.table_storage.account_replication_type

#   tags = var.tags
# }

# # Storage Tables
# resource "azurerm_storage_table" "main" {
#   for_each = var.databases.table_storage.tables
  
#   name                 = each.value.name
#   storage_account_name = azurerm_storage_account.table_storage.name
# }

# # MongoDB Cosmos DB Account
# resource "azurerm_cosmosdb_account" "mongodb" {
#   name                = var.databases.mongodb.name
#   location            = var.location
#   resource_group_name = var.resource_group_name
#   offer_type          = var.databases.mongodb.offer_type
#   kind                = var.databases.mongodb.kind
#   mongo_server_version = var.databases.mongodb.mongo_server_version

#   consistency_policy {
#     consistency_level = var.databases.mongodb.consistency_policy.consistency_level
#   }

#   geo_location {
#     location          = var.location
#     failover_priority = 0
#   }

#   tags = var.tags
# }

# # MongoDB Databases
# resource "azurerm_cosmosdb_mongo_database" "main" {
#   for_each = var.databases.mongodb.databases
  
#   name                = each.value.name
#   resource_group_name = var.resource_group_name
#   account_name        = azurerm_cosmosdb_account.mongodb.name
#   throughput          = each.value.throughput
# }

# # MongoDB Collections
# resource "azurerm_cosmosdb_mongo_collection" "main" {
#   for_each = merge([
#     for db_name, db_config in var.databases.mongodb.databases : {
#       for collection_name, collection_config in db_config.collections : 
#       "${db_name}_${collection_name}" => merge(collection_config, {
#         database_name = db_name
#       })
#     }
#   ]...)

#   name                = each.value.name
#   resource_group_name = var.resource_group_name
#   account_name        = azurerm_cosmosdb_account.mongodb.name
#   database_name       = azurerm_cosmosdb_mongo_database.main[each.value.database_name].name
#   throughput          = each.value.throughput

#   dynamic "index" {
#     for_each = each.value.indexes
#     content {
#       keys   = index.value.keys
#       unique = index.value.unique
#     }
#   }
# }