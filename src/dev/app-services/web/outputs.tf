output principal_id {
  value = azurerm_app_service.web.identity[0].principal_id
}

output principal_id_staging {
  value = azurerm_app_service_slot.web.identity[0].principal_id
}

output virtual_network_web_app_subnet_id {
  value = azurerm_subnet.web.id
}
