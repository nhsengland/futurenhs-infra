variable "application_fqdn" { type = string }

variable "location" {
  type = string

  validation {
    condition     = contains(["uksouth", "ukwest"], lower(var.location))
    error_message = "Unsupported Azure Region specified. Supported regions include: uksouth, ukwest."
  }
}

variable "environment" {
  type = string

  validation {
    condition     = contains(["dev", "uat", "pre", "prod"], lower(var.environment))
    error_message = "Unsupported environment specified. Supported environments include: dev, uat, pre, prod."
  }
}

variable "product_name" {
  type        = string
  description = "The product name to use"
}

variable "sqlserver_admin_email" {
  type = string
  #sensitive = true

  #validation {
  #  condition     = length(regexall("/^w+[+.w-]*@([w-]+.)*w+[w-]*.([a-z]{2,4}|d+)$/i", var.sqlserver_admin_email)) > 0
  #  error_message = "The sqlserver_admin_email variable must contain an email address."
  #}
}

variable "sqlserver_admin_user_id" { type = string }

variable "sqlserver_admin_password" {
  type      = string
  sensitive = true
}

variable "sqlserver_active_directory_administrator_login_name" {
  type = string
  #sensitive = true
}

variable "sqlserver_active_directory_administrator_objectid" {
  type = string
  #sensitive = true
}

variable "security_center_contact_email" {
  type = string
  #sensitive = true

  #validation {
  #  condition     = length(regexall("/^w+[+.w-]*@([w-]+.)*w+[w-]*.([a-z]{2,4}|d+)$/i", var.sqlserver_admin_email)) > 0
  #  error_message = "The security_center_contact_email variable must contain an email address."
  #}
}

variable "security_center_contact_phone" {
  type = string
  #sensitive = true
}

variable "appgw_tls_certificate_base64" { type = string }

variable "appgw_tls_certificate_password" {
  type      = string
  sensitive = true
}

variable "appgw_tls_certificate_content_type" {
  type = string
  validation {
    condition     = contains(["application/x-pkcs12", "application/x-pem-file"], var.appgw_tls_certificate_content_type)
    error_message = "Unsupported value specified for the certificate content type."
  }
}

variable "forum_email_sendgrid_apikey" { type = string }

variable "forum_email_smtp_from" { type = string }

variable "forum_email_smpt_username" { type = string }

variable "api_forum_application_shared_secret" {
  type      = string
  sensitive = true
}

variable "web_cookie_parser_secret" {
  type      = string
  sensitive = true
}

variable "api_govnotify_api_key" {
  type      = string
  sensitive = true
}

variable "api_govnotify_registration_template_id" { type = string }

variable "web_next_public_gtm_key" {
  type      = string
  sensitive = true
}
variable "api_govnotify_group_member_comment_on_discussion" {
  type      = string
  sensitive = true
}

variable "api_govnotify_member_response_to_comment" {
  type      = string
  sensitive = true
}
variable "api_govnotify_group_member_request_rejected" {
  type      = string
  sensitive = true
}
variable "api_govnotify_group_member_request_accepted__platform_user" {
  type      = string
  sensitive = true
}
variable "api_govnotify_group_member_request_rejected_platform_user" {
  type      = string
  sensitive = true
}
variable "api_govnotify_group_membership_request" {
  type      = string
  sensitive = true
}
variable "api_govnotify_group_registration_template_id" { type = string }

variable "api_govnotify_group_invite_template_id" { type = string }

variable "b2c_domain_name" {
  type = string
}

variable "b2c_application_name" {
  type = string
}

variable "tenant_id" {
  type = string
}

variable "web_nextauth_secret" {
  type      = string
  sensitive = true
}

variable "web_azure_ad_b2c_tenant_name" {
  type = string
}

variable "web_azure_ad_b2c_client_id" {
  type = string
}

variable "web_azure_ad_b2c_client_secret" {
  type      = string
  sensitive = true
}

variable "web_azure_ad_b2c_primary_user_flow" {
  type = string
}

variable "web_azure_ad_b2c_signup_user_flow" {
  type = string
}

variable "web_azure_ad_b2c_password_reset_user_flow" {
  type = string
}

variable "app_configuration_self_register" {
  type = bool
}

variable "app_configuration_group_invite" {
  type = bool
}
