output instrumentation_key {
  value     = azurerm_application_insights.api.instrumentation_key
  sensitive = true
}

output connection_string {
  value     = azurerm_application_insights.api.connection_string
  sensitive = true
}