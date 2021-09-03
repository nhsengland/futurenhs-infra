output forum_primary_blob_fqdn {
  value = "${azurerm_storage_account.public_content.name}.blob.core.windows.net"
}

output forum_primary_blob_container_endpoint {
  value = "${azurerm_storage_account.public_content.primary_blob_endpoint}${azurerm_storage_container.images.name}"
}

output forum_primary_blob_container_resource_manager_id {
  value = azurerm_storage_container.images.resource_manager_id
}

output forum_primary_blob_container_name {
  value = azurerm_storage_container.images.name
}


output files_primary_blob_fqdn {
  value = "${azurerm_storage_account.public_content.name}.blob.core.windows.net"
}

output files_primary_blob_resource_manager_id {
  value = azurerm_storage_account.public_content.id
}

output files_primary_blob_container_endpoint {
  value = "${azurerm_storage_account.public_content.primary_blob_endpoint}${azurerm_storage_container.files.name}"
}

output files_primary_blob_container_resource_manager_id {
  value = azurerm_storage_container.files.resource_manager_id
}

output files_blob_primary_endpoint {
  value = azurerm_storage_account.public_content.primary_blob_endpoint
}

output files_blob_secondary_endpoint {
  value = azurerm_storage_account.public_content.secondary_blob_endpoint
}

output files_primary_blob_container_name {
  value = azurerm_storage_container.files.name
}