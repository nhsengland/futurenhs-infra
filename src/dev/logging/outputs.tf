output "log_analytics_workspace_resource_id" {
  value = azurerm_log_analytics_workspace.main.id
}

output "log_analytics_workspace_id" {
  value = azurerm_log_analytics_workspace.main.workspace_id
}

output "log_storage_account_id" {
  value = azurerm_storage_account.logs.id
}

output "log_storage_account_blob_endpoint" { 
  value = azurerm_storage_account.logs.primary_blob_endpoint
}

output "log_storage_account_access_key" { 
  value = azurerm_storage_account.logs.primary_access_key
  sensitive = true
}

output log_storage_account_connection_string {
  value = azurerm_storage_account.logs.primary_connection_string
  sensitive = true
}

output log_storage_account_appsvclogs_container_name { 
  value = azurerm_storage_container.appsvclogs.name
}

output log_storage_account_sql_server_vulnerability_assessments_container_name {
  value = azurerm_storage_container.sql_vulnerability_assessments.name
}
