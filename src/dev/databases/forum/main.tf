resource "azurerm_mssql_database" "forum" {
  name                                      = "sqldb-${var.product_name}-${var.environment}-${var.location}-forum"
  server_id                                 = var.sql_server_id
  create_mode                               = "Default"
  sku_name                                  = "ElasticPool" 
  collation                                 = "SQL_LATIN1_GENERAL_CP1_CI_AS"
  elastic_pool_id                           = var.sql_server_elasticpool_id

  zone_redundant                            = false 	# TODO - Needs to be set to true once databases are changed to Premium tier
  #read_scale                                = true      # TODO - Enable in production once we've moved to a Premium or Business Critical tier

  threat_detection_policy {
    state                                   = "Enabled"
    disabled_alerts                         = []
    email_account_admins                    = "Enabled"
    email_addresses                         = [ var.sqlserver_admin_email ]
    retention_days                          = 120
    storage_endpoint                        = var.log_storage_account_blob_endpoint
    storage_account_access_key              = var.log_storage_account_access_key
  }

  short_term_retention_policy {
    retention_days                          = 7 # 1-7 days
  }

  long_term_retention_policy {
    weekly_retention                        = "P1W"
    monthly_retention                       = "P1M"
    yearly_retention                        = "P1Y"
    week_of_year                            = 52
  }
}

# TDE is automatically enabled for all new Azure SQL databases
#resource "azurerm_mssql_server_transparent_data_encryption" "forum" {
#  server_id = azurerm_mssql_server.forum.id
#}

data "azurerm_monitor_diagnostic_categories" "sqldb" {
  resource_id                                  = azurerm_mssql_database.forum.id
}

resource "azurerm_monitor_diagnostic_setting" "sqldb" {
  name                                         = "sqldb-forum-diagnostics"
  target_resource_id                           = azurerm_mssql_database.forum.id
  log_analytics_workspace_id                   = var.log_analytics_workspace_resource_id
  storage_account_id                           = var.log_storage_account_id

  dynamic "log" {
    iterator = log_category
    for_each = data.azurerm_monitor_diagnostic_categories.sqldb.logs

    content {
      category = log_category.value
      enabled  = true

      retention_policy {
        enabled = true
        days    = 90
      }
    }
  }

  dynamic "metric" {
    iterator = metric_category
    for_each = data.azurerm_monitor_diagnostic_categories.sqldb.metrics

    content {
      category = metric_category.value
      enabled  = true

      retention_policy {
        enabled = true
        days    = 90
      }
    }
  }
}

resource "azurerm_key_vault_secret" "sqlserver_primary_forumdb_connection_string" {
  name                                      = "sqldb-${var.product_name}-${var.environment}-${var.location}-forum-connection-string"
  value                                     = "Server=tcp:${var.sql_server_primary_fully_qualified_domain_name},1433;Initial Catalog=sqldb-${var.product_name}-${var.environment}-${var.location}-forum;Persist Security Info=False;User ID=${var.database_login_user};Password=${var.database_login_password};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
  key_vault_id                              = var.key_vault_id

  content_type                              = "text/plain"
  expiration_date                           = timeadd(timestamp(), "87600h")   
}

resource "azurerm_key_vault_secret" "sqlserver_primary_forumdb_readonly_connection_string" {
  name                                      = "sqldb-${var.product_name}-${var.environment}-${var.location}-forum-readonly-connection-string"
  value                                     = "Server=tcp:${var.sql_server_primary_fully_qualified_domain_name},1433;Initial Catalog=sqldb-${var.product_name}-${var.environment}-${var.location}-forum;Persist Security Info=False;User ID=${var.database_login_user};Password=${var.database_login_password};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;ApplicationIntent=ReadOnly;"
  key_vault_id                              = var.key_vault_id

  content_type                              = "text/plain"
  expiration_date                           = timeadd(timestamp(), "87600h")   
}

resource "azurerm_key_vault_secret" "sqlserver_primary_filesdb_connection_string" {
  name                                      = "sqldb-${var.product_name}-${var.environment}-${var.location}-files-readwrite-connection-string"
  value                                     = "Server=tcp:${var.sql_server_primary_fully_qualified_domain_name},1433;Initial Catalog=sqldb-${var.product_name}-${var.environment}-${var.location}-forum;Persist Security Info=False;User ID=${var.database_login_user};Password=${var.database_login_password};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
  key_vault_id                              = var.key_vault_id

  content_type                              = "text/plain"
  expiration_date                           = timeadd(timestamp(), "87600h")   
}

resource "azurerm_key_vault_secret" "sqlserver_primary_filesdb_readonly_connection_string" {
  name                                      = "sqldb-${var.product_name}-${var.environment}-${var.location}-files-readonly-connection-string"
  value                                     = "Server=tcp:${var.sql_server_primary_fully_qualified_domain_name},1433;Initial Catalog=sqldb-${var.product_name}-${var.environment}-${var.location}-forum;Persist Security Info=False;User ID=${var.database_login_user};Password=${var.database_login_password};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;ApplicationIntent=ReadOnly;"
  key_vault_id                              = var.key_vault_id

  content_type                              = "text/plain"
  expiration_date                           = timeadd(timestamp(), "87600h")   
}

resource "azurerm_key_vault_secret" "sqlserver_primary_apidb_connection_string" {
  name                                      = "sqldb-${var.product_name}-${var.environment}-${var.location}-api-readwrite-connection-string"
  value                                     = "Server=tcp:${var.sql_server_primary_fully_qualified_domain_name},1433;Initial Catalog=sqldb-${var.product_name}-${var.environment}-${var.location}-forum;Persist Security Info=False;User ID=${var.database_login_user};Password=${var.database_login_password};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
  key_vault_id                              = var.key_vault_id

  content_type                              = "text/plain"
  expiration_date                           = timeadd(timestamp(), "87600h")   
}

resource "azurerm_key_vault_secret" "sqlserver_primary_apidb_readonly_connection_string" {
  name                                      = "sqldb-${var.product_name}-${var.environment}-${var.location}-api-readonly-connection-string"
  value                                     = "Server=tcp:${var.sql_server_primary_fully_qualified_domain_name},1433;Initial Catalog=sqldb-${var.product_name}-${var.environment}-${var.location}-forum;Persist Security Info=False;User ID=${var.database_login_user};Password=${var.database_login_password};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;ApplicationIntent=ReadOnly;"
  key_vault_id                              = var.key_vault_id

  content_type                              = "text/plain"
  expiration_date                           = timeadd(timestamp(), "87600h")   
}