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
