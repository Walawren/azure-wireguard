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

resource "azurerm_linux_virtual_machine" "main" {
  name                = "${azurerm_resource_group.rgrp.name}-MainVM"
  location            = azurerm_resource_group.rgrp.location
  resource_group_name = azurerm_resource_group.rgrp.name

  network_interface_ids = [azurerm_network_interface.nic.id]
  size                  = "Standard_DS2_v2"
  admin_username        = "walawren"
  computer_name         = "${lower(azurerm_resource_group.rgrp.name)}vm"
  custom_data           = filebase64("./CustomScripts/vm_init.sh")

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

