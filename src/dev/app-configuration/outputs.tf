output primary_principal_id { 
  value     = azurerm_app_configuration.main.identity[0].principal_id
}

output primary_endpoint { 
  value     = azurerm_app_configuration.main.endpoint
}

output secondary_endpoint { 
  value     = "<<failover region endpoint will eventually go here>>"
}

output primary_app_configuration_id {
  value     = azurerm_app_configuration.main.id
}

#output connection_string_readonly {
#  value     = azurerm_app_configuration.main.primary_read_key.connection_string
#  sensitive = true
#}

#output connection_string_writeonly {
#  value     = azurerm_app_configuration.main.primary_write_key.connection_string
#  sensitive = true
#}