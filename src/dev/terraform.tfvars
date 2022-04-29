TF_VAR_API_FORUM_APPLICATION_SHARED_SECRET = [
  {
  api_forum_application_shared_secret = "$(terraform.api_forum_application_shared_secret)"
  }
 ]
TF_VA_RAPI_GOVNOTIFY_API_KEY =  [
  { 
    api_govnotify_api_key = "$(terraform.api_govnotify_api_key)"
  }
  ]
TF_VAR_API_GOVNOTIFY_REGISTRATION_TEMPLATE_ID  = [
  {
    api_govnotify_registration_template_id = "$(terraform.api_govnotify_registration_template_id)"
  }
  ]
TF_VAR_APPGW_TLS_CERTIFICATE_BASE64  = [
  {
    appgw_tls_certificate_base64 = "$(terraform.appgw_tls_certificate_base64)"
  }
  ]
TF_VAR_APPGW_TLS_CERTIFICATE_PASSWORD = [
  {
    appgw_tls_certificate_password = "$(terraform.appgw_tls_certificate_password)"
  }
  ]
TF_VAR_FORUM_EMAIL_SENDGRID_APIKEY   = [
  {
    forum_email_sendgrid_apikey = "$(terraform.forum_email_sendgrid_apikey)"
  }
  ]
TF_VAR_SQLSERVER_ACTIVE_DIRECTORY_ADMINISTRATOR_OBJECTID = [
  {
    sqlserver_active_directory_administrator_objectid = "$(terrform.sqlserver_active_directory_administrator_objectid)"
  }
  ]
TF_VAR_SQLSERVER_ADMIN_PASSWORD    = [
  {
    sqlserver_admin_password = "$(terraformsqlserver_admin_password)"
  }
  ]
TF_VAR_SQLSERVER_ADMIN_USER_ID     = [
  {
    sqlserver_admin_user_id = "$(terraform.sqlserver_admin_user_id)"
  }
  ]
TF_VAR_WEB_COOKIE_PARSER_SECRET    = [
  {
    web_cookie_parser_secret = "$(terraform.web_cookie_parser_secret)"
  }
  ]
