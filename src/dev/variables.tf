variable application_fqdn { type = string }

variable location {
  type = string

  validation {
    condition     = contains(["uksouth", "ukwest"], lower(var.location))
    error_message = "Unsupported Azure Region specified. Supported regions include: uksouth, ukwest."
  }
}

variable environment {
  type = string

  validation {
    condition     = contains(["dev", "uat", "pre", "prod"], lower(var.environment))
    error_message = "Unsupported environment specified. Supported environments include: dev, uat, pre, prod."
  }
}

variable product_name {
  type        = string
  description = "The product name to use"
}

variable sqlserver_admin_email {
  type = string
  #sensitive = true

  #validation {
  #  condition     = length(regexall("/^w+[+.w-]*@([w-]+.)*w+[w-]*.([a-z]{2,4}|d+)$/i", var.sqlserver_admin_email)) > 0
  #  error_message = "The sqlserver_admin_email variable must contain an email address."
  #}
}

variable sqlserver_admin_user_id { type = string }

variable sqlserver_admin_password { 
  type = string 
  sensitive = true
}

variable sqlserver_active_directory_administrator_login_name {
  type = string
  #sensitive = true
}

variable sqlserver_active_directory_administrator_objectid {
  type = string
  #sensitive = true
}

variable security_center_contact_email {
  type = string
  #sensitive = true

  #validation {
  #  condition     = length(regexall("/^w+[+.w-]*@([w-]+.)*w+[w-]*.([a-z]{2,4}|d+)$/i", var.sqlserver_admin_email)) > 0
  #  error_message = "The security_center_contact_email variable must contain an email address."
  #}
}

variable security_center_contact_phone {
  type = string
  #sensitive = true
}

variable appgw_tls_certificate_base64 { type = string }

variable appgw_tls_certificate_password { 
    type         = string
    sensitive    = true
}

variable appgw_tls_certificate_content_type { 
  type = string 
  validation {
    condition     = contains(["application/x-pkcs12", "application/x-pem-file"], var.appgw_tls_certificate_content_type)
    error_message = "Unsupported value specified for the certificate content type."
  }
}

variable forum_email_sendgrid_apikey { type = string }

variable forum_email_smtp_from { type = string }

variable forum_email_smpt_username { type = string }

variable api_forum_application_shared_secret { 
    type      = string
    #sensitive = true 
    default = "29f47452-eff9-45c5-9de4-10affac3d862"
}

variable web_cookie_parser_secret { 
    type      = string
    sensitive = true
}

variable api_govnotify_api_key  {
    type      = string
    #sensitive = true 
    default = "dev-86e80710-e986-4edf-b9f2-65779d2fb046-7d70615b-bbf1-4438-bc19-19a357dad191"
}

variable api_govnotify_registration_template_id { type = string }

variable web_next_public_gtm_key { 
    type      = string
    sensitive = true
}
