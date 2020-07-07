provider azurerm {
  version = "~> 2.17"
  features {}
}

 terraform {
   backend "remote" {
     # The name of your Terraform Cloud organization.
     organization = "Walawren"

     # The name of the Terraform Cloud workspace to store Terraform state files in.
     workspaces {
       name = "azure-wireguard"
     }
   }
 }

resource azurerm_resource_group rgrp {
  name     = "AzureWireGuard"
  location = "West Central US"
}
