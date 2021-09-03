resource "azurerm_network_watcher" "main" {
  name                      = "nww-${lower(var.product_name)}-${lower(var.environment)}-${lower(var.location)}-001"
  location                  = var.location
  resource_group_name       = var.resource_group_name
}

resource "azurerm_virtual_network" "main" {
  name                      = "vnet-${lower(var.product_name)}-${lower(var.environment)}-${lower(var.location)}-001"
  location                  = azurerm_network_watcher.main.location
  resource_group_name       = azurerm_network_watcher.main.resource_group_name
  address_space             = ["10.0.0.0/16"]
}

data "azurerm_monitor_diagnostic_categories" "vnet" {
  resource_id                                  = azurerm_virtual_network.main.id
}

resource "azurerm_monitor_diagnostic_setting" "vnet" {
  name                                         = "vnet-diagnostics"
  target_resource_id                           = azurerm_virtual_network.main.id
  log_analytics_workspace_id                   = var.log_analytics_workspace_resource_id
  storage_account_id                           = var.log_storage_account_id

  dynamic "log" {
    iterator = log_category
    for_each = data.azurerm_monitor_diagnostic_categories.vnet.logs

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
    for_each = data.azurerm_monitor_diagnostic_categories.vnet.metrics

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