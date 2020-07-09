## VM Managed User
resource "azurerm_user_assigned_identity" "vm" {
  name                = "${azurerm_resource_group.rgrp.name}-VM-Identity"
  resource_group_name = azurerm_resource_group.rgrp.name
  location            = azurerm_resource_group.rgrp.location
}

resource "azurerm_role_assignment" "vm_admin" {
  scope = azurerm_resource_group.rgrp.id

  role_definition_name = "Virtual Machine Administrator Login"
  principal_id         = azurerm_user_assigned_identity.vm.principal_id
}

resource "azurerm_key_vault_access_policy" "vm_identity" {
  key_vault_id = azurerm_key_vault.vault.id

  tenant_id = data.azurerm_client_config.current.tenant_id

  object_id = azurerm_user_assigned_identity.vm.principal_id

  secret_permissions = [
    "get",
    "set",
    "delete",
    "list"
  ]
}

## Logic App Managed User
resource "azurerm_user_assigned_identity" "logic_app" {
  name                = "${azurerm_resource_group.rgrp.name}-LogicApp-Identity"
  resource_group_name = azurerm_resource_group.rgrp.name
  location            = azurerm_resource_group.rgrp.location
}

resource "azurerm_role_assignment" "storage_reader" {
  scope = azurerm_storage_container.wireguard_confs.id

  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_user_assigned_identity.logic_app.principal_id
}

