api_forum_application_shared_secret = [
  {
  "api_forum_application_shared_secret" = "$(terraform.api_forum_application_shared_secret)"
  }
 ]
api_govnotify_api_key =  [
  { 
    "api_govnotify_api_key" = "$(terraform.api_govnotify_api_key)"
  }
  ]
api_govnotify_registration_template_id  = [
  {
    "api_govnotify_registration_template_id" = "$(terraform.api_govnotify_registration_template_id)"
  }
  ]
appgw_tls_certificate_base64  = [
  {
    "appgw_tls_certificate_base64" = "$(terraform.appgw_tls_certificate_base64)"
  }
  ]
appgw_tls_certificate_password = [
  {
    "appgw_tls_certificate_password" = "$(terraform.appgw_tls_certificate_password)"
  }
  ]
forum_email_sendgrid_apikey   = [
  {
    "forum_email_sendgrid_apikey" = "$(terraform.forum_email_sendgrid_apikey)"
  }
  ]
sqlserver_active_directory_administrator_objectid = [
  {
    "sqlserver_active_directory_administrator_objectid" = "$(terrform.sqlserver_active_directory_administrator_objectid)"
  }
  ]
sqlserver_admin_password    = [
  {
    "sqlserver_admin_password" = "$(terraformsqlserver_admin_password)"
  }
  ]
sqlserver_admin_user_id    = [
  {
    "sqlserver_admin_user_id" = "$(terraform.sqlserver_admin_user_id)"
  }
  ]
web_cookie_parser_secret    = [
  {
    "web_cookie_parser_secret" = "$(terraform.web_cookie_parser_secret)"
  }
  ]
