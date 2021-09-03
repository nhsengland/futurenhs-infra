output instrumentation_key {
  value     = azurerm_application_insights.forum.instrumentation_key
  sensitive = true
}

output connection_string {
  value     = azurerm_application_insights.forum.connection_string
  sensitive = true
}