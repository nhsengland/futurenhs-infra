variable location { type = string }

variable environment { type = string }

variable product_name { type = string }

variable resource_group_name { type = string }

variable virtual_network_security_group_id { type = string }

variable virtual_network_name { type = string }

variable virtual_network_application_gateway_subnet_id { type = string }

variable log_storage_account_id { type = string }

variable log_storage_account_connection_string { type = string }

variable log_storage_account_container_name { type = string }

variable log_storage_account_blob_endpoint { type = string }

variable log_analytics_workspace_resource_id { type = string }

variable collabora_app_insights_connection_string { 
    type      = string 
    sensitive = true
}

variable collabora_app_insights_instrumentation_key { 
    type      = string 
    sensitive = true
}

variable collabora_staging_app_insights_connection_string { 
    type      = string 
    sensitive = true
}

variable collabora_staging_app_insights_instrumentation_key { 
    type      = string 
    sensitive = true
}

variable collabora_container_registry_url { 
    type      = string 
}

variable collabora_container_registry_username { 
    type      = string 
    sensitive = true
}

variable collabora_container_registry_password { 
    type      = string 
    sensitive = true
}
