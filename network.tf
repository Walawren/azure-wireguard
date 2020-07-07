locals {
  vnet_address = "10.1.2.0/24"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${azurerm_resource_group.rgrp.name}-VNET"
  resource_group_name = azurerm_resource_group.rgrp.name
  location            = azurerm_resource_group.rgrp.location

  address_space = [local.vnet_address]
}

resource "azurerm_subnet" "subnet" {
  name                 = "${azurerm_resource_group.rgrp.name}-SUBN01"
  resource_group_name  = azurerm_resource_group.rgrp.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [cidrsubnet(local.vnet_address, 1, 1)]
}

resource "azurerm_public_ip" "ip" {
  name                = "${azurerm_resource_group.rgrp.name}-PublicIP"
  resource_group_name = azurerm_resource_group.rgrp.name
  location            = azurerm_resource_group.rgrp.location

  domain_name_label = "walawren"
  allocation_method = "Static"
}

resource "azurerm_network_interface" "nic" {
  name                = "${azurerm_resource_group.rgrp.name}-NIC"
  location            = azurerm_resource_group.rgrp.location
  resource_group_name = azurerm_resource_group.rgrp.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.ip.id
  }

  enable_accelerated_networking = true
}

