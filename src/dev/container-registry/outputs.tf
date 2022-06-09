output container_registry_url {
  value = azurerm_container_registry.container_registry.login_server
}

output container_registry_username {
  value = azurerm_container_registry.container_registry.admin_username
}

output container_registry_password {
  value = azurerm_container_registry.container_registry.admin_password 
}