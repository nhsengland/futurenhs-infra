output principal_id {
  value = azurerm_app_service.api.identity[0].principal_id
}

output principal_id_staging {
  value = azurerm_app_service_slot.api.identity[0].principal_id
}

output virtual_network_api_app_subnet_id {
  value = azurerm_subnet.api.id
}
