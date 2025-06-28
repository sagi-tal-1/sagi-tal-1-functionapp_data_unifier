# Service plan for function app
resource "azurerm_service_plan" "function_plan" {
  name                = var.function_app_config.service_plan_name
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = var.function_app_config.os_type
  sku_name            = var.function_app_config.sku_name

  tags = var.tags
}

# Application Insights
resource "azurerm_application_insights" "function_insights" {
  name                = "${var.function_app_config.name}-insights"
  location            = var.location
  resource_group_name = var.resource_group_name
  application_type    = "web"

  tags = var.tags
}

# Storage account for function app
resource "azurerm_storage_account" "function_storage" {
  name                     = "${substr(lower(replace(replace(var.function_app_config.name, "-", ""), "_", "")), 0, 19)}st001"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = var.tags
}

# Storage container for uploads (trigger container)
resource "azurerm_storage_container" "uploads" {
  name                  = "uploads"
  storage_account_name  = azurerm_storage_account.function_storage.name
  container_access_type = "private"
}

# Function App
resource "azurerm_linux_function_app" "main" {
  name                = var.function_app_config.name
  resource_group_name = var.resource_group_name
  location            = var.location

  storage_account_name       = azurerm_storage_account.function_storage.name
  storage_account_access_key = azurerm_storage_account.function_storage.primary_access_key
  service_plan_id            = azurerm_service_plan.function_plan.id

  site_config {
    application_stack {
      python_version = var.function_app_config.python_version
    }
    
    cors {
      allowed_origins = ["*"]
    }
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"     = "python"
    "FUNCTIONS_EXTENSION_VERSION"  = var.function_app_config.runtime_version
    "APPINSIGHTS_INSTRUMENTATIONKEY" = azurerm_application_insights.function_insights.instrumentation_key
    
    # Database connection strings
    "SQL_CONNECTION_STRING" = "Server=tcp:${var.database_config.sql_server.name}.database.windows.net,1433;Initial Catalog=${values(var.database_config.sql_server.databases)[0].name};Persist Security Info=False;User ID=${var.database_config.sql_server.administrator_login};Password=${var.database_config.sql_server.administrator_login_password};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
    
    "COSMOS_CONNECTION_STRING" = "AccountEndpoint=https://${var.database_config.cosmos_db.name}.documents.azure.com:443/;AccountKey=${data.azurerm_cosmosdb_account.main.primary_key};"
    
    "TABLE_STORAGE_CONNECTION_STRING" = data.azurerm_storage_account.table_storage.primary_connection_string
    
    "MONGODB_CONNECTION_STRING" = data.azurerm_cosmosdb_account.mongodb.primary_mongodb_connection_string
    
    # Storage trigger settings
    "STORAGE_CONNECTION_STRING" = azurerm_storage_account.function_storage.primary_connection_string
    "TRIGGER_CONTAINER_NAME"    = azurerm_storage_container.uploads.name
  }

  tags = var.tags
}

# CosmosDB Account (referenced for connection string)
data "azurerm_cosmosdb_account" "main" {
  name                = var.database_config.cosmos_db.name
  resource_group_name = var.resource_group_name
  
  depends_on = [var.database_config]
}

# # Table Storage Account (referenced for connection string)
# data "azurerm_storage_account" "table_storage" {
#   name                = var.database_config.table_storage.name
#   resource_group_name = var.resource_group_name
# }

# # MongoDB Cosmos Account (referenced for connection string)
# data "azurerm_cosmosdb_account" "mongodb" {
#   name                = var.database_config.mongodb.name
#   resource_group_name = var.resource_group_name
# }

# Note: Function code deployment should be done separately using Azure Functions Core Tools
# or Azure CLI. The function code is not managed by Terraform.
# 
# To deploy function code:
# 1. Package your function code: func azure functionapp publish <function-app-name>
# 2. Or use Azure CLI: az functionapp deployment source config-zip --resource-group <rg> --name <function-app-name> --src <path-to-zip>