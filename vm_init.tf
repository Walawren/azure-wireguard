resource "azurerm_virtual_machine_extension" "vm_init" {
  name               = "${azurerm_resource_group.rgrp.name}-VMInit"
  virtual_machine_id = azurerm_linux_virtual_machine.main.id

  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  protected_settings = <<PROT
{
  "script": "${base64encode(templatefile("./templates/vm_init.tpl", {
  wg_server_cidr    = var.wg_server_cidr
  wg_server_address = local.wg_server_address
  wg_server_port    = var.wg_server_port
}))}"
}
PROT
}
