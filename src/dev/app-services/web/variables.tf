variable application_fqdn { type = string }

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


variable web_cookie_parser_secret { 
    type      = string
    sensitive = true
}

variable web_next_public_gtm_key { 
    type      = string
    sensitive = true
}

variable web_app_config_primary_endpoint { type = string }

variable web_app_config_secondary_endpoint { type = string }

variable web_primary_app_configuration_id { type = string }

variable web_app_insights_connection_string { 
    type      = string 
    sensitive = true
}

variable web_app_insights_instrumentation_key { 
    type      = string 
    sensitive = true
}

variable web_staging_app_insights_connection_string { 
    type      = string 
    sensitive = true
}

variable web_staging_app_insights_instrumentation_key { 
    type      = string 
    sensitive = true
}

variable web_api_keyvault_application_shared_secret_reference { 
    type      = string
    sensitive = true  
}

variable web_nextauth_secret { 
    type      = string
    sensitive = true  
}

variable web_azure_ad_b2c_tenant_name { 
    type      = string
}

variable web_azure_ad_b2c_client_id { 
    type      = string
}

variable web_azure_ad_b2c_client_secret { 
    type      = string
    sensitive = true  
}

variable web_azure_ad_b2c_primary_user_flow { 
    type      = string
}

variable web_azure_ad_b2c_signup_user_flow { 
    type      = string
}