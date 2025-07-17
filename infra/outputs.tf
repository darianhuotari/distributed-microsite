output "static_web_app_api_key" {
  description = "The API key for the Azure Static Web App."
  value       = azurerm_static_web_app.main.api_key
  sensitive   = true
}