
resource "azurerm_network_security_group" "nsg" {
  name                = "${azurerm_resource_group.rgrp.name}-NSG"
  location            = azurerm_resource_group.rgrp.location
  resource_group_name = azurerm_resource_group.rgrp.name

  security_rule {
    name                       = "AllowWireguardInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_address_prefix      = "Internet"
    source_port_range          = "*"
    destination_address_prefix = "VirtualNetwork"
    destination_port_range     = 51820
  }

  security_rule {
    name                       = "AllowSSHInbound"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = "Internet"
    source_port_range          = "*"
    destination_address_prefix = "VirtualNetwork"
    destination_port_range     = 22
  }

  security_rule {
    name                       = "AllowInternetOutbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = "VirtualNetwork"
    source_port_range          = "*"
    destination_address_prefix = "Internet"
    destination_port_range     = 443
  }

  security_rule {
    name                       = "DenyAllOutbound"
    priority                   = 4000
    direction                  = "Outbound"
    access                     = "Deny"
    protocol                   = "*"
    source_address_prefix      = "*"
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_range     = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "subnet_association" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_network_interface_security_group_association" "nic_association" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

