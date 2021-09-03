output instrumentation_key {
  value     = azurerm_application_insights.files_staging.instrumentation_key
  sensitive = true
}

output connection_string {
  value     = azurerm_application_insights.files_staging.connection_string
  sensitive = true
}