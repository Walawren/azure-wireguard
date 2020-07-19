locals {
  email_secrets = {
    for t in var.personal_vpn_tunnels :
    "${var.wg_server_name}-${t.name}-Email" => t.email
  }

  phone_number_secrets = {
    for t in var.personal_vpn_tunnels :
    "${var.wg_server_name}-${t.name}-PhoneNumber" => t.phone_number
  }
}

resource "azurerm_key_vault" "vault" {
  name                = "${azurerm_resource_group.rgrp.name}-KV"
  location            = azurerm_resource_group.rgrp.location
  resource_group_name = azurerm_resource_group.rgrp.name

  sku_name = "standard"

  tenant_id = data.azurerm_client_config.current.tenant_id

  enabled_for_disk_encryption = true
}

resource "azurerm_key_vault_access_policy" "current" {
  key_vault_id = azurerm_key_vault.vault.id

  tenant_id = data.azurerm_client_config.current.tenant_id
  object_id = data.azurerm_client_config.current.object_id

  key_permissions = [
    "get"
  ]

  secret_permissions = [
    "get",
    "set",
    "delete",
    "list",
    "purge"
  ]
}

resource "azurerm_key_vault_access_policy" "myself" {
  key_vault_id = azurerm_key_vault.vault.id

  tenant_id = data.azurerm_client_config.current.tenant_id
  object_id = "4bf92e5c-a466-4811-b058-60be3ab1839a"

  key_permissions = [
    "get"
  ]

  secret_permissions = [
    "get",
    "set",
    "delete",
    "list",
    "purge"
  ]
}

resource "azurerm_key_vault_secret" "emails" {
  for_each = local.email_secrets

  name         = each.key
  value        = each.value
  key_vault_id = azurerm_key_vault.vault.id
}

resource "azurerm_key_vault_secret" "phone_numbers" {
  for_each = local.phone_number_secrets

  name         = each.key
  value        = each.value
  key_vault_id = azurerm_key_vault.vault.id
}

