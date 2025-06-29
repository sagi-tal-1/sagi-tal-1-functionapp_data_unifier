# Create resource groups for each environment
resource "azurerm_resource_group" "main" {
  for_each = var.environments
  name     = each.value.resource_group_name
  location = each.value.location
}

# Deploy static website module
module "static_website" {
  source   = "./modules/static_website"
  for_each = var.environments

  resource_group_name = azurerm_resource_group.main[each.key].name
  location            = azurerm_resource_group.main[each.key].location
  storage_account     = each.value.static_website
  tags                = each.value.tags
}

# Deploy function app module
module "function_app" {
  source   = "./modules/function_app"
  for_each = var.environments

  resource_group_name = azurerm_resource_group.main[each.key].name
  location            = azurerm_resource_group.main[each.key].location
  function_app_config = each.value.function_app
  database_config     = each.value.databases
  tags                = each.value.tags
  depends_on = [module.static_website, module.databases]

 
}

# Deploy databases module
module "databases" {
  source   = "./modules/databases"
  for_each = var.environments

  resource_group_name = azurerm_resource_group.main[each.key].name
  location            = azurerm_resource_group.main[each.key].location
  databases           = each.value.databases
  tags                = each.value.tags
}