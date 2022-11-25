output "forum_primary_blob_fqdn" {
  value = "${azurerm_storage_account.public_content.name}.blob.core.windows.net"
}

output "forum_primary_blob_container_endpoint" {
  value = "${azurerm_storage_account.public_content.primary_blob_endpoint}${azurerm_storage_container.images.name}"
}

output "forum_primary_blob_container_resource_manager_id" {
  value = azurerm_storage_container.images.resource_manager_id
}

output "forum_primary_blob_container_name" {
  value = azurerm_storage_container.images.name
}


output "files_primary_blob_fqdn" {
  value = "${azurerm_storage_account.public_content.name}.blob.core.windows.net"
}

output "files_primary_blob_resource_manager_id" {
  value = azurerm_storage_account.public_content.id
}

output "files_primary_blob_container_endpoint" {
  value = "${azurerm_storage_account.public_content.primary_blob_endpoint}${azurerm_storage_container.files.name}"
}

output "files_primary_blob_container_resource_manager_id" {
  value = azurerm_storage_container.files.resource_manager_id
}

output "files_blob_primary_endpoint" {
  value = azurerm_storage_account.public_content.primary_blob_endpoint
}

output "files_blob_secondary_endpoint" {
  value = azurerm_storage_account.public_content.secondary_blob_endpoint
}

output "files_primary_blob_container_name" {
  value = azurerm_storage_container.files.name
}

output "files_primary_table_resource_manager_id" {
  value = azurerm_storage_account.private_content.id
}

output "files_table_primary_endpoint" {
  value = azurerm_storage_account.private_content.primary_table_endpoint
}

output "files_table_secondary_endpoint" {
  value = azurerm_storage_account.private_content.secondary_table_endpoint
}

output "api_primary_file_blob_container_endpoint" {
  value = "${azurerm_storage_account.public_content.primary_blob_endpoint}${azurerm_storage_container.files.name}"
}

output "api_primary_image_blob_container_endpoint" {
  value = "${azurerm_storage_account.public_content.primary_blob_endpoint}${azurerm_storage_container.images.name}"
}

output "b2c_storage_account_name" {
  value = azurerm_storage_account.b2c_content.name
}

output "b2c_storage_container_name" {
  value = azurerm_storage_container.b2c.name
}

