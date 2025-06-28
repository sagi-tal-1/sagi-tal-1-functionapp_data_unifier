environments = {
  dev = {
    resource_group_name = "rg-static-website-dev"
    location            = "East US"
    
    static_website = {
      name                     = "staticweb2343212"
      account_tier             = "Standard"
      account_replication_type = "LRS"
      enable_static_website    = true
      index_document           = "index.html"
      error_404_document       = "404.html"
    }
    
    function_app = {
      name             = "func-data-unify-dev"
      service_plan_name = "plan-func-dev"
      sku_name         = "Y1"
      os_type          = "Linux"
      runtime_version  = "~4"
      python_version   = "3.9"
    }
    
    databases = {
      sql_server = {
        name                         = "sqlserver-poc-dev"
        administrator_login          = "sqladmin"
        administrator_login_password = "P@ssw0rd123!"
        version                      = "12.0"
        databases = {
          db1 = {
            name      = "database1"
            collation = "SQL_Latin1_General_CP1_CI_AS"
          }
        }
      }
      cosmos_db = {
        name               = "cosmosdb-poc-dev"
        offer_type         = "Standard"
        kind               = "GlobalDocumentDB"
        consistency_policy = {
          consistency_level = "Session"
        }
        databases = {
          db2 = {
            name       = "database2"
            throughput = 400
            containers = {
              container1 = {
                name           = "items"
                partition_key  = "/id"
                throughput     = 400
              }
            }
          }
        }
      }
      table_storage = {
        name                     = "tablestoragepocdev"
        account_tier             = "Standard"
        account_replication_type = "LRS"
        tables = {
          employees = {
            name = "employees"
          }
          products = {
            name = "products"
          }
        }
      }
      mongodb = {
        name               = "mongodb-poc-dev"
        offer_type         = "Standard"
        kind               = "MongoDB"
        mongo_server_version = "4.2"
        consistency_policy = {
          consistency_level = "Session"
        }
        databases = {
          db4 = {
            name       = "inventorydb"
            throughput = 400
            collections = {
              inventory = {
                name = "inventory"
                throughput = 400
                indexes = [
                  {
                    keys = ["_id"]
                    unique = true
                  }
                ]
              }
            }
          }
        }
      }
    }
    
    tags = {
      Environment = "dev"
      Project     = "static-website-poc"
    }
  }
  
}
#   prod = {
#     resource_group_name = "rg-static-website-prod"
#     location            = "East US"
    
#     static_website = {
#       name                     = "staticwebsiteprod001"
#       account_tier             = "Standard"
#       account_replication_type = "GRS"
#       enable_static_website    = true
#       index_document           = "index.html"
#       error_404_document       = "404.html"
#     }
    
#     function_app = {
#       name             = "func-data-unify-prod"
#       service_plan_name = "plan-func-prod"
#       sku_name         = "S1"
#       os_type          = "Linux"
#       runtime_version  = "~4"
#       python_version   = "3.9"
#     }
    
#     databases = {
#       sql_server = {
#         name                         = "sqlserver-poc-prod"
#         administrator_login          = "sqladmin"
#         administrator_login_password = "P@ssw0rd123!"
#         version                      = "12.0"
#         databases = {
#           db1 = {
#             name      = "database1"
#             collation = "SQL_Latin1_General_CP1_CI_AS"
#           }
#         }
#       }
#       cosmos_db = {
#         name               = "cosmosdb-poc-prod"
#         offer_type         = "Standard"
#         kind               = "GlobalDocumentDB"
#         consistency_policy = {
#           consistency_level = "Session"
#         }
#         databases = {
#           db2 = {
#             name       = "database2"
#             throughput = 800
#             containers = {
#               container1 = {
#                 name           = "items"
#                 partition_key  = "/id"
#                 throughput     = 800
#               }
#             }
#           }
#         }
#       }
#       table_storage = {
#         name                     = "tablestoragepocprod"
#         account_tier             = "Standard"
#         account_replication_type = "GRS"
#         tables = {
#           employees = {
#             name = "employees"
#           }
#           products = {
#             name = "products"
#           }
#         }
#       }
#       mongodb = {
#         name               = "mongodb-poc-prod"
#         offer_type         = "Standard"
#         kind               = "MongoDB"
#         mongo_server_version = "4.2"
#         consistency_policy = {
#           consistency_level = "Session"
#         }
#         databases = {
#           db4 = {
#             name       = "inventorydb"
#             throughput = 800
#             collections = {
#               inventory = {
#                 name = "inventory"
#                 throughput = 800
#                 indexes = [
#                   {
#                     keys = ["_id"]
#                     unique = true
#                   }
#                 ]
#               }
#             }
#           }
#         }
#       }
#     }
    
#     tags = {
#       Environment = "prod"
#       Project     = "static-website-poc"
#     }
#   }
# }