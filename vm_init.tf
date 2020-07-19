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

  depends_on = [azurerm_storage_container.wireguard_confs]
}

locals {
  tunnels_string = join(";", [
    for t in var.personal_vpn_tunnels :
    t.name
  ])
  wg_conf_directory = "/etc/wireguard"
  wg_server_name    = var.wg_server_name

  # Bash substitutions
  tunnels     = "($${tunnels_string//;/ })"
  tunnel_loop = "$${tunnels[@]}"
  server_name = "$${wg_server_name}"

  # Scripts
  init_script = templatefile("./templates/vm_init.tpl", {
    wg_server_cidr = var.wg_server_cidr
    wg_server_port = var.wg_server_port

    personal_vpn_tunnels  = local.personal_vpn_tunnels
    upload_configurations = local.upload_configurations
  })

  upload_configurations = templatefile("./templates/upload_configurations.tpl", {
    tunnels_string                 = local.tunnels_string
    wg_server_name                 = local.wg_server_name
    wg_storage_account_name        = azurerm_storage_account.sa.name
    wg_conf_storage_container_name = azurerm_storage_container.wireguard_confs.name
    wg_rgrp_name                   = azurerm_resource_group.rgrp.name
    wg_conf_directory              = local.wg_conf_directory

    # Bash substitutions
    tunnels     = local.tunnels
    tunnel_loop = local.tunnel_loop
    server_name = local.server_name
  })

  personal_vpn_tunnels = templatefile("./templates/vpn_tunnels.tpl", {
    vm_identity_id              = azurerm_user_assigned_identity.vm.id
    vault_name                  = azurerm_key_vault.vault.name
    wg_server_address           = local.wg_server_address
    tunnels_string              = local.tunnels_string
    dns_server                  = var.dns_server
    wg_server_endpoint          = azurerm_public_ip.ip.fqdn
    wg_server_port              = var.wg_server_port
    persistent_keep_alive       = var.persistent_keep_alive
    wg_server_address_with_cidr = local.wg_server_address_with_cidr
    wg_server_name              = local.wg_server_name
    wg_conf_directory           = local.wg_conf_directory

    # Bash substitutions
    tunnels                  = local.tunnels
    wg_server_address_length = "$${#wg_server_address}"
    wg_server_last_ip        = "$${wg_server_address##*.}"
    addr_prefix_calc         = "$${wg_server_address:0:wg_server_substr_length}"
    tunnel_loop              = local.tunnel_loop
    KEYS_DIRECTORY           = "$${KEYS_DIRECTORY}"
    t                        = "$${t}"
    addr_prefix              = "$${addr_prefix}"
    count                    = "$${count}"
    server_name              = local.server_name
  })
}
