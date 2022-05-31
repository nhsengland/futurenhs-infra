variable application_fqdn { type = string }

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

variable log_storage_account_blob_endpoint {type = string }

variable log_storage_account_container_name { type = string }

variable log_storage_account_id { type = string }

variable log_analytics_workspace_resource_id { type = string }



variable forum_db_keyvault_readwrite_connection_string_reference { type = string }

variable forum_db_keyvault_readonly_connection_string_reference { type = string }

variable forum_primary_blob_container_endpoint { type = string }

variable forum_primary_blob_container_resource_manager_id { type = string }

variable forum_primary_blob_container_name { type = string }

variable forum_primary_blob_keyvault_connection_string_reference { type = string }

variable forum_app_config_primary_endpoint { type = string }

variable forum_app_config_secondary_endpoint { type = string }

variable forum_primary_app_configuration_id { type = string }

#variable forum_redis_primary_keyvault_connection_string_reference { type = string }

#variable forum_redis_secondary_keyvault_connection_string_reference { type = string }

variable forum_email_sendgrid_apikey { type = string }

variable forum_email_smtp_from { type = string }

variable forum_email_smpt_username { type = string }

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


variable files_primary_blob_resource_manager_id { type = string }

variable files_primary_blob_container_endpoint { type = string }

variable files_primary_blob_container_resource_manager_id { type = string }

variable files_primary_blob_container_name { type = string }


variable files_blob_primary_endpoint { type = string }

variable files_blob_secondary_endpoint { type = string }

variable files_blob_container_name { type = string }


variable files_primary_table_resource_manager_id { type = string }


variable files_table_primary_endpoint { type = string }

variable files_table_secondary_endpoint { type = string }


variable files_db_keyvault_readwrite_connection_string_reference { type = string }

variable files_db_keyvault_readonly_connection_string_reference { type = string }

variable files_primary_blob_keyvault_connection_string_reference { type = string }  // TODO - retire once removed from forum


variable files_app_config_primary_endpoint { type = string }

variable files_app_config_secondary_endpoint { type = string }

variable files_primary_app_configuration_id { type = string }

variable files_app_insights_instrumentation_key { 
  type      = string 
  sensitive = true
}

variable files_app_insights_connection_string { 
  type      = string
  sensitive = true
}

variable files_staging_app_insights_instrumentation_key { 
  type      = string 
  sensitive = true
}

variable files_staging_app_insights_connection_string { 
  type      = string
  sensitive = true
}




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


variable api_db_keyvault_readwrite_connection_string_reference { type = string }

variable api_db_keyvault_readonly_connection_string_reference { type = string }

variable api_app_config_primary_endpoint { type = string }

variable api_app_config_secondary_endpoint { type = string }

variable api_primary_app_configuration_id { type = string }

variable api_primary_blob_keyvault_connection_string_reference  { type = string }

variable api_primary_file_blob_container_endpoint { type = string }

variable api_primary_image_blob_container_endpoint { type = string }

variable api_app_insights_instrumentation_key { 
  type      = string 
  sensitive = true
}

variable api_app_insights_connection_string { 
  type      = string
  sensitive = true
}

variable api_staging_app_insights_instrumentation_key { 
  type      = string 
  sensitive = true
}

variable api_staging_app_insights_connection_string { 
  type      = string
  sensitive = true
}

variable api_forum_keyvault_application_shared_secret_reference { 
    type      = string
    sensitive = true  
}

variable api_govnotify_keyvault_api_key_reference  {
    type      = string
    sensitive = true 
}

variable api_govnotify_registration_template_id { type = string }

variable api_govnotify_group_member_comment_on_discussion { 
  type      = string
}

variable api_govnotify_member_response_to_comment { 
  type      = string
}
variable api_govnotify_group_member_request_rejected { 
   type      = string
}
variable api_govnotify_group_member_request_accepted__platform_user { 
  type      = string
}
variable api_govnotify_group_member_request_rejected_platform_user { 
   type      = string
}
variable api_govnotify_group_membership_request { 
   type      = string
}

variable web_app_config_primary_endpoint { type = string }

variable web_app_config_secondary_endpoint { type = string }

variable web_primary_app_configuration_id { type = string }

variable web_app_insights_instrumentation_key { 
  type      = string 
  sensitive = true
}

variable web_app_insights_connection_string { 
  type      = string
  sensitive = true
}

variable web_staging_app_insights_instrumentation_key { 
  type      = string 
  sensitive = true
}

variable web_staging_app_insights_connection_string { 
  type      = string
  sensitive = true
}

variable web_cookie_parser_secret { 
    type      = string
    sensitive = true
}

variable web_next_public_gtm_key { 
    type      = string
    sensitive = true
}

variable content_db_keyvault_readwrite_connection_string_reference { type = string }

variable content_app_config_primary_endpoint { type = string }

variable content_app_config_secondary_endpoint { type = string }

variable content_primary_app_configuration_id { type = string }

variable content_primary_blob_keyvault_connection_string_reference { type = string }

variable content_app_insights_connection_string { 
    type      = string 
    sensitive = true
}

variable content_app_insights_instrumentation_key { 
    type      = string 
    sensitive = true
}

variable content_staging_app_insights_connection_string { 
    type      = string 
    sensitive = true
}

variable content_staging_app_insights_instrumentation_key { 
    type      = string 
    sensitive = true
}
