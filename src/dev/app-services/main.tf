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
}