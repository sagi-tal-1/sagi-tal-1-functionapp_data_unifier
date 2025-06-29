variable "oidc_token" {}
variable "oidc_token_file_path" {}
variable "oidc_request_token" {}
variable "oidc_request_url" {}
variable "ado_pipeline_service_connection_id" {}

# We strongly recommend using the required_providers block to set the
# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.1.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}

  subscription_id = data.azurerm_client_config.current.subscription_id

  client_id       = data.azurerm_client_config.current.client_id
  client_secret = data.azurerm_client_config.current.client_secret
  use_oidc        = true

  # # for GitHub Actions or Azure DevOps Pipelines
  # oidc_request_token = var.oidc_request_token
  # oidc_request_url   = var.oidc_request_url

  # # for Azure DevOps Pipelines
  # ado_pipeline_service_connection_id = var.ado_pipeline_service_connection_id

  # # for other generic OIDC providers, providing token directly
  # oidc_token = var.oidc_token

  # # for other generic OIDC providers, reading token from a file
  # oidc_token_file_path = var.oidc_token_file_path

  tenant_id = data.azurerm_client_config.current.tenant_id
}