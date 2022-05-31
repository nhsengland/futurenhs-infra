output instrumentation_key {
  value     = azurerm_application_insights.content.instrumentation_key
  sensitive = true
}

output connection_string {
  value     = azurerm_application_insights.content.connection_string
  sensitive = true
}