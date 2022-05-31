output principal_id {
  value = azurerm_app_service.content.identity[0].principal_id
}

output principal_id_staging {
  value = azurerm_app_service_slot.content.identity[0].principal_id
}

