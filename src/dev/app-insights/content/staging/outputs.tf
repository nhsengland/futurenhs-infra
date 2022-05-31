output instrumentation_key {
  value     = azurerm_application_insights.content_staging.instrumentation_key
  sensitive = true
}

output connection_string {
  value     = azurerm_application_insights.content_staging.connection_string
  sensitive = true
}