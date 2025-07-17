resource "azurerm_resource_group" "main" {
  name     = "${var.site-name}-rg"
  location = var.location
}

resource "azurerm_static_web_app" "main" {
  name                = var.site-name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
}

resource "azurerm_key_vault" "main" {
  name                       = "${var.site-name}-kv"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  #soft_delete_retention_days = 7
  purge_protection_enabled   = false
  sku_name                   = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Create",
      "Get",
    ]

    secret_permissions = [
      "Set",
      "Get",
      "Delete",
      "Purge",
      "Recover"
    ]
  }
}

resource "azurerm_key_vault_secret" "main" {
  name         = "${var.site-name}-api-key"
  value        = azurerm_static_web_app.main.api_key
  key_vault_id = azurerm_key_vault.main.id
}



data "azurerm_client_config" "current" {}
