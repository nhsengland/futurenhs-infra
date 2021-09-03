variable location { type = string }

variable environment { type = string }

variable product_name { type = string }

variable resource_group_name { type = string }

variable virtual_network_name { type = string }

variable virtual_network_application_gateway_subnet_id { type = string }

variable virtual_network_security_group_id { type = string }

variable log_storage_account_connection_string { 
  type = string
  sensitive = true
} 

variable log_storage_account_blob_endpoint { type = string }

variable log_storage_account_container_name { type = string }

variable log_storage_account_id { type = string }

variable log_analytics_workspace_resource_id { type = string }

variable forum_db_keyvault_readwrite_connection_string_reference { type = string }

variable forum_db_keyvault_readonly_connection_string_reference { type = string }

variable forum_primary_blob_container_endpoint { type = string }

variable forum_primary_blob_container_resource_manager_id { type = string }

variable forum_primary_blob_container_name { type = string }

variable forum_primary_blob_keyvault_connection_string_reference { type = string }

variable files_blob_primary_endpoint { type = string }

variable files_primary_blob_container_endpoint { type = string }

variable files_primary_blob_resource_manager_id { type = string }

variable files_primary_blob_container_resource_manager_id { type = string }

variable files_primary_blob_container_name { type = string }

variable files_primary_blob_keyvault_connection_string_reference { type = string }

variable forum_redis_primary_keyvault_connection_string_reference { type = string }

variable forum_redis_secondary_keyvault_connection_string_reference { type = string }

variable forum_app_config_primary_endpoint { type = string }

variable forum_app_config_secondary_endpoint { type = string }

variable forum_primary_app_configuration_id { type = string }

variable forum_app_insights_instrumentation_key { 
  type      = string 
  sensitive = true
}

variable forum_app_insights_connection_string { 
  type      = string
  sensitive = true
}

variable forum_staging_app_insights_instrumentation_key { 
  type      = string 
  sensitive = true
}

variable forum_staging_app_insights_connection_string { 
  type      = string
  sensitive = true
}