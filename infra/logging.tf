resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.site-name}-${var.environment_name}-la"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_application_insights" "main" {
  name                = "${var.site-name}-${var.environment_name}-appinsights"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "other"
}

resource "azurerm_application_insights_standard_web_test" "main" {
  name                    = "${var.site-name}-${var.environment_name}-webtest"
  location                = azurerm_resource_group.main.location
  resource_group_name     = azurerm_resource_group.main.name
  application_insights_id = azurerm_application_insights.main.id
  geo_locations           = ["us-fl-mia-edge", "emea-gb-db3-azr", "us-va-ash-azr"]
  enabled                 = true

  request {
    url = "https://${azurerm_static_web_app.main.default_host_name}"
  }
}

resource "azurerm_monitor_metric_alert" "main" {
  name                = "${var.site-name}-${var.environment_name}-alert"
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [azurerm_application_insights_standard_web_test.main.id, azurerm_application_insights.main.id]
  description         = "Web test alert"

  application_insights_web_test_location_availability_criteria {
    web_test_id           = azurerm_application_insights_standard_web_test.main.id
    component_id          = azurerm_application_insights.main.id
    failed_location_count = 2
  }
}