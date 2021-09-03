output principal_id_app_gateway_svc {
  value = azurerm_user_assigned_identity.app_gateway.principal_id
}

output managed_identity_app_gateway {
  value = azurerm_user_assigned_identity.app_gateway.id
}