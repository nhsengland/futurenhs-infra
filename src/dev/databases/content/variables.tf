variable location { type = string }

variable environment { type = string }

variable product_name { type = string }

variable resource_group_name { type = string }

variable key_vault_id { type = string }

variable log_storage_account_id { type = string }

variable log_analytics_workspace_resource_id { type = string }

variable sql_server_id { type = string }

variable sql_server_elasticpool_id { type = string }

variable sql_server_primary_fully_qualified_domain_name { type = string }

variable sqlserver_admin_email { 
  type            = string 
  #sensitive       = true
}

variable log_storage_account_blob_endpoint { 
  type            = string 
  #sensitive       = true
}

variable log_storage_account_access_key { 
  type            = string
  #sensitive       = true
}

variable database_login_user { 
  type            = string
  #sensitive       = true
}

variable database_login_password { 
  type            = string
  #sensitive       = true
}