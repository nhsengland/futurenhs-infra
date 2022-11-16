terraform {
  required_providers {
    akc = {				# using until AzureRM adds support for creating app configuration values
      source = "arkiaconsulting/akc"
    }
  }
}

data "azurerm_client_config" "current" {}

resource "azurerm_app_configuration" "main" {
  name                = "appcs-${var.product_name}-${var.environment}-${var.location}-001"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "free" 				# free | standard  # TODO - use standard for production for more requests, storage and private link support

  identity { 
    type              = "SystemAssigned"
  }
  
  depends_on = [
    azurerm_role_assignment.data-owner
  ]
}

resource "azurerm_role_assignment" "data-owner" {
  scope                = azurerm_app_configuration.main.id
  role_definition_name = "App Configuration Data Owner"
  principal_id         = data.azurerm_client_config.current.object_id
}

# TODO - Confirm this can be removed - think it is now redundant
resource "azurerm_key_vault_secret" "appconfig_primary_forum_connection_string" {
  name                                      = "appcs-${var.product_name}-${var.environment}-${var.location}-forum-connection-string"
  value                                     = azurerm_app_configuration.main.primary_read_key.0.connection_string
  key_vault_id                              = var.key_vault_id

  content_type                              = "text/plain"
  expiration_date                           = timeadd(timestamp(), "87600h")   
}

data "azurerm_monitor_diagnostic_categories" "main" {
  resource_id                                  = azurerm_app_configuration.main.id
}

resource "azurerm_monitor_diagnostic_setting" "main" {
  name                                         = "appcs-diagnostics"
  target_resource_id                           = azurerm_app_configuration.main.id
  log_analytics_workspace_id                   = var.log_analytics_workspace_resource_id
  storage_account_id                           = var.log_storage_account_id

  dynamic "log" {
    iterator = log_category
    for_each = data.azurerm_monitor_diagnostic_categories.main.logs

    content {
      category = log_category.value
      enabled  = true

      retention_policy {
        enabled = true
        days    = 7        # TODO - Increase for production or set to 0 for infinite retention
      }
    }
  }

  dynamic "metric" {
    iterator = metric_category
    for_each = data.azurerm_monitor_diagnostic_categories.main.metrics

    content {
      category = metric_category.value
      enabled  = true

      retention_policy {
        enabled = true
        days    = 7        # TODO - Increase for production or set to 0 for infinite retention
      }
    }
  }
}

resource "azurerm_app_configuration_feature" "SelfRegister" {
  configuration_store_id = azurerm_app_configuration.main.id
  description            = "Controls if users can self register on the platform"
  name                   = "SelfRegistration"
  label                  = "SelfRegistration"
  enabled                = var.self_register
}


# TODO - Comment back in once the terraform state file has been fixed by importing these resources

# Give current identity the relevant permission to add new key values - unless we can figure out how to use connection string

#resource "azurerm_role_assignment" "data-owner" {
#  scope                = azurerm_app_configuration.main.id
#  role_definition_name = "App Configuration Data Owner"
#  principal_id         = data.azurerm_client_config.current.object_id
#}





# TODO - Falls over with a connection error - investigate and fix, else fallback to using a null_resource executing an az cli script

# Add the sentinel keys.  Apps can watch these to keep track of when it changes so it knows when to refresh it's configuration (rather than tracking each value independently)
# https://github.com/arkiaconsulting/terraform-provider-akc
# TODO - AzureRM doesn't support doing this so temporarily using a custom provider to handle it for us

#resource "akc_key_value" "forum-sentinel-key" {
#  endpoint            = azurerm_app_configuration.main.endpoint   # shoudl we use connection string instead?
#  label               = var.environment
#  key                 = "Forum_SentinelKey"
#  value               = "1"
#
#  lifecycle {
#    ignore_changes = [
#      value
#    ]
#  }
#
#  depends_on = [
#    azurerm_role_assignment.data-owner
#  ]
#}