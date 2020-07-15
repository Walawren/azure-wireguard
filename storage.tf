locals {
  lower_rgrp_name = lower(azurerm_resource_group.rgrp.name)
}

resource "azurerm_storage_account" "sa" {
  name                     = "${local.lower_rgrp_name}sa"
  resource_group_name      = azurerm_resource_group.rgrp.name
  location                 = azurerm_resource_group.rgrp.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "wireguard_confs" {
  name                  = "wireguard-confs"
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "private"
}

