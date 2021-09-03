output instrumentation_key {
  value     = azurerm_application_insights.files.instrumentation_key
  sensitive = true
}

output connection_string {
  value     = azurerm_application_insights.files.connection_string
  sensitive = true
}