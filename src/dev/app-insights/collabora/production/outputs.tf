output instrumentation_key {
  value     = azurerm_application_insights.collabora.instrumentation_key
  sensitive = true
}

output connection_string {
  value     = azurerm_application_insights.collabora.connection_string
  sensitive = true
}