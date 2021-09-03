# We need 'Read directory data' permissions within the 'Windows Azure Active Directory' API
# see https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/user for more info

# TODO - Having some grief trying to ascertain the correct privileges needed by the deployment pipeline host in order
#        to access the MS Graph and pull out AAD ids.  Followed about referenced docs to no avail.  Parking for now
#        and object_id being passed in as variable, but revisit in future when time allows as this is the preferred
#        method

#data "azuread_user" "azuread_administrator" {
#  user_principal_name = var.sqlserver_active_directory_administrator_login_name
#}

resource "random_password" "sqlserver_admin_user" {
  length                                        = 20
  special                                       = true
}

resource "azurerm_key_vault_secret" "sqlserver_admin_user" {
  name                                          = "${lower(var.product_name)}-${lower(var.environment)}-${lower(var.location)}-sqlserver-adminuser"
  value                                         = random_password.sqlserver_admin_user.result
  key_vault_id                                  = var.key_vault_id

  content_type                                  = "text/plain"
  expiration_date                               = timeadd(timestamp(), "87600h")   

  lifecycle {
    ignore_changes = [
      value
    ]
  }
}

resource "random_password" "sqlserver_admin_pwd" {
  length                                        = 20
  special                                       = true
  min_lower                                     = 1
  min_upper                                     = 1
  min_special                                   = 1
  min_numeric                                   = 1
}
	
resource "azurerm_key_vault_secret" "sqlserver_admin_pwd" {
  name                                          = "${lower(var.product_name)}-${lower(var.environment)}-${lower(var.location)}-sqlserver-adminpwd"
  value                                         = random_password.sqlserver_admin_pwd.result
  key_vault_id                                  = var.key_vault_id

  content_type                                  = "text/plain"
  expiration_date                               = timeadd(timestamp(), "87600h")   

  lifecycle {
    ignore_changes = [
      value
    ]
  }
}


# All Azure SQL databases are automatically backed up to RA-GRS by the server.

resource "azurerm_mssql_server" "primary" {
  #checkov:skip=CKV_AZURE_23:The sql server configures auditing using a separate azurerm_mssql_server_extended_auditing_policy resource that Checkov doesn't seem to be considering
  #checkov:skip=CKV_AZURE_24:The sql server configures auditing using a separate azurerm_mssql_server_extended_auditing_policy resource that Checkov doesn't seem to be considering
  name                                          = "sql-${lower(var.product_name)}-${lower(var.environment)}-${lower(var.location)}-primary"
  resource_group_name                           = var.resource_group_name
  location                                      = var.location
  version                                       = "12.0"
  connection_policy                             = "Default"
  administrator_login                           = azurerm_key_vault_secret.sqlserver_admin_user.value
  administrator_login_password                  = azurerm_key_vault_secret.sqlserver_admin_pwd.value
  minimum_tls_version                           = "1.2"

  public_network_access_enabled                 = true # TODO - Remove this for production configuration and lock down with firewall rules etc

  identity {
    type = "SystemAssigned"
  }

  azuread_administrator {
    #login_username = data.azuread_user.azuread_administrator.user_principal_name
    #object_id      = data.azuread_user.azuread_administrator.id 
    login_username = var.sqlserver_active_directory_administrator_login_name
    object_id      = var.sqlserver_active_directory_administrator_objectid
  }
}

resource "azurerm_role_assignment" "primary_sql_server_blob_data_contributor" {
  scope                = var.log_storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_mssql_server.primary.identity.0.principal_id
}

resource "azurerm_mssql_server_extended_auditing_policy" "primary" {
  server_id                                     = azurerm_mssql_server.primary.id
  storage_endpoint                              = var.log_storage_account_blob_endpoint
  storage_account_access_key                    = var.log_storage_account_access_key
  storage_account_access_key_is_secondary       = false
  retention_in_days                             = 120
  log_monitoring_enabled                        = true 
  
}

resource "azurerm_mssql_server_security_alert_policy" "primary" {
  #checkov:skip=CKV2_AZURE_3:The recurring_scans policy is handled by the azurerm_mssql_server_vulnerability_assessment.primary resource
  resource_group_name                           = var.resource_group_name
  server_name                                   = azurerm_mssql_server.primary.name
  state                                         = "Enabled"
  email_account_admins                          = true
  email_addresses                               = [ var.sqlserver_admin_email ]   
}

resource "azurerm_mssql_server_vulnerability_assessment" "primary" {
  server_security_alert_policy_id               = azurerm_mssql_server_security_alert_policy.primary.id
  storage_container_path                        = "${var.log_storage_account_blob_endpoint}${var.log_storage_account_sql_server_vulnerability_assessments_container_name}/"
  storage_account_access_key                    = var.log_storage_account_access_key
  
  recurring_scans {
    enabled                   = true
    email_subscription_admins = true
    emails = [
      var.sqlserver_admin_email
    ]
  }
}

# https://docs.microsoft.com/en-us/rest/api/sql/firewallrules/createorupdate
resource "azurerm_mssql_firewall_rule" "firewall_rule_1" {
  name                                         = "sqlfwr-${var.product_name}-${var.environment}-${var.location}-001"
  server_id                                    = azurerm_mssql_server.primary.id
  start_ip_address                             = "0.0.0.0"
  end_ip_address                               = "0.0.0.0"
}

data "azurerm_mssql_database" "master" {
  name                                         = "master"
  server_id                                    = azurerm_mssql_server.primary.id
}

# TODO - works ok first run then terraform tries to recreate it each time which leads to an error
#        need to figure out why it thinks it needs recreating and comment the below setting back in

#data "azurerm_monitor_diagnostic_categories" "master" {
#  resource_id                                  = data.azurerm_mssql_database.master.id
#}

#resource "azurerm_monitor_diagnostic_setting" "master" {
#  name                                         = "sqldb-master-diagnostics"
#  target_resource_id                           = data.azurerm_mssql_database.master.id
#  log_analytics_workspace_id                   = var.log_analytics_workspace_resource_id
#  storage_account_id                           = var.log_storage_account_id

#  dynamic "log" {
#    iterator = log_category
#    for_each = data.azurerm_monitor_diagnostic_categories.master.logs

#    content {
#      category = log_category.value
#      enabled  = true

#      retention_policy {
#        enabled = true
#        days    = 90        # Set to 0 for infinite retention
#      }
#    }
#  }

#  dynamic "metric" {
#    iterator = metric_category
#    for_each = data.azurerm_monitor_diagnostic_categories.master.metrics

#    content {
#      category = metric_category.value
#      enabled  = true

#      retention_policy {
#        enabled = true
#        days    = 90        # Set to 0 for infinite retention
#      }
#    }
#  }
#}




# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/mssql_elasticpool
resource "azurerm_mssql_elasticpool" "primary" {
  name                                          = "sqlep-${var.product_name}-${var.environment}-${var.location}-primary"
  resource_group_name                           = var.resource_group_name
  location                                      = var.location
  server_name                                   = azurerm_mssql_server.primary.name
  license_type                                  = "LicenseIncluded" # LicenseIncluded | BasePrice
  max_size_gb                                   = 4.8828125		# 756
  zone_redundant                                = false	

  sku {
    name                                        = "BasicPool" 	# "GP_Gen5"
    tier                                        = "Basic" 		#"GeneralPurpose"
    #family                                      = "Gen5"
    capacity                                    = 50		#4 
  }

  per_database_settings {
    min_capacity                                = 5			# 0.25
    max_capacity                                = 5			# 4
  }

  lifecycle {
    ignore_changes = [
      license_type
    ]
  }
}

data "azurerm_monitor_diagnostic_categories" "sqlep" {
  resource_id                                  = azurerm_mssql_elasticpool.primary.id
}

resource "azurerm_monitor_diagnostic_setting" "sqlep" {
  name                                         = "sqlep-diagnostics"
  target_resource_id                           = azurerm_mssql_elasticpool.primary.id
  log_analytics_workspace_id                   = var.log_analytics_workspace_resource_id
  storage_account_id                           = var.log_storage_account_id
  
  dynamic "log" {
    iterator = log_category
    for_each = data.azurerm_monitor_diagnostic_categories.sqlep.logs

    content {
      category = log_category.value
      enabled  = true

      retention_policy {
        enabled = true
        days    = 90        # Set to 0 for infinite retention
      }
    }
  }

  dynamic "metric" {
    iterator = metric_category
    for_each = data.azurerm_monitor_diagnostic_categories.sqlep.metrics

    content {
      category = metric_category.value
      enabled  = true

      retention_policy {
        enabled = true
        days    = 90        # Set to 0 for infinite retention
      }
    }
  }
}




module "forum" {
  source = "./forum"

  resource_group_name                            = var.resource_group_name

  location                                       = var.location
  environment                                    = var.environment
  product_name                                   = var.product_name

  key_vault_id                                   = var.key_vault_id

  log_analytics_workspace_resource_id            = var.log_analytics_workspace_resource_id

  log_storage_account_id                         = var.log_storage_account_id
  log_storage_account_blob_endpoint              = var.log_storage_account_blob_endpoint
  log_storage_account_access_key                 = var.log_storage_account_access_key

  sql_server_id                                  = azurerm_mssql_server.primary.id
  sql_server_elasticpool_id                      = azurerm_mssql_elasticpool.primary.id
  sqlserver_admin_email                          = var.sqlserver_admin_email

  sql_server_primary_fully_qualified_domain_name = azurerm_mssql_server.primary.fully_qualified_domain_name

  # TODO - Change below to use none admin credentials when forum up and running and access rights are understood.  Using admin credentials is no good!

  database_login_user                            = azurerm_mssql_server.primary.administrator_login
  database_login_password                        = azurerm_mssql_server.primary.administrator_login_password
}

