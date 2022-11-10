data "azurerm_storage_account_blob_container_sas" "web_logs" {
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

resource "azurerm_app_service_plan" "web" {
  name                                      = "plan-${lower(var.product_name)}-${lower(var.environment)}-${lower(var.location)}-web"
  location                                  = var.location
  resource_group_name                       = var.resource_group_name
  kind                                      = "Linux" # "Windows"
  per_site_scaling                          = true
  reserved                                  = true #true for linux and false for windows  

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
  resource_id                                  = azurerm_app_service_plan.web.id
}

resource "azurerm_monitor_diagnostic_setting" "plan" {
  name                                         = "plan-web-diagnostics"
  target_resource_id                           = azurerm_app_service_plan.web.id
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


resource "azurerm_app_service" "web" {
  #checkov:skip=CKV_AZURE_13:Authentication is taken care of by the application and we do not need to use the federation services provided by Azure
  name                                      = "app-${lower(var.product_name)}-${lower(var.environment)}-${lower(var.location)}-web"
  location                                  = var.location
  resource_group_name                       = var.resource_group_name
  app_service_plan_id                       = azurerm_app_service_plan.web.id

  enabled                                   = true
  client_affinity_enabled                   = false
  client_cert_enabled                       = false
  https_only                                = true
  
  identity {
    type                                    = "SystemAssigned"
  }

  site_config {
    always_on                               = true
    linux_fx_version                        = "NODE|14-lts"   
    remote_debugging_enabled                = false
    remote_debugging_version                = "VS2019"
    ftps_state                              = "Disabled"
    health_check_path                       = "/health-check"
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

  # For a list of the Azure owned config settings, visit https://docs.microsoft.com/en-us/azure/app-service/reference-app-settings
  # https://whatazurewebsiteenvironmentvariablesareavailable.azurewebsites.net/
  
  app_settings = {
    "APP_ENVIRONMENT"                       = var.environment                                   # this value will be used to match with the label on the environment specific configuration in the azure app config service
    "APP_URL"                               = "${var.application_fqdn}"

    "APPLICATIONINSIGHTS_CONNECTION_STRING" = var.web_app_insights_connection_string

    # Enable app service profiling - 
    # see https://docs.microsoft.com/en-us/azure/azure-monitor/app/profiler-overview
    # and https://docs.microsoft.com/en-us/azure/azure-monitor/app/profiler?toc=/azure/azure-monitor/toc.json 
   
    "APPINSIGHTS_INSTRUMENTATIONKEY"        = var.web_app_insights_instrumentation_key
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

    "WEBSITES_ENABLE_APP_SERVICE_STORAGE"   = false
    #"WEBSITES_PORT"                         = "5000" # the port vNext.App is listening on

    # use app config store to get settings for the environment including feature flags, storage endpoints etc

    "USE_AZURE_APP_CONFIGURATION"           = true 
    "AZUREPLATFORM_AZUREAPPCONFIGURATION_CACHEEXPIRATIONINTERVALINSECONDS"      = "300" # 5 minutes       
    "AZUREPLATFORM_AZUREAPPCONFIGURATION_PRIMARYSERVICEURL"                     = var.web_app_config_primary_endpoint		          
    "AZUREPLATFORM_AZUREAPPCONFIGURATION_GEOREDUNDANTSERVICEURL"                = var.web_app_config_secondary_endpoint		          

    "SHAREDSECRETS_APIAPPLICATION"                                              = var.web_api_keyvault_application_shared_secret_reference  

    #"WEBSITE_NODE_DEFAULT_VERSION"                                              = "14.18.1" # only needed for Windows plan  

    "NEXT_PUBLIC_MVC_FORUM_REFRESH_TOKEN_URL"                                   = "https://app-${lower(var.product_name)}-${lower(var.environment)}-${lower(var.location)}-forum.azurewebsites.net/auth/userinfo"
    "NEXT_PUBLIC_MVC_FORUM_LOGIN_URL"                                           = "${var.application_fqdn}/members/logon"
    "MVC_FORUM_HEALTH_CHECK_URL"                                                = "https://app-${lower(var.product_name)}-${lower(var.environment)}-${lower(var.location)}-forum.azurewebsites.net/api/healthcheck/heartbeat"
    "NEXT_PUBLIC_API_BASE_URL"                                                  = "https://app-${lower(var.product_name)}-${lower(var.environment)}-${lower(var.location)}-api.azurewebsites.net/api"
    "NEXT_PUBLIC_API_GATEWAY_BASE_URL"                                          = "${var.application_fqdn}/gateway/api"
    "API_HEALTH_CHECK_URL"                                                      = "https://app-${lower(var.product_name)}-${lower(var.environment)}-${lower(var.location)}-api.azurewebsites.net/health-check"

    "COOKIE_PARSER_SECRET"                                                      = var.web_cookie_parser_secret
    "NEXT_PUBLIC_GTM_KEY"                                                       = var.web_next_public_gtm_key  

    ## NextAuth
    "NEXTAUTH_URL"                                                              = "${var.application_fqdn}"
    "NEXTAUTH_SECRET"                                                           = var.web_nextauth_secret
    "AZURE_AD_B2C_TENANT_NAME"                                                  = var.web_azure_ad_b2c_tenant_name
    "AZURE_AD_B2C_CLIENT_ID"                                                    = var.web_azure_ad_b2c_client_id
    "AZURE_AD_B2C_CLIENT_SECRET"                                                = var.web_azure_ad_b2c_client_secret
    "AZURE_AD_B2C_PRIMARY_USER_FLOW"                                            = var.web_azure_ad_b2c_primary_user_flow
    "AZURE_AD_B2C_SIGNUP_USER_FLOW"                                             = var.web_azure_ad_b2c_signup_user_flow
    "AZURE_AD_B2C_PASSWORD_RESET_USER_FLOW"                                     = var.web_azure_ad_b2c_password_reset_user_flow
  }

  logs {
    detailed_error_messages_enabled         = true
    failed_request_tracing_enabled          = true

    application_logs {
      #file_system_level                     = "Error"

      azure_blob_storage { 
        level                               = "Information"	# Off | Error | Verbose | Information | Warning
        sas_url                             = "${var.log_storage_account_blob_endpoint}${var.log_storage_account_container_name}${data.azurerm_storage_account_blob_container_sas.web_logs.sas}"
        retention_in_days                   = 90
      }
    }

    http_logs {
      azure_blob_storage { 
        sas_url                             = "${var.log_storage_account_blob_endpoint}${var.log_storage_account_container_name}${data.azurerm_storage_account_blob_container_sas.web_logs.sas}"
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


# now assign reader role to app configuration service so we can use managed identity to access it

resource "azurerm_role_assignment" "web_app_config_data_reader" {
  scope                                     = var.web_primary_app_configuration_id
  principal_id                              = azurerm_app_service.web.identity[0].principal_id
  role_definition_name                      = "App Configuration Data Reader"
}

data "azurerm_monitor_diagnostic_categories" "web" {
  resource_id                                  = azurerm_app_service.web.id
}

resource "azurerm_monitor_diagnostic_setting" "web" {
  name                                         = "app-web-diagnostics"
  target_resource_id                           = azurerm_app_service.web.id
  log_analytics_workspace_id                   = var.log_analytics_workspace_resource_id
  storage_account_id                           = var.log_storage_account_id

  dynamic "log" {
    iterator = log_category
    for_each = data.azurerm_monitor_diagnostic_categories.web.logs

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
    for_each = data.azurerm_monitor_diagnostic_categories.web.metrics

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

resource "azurerm_subnet" "web" {
  name                                           = "snet-${lower(var.product_name)}-${lower(var.environment)}-${lower(var.location)}-web"
  resource_group_name                            = azurerm_app_service.web.resource_group_name
  virtual_network_name                           = var.virtual_network_name
  address_prefixes                               = ["10.0.6.0/24"]

  enforce_private_link_endpoint_network_policies = false
  enforce_private_link_service_network_policies  = false

  delegation {
    name = "snet-delegation-${lower(var.product_name)}-${lower(var.environment)}-${lower(var.location)}-web"

    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
  
  # configure the service endpoint that will allow us to connect to the API and MVCForum subnet to interact directly (without
  # having to route through our application gateway)
  service_endpoints                              = [
    "Microsoft.Web"
  ]
}

# now we need to add the vnet integration by connecting the two resources together

resource "azurerm_app_service_virtual_network_swift_connection" "web" {
  app_service_id                                 = azurerm_app_service.web.id
  subnet_id                                      = azurerm_subnet.web.id
}

# next piece is to hook up the subnet to use our network security group

resource "azurerm_subnet_network_security_group_association" "web" {
  subnet_id                                      = azurerm_subnet.web.id
  network_security_group_id                      = var.virtual_network_security_group_id
}



# set up the staging slot for blue/green deployment strategy

resource "azurerm_app_service_slot" "web" {
  name                                      = "staging"  # combined with app_service_name must be less than 59 characters
  location                                  = azurerm_app_service.web.location
  resource_group_name                       = azurerm_app_service.web.resource_group_name
  app_service_plan_id                       = azurerm_app_service_plan.web.id
  app_service_name                          = azurerm_app_service.web.name

  enabled                                   = true
  client_affinity_enabled                   = false
  https_only                                = true
  
  identity {
    type                                    = "SystemAssigned"
  }

  site_config {
    always_on                               = false # important we don't have this on for slots because it can cause significant IO spike to production slot on service restart
    linux_fx_version                        = "NODE|14-lts"
    remote_debugging_enabled                = false
    remote_debugging_version                = "VS2019"
    ftps_state                              = "Disabled"
    health_check_path                       = "/health-check"
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
    "APP_ENVIRONMENT"                       = var.environment                                   # this value will be used to match with the label on the environment specific configuration in the azure app config service
    "APP_URL"                               = "${var.application_fqdn}"    
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = var.web_staging_app_insights_connection_string
    "APPINSIGHTS_INSTRUMENTATIONKEY"        = var.web_staging_app_insights_instrumentation_key
    "APPINSIGHTS_PROFILERFEATURE_VERSION"   = "1.0.0"
    "DiagnosticServices_EXTENSION_VERSION"  = "~3"
    "WEBSITE_VNET_ROUTE_ALL"                = "1"
    "WEBSITE_DNS_SERVER"                    = "168.63.129.16"
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE"   = false
    #"WEBSITES_PORT"                         = "5000" # the port vNext.App is listening on

    "USE_AZURE_APP_CONFIGURATION"           = true 
    
    "AZUREPLATFORM_AZUREAPPCONFIGURATION_CACHEEXPIRATIONINTERVALINSECONDS"      = "300" # 5 minutes       
    "AZUREPLATFORM_AZUREAPPCONFIGURATION_PRIMARYSERVICEURL"                     = var.web_app_config_primary_endpoint		          
    "AZUREPLATFORM_AZUREAPPCONFIGURATION_GEOREDUNDANTSERVICEURL"                = var.web_app_config_secondary_endpoint		          

    "SHAREDSECRETS_APIAPPLICATION"                                              = var.web_api_keyvault_application_shared_secret_reference    

    #"WEBSITE_NODE_DEFAULT_VERSION"                                              = "14.18.1" # only needed for Windows plan  

    "NEXT_PUBLIC_MVC_FORUM_REFRESH_TOKEN_URL"                                   = "https://app-${lower(var.product_name)}-${lower(var.environment)}-${lower(var.location)}-forum.azurewebsites.net/auth/userinfo"
    "NEXT_PUBLIC_MVC_FORUM_LOGIN_URL"                                           = "${var.application_fqdn}/members/logon"
    "MVC_FORUM_HEALTH_CHECK_URL"                                                = "https://app-${lower(var.product_name)}-${lower(var.environment)}-${lower(var.location)}-forum.azurewebsites.net/api/healthcheck/heartbeat"
    "NEXT_PUBLIC_API_BASE_URL"                                                  = "https://app-${lower(var.product_name)}-${lower(var.environment)}-${lower(var.location)}-api.azurewebsites.net/api"
    "NEXT_PUBLIC_API_GATEWAY_BASE_URL"                                          = "${var.application_fqdn}/gateway/api"    
    "API_HEALTH_CHECK_URL"                                                      = "https://app-${lower(var.product_name)}-${lower(var.environment)}-${lower(var.location)}-api.azurewebsites.net/health-check"
    "COOKIE_PARSER_SECRET"                                                      = var.web_cookie_parser_secret
    "NEXT_PUBLIC_GTM_KEY"                                                       = var.web_next_public_gtm_key

    ## NextAuth
    "NEXTAUTH_URL"                                                              = "${var.application_fqdn}"
    "NEXTAUTH_SECRET"                                                           = var.web_nextauth_secret
    "AZURE_AD_B2C_TENANT_NAME"                                                  = var.web_azure_ad_b2c_tenant_name
    "AZURE_AD_B2C_CLIENT_ID"                                                    = var.web_azure_ad_b2c_client_id
    "AZURE_AD_B2C_CLIENT_SECRET"                                                = var.web_azure_ad_b2c_client_secret
    "AZURE_AD_B2C_PRIMARY_USER_FLOW"                                            = var.web_azure_ad_b2c_primary_user_flow
    "AZURE_AD_B2C_SIGNUP_USER_FLOW"                                             = var.web_azure_ad_b2c_signup_user_flow
    "AZURE_AD_B2C_PASSWORD_RESET_USER_FLOW"                                     = var.web_azure_ad_b2c_password_reset_user_flow

  }

  logs {
    detailed_error_messages_enabled         = true
    failed_request_tracing_enabled          = true

    application_logs {
      azure_blob_storage { 
        level                               = "Information"	# Off | Error | Verbose | Information | Warning
        sas_url                             = "${var.log_storage_account_blob_endpoint}${var.log_storage_account_container_name}${data.azurerm_storage_account_blob_container_sas.web_logs.sas}"
        retention_in_days                   = 90
      }
    }

    http_logs {
      azure_blob_storage { 
        sas_url                             = "${var.log_storage_account_blob_endpoint}${var.log_storage_account_container_name}${data.azurerm_storage_account_blob_container_sas.web_logs.sas}"
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

resource "azurerm_role_assignment" "web_staging_slot_app_config_data_reader" {
  scope                                     = var.web_primary_app_configuration_id
  principal_id                              = azurerm_app_service_slot.web.identity[0].principal_id
  role_definition_name                      = "App Configuration Data Reader"
}

data "azurerm_monitor_diagnostic_categories" "web_staging_slot" {
  resource_id                                  = azurerm_app_service_slot.web.id
}

resource "azurerm_monitor_diagnostic_setting" "web_staging_slot" {
  name                                         = "app-web-diagnostics"
  target_resource_id                           = azurerm_app_service_slot.web.id
  log_analytics_workspace_id                   = var.log_analytics_workspace_resource_id
  storage_account_id                           = var.log_storage_account_id

  dynamic "log" {
    iterator = log_category
    for_each = data.azurerm_monitor_diagnostic_categories.web_staging_slot.logs

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
    for_each = data.azurerm_monitor_diagnostic_categories.web_staging_slot.metrics

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

resource "azurerm_app_service_slot_virtual_network_swift_connection" "web_staging_slot" {
  slot_name                                      = azurerm_app_service_slot.web.name
  app_service_id                                 = azurerm_app_service.web.id
  subnet_id                                      = azurerm_subnet.web.id
}
