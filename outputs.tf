# outputs.tf
output "resource_group_names" {
  description = "Names of the resource groups"
  value       = { for k, v in azurerm_resource_group.main : k => v.name }
}

output "storage_account_names" {
  description = "Names of the storage accounts"
  value       = { for k, v in module.static_website : k => v.storage_account_name }
}

output "storage_account_primary_web_endpoints" {
  description = "Primary web endpoints of the storage accounts"
  value       = { for k, v in module.static_website : k => v.static_website_url }
}

# output "function_app_names" {
#   description = "Names of the function apps"
#   value       = { for k, v in module.function_app : k => v.function_app_name }
# }

# output "function_app_urls" {
#   description = "URLs of the function apps"
#   value       = { for k, v in module.function_app : k => v.function_app_url }
# }

# output "deployment_info" {
#   description = "Summary of deployed resources"
#   value = {
#     environments = { for k, v in var.environments : k => {
#       resource_group_name = azurerm_resource_group.main[k].name
#       location           = azurerm_resource_group.main[k].location
#       storage_account    = module.static_website[k].storage_account_name
#       function_app       = module.function_app[k].function_app_name
#       storage_web_url    = module.static_website[k].static_website_url
#       function_app_url   = module.function_app[k].function_app_url
#     }}
#   }
# }