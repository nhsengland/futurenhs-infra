output "database_name" {
  value       = azurerm_mssql_database.content.name
}

output "keyvault_connection_string_reference" {
  value       = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.sqlserver_primary_contentdb_connection_string.versionless_id})"
}

output connection_string { 
  value       = azurerm_key_vault_secret.sqlserver_primary_contentdb_connection_string.value
  sensitive   = true
}