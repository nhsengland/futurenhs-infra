# create a subnet into which we will deploy the redis cache.  This subnet can only contain redis services

#resource "azurerm_subnet" "redis" {
#  name                                           = "snet-${lower(var.product_name)}-${lower(var.environment)}-${lower(var.location)}-redis"
#  resource_group_name                            = var.resource_group_name
#  virtual_network_name                           = var.virtual_network_name
#  address_prefixes                               = ["10.0.3.0/24"]

#  enforce_private_link_endpoint_network_policies = false
#  enforce_private_link_service_network_policies  = false

#  subnet delegation for redis is not an option in the portal and I can find no information online that it is needed
#}

resource "azurerm_redis_cache" "forum" {
  name                = "redis-${lower(var.product_name)}-${lower(var.environment)}-${lower(var.location)}-forum"
  location            = var.location
  resource_group_name = var.resource_group_name
  enable_non_ssl_port = false        # enables port 6379 if set to true
  minimum_tls_version = "1.2"

  redis_configuration {
      enable_authentication = true # TODO - might not be necessary in VNet - review when we can

      maxfragmentationmemory_reserved = 50
      maxmemory_reserved = 50
      maxmemory_delta = 50
      maxmemory_policy = "volatile-lru"

      rdb_backup_enabled = false  # TODO - review for production as only supported for premium sku
      #rbd_backup_frequency = "60"
      #rbd_backup_max_snapshot_count = 1
      #rdb_storage_connection_string = null

      aof_backup_enabled = false  # TODO - Enable for production
      #aof_storage_connection_string_0 = null
      #aof_storage_connection_string_1 = null
  }

  patch_schedule {
    day_of_week = "Saturday"
    start_hour_utc = 0  # 12am to 5am
  }

  patch_schedule {
    day_of_week = "Sunday"
    start_hour_utc = 0  # 12am to 5am
  }

  # TODO - Change for production to premium so we can host in our own subnet

  capacity            = 0            # 0-6 (basic/standard) | 1-4 (premium)
  family              = "C"          # C (basic/standard) | P (premium)
  sku_name            = "Standard"   # Basic | Standard | Premium

  # TODO - Implement these bits when we move to Premium and host inside our VNet
  #        see https://docs.microsoft.com/en-us/azure/azure-cache-for-redis/cache-how-to-premium-vnet#outbound-port-requirements
  #        for the inbound/outbound port requirements.  MIght make sense to stand up a new NSG for the subnet and 
  #        open up all the necessary ports in there rather than do so in the main NSG used by the app gw subnet
  #        see https://azure.microsoft.com/en-gb/resources/templates/vnet-nsg-for-redis/ for some ideas

  #private_static_ip_address = null # one should be assigned for us that we can read out (note first 5 ip addresses are reserved so will be something like 10.0.3.5)
  #public_network_access_enabled = true # TODO - change to false when locked down
  #replicas_per_master = ?
  #subnet_id = azurerm_subnet.redis.id
  #zones = [1, 2, 3] # TODO - check when releasing to production if this is yet enabled in UK South
}

data "azurerm_monitor_diagnostic_categories" "redis_forum" {
  resource_id                                  = azurerm_redis_cache.forum.id
}

resource "azurerm_monitor_diagnostic_setting" "redis_forum" {
  name                                         = "redis-forum-diagnostics"
  target_resource_id                           = azurerm_redis_cache.forum.id
  log_analytics_workspace_id                   = var.log_analytics_workspace_resource_id
  storage_account_id                           = var.log_storage_account_id

  dynamic "log" {
    iterator = log_category
    for_each = data.azurerm_monitor_diagnostic_categories.redis_forum.logs

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
    for_each = data.azurerm_monitor_diagnostic_categories.redis_forum.metrics

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

resource "azurerm_key_vault_secret" "redis_primary_forum_connection_string" {
  name                                      = "redis-${var.product_name}-${var.environment}-${var.location}-forum-primary-connection-string"
  value                                     = azurerm_redis_cache.forum.primary_connection_string
  key_vault_id                              = var.key_vault_id

  content_type                              = "text/plain"
  expiration_date                           = timeadd(timestamp(), "87600h")   
}

resource "azurerm_key_vault_secret" "redis_secondary_forum_connection_string" {
  name                                      = "redis-${var.product_name}-${var.environment}-${var.location}-forum-secondary-connection-string"
  value                                     = azurerm_redis_cache.forum.secondary_connection_string
  key_vault_id                              = var.key_vault_id

  content_type                              = "text/plain"
  expiration_date                           = timeadd(timestamp(), "87600h")   
}