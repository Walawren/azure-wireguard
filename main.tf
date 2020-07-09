variable client_id { type = string }
variable client_secret { type = string }
variable tenant_id { type = string }
variable subscription_id { type = string }

data "azurerm_client_config" "current" {}

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

locals {
  vnet_address                = "10.1.2.0/24"
  wg_server_address           = cidrhost(var.wg_server_cidr, 1)
  wg_server_address_with_cidr = "${local.wg_server_address}/${split("/", var.wg_server_cidr)[1]}"
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

