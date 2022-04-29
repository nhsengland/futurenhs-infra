TF_VAR_api_forum_application_shared_secret = [
  {
  api_forum_application_shared_secret = "$(terraform.api_forum_application_shared_secret)"
  }
 ]
TF_VAR_api_govnotify_api_key =  [
  { 
    api_govnotify_api_key = "$(terraform.api_govnotify_api_key)"
  }
  ]
TF_VAR_api_govnotify_registration_template_id  = [
  {
    api_govnotify_registration_template_id = "$(terraform.api_govnotify_registration_template_id)"
  }
  ]
TF_VAR_appgw_tls_certificate_base64  = [
  {
    appgw_tls_certificate_base64 = "$(terraform.appgw_tls_certificate_base64)"
  }
  ]
TF_VAR_APPGW_TLS_CERTIFICATE_PASSWORD = [
  {
    APPGW_TLS_CERTIFICATE_PASSWORD = "$(terraform.appgw_tls_certificate_password)"
  }
  ]
TF_VAR_forum_email_sendgrid_apikey   = [
  {
    forum_email_sendgrid_apikey = "$(terraform.forum_email_sendgrid_apikey)"
  }
  ]
TF_VAR_sqlserver_active_directory_administrator_objectid = [
  {
    sqlserver_active_directory_administrator_objectid = "$(terrform.sqlserver_active_directory_administrator_objectid)"
  }
  ]
TF_VAR_sqlserver_admin_password    = [
  {
    sqlserver_admin_password = "$(terraformsqlserver_admin_password)"
  }
  ]
TF_VAR_sqlserver_admin_user_id    = [
  {
    sqlserver_admin_user_id = "$(terraform.sqlserver_admin_user_id)"
  }
  ]
TF_VAR_web_cookie_parser_secret    = [
  {
    web_cookie_parser_secret = "$(terraform.web_cookie_parser_secret)"
  }
  ]
