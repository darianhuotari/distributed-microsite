resource "azurerm_resource_group" "main" {
  name     = "${var.site-name}-rg"
  location = var.location
}

resource "azurerm_static_web_app" "main" {
  name                = var.site-name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
}