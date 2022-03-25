variable application_fqdn { type = string }

variable location { type = string }

variable environment { type = string }

variable product_name { type = string }

variable resource_group_name { type = string }

variable virtual_network_security_group_id { type = string }

variable virtual_network_name { type = string }

variable virtual_network_application_gateway_subnet_id { type = string }

variable virtual_network_web_app_subnet_id {type = string }

variable log_storage_account_id { type = string }

variable log_storage_account_connection_string { type = string }

variable log_storage_account_container_name { type = string }

variable log_storage_account_blob_endpoint { type = string }

variable log_analytics_workspace_resource_id { type = string }


variable api_db_keyvault_readwrite_connection_string_reference { type = string }

variable api_db_keyvault_readonly_connection_string_reference { type = string }

variable api_app_config_primary_endpoint { type = string }

variable api_app_config_secondary_endpoint { type = string }

variable api_primary_app_configuration_id { type = string }

variable api_primary_blob_keyvault_connection_string_reference { type = string }

variable api_primary_file_blob_container_endpoint { type = string }

variable api_primary_image_blob_container_endpoint { type = string }

variable api_app_insights_connection_string { 
    type      = string 
    sensitive = true
}

variable api_app_insights_instrumentation_key { 
    type      = string 
    sensitive = true
}

variable api_staging_app_insights_connection_string { 
    type      = string 
    sensitive = true
}

variable api_staging_app_insights_instrumentation_key { 
    type      = string 
    sensitive = true
}

variable api_forum_keyvault_application_shared_secret_reference { 
    type      = string
    sensitive = true  
}