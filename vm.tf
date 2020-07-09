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

resource "random_password" "vm_password" {
  length           = 30
  special          = true
  override_special = "_%@"
}

resource "azurerm_linux_virtual_machine" "main" {
  name                = "${azurerm_resource_group.rgrp.name}-VM"
  location            = azurerm_resource_group.rgrp.location
  resource_group_name = azurerm_resource_group.rgrp.name

  admin_username                  = "walawren"
  admin_password                  = random_password.vm_password.result
  disable_password_authentication = false

  network_interface_ids = [azurerm_network_interface.nic.id]
  size                  = "Standard_DS2_v2"
  computer_name         = "${lower(azurerm_resource_group.rgrp.name)}vm"

  os_disk {
    name                 = "${azurerm_resource_group.rgrp.name}-VM-disk1"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.vm.id]
  }
}

