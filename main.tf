variable client_id { type = string }
variable client_secret { type = string }
variable tenant_id { type = string }
variable subscription_id { type = string }

provider azurerm {
  version = "~> 2.17"

  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id

  features {}
}

provider random {
  version = "~> 2.2"
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

