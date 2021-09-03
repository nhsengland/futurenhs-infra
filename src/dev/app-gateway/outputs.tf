output virtual_network_application_gateway_subnet_id {
    value = azurerm_subnet.default.id
}

output virtual_network_security_group_id {
    value = azurerm_network_security_group.default.id
}