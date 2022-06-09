module "forum" {
  source                                                        = "./forum"

  resource_group_name                                           = var.resource_group_name

  location                                                      = var.location
  environment                                                   = var.environment
  product_name                                                  = var.product_name

  application_fqdn                                              = var.application_fqdn

  virtual_network_name                                          = var.virtual_network_name
  virtual_network_application_gateway_subnet_id                 = var.virtual_network_application_gateway_subnet_id
  virtual_network_security_group_id                             = var.virtual_network_security_group_id
  virtual_network_web_app_subnet_id                             = module.web.virtual_network_web_app_subnet_id
  virtual_network_file_server_subnet_id                         = module.files.virtual_network_file_server_subnet_id

  log_storage_account_id                                        = var.log_storage_account_id
  log_storage_account_connection_string                         = var.log_storage_account_connection_string
  log_storage_account_blob_endpoint                             = var.log_storage_account_blob_endpoint
  log_storage_account_container_name                            = var.log_storage_account_container_name

  log_analytics_workspace_resource_id                           = var.log_analytics_workspace_resource_id

  forum_primary_blob_container_endpoint                         = var.forum_primary_blob_container_endpoint
  forum_primary_blob_container_resource_manager_id              = var.forum_primary_blob_container_resource_manager_id
  forum_primary_blob_container_name                             = var.forum_primary_blob_container_name
  forum_primary_blob_keyvault_connection_string_reference       = var.forum_primary_blob_keyvault_connection_string_reference

  forum_app_config_primary_endpoint                             = var.forum_app_config_primary_endpoint
  forum_app_config_secondary_endpoint                           = var.forum_app_config_secondary_endpoint
  forum_primary_app_configuration_id                            = var.forum_primary_app_configuration_id

  forum_email_sendgrid_apikey                                   = var.forum_email_sendgrid_apikey
  forum_email_smtp_from                                         = var.forum_email_smtp_from
  forum_email_smpt_username                                     = var.forum_email_smpt_username

  #forum_redis_primary_keyvault_connection_string_reference      = var.forum_redis_primary_keyvault_connection_string_reference
  #forum_redis_secondary_keyvault_connection_string_reference    = var.forum_redis_secondary_keyvault_connection_string_reference

  forum_db_keyvault_readwrite_connection_string_reference       = var.forum_db_keyvault_readwrite_connection_string_reference
  forum_db_keyvault_readonly_connection_string_reference        = var.forum_db_keyvault_readonly_connection_string_reference

  forum_app_insights_instrumentation_key                        = var.forum_app_insights_instrumentation_key
  forum_app_insights_connection_string                          = var.forum_app_insights_connection_string

  forum_staging_app_insights_instrumentation_key                = var.forum_staging_app_insights_instrumentation_key
  forum_staging_app_insights_connection_string                  = var.forum_staging_app_insights_connection_string

  # TODO - Remove once file server is handling all this file access stuff and legacy removed from forum app
  
  files_blob_primary_endpoint                                   = var.files_blob_primary_endpoint
  files_primary_blob_resource_manager_id                        = var.files_primary_blob_resource_manager_id
  files_primary_blob_container_endpoint                         = var.files_primary_blob_container_endpoint
  files_primary_blob_container_resource_manager_id              = var.files_primary_blob_container_resource_manager_id
  files_primary_blob_container_name                             = var.files_primary_blob_container_name
  files_primary_blob_keyvault_connection_string_reference       = var.files_primary_blob_keyvault_connection_string_reference
}

module "files" {
  source                                                        = "./files"

  application_fqdn                                              = var.application_fqdn
  
  resource_group_name                                           = var.resource_group_name

  location                                                      = var.location
  environment                                                   = var.environment
  product_name                                                  = var.product_name

  virtual_network_name                                          = var.virtual_network_name
  virtual_network_application_gateway_subnet_id                 = var.virtual_network_application_gateway_subnet_id
  virtual_network_security_group_id                             = var.virtual_network_security_group_id

  log_storage_account_id                                        = var.log_storage_account_id
  log_storage_account_connection_string                         = var.log_storage_account_connection_string
  log_storage_account_blob_endpoint                             = var.log_storage_account_blob_endpoint
  log_storage_account_container_name                            = var.log_storage_account_container_name

  log_analytics_workspace_resource_id                           = var.log_analytics_workspace_resource_id

  files_primary_blob_resource_manager_id                        = var.files_primary_blob_resource_manager_id
  files_primary_blob_container_resource_manager_id              = var.files_primary_blob_container_resource_manager_id

  files_blob_primary_endpoint                                   = var.files_blob_primary_endpoint
  files_blob_secondary_endpoint                                 = var.files_blob_secondary_endpoint
  files_blob_container_name                                     = var.files_primary_blob_container_name

  files_primary_table_resource_manager_id                       = var.files_primary_table_resource_manager_id
  
  files_table_primary_endpoint                                  = var.files_table_primary_endpoint
  files_table_secondary_endpoint                                = var.files_table_secondary_endpoint

  files_app_config_primary_endpoint                             = var.files_app_config_primary_endpoint
  files_app_config_secondary_endpoint                           = var.files_app_config_secondary_endpoint
  files_primary_app_configuration_id                            = var.files_primary_app_configuration_id

  files_db_keyvault_readwrite_connection_string_reference       = var.files_db_keyvault_readwrite_connection_string_reference
  files_db_keyvault_readonly_connection_string_reference        = var.files_db_keyvault_readonly_connection_string_reference

  files_app_insights_instrumentation_key                        = var.files_app_insights_instrumentation_key
  files_app_insights_connection_string                          = var.files_app_insights_connection_string

  files_staging_app_insights_instrumentation_key                = var.files_staging_app_insights_instrumentation_key
  files_staging_app_insights_connection_string                  = var.files_staging_app_insights_connection_string
}

module "collabora" {
  source                                                        = "./collabora"
  
  resource_group_name                                           = var.resource_group_name

  location                                                      = var.location
  environment                                                   = var.environment
  product_name                                                  = var.product_name

  virtual_network_name                                          = var.virtual_network_name
  virtual_network_application_gateway_subnet_id                 = var.virtual_network_application_gateway_subnet_id
  virtual_network_security_group_id                             = var.virtual_network_security_group_id

  log_storage_account_id                                        = var.log_storage_account_id
  log_storage_account_connection_string                         = var.log_storage_account_connection_string
  log_storage_account_blob_endpoint                             = var.log_storage_account_blob_endpoint
  log_storage_account_container_name                            = var.log_storage_account_container_name

  log_analytics_workspace_resource_id                           = var.log_analytics_workspace_resource_id

  collabora_app_insights_instrumentation_key                    = var.collabora_app_insights_instrumentation_key
  collabora_app_insights_connection_string                      = var.collabora_app_insights_connection_string

  collabora_staging_app_insights_instrumentation_key            = var.collabora_staging_app_insights_instrumentation_key
  collabora_staging_app_insights_connection_string              = var.collabora_staging_app_insights_connection_string
  collabora_container_registry_url                              = var.collabora_container_registry_url
  collabora_container_registry_username                         = var.collabora_container_registry_username
  collabora_container_registry_password                         = var.collabora_container_registry_password
}

module "api" {
  source                                                        = "./api"

  application_fqdn                                              = var.application_fqdn
  
  resource_group_name                                           = var.resource_group_name

  location                                                      = var.location
  environment                                                   = var.environment
  product_name                                                  = var.product_name

  virtual_network_name                                          = var.virtual_network_name
  virtual_network_application_gateway_subnet_id                 = var.virtual_network_application_gateway_subnet_id
  virtual_network_web_app_subnet_id                             = module.web.virtual_network_web_app_subnet_id
  virtual_network_security_group_id                             = var.virtual_network_security_group_id

  log_storage_account_id                                        = var.log_storage_account_id
  log_storage_account_connection_string                         = var.log_storage_account_connection_string
  log_storage_account_blob_endpoint                             = var.log_storage_account_blob_endpoint
  log_storage_account_container_name                            = var.log_storage_account_container_name

  log_analytics_workspace_resource_id                           = var.log_analytics_workspace_resource_id

  api_app_config_primary_endpoint                               = var.api_app_config_primary_endpoint
  api_app_config_secondary_endpoint                             = var.api_app_config_secondary_endpoint
  api_primary_app_configuration_id                              = var.api_primary_app_configuration_id

  api_db_keyvault_readwrite_connection_string_reference         = var.api_db_keyvault_readwrite_connection_string_reference
  api_db_keyvault_readonly_connection_string_reference          = var.api_db_keyvault_readonly_connection_string_reference

  api_forum_keyvault_application_shared_secret_reference        = var.api_forum_keyvault_application_shared_secret_reference
  api_govnotify_keyvault_api_key_reference                      = var.api_govnotify_keyvault_api_key_reference
  api_govnotify_registration_template_id                        = var.api_govnotify_registration_template_id
  api_govnotify_group_member_comment_on_discussion              = var.api_govnotify_group_member_comment_on_discussion
  api_govnotify_member_response_to_comment                      = var.api_govnotify_member_response_to_comment
  api_govnotify_group_member_request_rejected                   = var.api_govnotify_group_member_request_rejected
  api_govnotify_group_member_request_accepted__platform_user    = var.api_govnotify_group_member_request_accepted__platform_user
  api_govnotify_group_member_request_rejected_platform_user     = var.api_govnotify_group_member_request_rejected_platform_user
  api_govnotify_group_membership_request                        = var.api_govnotify_group_membership_request

  api_app_insights_instrumentation_key                          = var.api_app_insights_instrumentation_key
  api_app_insights_connection_string                            = var.api_app_insights_connection_string

  api_staging_app_insights_instrumentation_key                  = var.api_staging_app_insights_instrumentation_key
  api_staging_app_insights_connection_string                    = var.api_staging_app_insights_connection_string

  api_primary_file_blob_container_endpoint                      = var.api_primary_file_blob_container_endpoint
  api_primary_image_blob_container_endpoint                     = var.api_primary_image_blob_container_endpoint
  api_primary_blob_keyvault_connection_string_reference         = var.api_primary_blob_keyvault_connection_string_reference
}

module "web" {
  source                                                        = "./web"

  application_fqdn                                              = var.application_fqdn
  
  resource_group_name                                           = var.resource_group_name

  location                                                      = var.location
  environment                                                   = var.environment
  product_name                                                  = var.product_name

  virtual_network_name                                          = var.virtual_network_name
  virtual_network_application_gateway_subnet_id                 = var.virtual_network_application_gateway_subnet_id
  virtual_network_security_group_id                             = var.virtual_network_security_group_id

  log_storage_account_id                                        = var.log_storage_account_id
  log_storage_account_connection_string                         = var.log_storage_account_connection_string
  log_storage_account_blob_endpoint                             = var.log_storage_account_blob_endpoint
  log_storage_account_container_name                            = var.log_storage_account_container_name

  log_analytics_workspace_resource_id                           = var.log_analytics_workspace_resource_id

  web_app_config_primary_endpoint                               = var.web_app_config_primary_endpoint
  web_app_config_secondary_endpoint                             = var.web_app_config_secondary_endpoint
  web_primary_app_configuration_id                              = var.web_primary_app_configuration_id

  web_api_keyvault_application_shared_secret_reference          = var.api_forum_keyvault_application_shared_secret_reference

  web_app_insights_instrumentation_key                          = var.web_app_insights_instrumentation_key
  web_app_insights_connection_string                            = var.web_app_insights_connection_string

  web_staging_app_insights_instrumentation_key                  = var.web_staging_app_insights_instrumentation_key
  web_staging_app_insights_connection_string                    = var.web_staging_app_insights_connection_string

  web_cookie_parser_secret                                      = var.web_cookie_parser_secret
  web_next_public_gtm_key                                       = var.web_next_public_gtm_key
}

module "content" {
  source                                                        = "./content"

  application_fqdn                                              = var.application_fqdn
  
  resource_group_name                                           = var.resource_group_name

  location                                                      = var.location
  environment                                                   = var.environment
  product_name                                                  = var.product_name

  virtual_network_name                                          = var.virtual_network_name
  virtual_network_application_gateway_subnet_id                 = var.virtual_network_application_gateway_subnet_id
  virtual_network_api_app_subnet_id                             = module.api.virtual_network_api_app_subnet_id
  virtual_network_security_group_id                             = var.virtual_network_security_group_id

  log_storage_account_id                                        = var.log_storage_account_id
  log_storage_account_connection_string                         = var.log_storage_account_connection_string
  log_storage_account_blob_endpoint                             = var.log_storage_account_blob_endpoint
  log_storage_account_container_name                            = var.log_storage_account_container_name

  log_analytics_workspace_resource_id                           = var.log_analytics_workspace_resource_id

  content_app_config_primary_endpoint                           = var.content_app_config_primary_endpoint
  content_app_config_secondary_endpoint                         = var.content_app_config_secondary_endpoint
  content_primary_app_configuration_id                          = var.content_primary_app_configuration_id

  content_db_keyvault_readwrite_connection_string_reference     = var.content_db_keyvault_readwrite_connection_string_reference

  content_app_insights_instrumentation_key                      = var.content_app_insights_instrumentation_key
  content_app_insights_connection_string                        = var.content_app_insights_connection_string

  content_staging_app_insights_instrumentation_key              = var.content_staging_app_insights_instrumentation_key
  content_staging_app_insights_connection_string                = var.content_staging_app_insights_connection_string

  content_primary_blob_keyvault_connection_string_reference     = var.content_primary_blob_keyvault_connection_string_reference
}