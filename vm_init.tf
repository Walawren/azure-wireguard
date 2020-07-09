resource "azurerm_virtual_machine_extension" "vm_init" {
  name               = "${azurerm_resource_group.rgrp.name}-VMInit"
  virtual_machine_id = azurerm_linux_virtual_machine.main.id

  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  protected_settings = <<PROT
{
  "script": "${base64encode(local.init_script)}"
}
PROT
}

locals {

  init_script = templatefile("./templates/vm_init.tpl", {
    wg_server_cidr = var.wg_server_cidr
    wg_server_port = var.wg_server_port

    personal_vpn_tunnels = local.personal_vpn_tunnels
  })

  personal_vpn_tunnels = templatefile("./templates/vpn_tunnels.tpl", {
    vm_identity_id              = azurerm_user_assigned_identity.vm.id
    vault_name                  = azurerm_key_vault.vault.name
    wg_server_address           = local.wg_server_address
    tunnels_string              = join(";", var.personal_vpn_tunnels)
    dns_server                  = var.dns_server
    wg_server_endpoint          = azurerm_public_ip.ip.fqdn
    wg_server_port              = var.wg_server_port
    persistent_keep_alive       = var.persistent_keep_alive
    wg_server_address_with_cidr = local.wg_server_address_with_cidr
    wg_server_name              = var.wg_server_name

    # Bash substitutions
    tunnels                  = "($${tunnels_string//;/ })"
    wg_server_address_length = "$${#wg_server_address}"
    wg_server_last_ip        = "$${wg_server_address##*.}"
    addr_prefix              = "$${wg_server_address:0:wg_server_substr_length}"
    tunnel_loop              = "$${tunnels[@]}"
    KEYS_DIRECTORY           = "$${KEYS_DIRECTORY}"
    t                        = "$${t}"
    addr_prefix              = "$${addr_prefix}"
    count                    = "$${count}"
    server_name              = "$${wg_server_name}"
  })
}
