module "collabora_production_slot" {
  source                                      = "./production"

  resource_group_name                         = var.resource_group_name

  application_fqdn                            = var.application_fqdn

  location                                    = var.location
  environment                                 = var.environment
  product_name                                = var.product_name

  log_storage_account_id                      = var.log_storage_account_id
  log_analytics_workspace_resource_id         = var.log_analytics_workspace_resource_id
}

module "collabora_staging_slot" {
  source                                      = "./staging"

  resource_group_name                         = var.resource_group_name

  location                                    = var.location
  environment                                 = var.environment
  product_name                                = var.product_name

  log_storage_account_id                      = var.log_storage_account_id
  log_analytics_workspace_resource_id         = var.log_analytics_workspace_resource_id
}