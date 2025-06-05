terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate"
    storage_account_name = "tfstatestorage"
    container_name       = "statefiles"
    key                  = "azurefiles/terraform.tfstate"
  }
}
