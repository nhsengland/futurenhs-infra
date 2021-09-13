data "azurerm_storage_account_blob_container_sas" "collabora_logs" {
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

resource "azurerm_app_service_plan" "collabora" {
  name                                      = "plan-${lower(var.product_name)}-${lower(var.environment)}-${lower(var.location)}-collabora"
  location                                  = var.location
  resource_group_name                       = var.resource_group_name
  kind                                      = "Linux"
  per_site_scaling                          = true
  reserved                                  = true  

  sku {
    tier                                    = "PremiumV2" # needed for deployment slots, auto-scaling and vnet integration
    size                                    = "P1v2"      
    capacity                                = 1 # TODO - Increase for production
  }

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

data "azurerm_monitor_diagnostic_categories" "plan" {
  resource_id                                  = azurerm_app_service_plan.collabora.id
}

resource "azurerm_monitor_diagnostic_setting" "plan" {
  name                                         = "plan-collabora-diagnostics"
  target_resource_id                           = azurerm_app_service_plan.collabora.id
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


resource "azurerm_app_service" "collabora" {
  #checkov:skip=CKV_AZURE_13:Authentication is taken care of by the application and we do not need to use the federation services provided by Azure
  name                                      = "app-${lower(var.product_name)}-${lower(var.environment)}-${lower(var.location)}-collabora"
  location                                  = var.location
  resource_group_name                       = var.resource_group_name
  app_service_plan_id                       = azurerm_app_service_plan.collabora.id

  enabled                                   = true
  client_affinity_enabled                   = true
  client_cert_enabled                       = false
  https_only                                = true
  
  identity {
    type                                    = "SystemAssigned"
  }

  site_config {
    always_on                               = true
    dotnet_framework_version                = "v5.0"
    remote_debugging_enabled                = false
    remote_debugging_version                = "VS2019"
    ftps_state                              = "Disabled"
    health_check_path                       = "/"
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
    websockets_enabled                      = true

    # this next bit will configure the docker container hosting collabora CODE
    # I toyed with doing this in the deployment pipeline using the Azure Web App for Containers task so we had a little
    # more control on when the container is updated, but I think this will be better managed longer term by us using our
    # own azure container registry and deploying a container to it.  For now (dev) we'll pull the latest version from 
    # docker hub, albeit acknowldging this could break the environment so is not appropriate for prodction

    app_command_line                        = "" # this bit is appended to the end of the docker run command after the container source
    linux_fx_version                        = "DOCKER|richardcds/fnhs-wopi-client:${lower(var.environment)}-latest" 
  }

  app_settings = {
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = var.collabora_app_insights_connection_string

    # Enable app service profiling - 
    # see https://docs.microsoft.com/en-us/azure/azure-monitor/app/profiler-overview
    # and https://docs.microsoft.com/en-us/azure/azure-monitor/app/profiler?toc=/azure/azure-monitor/toc.json 
   
    "APPINSIGHTS_INSTRUMENTATIONKEY"        = var.collabora_app_insights_instrumentation_key
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

    # configure the container stuff so we can pull down from docker hub noting we are pulling from the public repository
    # so no need to provide authentication details

    "WEBSITES_ENABLE_APP_SERVICE_STORAGE"   = false
    "WEBSITES_PORT"                         = "9980" # the port collabora is listening on

    "DOCKER_REGISTRY_SERVER_URL"            = "https://index.docker.io"
#    "DOCKER_REGSITRY_SERVER_USERNAME"       = ""
#    "DOCKER_REGSITRY_SERVER_PASSWORD"       = ""
  }

  logs {
    detailed_error_messages_enabled         = true
    failed_request_tracing_enabled          = true

    application_logs {
      #file_system_level                     = "Error"

      azure_blob_storage { 
        level                               = "Information"	# Off | Error | Verbose | Information | Warning
        sas_url                             = "${var.log_storage_account_blob_endpoint}${var.log_storage_account_container_name}${data.azurerm_storage_account_blob_container_sas.collabora_logs.sas}"
        retention_in_days                   = 90
      }
    }

    http_logs {
      azure_blob_storage { 
        sas_url                             = "${var.log_storage_account_blob_endpoint}${var.log_storage_account_container_name}${data.azurerm_storage_account_blob_container_sas.collabora_logs.sas}"
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

data "azurerm_monitor_diagnostic_categories" "collabora" {
  resource_id                                  = azurerm_app_service.collabora.id
}

resource "azurerm_monitor_diagnostic_setting" "collabora" {
  name                                         = "app-collabora-diagnostics"
  target_resource_id                           = azurerm_app_service.collabora.id
  log_analytics_workspace_id                   = var.log_analytics_workspace_resource_id
  storage_account_id                           = var.log_storage_account_id

  dynamic "log" {
    iterator = log_category
    for_each = data.azurerm_monitor_diagnostic_categories.collabora.logs

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
    for_each = data.azurerm_monitor_diagnostic_categories.collabora.metrics

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
# for the app service, such that it can be granted access to PaaS service private endpoints hosted in the same vnet (database etc).
# https://docs.microsoft.com/en-us/azure/virtual-network/subnet-delegation-overview

resource "azurerm_subnet" "collabora" {
  name                                           = "snet-${lower(var.product_name)}-${lower(var.environment)}-${lower(var.location)}-collabora"
  resource_group_name                            = azurerm_app_service.collabora.resource_group_name
  virtual_network_name                           = var.virtual_network_name
  address_prefixes                               = ["10.0.4.0/24"]

  enforce_private_link_endpoint_network_policies = false
  enforce_private_link_service_network_policies  = false

  delegation {
    name = "snet-delegation-${lower(var.product_name)}-${lower(var.environment)}-${lower(var.location)}-collabora"

    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

# now we need to add the vnet integration by connecting the two resources together
# TODO - temp removed to due to issue with deployment (gets stuck trying to create swift connections)
#resource "azurerm_app_service_virtual_network_swift_connection" "collabora" {
#  app_service_id                                 = azurerm_app_service.collabora.id
#  subnet_id                                      = azurerm_subnet.collabora.id
#}

# next piece is to hook up the subnet to use our network security group

resource "azurerm_subnet_network_security_group_association" "collabora" {
  subnet_id                                      = azurerm_subnet.collabora.id
  network_security_group_id                      = var.virtual_network_security_group_id
}



# set up the staging slot for blue/green deployment strategy

resource "azurerm_app_service_slot" "collabora" {
  name                                      = "staging"  # combined with app_service_name must be less than 59 characters
  location                                  = azurerm_app_service.collabora.location
  resource_group_name                       = azurerm_app_service.collabora.resource_group_name
  app_service_plan_id                       = azurerm_app_service_plan.collabora.id
  app_service_name                          = azurerm_app_service.collabora.name

  enabled                                   = true
  client_affinity_enabled                   = true
  https_only                                = true
  
  identity {
    type                                    = "SystemAssigned"
  }

  site_config {
    always_on                               = false # important we don't have this on for slots because it can cause significant IO spike to production slot on service restart
    dotnet_framework_version                = "v5.0"
    remote_debugging_enabled                = false
    remote_debugging_version                = "VS2019"
    ftps_state                              = "Disabled"
    health_check_path                       = "/"
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
    websockets_enabled                      = true
  }

  app_settings = {
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = var.collabora_staging_app_insights_connection_string
    "APPINSIGHTS_INSTRUMENTATIONKEY"        = var.collabora_staging_app_insights_instrumentation_key
    "APPINSIGHTS_PROFILERFEATURE_VERSION"   = "1.0.0"
    "DiagnosticServices_EXTENSION_VERSION"  = "~3"
    "WEBSITE_VNET_ROUTE_ALL"                = "1"
    "WEBSITE_DNS_SERVER"                    = "168.63.129.16"
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE"   = false
    "WEBSITES_PORT"                         = "9980" # the port collabora is listening on
    "DOCKER_REGISTRY_SERVER_URL"            = "https://index.docker.io"
#    "DOCKER_REGSITRY_SERVER_USERNAME"       = ""
#    "DOCKER_REGSITRY_SERVER_PASSWORD"       = ""

  }

  logs {
    detailed_error_messages_enabled         = true
    failed_request_tracing_enabled          = true

    application_logs {
      azure_blob_storage { 
        level                               = "Information"	# Off | Error | Verbose | Information | Warning
        sas_url                             = "${var.log_storage_account_blob_endpoint}${var.log_storage_account_container_name}${data.azurerm_storage_account_blob_container_sas.collabora_logs.sas}"
        retention_in_days                   = 90
      }
    }

    http_logs {
      azure_blob_storage { 
        sas_url                             = "${var.log_storage_account_blob_endpoint}${var.log_storage_account_container_name}${data.azurerm_storage_account_blob_container_sas.collabora_logs.sas}"
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

data "azurerm_monitor_diagnostic_categories" "collabora_staging_slot" {
  resource_id                                  = azurerm_app_service_slot.collabora.id
}

resource "azurerm_monitor_diagnostic_setting" "collabora_staging_slot" {
  name                                         = "app-collabora-diagnostics"
  target_resource_id                           = azurerm_app_service_slot.collabora.id
  log_analytics_workspace_id                   = var.log_analytics_workspace_resource_id
  storage_account_id                           = var.log_storage_account_id

  dynamic "log" {
    iterator = log_category
    for_each = data.azurerm_monitor_diagnostic_categories.collabora_staging_slot.logs

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
    for_each = data.azurerm_monitor_diagnostic_categories.collabora_staging_slot.metrics

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
#resource "azurerm_app_service_slot_virtual_network_swift_connection" "collabora_staging_slot" {
#  slot_name                                      = azurerm_app_service_slot.collabora.name
#  app_service_id                                 = azurerm_app_service.collabora.id
#  subnet_id                                      = azurerm_subnet.collabora.id
#}
