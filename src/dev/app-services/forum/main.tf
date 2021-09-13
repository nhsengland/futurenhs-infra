data "azurerm_storage_account_blob_container_sas" "forum_logs" {
  connection_string                         = var.log_storage_account_connection_string
  container_name                            = var.log_storage_account_container_name
  https_only                                = true

  start                                     = timestamp()
  expiry                                    = timeadd(timestamp(), "876000h")	# 100 years - TODO - confused why we have to use a SAS token for this given it expires.  Don't do this in the portal.

  permissions {
    read                                    = true
    add                                     = true
    create                                  = true
    write                                   = true
    delete                                  = true
    list                                    = true
  }
}

resource "azurerm_app_service_plan" "forum" {
  name                                      = "plan-${lower(var.product_name)}-${lower(var.environment)}-${lower(var.location)}-forum"
  location                                  = var.location
  resource_group_name                       = var.resource_group_name
  kind                                      = "Windows"
  per_site_scaling                          = true
  reserved                                  = false  

  sku {
    tier                                    = "PremiumV2" # "Standard" - needed for deployment slots, auto-scaling and vnet integration
    size                                    = "P1v3" # 8GB RAM,2vCPU, 195ACU/vCPU
    capacity                                = 1 # TODO - Change to 3 for production
  }

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

data "azurerm_monitor_diagnostic_categories" "plan" {
  resource_id                                  = azurerm_app_service_plan.forum.id
}

resource "azurerm_monitor_diagnostic_setting" "plan" {
  name                                         = "plan-forum-diagnostics"
  target_resource_id                           = azurerm_app_service_plan.forum.id
  log_analytics_workspace_id                   = var.log_analytics_workspace_resource_id
  storage_account_id                           = var.log_storage_account_id

  dynamic "log" {
    iterator = log_category
    for_each = data.azurerm_monitor_diagnostic_categories.plan.logs

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
    for_each = data.azurerm_monitor_diagnostic_categories.plan.metrics

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


resource "azurerm_app_service" "forum" {
  #checkov:skip=CKV_AZURE_13:Authentication is taken care of by the application and we do not need to use the federation services provided by Azure
  name                                      = "app-${lower(var.product_name)}-${lower(var.environment)}-${lower(var.location)}-forum"
  location                                  = var.location
  resource_group_name                       = var.resource_group_name
  app_service_plan_id                       = azurerm_app_service_plan.forum.id

  enabled                                   = true
  client_affinity_enabled                   = false
  client_cert_enabled                       = false
  https_only                                = true
  
  identity {
    type                                    = "SystemAssigned"
  }

  site_config {
    always_on                               = true
    dotnet_framework_version                = "v4.0"
    remote_debugging_enabled                = false
    remote_debugging_version                = "VS2019"
    ftps_state                              = "Disabled"
    health_check_path                       = "api/HealthCheck/heartbeat"
    http2_enabled                           = true
    ip_restriction                          = [
      {
        name                                = "VirtualNetworkAllowInbound"
        priority                            = "1"
        action                              = "Allow"
        virtual_network_subnet_id           = var.virtual_network_application_gateway_subnet_id
        ip_address                          = null
        headers                             = null
        service_tag                         = null
      }
    ] 
    scm_use_main_ip_restriction             = false   # setting this to true will cause deployment issues unless the azdo pool is granted access
    scm_ip_restriction                      = []
    local_mysql_enabled                     = false
    managed_pipeline_mode                   = "Integrated"
    min_tls_version                         = "1.2"
    scm_type                                = "None"
    use_32_bit_worker_process               = false
    websockets_enabled                      = false
  }

  app_settings = {
    "ASPNET_ENV"                            = var.environment                                   # this value will be used to match with the label on the environment specific configuration in the azure app config service
    "ASPNETCORE_ENVIRONMENT"                = var.environment                                   # this value will be used to match with the label on the environment specific configuration in the azure app config service
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = var.forum_app_insights_connection_string

    # Enable app service profiling - 
    # see https://docs.microsoft.com/en-us/azure/azure-monitor/app/profiler-overview
    # and https://docs.microsoft.com/en-us/azure/azure-monitor/app/profiler?toc=/azure/azure-monitor/toc.json 
   
    "APPINSIGHTS_INSTRUMENTATIONKEY"        = var.forum_app_insights_instrumentation_key
    "APPINSIGHTS_PROFILERFEATURE_VERSION"   = "1.0.0"
    "DiagnosticServices_EXTENSION_VERSION"  = "~3"

    # Because we are going to configure vnet integration for this app service, and because by default only RFC1918 traffic
    # will be routed through it, we need to set a configuration value to assure all other traffic is also sent through the 
    # vnet so we can restrict outbound traffic using a network security group on the sub domain hosting the app
    # see https://docs.microsoft.com/en-us/azure/app-service/web-sites-integrate-with-vnet for more info

    "WEBSITE_VNET_ROUTE_ALL"                = "1"

    # When we configure vnet integration, the app service would by default use the same DNS server as the virtual network.
    # This will not be able to resolve Azure DNS Private Zones, so we have to direct to an alternate DNS Server to successfully
    # resolve the private endpoints for the services we depend on, such as the database

    "WEBSITE_DNS_SERVER"                    = "168.63.129.16"

    # Azure config service related settings

    "USE_AZURE_APP_CONFIGURATION"                                 = false
    "AzureAppConfiguration:CacheExpirationIntervalInSeconds"      = "300" # 5 minutes       
    "AzureAppConfiguration:PrimaryRegionEndpoint"                 = var.forum_app_config_primary_endpoint		          
    "AzureAppConfiguration:SecondaryRegionEndpoint"               = var.forum_app_config_secondary_endpoint		          


    # TODO - Move the following settings to the azure config service for the forum once it has been integrated with the site

    "FeatureFlag_FilesAndFolders"           = true
    "AzureBlobStorage:PrimaryEndpoint"      = var.forum_primary_blob_container_endpoint		# for storing avatar and group images
    "AzureBlobStorage:ContainerName"        = var.forum_primary_blob_container_name
    "AzureBlobStorage:Provider"             = "MvcForum.Plugins.Providers.AzureBlobStorageProvider"

    # TODO - Remove and move over to file server once MVC is no longer handling file uploads to blob storage

    "AzureBlobStorage:PrimaryEndpoint_TO_BE_RETIRED" = var.files_blob_primary_endpoint
    "AzureBlobStorage:FilesPrimaryEndpoint_TO_BE_RETIRED" = var.files_blob_primary_endpoint
    "AzureBlobStorage:FilesContainerName_TO_BE_RETIRED"   = var.files_primary_blob_container_name


    # TODO - Remove these entries once they are no longer used in code
    "BlobContainer"                         = var.forum_primary_blob_container_name
    "StorageProvider"                       = "MvcForum.Plugins.Providers.AzureBlobStorageProvider"
  }

  # TODO - remove these once entity framework no longer used

  connection_string {
    name                                    = "MVCForumContext"
    type                                    = "SQLAzure"
    value                                   = var.forum_db_keyvault_readwrite_connection_string_reference
  }

  connection_string {
    name                                    = "MVCForumContextReadOnly"
    type                                    = "SQLAzure"
    value                                   = var.forum_db_keyvault_readonly_connection_string_reference
  }

  # these connection strings are not temporary

  # Add connection string for read scale-out support (available in Premium/Business Critical editions of Azure SQL by default) .. ApplicationIntent=ReadOnly

  connection_string {
    name                                    = "AzureSQL:ReadOnlyConnectionString"
    type                                    = "SQLAzure"
    value                                   = var.forum_db_keyvault_readonly_connection_string_reference
  }

  connection_string {
    name                                    = "AzureSQL:ReadWriteConnectionString"
    type                                    = "SQLAzure"
    value                                   = var.forum_db_keyvault_readwrite_connection_string_reference
  }

  connection_string {
    name                                    = "AzureBlobStorage:PrimaryConnectionString"
    type                                    = "Custom"
    value                                   = var.forum_primary_blob_keyvault_connection_string_reference
  }

  connection_string {
    name                                    = "AzureBlobStorage:FilesPrimaryConnectionString_TO_BE_RETIRED"
    type                                    = "Custom"
    value                                   = var.files_primary_blob_keyvault_connection_string_reference
  }

  #connection_string {
  #  name                                    = "AzureRedisConfiguration:PrimaryConnectionString"
  #  type                                    = "Custom"
  #  value                                   = var.forum_redis_primary_keyvault_connection_string_reference
  #}

  #connection_string {
  #  name                                    = "AzureRedisConfiguration:SecondaryConnectionString"
  #  type                                    = "Custom"
  #  value                                   = var.forum_redis_secondary_keyvault_connection_string_reference
  #}

  logs {
    detailed_error_messages_enabled         = true
    failed_request_tracing_enabled          = true

    application_logs {
      #file_system_level                     = "Error"

      azure_blob_storage { 
        level                               = "Information"	# Off | Error | Verbose | Information | Warning
        sas_url                             = "${var.log_storage_account_blob_endpoint}${var.log_storage_account_container_name}${data.azurerm_storage_account_blob_container_sas.forum_logs.sas}"
        retention_in_days                   = 90
      }
    }

    http_logs {
      azure_blob_storage { 
        sas_url                             = "${var.log_storage_account_blob_endpoint}${var.log_storage_account_container_name}${data.azurerm_storage_account_blob_container_sas.forum_logs.sas}"
        retention_in_days                   = 90
      }
      #file_system {
      #  retention_in_days                   = 90
      #  retention_in_mb                     = 35
      #}
    }
  }

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

# assign the blob reader role to the system identity so it can access the public blob storage container used by the forum to save images etc
# using its managed identity rather than having to manage connection string and sas tokens etc

resource "azurerm_role_assignment" "forum_blob_reader" {
  scope                                     = var.forum_primary_blob_container_resource_manager_id
  principal_id                              = azurerm_app_service.forum.identity[0].principal_id
  role_definition_name                      = "Storage Blob Data Contributor"
}

# TODO - Remove once file server handling uploading files to blob storage
resource "azurerm_role_assignment" "files_blob_reader" {
  scope                                     = var.files_primary_blob_container_resource_manager_id
  principal_id                              = azurerm_app_service.forum.identity[0].principal_id
  role_definition_name                      = "Storage Blob Data Contributor"
}

resource "azurerm_role_assignment" "files_blob_delegator" {
  scope                                     = var.files_primary_blob_resource_manager_id
  principal_id                              = azurerm_app_service.forum.identity[0].principal_id
  role_definition_name                      = "Storage Blob Delegator"
}

data "azurerm_monitor_diagnostic_categories" "main" {
  resource_id                                  = azurerm_app_service.forum.id
}

resource "azurerm_monitor_diagnostic_setting" "main" {
  name                                         = "app-forum-diagnostics"
  target_resource_id                           = azurerm_app_service.forum.id
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
        days    = 90
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
        days    = 90
      }
    }
  }
}

# https://docs.microsoft.com/en-us/azure/app-service/web-sites-integrate-with-vnet

# We will now set up a virtual network integration for the application service noting each app plan needs to be hooked 
# up to a different sub domain.  Azure will mount virtual interfaces for the services attached to the subnet
# Once this is done, all traffic will be kept off the public internet and we can lock down some services with private endpoints
# that the app service will now be able to navigate to.  We can also hook up a network security group to the sub domain and have 
# it restrict outbound traffic to enhance security further (can also use route tables to redirect outbound traffic if needed)

# add a delegate subnet (means the app service is given authority to configure it as needed, usually with network intent policies) 
# for the forum app service, such that it can be granted access to PaaS service private endpoints hosted in the same vnet (database etc).
# https://docs.microsoft.com/en-us/azure/virtual-network/subnet-delegation-overview

resource "azurerm_subnet" "forum" {
  name                                           = "snet-${lower(var.product_name)}-${lower(var.environment)}-${lower(var.location)}-forum"
  resource_group_name                            = azurerm_app_service.forum.resource_group_name
  virtual_network_name                           = var.virtual_network_name
  address_prefixes                               = ["10.0.2.0/24"]

  enforce_private_link_endpoint_network_policies = false
  enforce_private_link_service_network_policies  = false

  delegation {
    name = "snet-delegation-${lower(var.product_name)}-${lower(var.environment)}-${lower(var.location)}-forum"

    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

# now we need to add the vnet integration by connecting the two resources together
# TODO - temp removed to due to issue with deployment (gets stuck trying to create swift connections)
#resource "azurerm_app_service_virtual_network_swift_connection" "forum" {
#  app_service_id                                 = azurerm_app_service.forum.id
#  subnet_id                                      = azurerm_subnet.forum.id
#}

# next piece is to hook up the subnet to use our network security group

resource "azurerm_subnet_network_security_group_association" "forum_subnet" {
  subnet_id                                      = azurerm_subnet.forum.id
  network_security_group_id                      = var.virtual_network_security_group_id
}


# Set up a staging slot for the application service

resource "azurerm_app_service_slot" "forum" {
  name                                      = "staging"  # combined with app_service_name must be less than 59 characters
  location                                  = azurerm_app_service.forum.location
  resource_group_name                       = azurerm_app_service.forum.resource_group_name
  app_service_plan_id                       = azurerm_app_service_plan.forum.id
  app_service_name                          = azurerm_app_service.forum.name

  enabled                                   = true
  client_affinity_enabled                   = false
  https_only                                = true
  
  identity {
    type                                    = "SystemAssigned"
  }

  site_config {
    always_on                               = false # important we don't have this on for slots because it can cause significant IO spike to production slot on service restart
    dotnet_framework_version                = "v4.0"
    remote_debugging_enabled                = false
    remote_debugging_version                = "VS2019"
    ftps_state                              = "Disabled"
    health_check_path                       = "api/HealthCheck/heartbeat"
    http2_enabled                           = true
    ip_restriction                          = [
      {
        name                                = "VirtualNetworkAllowInbound"
        priority                            = "1"
        action                              = "Allow"
        virtual_network_subnet_id           = var.virtual_network_application_gateway_subnet_id
        ip_address                          = null
        headers                             = null
        service_tag                         = null
      }
    ] 
    scm_use_main_ip_restriction             = false   # setting this to true will cause deployment issues unless the azdo pool is granted access
    scm_ip_restriction                      = []
    scm_type                                = "VSTSRM" # "None" - workaround - see issue reported at https://github.com/terraform-providers/terraform-provider-azurerm/issues/8171
    local_mysql_enabled                     = false
    managed_pipeline_mode                   = "Integrated"
    min_tls_version                         = "1.2"
    use_32_bit_worker_process               = false
    websockets_enabled                      = false
  }

  app_settings = {
    "ASPNETCORE_ENVIRONMENT"                = var.environment                                   # this value will be used to match with the label on the environment specific configuration in the azure app config service
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = var.forum_staging_app_insights_connection_string
    "APPINSIGHTS_INSTRUMENTATIONKEY"        = var.forum_staging_app_insights_instrumentation_key
    "APPINSIGHTS_PROFILERFEATURE_VERSION"   = "1.0.0"
    "DiagnosticServices_EXTENSION_VERSION"  = "~3"
    "WEBSITE_VNET_ROUTE_ALL"                = "1"
    "WEBSITE_DNS_SERVER"                    = "168.63.129.16"
    "USE_AZURE_APP_CONFIGURATION"                                 = false
    "AzureAppConfiguration:CacheExpirationIntervalInSeconds"      = "300" # 5 minutes       
    "AzureAppConfiguration:PrimaryRegionEndpoint"                 = var.forum_app_config_primary_endpoint		          
    "AzureAppConfiguration:SecondaryRegionEndpoint"               = var.forum_app_config_secondary_endpoint		          
    "FeatureFlag_FilesAndFolders"           = true
    "AzureBlobStorage:PrimaryEndpoint_TO_BE_RETIRED"      = var.files_blob_primary_endpoint
    "AzureBlobStorage:FilesPrimaryEndpoint_TO_BE_RETIRED" = var.files_blob_primary_endpoint #Code using this value for wrong thing so temporarily setting to storage account endpoint but should really be files_primary_blob_container_endpoint		# for storing files
    "AzureBlobStorage:FilesContainerName_TO_BE_RETIRED"   = var.files_primary_blob_container_name
    "BlobContainer"                                       = var.forum_primary_blob_container_name
    "StorageProvider"                                     = "MvcForum.Plugins.Providers.AzureBlobStorageProvider"
  }

  # TODO - remove these once entity framework no longer used

  connection_string {
    name                                    = "MVCForumContext"
    type                                    = "SQLAzure"
    value                                   = var.forum_db_keyvault_readwrite_connection_string_reference
  }

  connection_string {
    name                                    = "MVCForumContextReadOnly"
    type                                    = "SQLAzure"
    value                                   = var.forum_db_keyvault_readonly_connection_string_reference
  }

  # these connection strings are not temporary

  # Add connection string for read scale-out support (available in Premium/Business Critical editions of Azure SQL by default) .. ApplicationIntent=ReadOnly

  connection_string {
    name                                    = "AzureSQL:ReadOnlyConnectionString"
    type                                    = "SQLAzure"
    value                                   = var.forum_db_keyvault_readonly_connection_string_reference
  }

  connection_string {
    name                                    = "AzureSQL:ReadWriteConnectionString"
    type                                    = "SQLAzure"
    value                                   = var.forum_db_keyvault_readwrite_connection_string_reference
  }

  connection_string {
    name                                    = "AzureBlobStorage:PrimaryConnectionString"
    type                                    = "Custom"
    value                                   = var.forum_primary_blob_keyvault_connection_string_reference
  }

  connection_string {
    name                                    = "AzureBlobStorage:FilesPrimaryConnectionString_TO_BE_RETIRED"
    type                                    = "Custom"
    value                                   = var.files_primary_blob_keyvault_connection_string_reference
  }

  #connection_string {
  #  name                                    = "AzureRedisConfiguration:PrimaryConnectionString"
  #  type                                    = "Custom"
  #  value                                   = var.forum_redis_primary_keyvault_connection_string_reference
  #}

  #connection_string {
  #  name                                    = "AzureRedisConfiguration:SecondaryConnectionString"
  #  type                                    = "Custom"
  #  value                                   = var.forum_redis_secondary_keyvault_connection_string_reference
  #}

  logs {
    detailed_error_messages_enabled         = true
    failed_request_tracing_enabled          = true

    application_logs {
      azure_blob_storage { 
        level                               = "Information"	# Off | Error | Verbose | Information | Warning
        sas_url                             = "${var.log_storage_account_blob_endpoint}${var.log_storage_account_container_name}${data.azurerm_storage_account_blob_container_sas.forum_logs.sas}"
        retention_in_days                   = 90
      }
    }

    http_logs {
      azure_blob_storage { 
        sas_url                             = "${var.log_storage_account_blob_endpoint}${var.log_storage_account_container_name}${data.azurerm_storage_account_blob_container_sas.forum_logs.sas}"
        retention_in_days                   = 90
      }
    }
  }

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

resource "azurerm_role_assignment" "forum_staging_slot_blob_reader" {
  scope                                     = var.forum_primary_blob_container_resource_manager_id
  principal_id                              = azurerm_app_service_slot.forum.identity[0].principal_id
  role_definition_name                      = "Storage Blob Data Contributor"
}

# TODO - Remove once file server handling uploading/downloading files to blob storage
resource "azurerm_role_assignment" "files_staging_slot_blob_reader" {
  scope                                     = var.files_primary_blob_container_resource_manager_id
  principal_id                              = azurerm_app_service_slot.forum.identity[0].principal_id
  role_definition_name                      = "Storage Blob Data Contributor"
}

resource "azurerm_role_assignment" "files_staging_slot_blob_delegator" {
  scope                                     = var.files_primary_blob_resource_manager_id
  principal_id                              = azurerm_app_service_slot.forum.identity[0].principal_id
  role_definition_name                      = "Storage Blob Delegator"
}

data "azurerm_monitor_diagnostic_categories" "forum_staging_slot" {
  resource_id                                  = azurerm_app_service_slot.forum.id
}

resource "azurerm_monitor_diagnostic_setting" "forum_staging_slot" {
  name                                         = "app-forum-staging-diagnostics"
  target_resource_id                           = azurerm_app_service_slot.forum.id
  log_analytics_workspace_id                   = var.log_analytics_workspace_resource_id
  storage_account_id                           = var.log_storage_account_id

  dynamic "log" {
    iterator = log_category
    for_each = data.azurerm_monitor_diagnostic_categories.forum_staging_slot.logs

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
    for_each = data.azurerm_monitor_diagnostic_categories.forum_staging_slot.metrics

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

# TODO - temp removed to due to issue with deployment (gets stuck trying to create swift connections)
#resource "azurerm_app_service_slot_virtual_network_swift_connection" "forum_staging_slot" {
#  slot_name                                      = azurerm_app_service_slot.forum.name
#  app_service_id                                 = azurerm_app_service.forum.id
#  subnet_id                                      = azurerm_subnet.forum.id
#}
