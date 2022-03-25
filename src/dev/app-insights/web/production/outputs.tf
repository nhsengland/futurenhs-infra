output instrumentation_key {
  value     = azurerm_application_insights.web.instrumentation_key
  sensitive = true
}

output connection_string {
  value     = azurerm_application_insights.web.connection_string
  sensitive = true
}