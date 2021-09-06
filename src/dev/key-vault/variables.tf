#variable host_agent_ip_address { type = string }   # TODO - Some sort of validation to assure format is as we would expect

variable location { type = string }

variable environment { type = string }

variable product_name { type = string }

variable resource_group_name { type = string }

variable principal_id_forum_app_svc { type = string }

variable principal_id_forum_staging_app_svc { type = string }

variable principal_id_files_app_svc { type = string }

variable principal_id_files_staging_app_svc { type = string }

variable principal_id_app_configuration_svc { type = string }

variable principal_id_app_gateway_svc { type = string }

variable log_storage_account_id { type = string }

variable log_analytics_workspace_resource_id { type = string }

variable appgw_tls_certificate_base64 { type = string }

variable appgw_tls_certificate_password { 
    type         = string
    sensitive    = true
}