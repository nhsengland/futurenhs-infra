output principal_id {
  value = azurerm_app_service.files.identity[0].principal_id
}

output principal_id_staging {
  value = azurerm_app_service_slot.files.identity[0].principal_id
}

output virtual_network_file_server_subnet_id {
  value = azurerm_subnet.files.id
}