data "template_file" "personal_vpn_tunnels" {

  template = file("./templates/vpn_tunnels.tpl")

  vars = {
    vm_identity_id              = azurerm_user_assigned_identity.vm.id
    vault_name                  = azurerm_key_vault.vault.name
    wg_server_address           = local.wg_server_address
    tunnels                     = join(";", var.personal_vpn_tunnels)
    dns_server                  = var.dns_server
    wg_server_endpoint          = azurerm_public_ip.ip.fqdn
    wg_server_port              = var.wg_server_port
    persistent_keep_alive       = var.persistent_keep_alive
    wg_server_address_with_cidr = local.wg_server_address_with_cidr
  }
}

resource "azurerm_virtual_machine_extension" "personal_tunnels" {
  name                 = "${azurerm_resource_group.rgrp.name}-PersonalTunnels"
  resource_group_name  = azurerm_resource_group.rgrp.name
  location             = azurerm_resource_group.location
  virtual_machine_name = azurerm_linux_virtual_machine.main.name

  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  protected_settings = <<PROT
{
    "script": "${base64encode(data.template_file.personal_vpn_tunnels.rendered)}"
}
  PROT
}
