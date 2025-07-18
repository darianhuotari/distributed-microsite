output "static_web_app_api_key" {
  description = "The API key for the Azure Static Web App."
  value       = azurerm_static_web_app.main.api_key
  sensitive   = true
}

output "app_insights_connection_string" {
  description = "Application Insights connection string."
  value       = azurerm_application_insights.main.connection_string
  sensitive   = true
}