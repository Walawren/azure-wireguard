resource "random_password" "vm_password" {
  length           = 30
  special          = true
  override_special = "_%@"
}

resource "azurerm_virtual_machine" "main" {
  name                = "${azurerm_resource_group.rgrp.name}-VM"
  location            = azurerm_resource_group.rgrp.location
  resource_group_name = azurerm_resource_group.rgrp.name

  network_interface_ids = [azurerm_network_interface.nic.id]
  vm_size               = "Standard_DS2_v2"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  # delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

  os_profile {
    computer_name  = "hostname"
    admin_username = "walawren"
    admin_password = random_password.vm_password.result
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}
